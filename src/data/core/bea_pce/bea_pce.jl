include("./data_defines.jl")

function load_bea_pce!(GU,data_dir,info_dict)
    
    info = info_dict["saexp1"]

    data_path = "$data_dir\\$(info["path"])"
    nrows = info["nrows"]
    df = DataFrame(CSV.File(data_path;limit = nrows,stringtype=String));
    
    df = select(df, Not([:Unit,:IndustryClassification,:GeoFIPS,:Region,:TableName,:LineCode]));
    df[!,:Description] = string.(strip.(df[!,:Description]));
    


    notations = []
    push!(notations,WiNDC.notation_link(pce_map,:Description,:pce_description))
    push!(notations,WiNDC.notation_link(pce_states,:GeoName,:region_fullname))
    push!(notations,WiNDC.notation_link(pce_map_gams,:pce,:pce))


    for notation in notations
        df = WiNDC.apply_notation!(df,notation)
    end
    df = stack(df,Not([:region_abbv,:i]),variable_name = :year,value_name = :value);
    filter!(:region_abbv => x-> x!="US",df);

    Y = combine(groupby(df,[:year,:i]),:value=>sum)

    df = leftjoin(df,Y, on = [:year,:i])
    
    df[!,:value] = df[!,:value]./df[!,:value_sum]

    df[!,:i] = Symbol.(df[!,:i])
    df[!,:region_abbv] = Symbol.(df[!,:region_abbv])
    df[!,:year] = Symbol.(df[!,:year])

    @create_parameters(GU,begin
        :pce_shr, (:yr,:r,:i), 	"Regional shares of final consumption"
    end)

    col_set_link = Dict(:yr => :year, 
                        :r => :region_abbv,
                        :i => :i 
                        )

    fill_parameter!(GU, df, :pce_shr, col_set_link, Dict())

    return GU
end