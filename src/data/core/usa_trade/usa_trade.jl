include("./data_defines.jl")


function load_usa_trade!(GU,data_dir,info_dict)



    df = load_raw_usa_trade(data_dir,info_dict)

    id = Dict("path" => raw"\USATradeOnline\commodity_detail_by_state_cy.xlsx")
    usda = load_raw_usda_trade_shares(data_dir,id)
    
    function mean(x)
        sum(x)/length(x)
    end
    
    # Fill out all missing years/values
    
    regions = DataFrame([unique(df[!,:r])],[:r])
    i = DataFrame([unique(df[!,:i])],[:i])
    flows = DataFrame([unique(df[!,:flow])],[:flow])
    years = DataFrame([unique(df[!,:year])],[:year])
    
    X = crossjoin(regions,i,years,flows)
    
    df = df |>
        x -> outerjoin(x,X, on = [:r,:i,:year,:flow]) |>
        x -> coalesce.(x,0) 
    
    # Make year sums
    Y = df |>
        x -> groupby(x,[:i,:flow,:r]) |>
        x -> combine(x, :value => sum => :yr_sum)
    
    # Make year/region sums
    X = df |>
        x -> groupby(x, [:i,:flow]) |>
        x -> combine(x, :value => sum => :yr_r_sum) 
    
    # Make value sums and add in year sums
    df = df |> 
        x -> groupby(x, [:year,:flow,:i]) |>
        x -> combine(x, 
                :value=> sum ,
                ) |>
        x -> leftjoin(df,x, on = [:i,:flow,:year]) |>
        x -> leftjoin(x, X, on = [:i,:flow]) |>
        x -> leftjoin(x, Y, on = [:i,:flow,:r])
    
    
    function f(value,value_sum,yr_sum,yr_r_sum)
        if value_sum !=0 
            return value/value_sum
        else
            return yr_sum/yr_r_sum
        end
    end
    
    df = df |>
        x-> transform(x, 
            [:value,:value_sum,:yr_sum,:yr_r_sum] => ((v,vs,ys,yrs) -> f.(v,vs,ys,yrs))=>:value
        ) |>
        x -> select(x, [:r,:i,:year,:flow,:value]) |>
        x -> leftjoin(x,usda, on = [:r, :year,:i,:flow],makeunique=true) |>
        x -> coalesce.(x,0) |>
        x -> transform(x, [:value,:value_1] => ((v,v1) -> ifelse.(v1.==0,v,v1))=>:value) |>
        x -> select(x, [:r,:i,:year,:flow,:value]) |>
        x -> transform(x, :flow => (y->Symbol.(y)) => :flow)
    
    
    
    col_set_link = Dict(
        :yr => :year, 
        :r => :r, 
        :i => :i,
        :flow => :flow,
    )


    @create_set!(GU,:flow,"Trade Flow",begin
        imports, "Imports"
        exports, "Exports"
    end)

    @create_parameters(GU,begin
        :usatrd_shr, (:yr, :r,:i,:flow), "Share of total trade by region"
    end)

    fill_parameter!(GU, df, :usatrd_shr, col_set_link, Dict())


    

    return GU

end







function load_raw_usa_trade(data_dir, info_dict)

    out = DataFrame()
    notations = []

    push!(notations, WiNDC.notation_link(states,:State,:region_fullname));
    push!(notations, WiNDC.notation_link(naics_map,:naics,:naics));    

    for (flow,dict) in info_dict
        file_path = dict["path"]

        col_rename = dict["col_rename"]

        df = DataFrame(CSV.File("$data_dir/$file_path",header=4,select=1:5,stringtype=String,silencewarnings=true)) |>
            x -> rename(x, col_rename => "value") |>
            x -> filter(:Time => y-> !occursin("through",y), x) |>
            x -> filter(:Country => y-> y=="World Total", x) |>
            x -> transform(x, 
                :value => (y -> parse.(Int,replace.(y,","=>""))/1_000_000) => :value,
                :Time => (y -> parse.(Int,y)) => :year,
                :Commodity => (y -> [String(e[1]) for e in split.(y)]) => :naics,
                :value => (y -> flow) => :flow
                ) |>
            x -> filter(:year => y->y<=2021, x) |>
            x -> apply_notations(x, notations) |>
            x -> groupby(x, [:i, :region_abbv,:year,:flow]) |>
            x -> combine(x, :value => sum => :value) |> 
            x -> transform(x, 
                :region_abbv => (y->Symbol.(y)) => :r,
                :year => (y-> Symbol.(y)) => :year,
                ) |>
            x -> select(x, [:r,:i,:year,:flow,:value]) 
        out = vcat(out,df)
    end
    return out
end



function load_raw_usda_trade_shares(data_dir,info_dict)
    file_path = info_dict["path"]
    #C:\Users\mphillipson\Documents\WiNDC\windc_raw_data\windc_2021\USATradeOnline\commodity_detail_by_state_cy.xlsx
    notations = []

    push!(notations, WiNDC.notation_link(states,:State,:region_fullname));

    X = XLSX.readdata("$data_dir/$file_path","Total exports","A3:W55")
    X[1,1] = "State"
    X = DataFrame(X[4:end,:], X[1,:]) |>
        x -> apply_notations(x,notations) |>
        x -> stack(x, Not(:region_abbv), variable_name = :year,value_name =:value) |>
        x -> transform(x, 
            :year => (y -> parse.(Int,y)) => :year,
            #:value => (y -> parse.(Float64,y)) => :value
        )

    X = X |>
        x -> groupby(x, [:year]) |>
        x -> combine(x, :value => sum => :r_sum) |>
        x -> leftjoin(X,x, on = :year) |>
        x -> transform(x, 
            [:value,:r_sum] => ((v,r) -> v./r) => :value,
            :region_abbv => (a -> :agr) => :i,
            :region_abbv => (a -> "exports") => :flow,
            :region_abbv => (a -> Symbol.(a)) => :r,
            :year => (a -> Symbol.(a)) => :year,
            ) |>
        x -> select(x, [:r,:year,:i,:flow,:value])

    return X
end
