
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


"""
    notation_link

Input data is dirty. This struct matches the dirty input data to a replacement
dataframe in a consistent manner.

dirty_to_replace -> The dirty column in the input data

data -> The replacement dataframe
dirty_to_match -> The column in the replacement dataframe that matches the dirty_to_replace
    column in the input data.
clean_column -> The column in the replacement dataframe with the correct output
clean_name -> The final name that should appear in the output dataframe.
"""
struct notation_link
    dirty_to_replace::Symbol
    data::DataFrame
    dirty_to_match::Symbol
    clean_column::Symbol
    clean_name::Symbol
end


function apply_notation(df, notation)
    data = notation.data
    dirty = notation.dirty_to_replace
    dirty_match = notation.dirty_to_match
    clean = notation.clean_column
    clean_name = notation.clean_name

    if dirty_match != clean
        cols = [clean,dirty_match]
    else
        cols = [dirty_match]
    end

    df = innerjoin(data[!,cols],df,on = dirty_match => dirty)

    if dirty_match != clean
        select!(df,Not(dirty_match))
    end

    if clean_name != clean
        rename!(df, clean => clean_name)
    end

    return df


end


function apply_notations(df, notations)
    for notation in notations
        df = apply_notation(df,notation)
    end
    return df
end