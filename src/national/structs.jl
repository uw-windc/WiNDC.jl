abstract type AbstractNationalTable <: WiNDCtable end

domain(data::AbstractNationalTable) = [:commodities, :sectors, :year]


struct NationalTable <: AbstractNationalTable
    table::DataFrame
    sets::DataFrame
end

######################
## Aggregate Tables ##
######################

gross_output(data::AbstractNationalTable; column::Symbol = :value, output::Symbol = :value) =
    vcat(
        get_subtable(data, "intermediate_supply", column = column, output = output),
        get_subtable(data, "household_supply", column = column, output = output),
        get_subtable(data, "margin_supply", column = column, output = output, negative = true)
    ) |>
    x -> groupby(x, filter(y -> y!=:sectors, domain(data))) |>
    x -> combine(x, output => (y -> sum(y;init=0)) => output)


armington_supply(data::AbstractNationalTable; column = :value, output = :value) = 
    vcat(
        get_subtable(data, "intermediate_demand", column = column, output = output),
        get_subtable(data, "exogenous_final_demand", column = column, output = output),
        get_subtable(data, "personal_consumption", column = column, output = output),
    ) |>
    x -> groupby(x, filter(y -> y!=:sectors, domain(data))) |>
    x -> combine(x, output => (y -> sum(y;init=0)) => output)


other_tax_rate(data::AbstractNationalTable; column = :value, output = :value) = 
    outerjoin(
        get_subtable(data, "intermediate_supply", column = column, output = :is) |>
            x -> groupby(x, filter(y -> y!=:commodities, domain(data))) |>
            x -> combine(x, :is => sum => :is),
        get_subtable(data, "other_tax", column = column, output = :ot) |>
            x -> select(x, Not(:commodities)),
        on = filter(y -> y!=:commodities, domain(data))
    ) |>
    x -> coalesce.(x,0) |>
    x -> transform(x,
        [:is, :ot] => ByRow((i,o) -> i == 0 ? 0 : o/i) => output
    ) |>
    x -> select(x, Not(:is,:ot))


absorption_tax(data::AbstractNationalTable; column = :value, output = :value) = 
    outerjoin(
        get_subtable(data, "tax", column = column, output = :tax) |>
            x -> select(x, Not(:sectors)),
        get_subtable(data, "subsidies", column = column, output = :subsidies) |>
            x -> select(x, Not(:sectors)),
        on = filter(y -> y!=:sectors, domain(data))
    ) |>
    x -> coalesce.(x, 0) |>
    x -> transform(x,
        [:tax, :subsidies] => ByRow((t,s) -> t-s) => output
    ) |>
    x -> select(x, Not(:tax, :subsidies))

absorption_tax_rate(data::AbstractNationalTable; column = :value, output = :value) =     
    outerjoin(
        absorption_tax(data; column = column, output = :total_tax),
        armington_supply(data; column = column, output = :arm_sup),
        on = filter(y -> y!=:sectors, domain(data))
    )|>
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