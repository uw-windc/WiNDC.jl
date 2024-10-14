

function zero_profit(data::WiNDCtable; column = :value, output = :zero_profit)

    ag_columns = filter(y -> y!=:commodities, domain(data))
    return vcat(
            get_subtable(data, "intermediate_demand", column = column),
            get_subtable(data, "value_added", column = column), 
            get_subtable(data, "intermediate_supply", column = column, negative = true) 
        ) |> 
        x -> groupby(x, ag_columns) |>
        x -> combine(x, column => sum => output)    
end


function market_clearance(data::WiNDCtable; column = :value, output = :market_clearance) 
    ag_columns = filter(y -> y!=:sectors, domain(data))

        return vcat(
            get_subtable(data, "intermediate_demand", column = column) ,
            get_subtable(data, "final_demand", column = column),
            get_subtable(data, "household_supply", column = column, negative = true),

            get_subtable(data, "intermediate_supply", column = column, negative = true),
            get_subtable(data, "imports", column = column, negative = true),
            get_subtable(data, "margin_demand", column = column, negative = true),
            get_subtable(data, "margin_supply", column = column), # Made negative earlier
            get_subtable(data, "duty", column = column, negative = true),
            get_subtable(data, "tax", column = column, negative = true),
            get_subtable(data, "subsidies", column = column) # Made negative earlier
        ) |>
        x -> groupby(x, ag_columns) |>
        x -> combine(x, column => sum => output)
end

margin_balance(data::WiNDCtable; column = :value, output = :margin_balance) =
    vcat(
        WiNDC.get_subtable(data, "margin_supply", column = column, negative = true),
        WiNDC.get_subtable(data, "margin_demand", column = column)
    ) |>
    x -> groupby(x, filter(y -> y!=:commodities, domain(data))) |>
    x -> combine(x, column => sum => output)
