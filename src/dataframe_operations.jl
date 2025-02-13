"""
    subset(
            data::T, 
            @nospecialize(args...)
        ) where T <: WiNDCtable

Return a subset of `data` based on the conditions given in `args`. This will 
subset both the main table and the set table.

## Required Arguments

- `data::T`: The `WiNDCtable` to subset.
- `args::Tuple`: Pairs of the form `set_name => boolean function`. 

## Return

A table of type `T`.

## Example
If `data` is a detailed `NationalTable` and we want to only view the soybean 
commodity:

```julia

subset(data, 
    :commodities => (y -> y=="1111A0")
    )
"""
function DataFrames.subset(
        data::T, 
        @nospecialize(args...);
        skipmissing::Bool=false, 
        view::Bool=false, 
        threads::Bool=true
    ) where T <: WiNDCtable

    D = []
    for (a, _) in args
        S = get_set(data) |>
            x -> subset(x, 
                :set => ByRow(==(String(a)))
            ) 
        elements = S[:, :element]
        new_d = unique(S[:, :domain])

        @assert length(new_d) <= 1 "More than one domain found for set $(a)"
        @assert length(new_d) !=0 "No domain found for set $(a)" 
        push!(D, (new_d[1], elements))
    end

    new_table = get_table(data) |>
        x -> subset(x, 
            [column => ByRow(a -> a∉L || F(a)) for  ((column, L), (TMP, F)) in zip(D,args)]...
        )  
    
    new_set = get_set(data) |>
        x -> subset(x,
            [[:element, :set] => ByRow((e,s) -> Symbol(s)!=S || F(e)) for (S, F) in args]...
        )

    return T(new_table, new_set)
end