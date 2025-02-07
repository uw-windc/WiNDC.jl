
"""
    filter_to_sut(x::AbstractString)

Return `true` if the string `x` corresponds to either a detailed or summary supply
or use table. Otherwise, return `false`.
"""
function filter_to_sut(x::AbstractString)
    return occursin(r"Supply.*_DET",x) || occursin(r"Use.*_DET",x) || occursin(r"Supply.*Summary",x) || occursin(r"Use.*_Summary",x)
end


"""
    fetch_supply_use(
        ;
        url::String = "https://apps.bea.gov/industry/iTables%20Static%20Files/AllTablesSUP.zip",
        output_path::String = joinpath(pwd(), "data/national"),
    )

Fetch the supply and use tables from the BEA website. The data is stored in a zip file,
which is downloaded and extracted to the `output_path`. The extracted files are then
returned as a vector of strings.

## Optional Arguments

- `url::String`: The url of the zip file containing the supply and use tables. Default is
"https://apps.bea.gov/industry/iTables%20Static%20Files/AllTablesSUP.zip".

- `output_path::String`: The path to save the extracted files. Default is the directory `data/national`

## Output

Returns a vector of the absolute paths to the extracted files.
"""
function fetch_supply_use(
    ;
    url::String = "https://apps.bea.gov/industry/iTables%20Static%20Files/AllTablesSUP.zip",
    output_path::String = joinpath(pwd(), "data/national"),
)
    return fetch_zip_data(url, filter_to_sut; output_path = output_path)
end

