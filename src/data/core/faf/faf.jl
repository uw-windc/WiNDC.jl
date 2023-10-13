include("./data_defines.jl")

function load_raw_faf_data(file_path)

    df_cur = DataFrame(CSV.File(file_path,stringtype=String))

    filter!(:trade_type => x-> x==1,df_cur)

    cols_to_keep = ["dms_origst","dms_destst","dms_mode","sctg2"]
    push!(cols_to_keep,[ col for col in names(df_cur) if occursin(r"^value_",col)]...)
    df_cur = select(df_cur, cols_to_keep)

    df_cur = stack(df_cur, Not(["dms_origst","dms_destst","dms_mode","sctg2"]),
        value_name = :value, variable_name = :year)

    df_cur[!,:year] = parse.(Int,replace.(df_cur[!,:year], "value_"=>""))

    df_cur = combine(groupby(df_cur, [:dms_origst,:dms_destst,:sctg2,:year]), :value=>sum=>:value)
    return df_cur
end


function load_faf_data!(GU,current_file_path,history_file_path)

    df_cur = load_raw_faf_data(current_file_path)
    df_hist = load_raw_faf_data(history_file_path)

    df = filter(:year => x-> x<=2021,vcat(df_cur,df_hist))

    notations = []

    push!(notations,WiNDC.notation_link(orig,:dms_origst,:state_fips))
    push!(notations,WiNDC.notation_link(dest,:dms_destst,:state_fips))
    push!(notations,WiNDC.notation_link(sctg2,:sctg2,:sctg2))
    push!(notations,WiNDC.notation_link(years,:year,:faf_year))

    for notation in notations
        df = WiNDC.apply_notation!(df,notation)
    end

    df = combine(groupby(df,[:dms_dest,:dms_orig,:year,:i]),:value=>sum=> :value)

    single_region = df[df[!,:dms_orig] .== df[!,:dms_dest],[:dms_dest,:year,:i,:value]]
    rename!(single_region, :dms_dest => :r, :value=>:local_supply)

    multi_region = df[df[!,:dms_orig] .!= df[!,:dms_dest],:]

    #exports
    Y = combine(groupby(multi_region, [:dms_orig,:year,:i]),:value=>sum=>:exports)
    single_region = leftjoin(single_region,Y, on = [:r=>:dms_orig,:year,:i])


    #exports
    Y = combine(groupby(multi_region, [:dms_dest,:year,:i]),:value=>sum=>:demand)
    single_region = leftjoin(single_region,Y, on = [:r=>:dms_dest,:year,:i])

    single_region = coalesce.(single_region,0)

    function mean(x)
        sum(x)/length(x)
    end

    Y = combine(groupby(single_region,[:r,:year]),
        :local_supply => mean => :local_supply,
        :exports      => mean => :exports,
        :demand       => mean => :demand
    )
    X = DataFrame([[i for i∈GU[:i] if i∉ Symbol.(unique(single_region[!,:i]))]],[:i])

    single_region = vcat(single_region,crossjoin(X,Y));

    single_region[!,:value] = single_region[!,:local_supply] ./ (single_region[!,:local_supply] .+ single_region[!,:demand])


    @create_parameters(GU,begin
        :rpc, (:yr,:r,:i), "Regional purchase coefficient"
    end)

    col_set_link = Dict(:yr => :year, 
                        :r => :r,
                        :i => :i 
    )

    fill_parameter!(GU, single_region, :rpc, col_set_link, Dict())

    return GU
end