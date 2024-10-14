abstract type WiNDCtable end;

domain(data::WiNDCtable) = throw(ArgumentError("domain not implemented for WiNDCtable"))




function get_set(data::WiNDCtable, set_name::String) 
    data.sets |>
        x -> subset(x, 
            :set => ByRow(==(set_name))
        )    
end

function get_table(data::WiNDCtable)
    return data.table
end


function get_subtable(
        data::WiNDCtable, 
        subtable::String;
        column::Symbol = :value,
        output::Symbol = :value
    )

    columns = domain(data)
    push!(columns, column)

    elements = get_set(data, subtable) |>
        x -> select(x, :element)
        
    return get_table(data) |>
        x -> innerjoin(
                x,
                elements,
            on = [:subtable => :element]
        ) |>
        x -> select(x, columns) |>
        x -> rename(x, column => output)
end