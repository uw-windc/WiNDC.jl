#include("./data_defines.jl")

function load_bea_pce!(GU,data_dir,info_dict)
    
    info = info_dict["saexp1"]
    data_path = "$data_dir\\$(info["path"])"
    nrows = info["nrows"]

    notations = bea_pce_notations()

    df = DataFrame(CSV.File(data_path;limit = nrows,stringtype=String)) |>
        x -> select(x,Not([:Unit,:IndustryClassification,:GeoFIPS,:Region,:TableName,:LineCode])) |>
        x -> transform(x,
            :Description => (y -> string.(strip.(y))) => :Description
        ) |>
        x -> apply_notations(x,notations) |>
        x -> stack(x, Not([:r,:i]),variable_name = :year,value_name = :value)

    df = df |> 
        x -> groupby(x,[:year,:i]) |>
        x -> combine(x, :value => sum) |>
        x -> leftjoin(df,x, on = [:year,:i]) |>
        x -> transform(x,
            [:value,:value_sum] => ((v,vs) -> v./vs) => :value,
            :i => (i -> Symbol.(i)) => :i,
            :r => (i -> Symbol.(i)) => :r,
            :year => (i -> Symbol.(i)) => :year
            )


    @create_parameters(GU,begin
        :pce_shr, (:yr,:r,:i), 	"Regional shares of final consumption"
    end)

    col_set_link = Dict(:yr => :year, 
                        :r => :r,
                        :i => :i 
                        )

    fill_parameter!(GU, df, :pce_shr, col_set_link, Dict())

    return GU
end