include("./data_defines.jl")

function load_bea_gsp!(GU,data_dir,gsp_info)

    @create_parameters(GU,begin
        :region_shr, (:yr,:r,:i), "Regional share of value added"
        :labor_shr, (:yr,:r,:i), "Estimated share of regional value added due to labor"
    end)

    df = load_raw_bea_gsp(data_dir,1997:2021,gsp_info)
    df = clean_raw_bea_gsp(df)

    df = unstack(df,:gdpcat,:value);

    # Region Shares
    df[!,:gdp_calc] = df[!,:cmp] + df[!,:gos] + df[!,:taxsbd]
    df[!,:gdp_diff] = df[!,:gdp] - df[!,:gdp_calc];



    X = df[!,[:region_abbv,:year,:i,:gdp]]
    Y = groupby(X,[:year,:i])

    C = combine(Y,:gdp=>sum)

    Y = leftjoin(X,C,on = [:year,:i])




    df[!,:region_shr] = Y[!,:gdp]./Y[!,:gdp_sum]

    for row in eachrow(df)
        d = [[row[e]] for e∈[:year,:region_abbv,:i]]
        GU[:region_shr][d...] = row[:region_shr]
    end


    klshare = create_klshare(GU,df)


        

    models = Dict()
    for yr∈GU[:yr],s∈GU[:i]
            
        function filter_cond(year,i)
            year==yr && i==s
        end

        klshare_l = GamsParameter(GU,(:r,:yr))
        klshare_k = GamsParameter(GU,(:r,))
        klshare_l_nat = GamsParameter(GU,(:r,))
        klshare_k_nat = GamsParameter(GU,(:r,))

        for y∈rolling_average_years(yr,8)

            X = filter([:year,:i]=> (year,i) -> year==y && i==s, klshare)
            for row∈eachrow(X)
                r = row[:region_abbv]
                klshare_l[[r],[y]] = row[:l]
            end
        end

        X = filter([:year,:i]=>filter_cond, klshare)
        for row∈eachrow(X)
            r = row[:region_abbv]
            klshare_k[[r]] = row[:k]
            klshare_l_nat[[r]] = row[:l_nat]
            klshare_k_nat[[r]] = row[:k_nat]
        end

        gspbal = GamsParameter(GU,(:r,))
        X = filter([:year,:i]=>filter_cond,df)
        for row∈eachrow(X)
            r = row[:region_abbv]
            gspbal[[r]] = row[:gdp]
        end

        ld0 = GU[:va0][[yr],[:compen],[s]]
        kd0 = GU[:va0][[yr],[:surplus],[s]]

        region_shr_ = GamsParameter(GU,(:r,))
        X = filter([:year,:i]=>filter_cond,df)
        for row∈eachrow(X)
            r = row[:region_abbv]
            region_shr_[[r]] = row[:region_shr]
        end
        

        m = gsp_share_calibrate(GU,gspbal,region_shr_,klshare_l,ld0,kd0,klshare_k,klshare_l_nat,klshare_k_nat)

        set_silent(m)

        optimize!(m)

        models[yr,s] = m

        GU[:labor_shr][[yr],:r,[s]] = value.(m[:L_SHR])
    end
    return (GU,models)
end


function load_bea_gsp_file(file_path::String,years::UnitRange,nrows::Int,ComponentName,rename_dict)

    df = DataFrame(CSV.File(file_path,silencewarnings=true,stringtype=String)[1:nrows]);

    df = stack(df,Symbol.(years),variable_name = :year)

    function parse_missing(val::Number)
        return val
    end

    function parse_missing(val::String)
        try
            return parse(Float64,val)
        catch
           return missing
        end
    end

    
    df[!,:value] = parse_missing.(df[!,:value])
    
    df[!,:value] = coalesce.(df[!,:value],0)
    #replace!(df[!,:value], missing => 0)

    df[!,:GeoFIPS] = parse.(Int,df[!,:GeoFIPS])

    df[!,:ComponentName] .= ComponentName

    df[!,:GeoName] = String.(strip.(replace.(df[!,:GeoName], "*"=>"")))

    rename!(df, :LineCode => :IndustryID)
    rename!(df,rename_dict)

    return df[!,["GeoFIPS","state","region","TableName","IndustryID","IndustryClassification","Description","ComponentName","units","year","value"]]
end


function load_raw_bea_gsp(data_dir,years,gsp_data)

    column_rename_dict = Dict(
                            :GeoFIPS=> :GeoFIPS,
                            :GeoName=> :state,
                            :Region=> :region,
                            :TableName=> :TableName,
                            :IndustryId=> :IndustryId,
                            :IndustryClassification=> :IndustryClassification,
                            :Description=> :Description,
                            :Unit=> :units,
                            :year=> :year,
                            :value=> :value,
                            :ComponentName=> :ComponentName
                    )

    df = DataFrame()

    for (a,gsp_info) ∈ gsp_data

        df1 = load_bea_gsp_file(joinpath(data_dir,gsp_info["path"]),
                                years,
                                gsp_info["nrows"],
                                gsp_info["ComponenentName"],
                                column_rename_dict);
        df = vcat(df,df1)
    end

    return df

end

function clean_raw_bea_gsp(df)
    notations = []

    push!(notations,notation_link(gsp_states,:state,:region_fullname))
    push!(notations,notation_link(gsp_industry_id,:IndustryID,:gsp_industry_id))
    push!(notations,notation_link(bea_gsp_map,:ComponentName,:bea_code))
    push!(notations,notation_link(bea_gsp_mapsec,:gsp_industry_id,:gdp_industry_id))


    #df = load_raw_bea_gsp(data_dir,1997:2021,info_dict)

    #return df

    for notation in notations
        df = apply_notation!(df,notation)
    end

 

    df = df[!,[:region_abbv,:year,:gdpcat,:i,:units,:value]]

    base_units = unique(df[!,:units])

    df = unstack(df,:units,:value)



    df[!,"Thousands of dollars"] = df[!,"Thousands of dollars"]./1_000

    df = dropmissing(stack(df,base_units,variable_name=:units,value_name=:value))

    df[!,:units] = replace(df[!,:units], 
        "Thousands of dollars" => "millions of us dollars (USD)",
        "Millions of current dollars" => "millions of us dollars (USD)"
    )



    function _filter_out(units,regions)
        out = units == "millions of us dollars (USD)" && 
              regions != "US"
        return out
    end

    filter!([:units,:region_abbv] => _filter_out,df)

    df[!,:year] = Symbol.(df[!,:year])
    df[!,:region_abbv] = Symbol.(df[!,:region_abbv])
    df[!,:i] = Symbol.(df[!,:i])
    

    return select(df,Not(:units))
end

function create_klshare(GU,df)

    klshare = df[!,[:year,:region_abbv,:i]]

    klshare[!,:l] = df[!,:cmp] ./ (df[!,:gdp_diff] .+ df[!,:gos] .+ df[!,:cmp])
    #klshare[!,:l_nat] = 

    kl = GamsParameter(GU,(:yr,:i))

    kl[:yr,:i] = GU[:va0][:yr,[:compen],:i] ./ (GU[:va0][:yr,[:compen],:i] .+ GU[:va0][:yr,[:surplus],:i])
    kl = DataFrame(vec([(yr,i,kl[[yr],[i]]) for yr∈GU[:yr],i∈GU[:i]]),[:year,:i,:l_nat]);

    klshare = leftjoin(klshare,kl,on = [:year,:i])

    klshare[!,:k] = 1 .- klshare[!,:l]
    klshare[!,:k_nat] = 1 .- klshare[!,:l_nat]


    Y = combine(groupby(df,[:year,:i]),:cmp=>sum,:gdp_diff=>sum,:gos=>sum)
    chk_national_shares = Y[!,[:year,:i]]
    chk_national_shares[!,:gsp] = Y[!,:cmp_sum] ./ (Y[!,:gdp_diff_sum] + Y[!,:gos_sum] + Y[!,:cmp_sum])

    chk_national_shares = leftjoin(chk_national_shares,kl,on = [:year,:i])

    chk_national_shares[!,:shr] = chk_national_shares[!,:l_nat]./chk_national_shares[!,:gsp]
    klshare = leftjoin(klshare,chk_national_shares[!,[:year,:i,:shr]],on = [:year,:i])

    klshare[!,:l_diff] = klshare[!,:l].*klshare[!,:shr]
    klshare[!,:l] = klshare[!,:l].*klshare[!,:shr]
    klshare[!,:k] = 1 .- klshare[!,:l]

    prob_tot = klshare[!,:k] .<0 .||
            klshare[!,:k] .>=1 .||
            abs.(klshare[!,:k] - klshare[!,:k_nat]) .>.75

    klshare[df[!,:region_shr] .!=0 .&& prob_tot,:l] .= klshare[df[!,:region_shr] .!=0 .&& prob_tot,:l_nat]
    klshare[df[!,:region_shr] .!=0, :k] = 1 .-klshare[df[!,:region_shr] .!=0, :l]

    for c ∈ eachcol(klshare)
        replace!(c, NaN => 0.0)
    end
    return klshare
end



function gsp_share_calibrate(GU,gspbal,region_shr_,klshare_l,ld0,kd0,klshare_k,klshare_l_nat,klshare_k_nat)

    m = JuMP.Model(Ipopt.Optimizer)

    R = [r for r∈GU[:r]]
    YR = [yr for yr∈GU[:yr]]

    @variables(m, begin
        K_SHR[r=R]>=.25*klshare_k_nat[[r]], (start = klshare_k[[r]],)
        L_SHR[r=R]>=.25*klshare_l_nat[[r]], (start = klshare_l[[r]],)
    end)

    for r∈R
        if region_shr_[[r]] == 0
            fix(K_SHR[r],0,force=true)
            fix(L_SHR[r],0,force=true)
        end
    end

    @constraints(m,begin
        shrdef[r=R; region_shr_[[r]]!=0],
            L_SHR[r] + K_SHR[r] == 1
        lshrdef,
            sum(L_SHR[r]*region_shr_[[r]]*(ld0+kd0) for r∈R) == ld0
        kshrdef,
            sum(K_SHR[r]*region_shr_[[r]]*(ld0+kd0) for r∈R) == kd0
    end)

    @objective(m, Min, 
        sum(abs(gspbal[[r]]) * (L_SHR[r]/klshare_l[[r],[yr]]-1)^2 for r∈R,yr∈YR if klshare_l[[r],[yr]]!=0 && region_shr_[[r]]!=0)
    )

    return m
end

function rolling_average_years(yr,numyears;min=1997,max=2021)
    yr = parse(Int,string(yr))
    return Symbol.([yr+y for y∈-Int(numyears/2):Int(numyears/2) if min<=yr+y<=max])
end
