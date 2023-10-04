
"""
    fill_parameter!(GU::GamsUniverse,df_full::DataFrame,parm::Symbol,col_set_link,additional_filters)

col_set_link is a dictionary with entries :set_name => :column_name

additional_filters is a dictionary with entries :parameter_name => (:column_name, :values_to_keep)
"""
function fill_parameter!(GU::GamsUniverse,df_full::DataFrame,parm::Symbol,col_set_link,additional_filters)
    df = deepcopy(df_full)

    for s in domain(GU[parm])
        col = col_set_link[s]
        filter!(col => x-> x in GU[s], df)
    end

    if parm in keys(additional_filters)
        
        col, good = additional_filters[parm]
        filter!(col => x-> x == good, df)
    end

    columns = [col_set_link[e] for e in domain(GU[parm])]
    for row in eachrow(df)
        d = [[row[e]] for e∈columns]
        GU[parm][d...] = row[:value]
    end

end



struct WiNDC_notation
    data::DataFrame
    default::Symbol
end

struct notation_link
    data::WiNDC_notation
    dirty::Symbol
    clean::Symbol
end


function apply_notation!(df, notation)
    windc_data = notation.data
    data = windc_data.data
    default = windc_data.default

    dirty = notation.dirty
    clean = notation.clean

    if default != clean
        cols = [clean,default]
    else
        cols = [clean]
    end

    df = innerjoin(data[!,cols],df,on = clean => dirty)

    if default != clean
        select!(df,Not(clean))
    end

    return df

end