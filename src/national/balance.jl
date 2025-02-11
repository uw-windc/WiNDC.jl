"""
    zero_profit(data::AbstractNationalTable; column = :value, output = :zero_profit)

Calculate the zero profit condition for the given data. In a calibrated dataset 
all values will be zero.

## Required Arguments

1. `data` - A WiNDCtable-like object.

## Optional Arguments

- `column::Symbol`: The column to use for the calculation. Default is `:value`.
- `output::Symbol`: The name of the output column. Default is `:zero_profit`.

## Output

Returns a DataFrame with the zero profit condition. 

"""
function zero_profit(data::AbstractNationalTable; column = :value, output = :zero_profit)

    ag_columns = filter(y -> y!=:commodities, domain(data))
    return vcat(
            get_subtable(data, "intermediate_demand", column = column, output = output),
            get_subtable(data, "value_added", column = column, output = output), 
            get_subtable(data, "intermediate_supply", column = column, output = output, negative = true) 
        ) |> 
        x -> groupby(x, ag_columns) |>
        x -> combine(x, output => (y -> sum(y;init=0)) => output)    
end

"""
    market_clearance(data::AbstractNationalTable; column = :value, output = :market_clearance) 

Calculate the market clearance condition for the given data. In a calibrated dataset
all values will be zero.

## Required Arguments

1. `data` - A WiNDCtable-like object.

## Optional Arguments

- `column::Symbol`: The column to use for the calculation. Default is `:value`.
- `output::Symbol`: The name of the output column. Default is `:market_clearance`.

## Output

Returns a DataFrame with the market clearance condition. 
"""
function market_clearance(data::AbstractNationalTable; column = :value, output = :market_clearance) 
    ag_columns = filter(y -> y!=:sectors, domain(data))

        return vcat(
            get_subtable(data, "intermediate_demand", column = column, output = output) ,
            get_subtable(data, "final_demand", column = column, output = output),
            get_subtable(data, "household_supply", column = column, output = output, negative = true),

            get_subtable(data, "intermediate_supply", column = column, output = output, negative = true),
            get_subtable(data, "imports", column = column, output = output, negative = true),
            get_subtable(data, "margin_demand", column = column, output = output, negative = true),
            get_subtable(data, "margin_supply", column = column, output = output), # Made negative earlier
            get_subtable(data, "duty", column = column, output = output, negative = true),
            get_subtable(data, "tax", column = column, output = output, negative = true),
            get_subtable(data, "subsidies", column = column, output = output) # Made negative earlier
        ) |>
        x -> groupby(x, ag_columns) |>
        x -> combine(x, output => (y -> sum(y;init=0)) => output)
end


"""
    margin_balance(data::AbstractNationalTable; column = :value, output = :margin_balance)

Calculate the margin balance condition for the given data. In a calibrated dataset
all values will be zero.

## Required Arguments

1. `data` - A WiNDCtable-like object.

## Optional Arguments

- `column::Symbol`: The column to use for the calculation. Default is `:value`.
- `output::Symbol`: The name of the output column. Default is `:margin_balance`.

## Output

Returns a DataFrame with the margin balance condition. 
"""
margin_balance(data::AbstractNationalTable; column = :value, output = :margin_balance) =
    vcat(
        WiNDC.get_subtable(data, "margin_supply", column = column, output = output, negative = true),
        WiNDC.get_subtable(data, "margin_demand", column = column, output = output)
    ) |>
    x -> groupby(x, filter(y -> y!=:commodities, domain(data))) |>
    x -> combine(x, output => (y -> sum(y;init=0)) => output)
