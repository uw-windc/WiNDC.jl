
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
        x[1:size(get_table(data),1)]
    )


    # Attach variables to dataframe
    get_table(data) |>
    x -> transform!(x,
        :value => (y -> M[:x]) => :variable
    )

    lob = .01
    upb = 100

    # set bounds and start values
    for row in eachrow(get_table(data))
        set_start_value(row[:variable], row[:value])
        lower_bound = row[:value]>0 ? row[:value]*lob : row[:value]*upb
        upper_bound = row[:value]>0 ? row[:value]*upb : row[:value]*lob
        set_lower_bound(row[:variable], lower_bound)
        set_upper_bound(row[:variable], upper_bound)
        if row[:value] == 0
            fix(row[:variable], 0; force=true)
        end
    end


    # Fix certain parameters -- exogenous portions of final demand,
    # value added, imports, exports and household supply
    vcat(
        get_subtable(data, "imports", [:value, :variable]),
        get_subtable(data, "exports", [:value, :variable]),
        get_subtable(data, "labor_demand", [:value, :variable]),
        get_subtable(data, "household_supply", [:value, :variable]),
    ) |>
    x -> transform(x,
        [:value, :variable] => ByRow((val, var) -> fix(var, val; force=true))
    ) 


    # Fix negative valued data to 0
    #get_table(data) |>
    #    x -> subset(x,
    #        :value => ByRow(y -> y < 0)
    #    ) |>
    #    x -> transform(x, 
    #        [:value, :variable] => ByRow((val, var) -> fix(var, 0; force=true))
    #    )


    @objective(
        M, 
        Min, 
        get_table(data) |> 
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
    
    
    # Bound gross output
    outerjoin(
        gross_output(data; column = :variable, output = :expr),
        gross_output(data; column = :value),
        on = [:commodities, :year]
    ) |> 
    x -> transform(x,
            :value => ByRow(v -> v>0 ? floor(lob*v)-5 : upb*v) => :lower, 
            :value => ByRow(v -> v>0 ? upb*v : ceil(lob*v)+5) => :upper, 
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
        max(0,lob * x[i,:value]) <= x[i,:expr] <= abs(upb * x[i,:value])
    )
    
    
    # Fix tax rates
    outerjoin(
        get_subtable(data, "intermediate_supply", column = :variable, output = :is) |>
            x -> groupby(x, filter(y -> y!=:commodities, domain(data))) |>
            x -> combine(x, :is => sum => :is),
        get_subtable(data, "other_tax", column = :variable, output = :ot) |>
            x -> select(x, Not(:commodities)),
        other_tax_rate(data, column = :value, output = :otr),
        on = filter(y -> y!=:commodities, domain(data))
    ) |>
    x -> dropmissing(x) |>
    x -> @constraint(M, 
        Output_Tax_Rate[i=1:size(x,1)],
        x[i,:ot] == x[i,:is] * x[i,:otr]
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
    


    optimize!(M)

    @assert is_solved_and_feasible(M) "Error: The model was not solved to optimality."

    df = get_table(data) |>
        x -> transform(x,
            :variable => ByRow(value) => :value
        ) |>
        x -> select(x, Not(:variable))


    get_table(data) |>
        x -> select!(x, Not(:variable))

    return (NationalTable(df, data.sets), M)

end