


"""
    calibrate_fix_variables(M::Model, data::AbstractNationalTable)

Four subtables are exogenous to the model and are fixed. These are:

- `imports`
- `exports`
- `labor_demand`
- `household_supply`

"""
function calibrate_fix_variables(M::Model, data::AbstractNationalTable)
    vcat(
        get_subtable(data, "imports", [:value, :variable]),
        get_subtable(data, "exports", [:value, :variable]),
        get_subtable(data, "labor_demand", [:value, :variable]),
        get_subtable(data, "household_supply", [:value, :variable]),
    ) |>
    x -> transform(x,
        [:value, :variable] => ByRow((val, var) -> fix(var, val; force=true))
    ) 
end



"""
    calibrate_constraints(
        M::Model, 
        data::AbstractNationalTable; 
        lower_bound = .01, 
        upper_bound = 10
        )

There are three primary balancing operations:
    
1. [`zero_profit`](@ref) - Column sums are equal
2. [`market_clearance`](@ref) - Row sums are equal
3. [`margin_balance`](@ref) - The margins balance

Two table sums are bounded by `lower_bound` and `upper_bound` multipliers. These 
are:

1. [`gross_output`](@ref)
2. [`armington_supply`](@ref)

The three tax rates are fixed. The tax rates are:

1. [`output_tax_rate`](@ref)
2. [`absorption_tax_rate`](@ref)
3. [`import_tariff_rate`](@ref)
"""
function calibrate_constraints(
        M::Model, 
        data::AbstractNationalTable; 
        lower_bound = .01, 
        upper_bound = 10
        )

    zero_profit(data; column = :variable) |> 
    x -> @constraint(M, 
        zero_profit[i=1:size(x,1)],
        x[i,:zero_profit] == 0
    )

    market_clearance(data; column = :variable) |>
    x -> @constraint(M,
        mkt[i=1:size(x,1)],
        x[i,:market_clearance] == 0
    )

    margin_balance(data; column = :variable) |>
    x -> @constraint(M,
        margin_balance[i=1:size(x,1)],
        x[i,:margin_balance] == 0
    )
    

    
    # Bound gross output
    outerjoin(
        gross_output(data; column = :variable, output = :expr),
        gross_output(data; column = :value),
        on = [:commodities, :year]
    ) |> 
    x -> transform(x,
            :value => ByRow(v -> v>0 ? floor(lower_bound*v)-5 : upper_bound*v) => :lower, 
            :value => ByRow(v -> v>0 ? upper_bound*v : ceil(lower_bound*v)+5) => :upper, 
    )|>
    x -> @constraint(M,
        gross_output[i=1:size(x,1)],
        x[i,:lower] <= x[i,:expr] <= x[i,:upper]
    )
  
    
    # Bound armington supply
    outerjoin(
        armington_supply(data; column = :variable, output = :expr),
        armington_supply(data; column = :value),
        on = [:commodities, :year]
    ) |>
    x -> @constraint(M,
        armington_supply[i=1:size(x,1)],
        max(0,lower_bound * x[i,:value]) <= x[i,:expr] <= abs(upper_bound * x[i,:value])
    )
 
    

    # Fix tax rates
    outerjoin(
        get_subtable(data, ["intermediate_demand", "value_added"])  |>
            x -> groupby(x, filter(y -> y!=:commodities, domain(data))) |>
            x -> combine(x, :variable => sum => :total_output),
        output_tax(data, column = :variable, output = :ot),
        other_tax_rate(data, column = :value, output = :otr),
        on = filter(y -> y!=:commodities, domain(data))
    ) |>
    x -> dropmissing(x) |>
    x -> @constraint(M, 
        Output_Tax_Rate[i=1:size(x,1)],
        x[i,:ot] == x[i,:total_output] * x[i,:otr]
    )
    

    outerjoin(
        absorption_tax(data, column = :variable, output = :at),
        armington_supply(data, column = :variable, output = :as),
        absorption_tax_rate(data, output = :atr),
        on = filter(y -> y!=:sectors, domain(data))
    ) |>
    x -> dropmissing(x) |>
    x -> @constraint(M,
        Absorption_Tax_Rate[i=1:size(x,1)],
        x[i,:at] == x[i,:as] * x[i,:atr]
    )
    
    outerjoin(
        get_subtable(data, "duty", column = :variable, output = :it) |>
            x -> select(x, Not(:sectors)),
        get_subtable(data, "imports", column = :variable, output = :imports) |>
            x -> select(x, Not(:sectors)),
        import_tariff_rate(data, output = :itr),
        on = filter(y -> y!=:sectors, domain(data))
    ) |>
    x -> dropmissing(x) |>
    x -> @constraint(M,
        Import_Tariff_Rate[i=1:size(x,1)],
        x[i,:it] == x[i,:imports] * x[i,:itr]
    )

    
end
