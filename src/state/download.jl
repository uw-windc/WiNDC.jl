
function filter_to_GSP(x::AbstractString)

    return occursin("ALL_AREAS", x)

end


function fetch_GSP(
    ;
    url::String = "https://apps.bea.gov/regional/zip/SAGDP.zip",
    output_path::String = joinpath(pwd(), "data/state"),
)
    return fetch_zip_data(url, filter_to_GSP; output_path = output_path)
end

"""
    fetch_extra_data(
        ;
        url::String = "https://drive.google.com/file/d/1ndl3-Julqi01LeivFwK_5aVCTFgY_5uH/view?usp=sharing",
        output_path::String = joinpath(pwd(), "data")
    )

Download and extract the extra data needed for the WiNDC model. This includes
the state data and trade data.

## Optional Arguments

- `url::String`: The url of the zip file to download. Default is the url of the
zip file in the Google Drive.

- `output_path::String`: The path to save the extracted files. Default is the
directory `data` in the current working directory. If this is not an absolute
path, it will be joined with the current working directory.

## Output

Returns a vector of the absolute paths to the extracted files.

## Process

Downloads the [Miscellaneous Data](@ref) and places the files in the correct 
directories.
"""
function fetch_extra_data(
    ;
    url::String = "https://drive.google.com/file/d/1ndl3-Julqi01LeivFwK_5aVCTFgY_5uH",
    output_path::String = joinpath(pwd(), "data")
)
    
    state_data = (
        distances = "distances.csv",
        industry_codes = "industry_codes.csv",
        state_fips = "state_fips.csv",
    )

    X = fetch_zip_data(url, x -> x∈state_data; output_path = joinpath(output_path, "state"))

    trade_data = (
        concordances = "concordances.csv",
        country_codes = "country_codes.csv",
    )

    Y = fetch_zip_data(url, x -> x∈trade_data; output_path = joinpath(output_path, "trade"))

    return vcat(X,Y)

end