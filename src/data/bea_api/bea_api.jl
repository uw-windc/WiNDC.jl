



"""
    get_bea_io_years(api_key::String)

Return a string containing all available years of BEA Input/Output data.
"""
function get_bea_io_years(api_key::String)
    url = "https://apps.bea.gov/api/data/?&UserID=$(api_key)&method=GetParameterValues&DataSetName=InputOutput&ParameterName=Year&ResultFormat=json"

    response = HTTP.post(url)#, headers, JSON.json(req))
    response_text = String(response.body)
    data = JSON.parse(response_text)
    years = [elm["Key"] for elm in data["BEAAPI"]["Results"]["ParamValue"]]
    
    years = join(years,",")

end



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

"""
    get_bea_io_table(api_key::String, code::Int)

Return a dataframe containing the BEA table correspoding to the code.

code - use table = 259, supply_table = 262
"""
function get_bea_io_table(api_key::String, table::Symbol)

    table ∈ [:supply,:use] || error("table must be either :supply or :use. Given $table.")
    code = table == :use ? 259 : 262

    years = get_bea_io_years(api_key)

    url = "https://apps.bea.gov/api/data/?&UserID=$(api_key)&method=GetData&DataSetName=InputOutput&Year=$years&tableID=$code&ResultFormat=json"
    response = HTTP.post(url)
    response_text = String(response.body)
    json_obj = JSON.parse(response_text)


    for elm in json_obj["BEAAPI"]["Results"][1]["Data"]
        if "DataValue" ∉ keys(elm)
            elm["DataValue"] = 0
        end
    end

    df = DataFrame(json_obj["BEAAPI"]["Results"][1]["Data"])

    df[!,:DataValue] = parse_missing.(df[!,:DataValue])

    df[!,:DataValue] = df[!,:DataValue]./1_000

    return df[!,[:Year,:RowCode,:ColCode,:DataValue]]    
end