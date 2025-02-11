abstract type AbstractNationalTable <: WiNDCtable end

domain(data::AbstractNationalTable) = [:commodities, :sectors, :year]

"""
    NationalTable

Subtype of [`WiNDCtable`](@ref) that holds the national data.

## Fields

- `table::DataFrame`: The main table of the WiNDCtable.
- `sets::DataFrame`: The sets of the WiNDCtable.

## Domain

- `:commodities`
- `:sectors`
- `:year`
"""
struct NationalTable <: AbstractNationalTable
    table::DataFrame
    sets::DataFrame
end


function reverse_subtable_flow(
    data::DataFrame, 
    subtables::Vector{String};
    column = :value
)
    data |>
        x -> transform(x, 
            [:subtable,column] => ByRow((s,v) -> in(s, subtables) ? -v : v) => column
        )
end



######################
## Aggregate Tables ##
######################

gross_output(data::AbstractNationalTable; column::Symbol = :value, output::Symbol = :value) =
    get_subtable(data, ["intermediate_supply", "household_supply", "margin_supply"]) |>
        x -> reverse_subtable_flow(x, ["margin_supply"], column = column) |>
        x -> groupby(x, filter(y -> y!=:sectors, domain(data))) |>
        x -> combine(x, column => (y -> sum(y;init=0)) => output)


armington_supply(data::AbstractNationalTable; column = :value, output = :value) = 
    get_subtable(data, ["intermediate_demand", "exogenous_final_demand","personal_consumption"]) |>
        x -> groupby(x, filter(y -> y!=:sectors, domain(data))) |>
        x -> combine(x, column => (y -> sum(y;init=0)) => output) 



output_tax(data::AbstractNationalTable; column = :value, output = :value) =
    get_subtable(data, ["other_tax", "sector_subsidy"]) |>
        x -> groupby(x, filter(y -> y!=:commodities, domain(data))) |>
        x -> combine(x, column => (y -> sum(y;init=0)) => output)

        

other_tax_rate(data::AbstractNationalTable; column = :value, output = :value) = 
    outerjoin(
        get_subtable(data, ["intermediate_demand", "value_added"])  |>
            x -> groupby(x, filter(y -> y!=:commodities, domain(data))) |>
            x -> combine(x, column => sum => :total_output),
        WiNDC.output_tax(data, column = column, output = :tax),
        on = filter(y -> y!=:commodities, domain(data))
    ) |>
    x -> coalesce.(x, 0) |>
    x -> transform(x,
        [:total_output, :tax] => ByRow((o,t) -> o == 0 ? 0 : t/o) => output
    ) |>
    x -> select(x, Not(:total_output, :tax))


absorption_tax(data::AbstractNationalTable; column = :value, output = :value) = 
    get_subtable(data, ["tax", "subsidies"]) |> 
        x -> reverse_subtable_flow(x, ["subsidies"], column = column) |>
        x -> groupby(x, filter(y -> y!=:sectors, domain(data))) |>
        x -> combine(x, column => (y -> sum(y;init=0)) => output) 

absorption_tax_rate(data::AbstractNationalTable; column = :value, output = :value) =     
    outerjoin(
        absorption_tax(data; column = column, output = :total_tax),
        armington_supply(data; column = column, output = :arm_sup),
        on = filter(y -> y!=:sectors, domain(data))
    ) |>
    x -> coalesce.(x, 0) |>
    x -> transform(x,
        [:arm_sup, :total_tax] => ByRow((v,t) -> v == 0 ? 0 : t/v) => output
    ) |>
    x -> select(x, Not(:total_tax, :arm_sup)) |>
    x -> subset(x, output => ByRow(!=(0)))


import_tariff_rate(data::AbstractNationalTable; column = :value, output = :value) = 
    outerjoin(
        get_subtable(data, "duty", column = column, output = :duty) |>
            x -> select(x, Not(:sectors)),
        get_subtable(data, "imports", column = column, output = :imports) |>
            x -> select(x, Not(:sectors)),
        on = filter(y -> y!=:sectors, domain(data))
    ) |>
    x -> coalesce.(x, 0) |>
    x -> transform(x,
        [:duty, :imports] => ByRow((d,i) -> i==0 ? 0 : d/i) => output
    ) |>
    x -> select(x, Not(:duty, :imports)) |>
    x -> subset(x, output => ByRow(!=(0)))


balance_of_payments(data::AbstractNationalTable; column = :value, output = :value) = 
    outerjoin(
        get_subtable(data, "imports", output = :im) |>
            x -> select(x, Not(:sectors)),
        get_subtable(data, "exports", output = :ex) |>
            x -> select(x, Not(:sectors)),
        WiNDC.armington_supply(data, output = :as),
        on = filter(y -> y!=:sectors, domain(data))
    ) |>
    x -> coalesce.(x,0) |>
    x -> transform(x,
        #[:im, :ex, :as] => ByRow((im, ex, a) -> a!= 0 ? im - ex : 0) => output
        [:im, :ex, :as] => ByRow((im, ex, a) -> im - ex) => output
    ) |>
    x -> groupby(x, :year) |>
    x -> combine(x, output => sum => output)