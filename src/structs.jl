abstract type WiNDCtable end;

domain(data::WiNDCtable) = throw(ArgumentError("domain not implemented for WiNDCtable"))




function get_set(data::T, set_name::String) where T<:WiNDCtable
    data.sets |>
        x -> subset(x, 
            :set => ByRow(==(set_name))
        )    
end

function get_table(data::T) where T<:WiNDCtable
    return data.table
end


function get_subtable(
        data::T, 
        subtable::String;
        column::Symbol = :value,
        output::Symbol = :value,
        negative = false
    ) where T<:WiNDCtable

    columns = domain(data)
    push!(columns, column)

    elements = get_set(data, subtable) |>
        x -> select(x, :element)

    @assert(size(elements, 1) > 0, "Error: No elements found in subtable $subtable")

    return get_table(data) |>
        x -> innerjoin(
                x,
                elements,
            on = [:subtable => :element]
        ) |>
        x -> select(x, columns) |>
        x -> rename(x, column => output) |>
        x -> transform(x, output => ByRow(y -> negative ? -y : identity(y)) => output)
end