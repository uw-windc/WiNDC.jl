
"""
    calibrate(data::WiNDCtable)

This is currently geared toward calibrating the national dataset.
I'll be working to make this be a general calibration function.

Returns a new WiNDCtable with the calibrated values and the model.

There are three primary balancing operations:

1. Zero Profit - Column sums are equal
2. Market Clearance - Row sums are equal
3. Margin Balance - The margins balance

The three tax rates are fixed. The tax rates are:

1. Output Tax Rate
2. Absorption Tax Rate
3. Import Tariff Rate

The following are fixed:

1. Labor Compensation
2. Imports
3. Exports
4. Household Supply

Any zero values will remain zero. 

"""
function calibrate(data::WiNDCtable)

    
    M = Model(Ipopt.Optimizer)

    @variable(M, 
        x[1:size(all_data(data),1)]
    )


    # Attach variables to dataframe
    all_data(data) |>
    x -> transform!(x,
        :value => (y -> M[:x]) => :variable
    )

    lob = .01
    upb = 10

    # set bounds and start values
    for row in eachrow(all_data(data))
        set_lower_bound(row[:variable], max(0,row[:value]*lob))
        set_upper_bound(row[:variable], abs(row[:value]*upb))
        set_start_value(row[:variable], row[:value])
    end


    # Fix certain parameters -- exogenous portions of final demand,
    # value added, imports, exports and household supply
    vcat(
        imports(data; return_cols = [:value, :variable]),
        exports(data; return_cols = [:value, :variable])
    ) |>
    x -> transform(x,
        [:value, :variable] => ByRow((val, var) -> fix(var, val; force=true))
    ) 


    # Fix negative valued data to 0
    all_data(data) |>
        x -> subset(x,
            :value => ByRow(y -> y < 0)
        ) |>
        x -> transform(x, 
            [:value, :variable] => ByRow((val, var) -> fix(var, 0; force=true))
        )


    # Fix labor compensation to target NIPA table totals
    value_added(data) |>
        x -> subset(x,
            :commodities => ByRow(==("V001"))
        ) |>
        x -> transform(x, 
            [:value, :variable] => ByRow((val, var) -> fix(var, val; force=true))
        )


    @objective(
        M, 
        Min, 
        all_data(data) |> #; filter = [:year => year]) |>
            x -> transform(x,
                [:value, :variable] => ByRow((val, var) -> 
                    abs(val) * (var/val - 1)^2) => :objective
            ) |>
            x -> combine(x, :objective => sum => :objective) |>
            x -> x[1,:objective]
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

    marginal_goods = ["441","445","452"]
    
    # Bound gross output
    outerjoin(
        gross_output(data; column = :variable, output = :expr),
        gross_output(data; column = :value),
        on = [:commodities, :state, :year]
    ) |> 
    x -> transform(x,
        [:commodities, :value] => ByRow((c,v) -> c∈marginal_goods ? 0 : max(lob*v)) => :lower,
        [:commodities, :value] => ByRow((c,v) -> c∈marginal_goods ? 0 : abs(upb*v)) => :upper,
    )|>
    x -> @constraint(M,
        gross_output[i=1:size(x,1)],
        x[i,:lower] <= x[i,:expr] <= x[i,:upper]
    )
    

    
    # Bound armington supply
    outerjoin(
        armington_supply(data; column = :variable, output = :expr),
        armington_supply(data; column = :value),
        on = [:commodities, :state, :year]
    ) |>
    x -> @constraint(M,
        armington_supply[i=1:size(x,1)],
        max(0,lob * x[i,:value]) <= x[i,:expr] <= abs(upb * x[i,:value])
    )
    
    # Fix tax rates
    outerjoin(
        output_tax(data, column = :variable, output = :output),
        intermediate_supply(data) |>
            x -> groupby(x, [:sectors, :state, :year]) |>
            x -> combine(x, :variable => sum => :id),
        output_tax_rate(data, column = :value, output = :otr),
        on = [:sectors, :state, :year]
    ) |>
    x -> dropmissing(x) |>
    x -> @constraint(M, 
        Output_Tax_Rate[i=1:size(x,1)],
        x[i,:output] == x[i,:id] * x[i,:otr]
    )
    
    outerjoin(
        absorption_tax(data, column = :variable, output = :at),
        armington_supply(data, column = :variable, output = :as),
        absorption_tax_rate(data, output = :atr),
        on = [:commodities, :state, :year]
    ) |>
    x -> dropmissing(x) |>
    x -> @constraint(M,
        Absorption_Tax_Rate[i=1:size(x,1)],
        x[i,:at] == x[i,:as] * x[i,:atr]
    )
    
    outerjoin(
        import_tariff(data, column = :variable, output = :it),
        imports(data, column = :variable, output = :imports),
        import_tariff_rate(data, output = :itr),
        on = [:commodities, :state, :year]
    ) |>
    x -> dropmissing(x) |>
    x -> @constraint(M,
        Import_Tariff_Rate[i=1:size(x,1)],
        x[i,:it] == x[i,:imports] * x[i,:itr]
    )

    optimize!(M)

    @assert is_solved_and_feasible(M) "Error: The model was not solved to optimality."

    df = all_data(data) |>
        x -> transform(x,
            :variable => ByRow(value) => :value
        ) |>
        x -> select(x, Not(:variable))


    all_data(data) |>
        x -> select!(x, Not(:variable))

    return (WiNDCtable(df, domain(data), data.sets), M)

end