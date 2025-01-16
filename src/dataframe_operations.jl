

function get_column_from_set(
        data::WiNDCtable,
        set_names::Vector{Symbol},
)
    D = []
    for a in set_names
        S = get_set(data) |>
            x -> subset(x, 
                :set => ByRow(==(String(a))),
                :domain => ByRow(!=(:composite))
            ) 
        elements = S[:, :element]
        new_d = unique(S[:, :domain])

        #return new_d
        @assert length(new_d) <= 1 "More than one domain found for set $(a)"
        @assert length(new_d) !=0 "No domain found for set $(a)" 
        push!(D, (new_d[1], elements))
    end
    return D

end


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

"""
function DataFrames.subset(
        data::T, 
        @nospecialize(args...);
        skipmissing::Bool=false, 
        view::Bool=false, 
        threads::Bool=true
    ) where T <: WiNDCtable


    D = get_column_from_set(data, [column for (column, L) in args])

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







"""
    function aggregate(
        data::T,
        aggregations...
    ) where T<:WiNDCtable


## Required Arguments

- `data::T`: The `WiNDCtable` to aggregate.
- `aggregations`: Takes the form `set_name => (X, original => new))`. 
    - `set_name` is a symbol, the name of the set to aggregate.
    - `X` a dataframe with the columns `original` and `new`.
    - `original` is the name of the column in with the elements to be aggregated.
    - `new` is the name of the column with the aggregated names.

"""
function aggregate(
    data::T,
    aggregations...
) where T<:WiNDCtable

    df = get_table(data)
    sets = get_set(data)

    for (set, (X, (original, new))) in aggregations
        (column, elements) = WiNDC.get_column_from_set(data, [set])[1]

        aggr = X |>
            y -> subset(y,
                original => ByRow(e -> in(e, elements))
            ) |>
            x -> select(x, [original, new])

        df = df |>
            x -> leftjoin(
                x,
                aggr,
                on = [column => original]
            ) |>
            x -> transform(x,
                [column, new] => ByRow((c, n) -> ismissing(n) ? c : n) => column
            ) |>
            x -> select(x, Not(new)) 

        sets = get_set(data, string(set)) |>
            x -> leftjoin(
                x,
                aggr,
                on = [:element => original]
            ) |>
            x -> transform(x,
                [:element, new] => ByRow((e, n) -> ismissing(n) ? e : n) => :element
            ) |>
            x -> select(x, Not(new))  |>
            x -> unique(x, :element) |>
            x -> vcat(
                sets |>
                    y -> subset(y, 
                        :set => ByRow(!=(string(set)))
                    ),
                    x
            )
        
    end
            
    df = df |>
        x -> groupby(x, [:subtable; domain(data)]) |>
        x -> combine(x, :value => sum => :value)



    return T(df, sets)

end