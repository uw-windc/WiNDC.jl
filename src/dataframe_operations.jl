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

        @assert length(new_d) <=1 "More than one domain found for set $(a)"
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




function get_set_domain_elements(
    data::WiNDCtable,
    set_name::Union{Symbol,String}
)

    S = get_set(data, String(set_name)) |>
        x -> subset(x,
            :domain => ByRow(!=(:composite))
        )

    elements = S[:, :element]
    new_d = unique(S[:, :domain])

    @assert length(new_d) <= 1 "More than one domain found for set $(set_name)"
    @assert length(new_d) !=0 "No domain found for set $(set_name)"

    return (new_d[1], elements)
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
        (column, elements) = WiNDC.get_set_domain_elements(data, set)

        # Filter out the elements that are not in the set
        aggr = X |>
            y -> subset(y,
                original => ByRow(e -> in(e, elements))
            ) |>
            x -> select(x, [original, new])

        # Replace the elements in the main table
        df = df |>
            x -> leftjoin(
                x,
                aggr,
                on = [column => original]
            ) |>
            x -> transform(x,
                [column, new] => ByRow((c, n) -> ismissing(n) ? c : n) => column
            ) |>
            x -> select(x, Not(new)) |>
            x -> groupby(x, [:subtable; domain(data)]) |>
            x -> combine(x, :value => sum => :value)

        # Replace the elements in the set table
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

    return T(df, sets)

end


"""



columns - :aggregated => :disaggregated
"""
function disaggregate(
        data::T,
        disaggregation::DataFrame,
        set_name::String,
        columns::Pair{Symbol,Symbol},
        shares::Symbol
        ) where T<:WiNDCtable

    df = get_table(data)
    active_set = get_set(data, set_name)
    other_sets = get_set(data) |> x -> subset(x, :set => ByRow(!=(set_name)))

    (domain_column, elements) = WiNDC.get_set_domain_elements(data, set_name)

    (original, new) = columns

    disaggregator = disaggregation |>
        x -> subset(x,
            original => ByRow(e -> e in elements)
        ) |>
        x -> select(x, original=>:original, new=>:new, shares => :shares)

    # Check that the shares sum to 1
    disaggregator |>
        x -> groupby(x, :original) |>
        x -> combine(x, :shares => sum => :shares) |>
        x -> subset(x, :shares => ByRow(!=(1))) |>
        x -> @assert(size(x,1) == 0, "The shares must sum to 1")

    Y = leftjoin(
            get_table(data),
            disaggregator,
            on = [domain_column => :original]
        ) |>
        x -> transform(x,
            [domain_column, :new] => ByRow((c, o) -> ismissing(o) ? c : o) => domain_column,
            [:value, :shares] => ByRow((v,s) -> ismissing(s) ? v : v*s) => :value,
        ) |>
        x -> select(x, Not(:new, :shares)) 

    sets = active_set |>
        x -> leftjoin(
            x,
            disaggregator |> x -> select(x, Not(:shares)),
            on = [:element => :original]
        ) |>
        x -> transform(x,
            [:element, :new] => ByRow((s, n) -> ismissing(n) ? s : n) => :element
        ) |>
        x -> select(x, Not(:new)) |>
        x -> vcat(x, other_sets)

    return T(Y, sets)

end

