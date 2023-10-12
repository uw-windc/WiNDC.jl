include("./data_defines.jl")



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


function sgf_load_clean_year(year,data_dir,year_info)
    data_path = "$data_dir\\$(year_info["path"])"

    s = open(data_path) do f
        s = read(f,String)
    end

    if year == "1999"
        f = sgf_parse_line_1999
    else
        f = sgf_parse_line
    end

    L = f.([e for e in split(s,'\n') if e!=""])
    df = DataFrame(L)

    notations = []

    push!(notations,WiNDC.notation_link(state_codes,:government_code,:code))
    push!(notations,WiNDC.notation_link(states, :state, :region_fullname))
    push!(notations,WiNDC.notation_link(item_codes, :item_code,:item_code));
    push!(notations,WiNDC.notation_link(sgf_map, :item_name,:sgf_category));
    push!(notations,WiNDC.notation_link(sgf_gams_map, :i,:sgf_category));

    for notation in notations
        df = WiNDC.apply_notation!(df,notation)
    end

    df[!,:amount] = parse.(Int,df[!,:amount])

    df = combine(groupby(df,[:i,:region_abbv]),:amount => sum);
    df[!,:year] .= year;
    df[!,:value] = df[!,:amount_sum]./1_000

    df[!,:year] = Symbol.(df[!,:year])
    df[!,:i] = Symbol.(df[!,:i])
    df[!,:region_abbv] = Symbol.(df[!,:region_abbv])

    return df
end


function load_sgf_data!(GU,data_dir,info_dict)

    @create_parameters(GU,begin
        :sgf_shr, (:yr,:r,:i), "Regional shares of final consumption"
    end)

    df = DataFrame()
    for (year,year_info) in info_dict["data"]
        small_df = sgf_load_clean_year(year,data_dir,year_info)
        df = vcat(df,small_df)
    end

    Y = combine(groupby(df,[:i,:year]),:value=>sum)

    df = leftjoin(df,Y,on = [:i,:year])
    
    df[!,:value] = df[!,:value]./df[!,:value_sum]

    col_set_link = Dict(:yr => :year, 
                        :r => :region_abbv,
                        :i => :i 
                        )

    fill_parameter!(GU, df, :sgf_shr, col_set_link, Dict())

    GU[:sgf_shr][:yr,[:DC],:i] = GU[:sgf_shr][:yr,[:MD],:i]

    return GU
end