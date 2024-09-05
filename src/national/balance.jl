

zero_profit(data::WiNDCtable; column = :value, output = :zero_profit) = 
    outerjoin(
        intermediate_demand(data) |>
            x -> groupby(x, [:sectors, :state, :year]) |>
            x -> combine(x, column => sum => :id),

        value_added(data) |>
            x -> groupby(x, [:sectors, :state, :year]) |>
            x -> combine(x, column => sum => :va),

        #output_tax(data, column = column, output = :output_tax),
        output_tax_rate(data, column = :value, output = :output_tax),

        intermediate_supply(data) |>
            x -> groupby(x, [:sectors, :state, :year]) |>
            x -> combine(x, column => sum => :is),
        on = [:sectors, :state, :year]
    ) |>
    x -> coalesce.(x, 0) |>
    x -> transform(x,
        [:id, :va, :output_tax, :is] => 
            ByRow((id, va, ot, is) -> id + va - (1-ot)*is) => output
    ) |>
    x -> select(x, :sectors, :state, :year, output)

market_clearance(data::WiNDCtable; column = :value, output = :market_clearance) = 
    outerjoin(
        armington_supply(data, column = column, output= :arm_sup),
        #absorption_tax(data, column = column, output = :abs_tax),
        absorption_tax_rate(data, output = :abs_tax),
        exports(data, column = column, output = :exports),
        gross_output(data, column = column, output = :gross_output),
        imports(data, column = column, output = :imports),
        #import_tariff(data, column = column, output = :import_tariff),
        import_tariff_rate(data, output = :import_tariff),
        margin_demand(data, column = column, output = :md) |>
            x -> groupby(x, [:commodities, :state, :year]) |>
            x -> combine(x, :md => sum => :mar_dem),

        on = [:commodities, :state, :year]
    ) |>
    x -> coalesce.(x,0) |>
    x -> transform(x, 
        [:arm_sup, :abs_tax, :exports, :gross_output, :imports, :import_tariff, :mar_dem] =>
        ByRow((as, at, ex, go, im, it, md) -> as*(1-at) + ex - ( go + im*(1+it) + md)) =>
        output
    ) |>
    x -> select(x, [:commodities, :state, :year, output])

margin_balance(data::WiNDCtable; column = :value) =
    outerjoin(
        margin_supply(data, column = column, output = :ms),
        margin_demand(data, column = column, output = :md),
        on = [:commodities, :sectors, :state, :year]
    ) |>
        x -> coalesce.(x, 0) |>
        x -> transform(x,
            [:ms, :md] => ByRow((ms,md) -> ms-md) => :value
        ) |>
        x -> groupby(x, [:sectors, :state, :year]) |>
        x -> combine(x, :value => sum => :margin_balance)

