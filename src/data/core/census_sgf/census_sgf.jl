#include("./data_defines.jl")



function sgf_parse_line(s)
    out = ( government_code = string(s[1:14]),
            item_code = string(s[15:17]),
            amount = string(s[18:29]),
            survey_year = string(s[30:31]),
            year = string(s[32:33]),
            origin = string(s[34:35])
    )
    return out
end

function sgf_parse_line_1999(s)
    out = ( government_code = string(s[1:14]),
            origin = string(s[18:19]),
            item_code = string(s[22:24]),
            amount = string(s[25:35]),
            survey_year = "99",
            year = "99",
    )
    return out
end


function sgf_load_clean_year(year,data_dir,path)
    data_path = joinpath(data_dir,path)

    s = open(data_path) do f
        s = read(f,String)
    end

    if year == "1999"
        f = sgf_parse_line_1999
    else
        f = sgf_parse_line
    end

    notations = sgf_notations()
    #notations = []

    #push!(notations,WiNDC.notation_link(sgf_state_codes,:government_code,:code))
    #push!(notations,WiNDC.notation_link(sgf_states, :state, :region_fullname))
    #push!(notations,WiNDC.notation_link(item_codes, :item_code,:item_code));
    #push!(notations,WiNDC.notation_link(sgf_map, :item_name,:sgf_category));
    #push!(notations,WiNDC.notation_link(sgf_gams_map, :i,:sgf_category));


    L = f.([e for e in split(s,'\n') if e!=""])
    df = DataFrame(L) |>
        x -> apply_notations(x,notations) |>
        x -> transform(x,
            :amount => (y -> parse.(Int,y)) => :amount
            ) |>
        x -> groupby(x,[:i,:region_abbv]) |>
        x -> combine(x, :amount => sum) |>
        x -> transform(x,
            :amount_sum => (y -> Symbol(year)) => :year,
            :amount_sum => (a -> a./1_000) => :value,
            :i => (i -> Symbol.(i)) => :i,
            :region_abbv => (r -> Symbol.(r)) => :region_abbv
        )


    #df = apply_notations(df,notations)

    #df[!,:amount] = parse.(Int,df[!,:amount])

    #df = combine(groupby(df,[:i,:region_abbv]),:amount => sum);
    #df[!,:year] .= year;
    #df[!,:value] = df[!,:amount_sum]./1_000

    #df[!,:year] = Symbol.(df[!,:year])
    #df[!,:i] = Symbol.(df[!,:i])
    #df[!,:region_abbv] = Symbol.(df[!,:region_abbv])

    return df
end


function load_sgf_data!(GU,data_dir,info_dict)

    @parameters(GU,begin
        sgf_shr, (:yr,:r,:i), (description = "Regional shares of final consumption",)
    end)

    df = DataFrame()
    for (year,path) in info_dict
        small_df = sgf_load_clean_year(year,data_dir,path)
        df = vcat(df,small_df)
    end


    #Add DC in regions
    df = df |>
        x -> select(x, [:i,:region_abbv,:year,:value]) |>
        x -> unstack(x, :region_abbv, :value) |>
        x -> transform(x, :MD => (y->y) => :DC) |> 
        x -> stack(x, Not(:i,:year),variable_name = :region_abbv) |>
        x -> transform(x, :region_abbv => (y->Symbol.(y)) => :region_abbv)|>
        x -> dropmissing(x) 

    #return df

    df = df |>
        x -> groupby(x, [:i,:year]) |>
        x -> combine(x, :value=> sum) |>
        x -> leftjoin(df, x, on = [:i,:year]) |>
        x -> transform(x, 
            [:value,:value_sum] => ((v,vs) -> v./vs) => :value)

    #return df

    col_set_link = Dict(:yr => :year, 
                        :r => :region_abbv,
                        :i => :i 
                        )

    WiNDC.fill_parameter!(GU, df, :sgf_shr, col_set_link, Dict())

    return GU

end