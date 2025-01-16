abstract type WiNDCtable end;

domain(data::WiNDCtable) = throw(ArgumentError("domain not implemented for WiNDCtable"))


"""
    get_set(data::T) where T<:WiNDCtable  

    get_set(data::T, set_name::String) where T<:WiNDCtable

    get_set(data::T, set_name::Vector{String}) where T<:WiNDCtable

Return the elements of the given sets. If no set is given, return all sets.

## Required Arguments
1. `data` - A WiNDCtable-like object. 
2. `set_name` - A string or vector of strings representing the set names to be extracted.

## Returns

Returns a DataFrame with three columns, `:element`, `:set` and `:description`
"""
function get_set(data::T, set_name::String) where T<:WiNDCtable
    data.sets |>
        x -> subset(x, 
            :set => ByRow(==(set_name))
        )    
end

function get_set(data::T, set_name::Vector{String}) where T<:WiNDCtable
    data.sets |>
        x -> subset(x, 
            :set => ByRow(x -> in(x, set_name))
        )    
end

"""
    get_table(data::T) where T<:WiNDCtable

Return the main table of the WiNDCtable object as a DataFrame

## Required Arguments

1. `data` - A WiNDCtable-like object.

## Output

Returns a DataFrame with columns `domain(data)`, `subtable`, and `value`.
"""
function get_set(data::T) where T<:WiNDCtable
    return data.sets
end

function get_table(data::T) where T<:WiNDCtable
    return data.table
end

"""
    get_subtable(data::T, subtable::String, column::Vector{Symbol}; negative::Bool = false, keep_all_columns = false) where T<:WiNDCtable

    get_subtable(data::T, subtable::String; column::Symbol = :value, output::Symbol = :value, negative = false) where T<:WiNDCtable

    get_subtable(data::T, subtable::Vector{String}) where T<:WiNDCtable

Return the subtables requested as a DataFrame

## Required Arguments
1. `data` - A WiNDCtable-like object.
2. `subtable` - A string or vector of strings representing the subtable names to be extracted.

## Optional Arguments
- `column` - A symbol representing the column to be extracted. Default is `:value`.
- `output` - A symbol representing the output column name. Default is `:value`.
- `negative` - A boolean representing whether the values should be negated. Default is `false`.

## Returns

Returns a DataFrame with the requested subtables and columns.

"""
function get_subtable(
    data::WiNDCtable,
    subtable::String,
    column::Vector{Symbol};
    negative::Bool = false,
    keep_all_columns = false
)  

    columns = domain(data)
    append!(columns, column)

    elements = get_set(data, subtable) |>
        x -> select(x, :element)

    @assert(size(elements, 1) > 0, "Error: No elements found in subtable $subtable")

    return get_table(data) |>
        x -> innerjoin(
                x,
                elements,
            on = [:subtable => :element]
        ) |>
        x -> ifelse(keep_all_columns, x, select(x, columns))

end


function get_subtable(
        data::WiNDCtable, 
        subtable::String;
        column::Symbol = :value,
        output::Symbol = :value,
        negative = false
    )

    return get_subtable(data, subtable, [column]) |>
        x -> rename(x, column => output) |>
        x -> transform(x, output => ByRow(y -> negative ? -y : identity(y)) => output)
end

function get_subtable(
        data::WiNDCtable,
        subtable::Vector{String}
)
    
    return reduce(
        (x,y) -> append!(x, get_subtable(data, y, [:value]; keep_all_columns = true)),
        subtable,
        init = DataFrame()
    )

end