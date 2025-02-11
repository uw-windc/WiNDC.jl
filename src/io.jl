"""
    save_table(
        output_path::String
        MU::T;
        overwrite::Bool = false
    ) where T<:WiNDCtable

Save a `WiNDCtable` to a file. The file format is HDF5, which can be opened
in any other language. The file will have the following structure:

year - DataFrame - The data for each year in the `WiNDCtable`
sets - DataFrame - The sets of the `WiNDCtable`
columns - Array - The column names of each yearly DataFrame

## Required Arguments

- `output_path::String`: The path to save the file. Must end in .jld2.
- `MU::WiNDCtable`: The `WiNDCtable` to save.

## Optional Arguments

- `overwrite::Bool`: If true, overwrite the file if it already exists. Default is false.

"""
function save_table(
    output_path::String,
    MU::T;
    overwrite::Bool = false
) where T <: WiNDCtable

    _, extension = splitext(output_path)

    @assert extension == ".jld2" "The output path must end in .jld2."
    output_path = !isabspath(output_path) ? joinpath(pwd(), output_path) : output_path

    if overwrite
        file = jldopen(output_path, "w+")
    else
        file = jldopen(output_path, "a")
    end

    all_years = get_table(MU) |>
        x -> x[!,:year] |>
        unique

    column_names = get_table(MU) |> names

    if haskey(file, "type")
        @assert file["type"] == T "The type of the table does not match the type of the file."
    else
        file["type"] = T
    end

    if !haskey(file, "sets")
        file["sets"] = MU.sets
    end

    if !haskey(file, "columns")
        file["columns"] = column_names
    end

    for year in all_years
        table = get_table(MU) |> x-> subset(x, :year => ByRow(==(year)))

        if !haskey(file, string(year))
            file[string(year)] = table
        end
    end

end

"""
    load_table(
        file_path::String
        years::Int...;
    )

Load a `WiNDCtable` from a file. 

## Required Arguments

- `file_path::String`: The path to the file.
- `years::Int...`: The years to load. If no years are provided, all years in the file
    will be loaded.

## Returns

A subtype of a WiNDCtable, with the data and sets loaded from the file.
"""
function load_table(
    file_path::String,
    years::Int...
    )

    file_path = !isabspath(file_path) ? joinpath(pwd(), file_path) : file_path
    @assert isfile(file_path) "The file `$file_path` does not exist."

    f = jldopen(file_path, "r+")

    @assert haskey(f, "sets") "The file `$file_path` does not have the key `sets`."
    sets = f["sets"]

    @assert haskey(f, "columns") "The file `$file_path` does not have the key `columns`."
    columns = f["columns"]


    if length(years) == 0
        years = parse.(Int,[k for k∈keys(f) if k∉["sets", "columns", "type"]])
    end

    df = DataFrame()
    for year∈years
        @assert haskey(f, string(year)) "The file `$file_path` does not have the key `$(string(year))`."
        data = f[string(year)]
        @assert isa(data, DataFrame) "The data for year $year is not a DataFrame."
        @assert all(isequal(names(data), columns)) "The data for year $year does not have the correct columns."

        df = vcat(df, data)
    end

    T = f["type"]

    close(f)

    return T(df, sets)
end

