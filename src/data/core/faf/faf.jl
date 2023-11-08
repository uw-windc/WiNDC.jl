include("./data_defines.jl")

function load_raw_faf_data(file_path)

    df = DataFrame(CSV.File(file_path,stringtype=String))

    cols_to_keep = ["dms_origst","dms_destst","dms_mode","sctg2"]
    push!(cols_to_keep,[ col for col in names(df) if occursin(r"^value_",col)]...)

    df = df |> 
        x -> filter(:trade_type => y-> y==1, x) |>
        x -> select(x, cols_to_keep) |> 
        x -> stack(x, 
                    Not(["dms_origst","dms_destst","dms_mode","sctg2"]),
                    value_name = :value, 
                    variable_name = :year
                    )

    df[!,:year] = df[!,:year] |>
        x -> replace.(x, "value_"=>"") |>
        x -> parse.(Int, x)

    df = df |>
        x -> groupby(x, [:dms_origst,:dms_destst,:sctg2,:year]) |>
        x -> combine(x, :value=>sum=>:value)


    return df
end


function load_faf_data!(GU,data_dir,info_dict)
    current_file_path = joinpath(data_dir,info_dict["current"])
    history_file_path = joinpath(data_dir,info_dict["history"])

    df_cur = load_raw_faf_data(current_file_path)
    df_hist = load_raw_faf_data(history_file_path)

    df = filter(:year => x-> x<=2021, vcat(df_cur,df_hist))

    notations = []

    push!(notations,WiNDC.notation_link(orig,:dms_origst,:state_fips))
    push!(notations,WiNDC.notation_link(dest,:dms_destst,:state_fips))
    push!(notations,WiNDC.notation_link(sctg2,:sctg2,:sctg2))
    push!(notations,WiNDC.notation_link(years,:year,:faf_year))

    for notation in notations
        df = WiNDC.apply_notation!(df,notation)
    end

    df = df |> 
        x -> groupby(x,[:dms_dest,:dms_orig,:year,:i]) |>
        x -> combine(x, :value => sum => :value)

    single_region = df |>
        x-> filter([:dms_orig,:dms_dest] => (a,b) -> a==b, x) |>
        x-> select(x, [:dms_dest,:year,:i,:value]) |>
        x-> rename(x, :dms_dest => :r, :value=>:local_supply)

    multi_region = filter([:dms_orig,:dms_dest] => (a,b) -> a!=b, df)


    #exports
    single_region = multi_region |>
        x -> groupby(x, [:dms_orig,:year,:i]) |>
        x -> combine(x, :value => sum => :exports) |>
        x -> outerjoin(single_region, x, on = [:r=>:dms_orig,:year,:i])


    #Imports
    single_region = multi_region |>
        x -> groupby(x, [:dms_dest,:year,:i]) |>
        x -> combine(x, :value => sum => :demand) |>
        x -> outerjoin(single_region, x, on = [:r=>:dms_dest,:year,:i])

    single_region = coalesce.(single_region,0)

    function mean(x)
        sum(x)/length(x)
    end

    Y = single_region |>
        x -> groupby(x, [:r,:year]) |>
        x -> combine(x, 
                :local_supply=> mean =>:local_supply,
                :exports => mean => :exports,
                :demand => mean => :demand
                    )

    # Make a dataframe with all the goods not present in the FAF data
    X = DataFrame([[i for i∈GU[:i] if i∉ Symbol.(unique(single_region[!,:i]))]],[:i])

    single_region = vcat(single_region,crossjoin(X,Y));

    single_region[!,:value] = single_region[!,:local_supply] ./ (single_region[!,:local_supply] .+ single_region[!,:demand])

    single_region = single_region |>
    x -> select(x,[:r,:year,:i,:value]) |>
    x -> unstack(x,:i,:value) |>
    x -> transform(x,
        :uti => (y -> .9) => :uti
    ) |>
    x -> stack(x,Not(:r,:year),variable_name = :i,value_name = :value)


    @create_parameters(GU,begin
        :rpc, (:yr,:r,:i), "Regional purchase coefficient"
    end)

    col_set_link = Dict(:yr => :year, 
                        :r => :r,
                        :i => :i 
    )

    single_region[!,[:r,:i,:year]] = Symbol.(single_region[!,[:r,:i,:year]])

    fill_parameter!(GU, single_region, :rpc, col_set_link, Dict())

    return GU

end