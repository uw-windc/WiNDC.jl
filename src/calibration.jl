
"""
    calibrate(data::T; silent = false, lower_bound = .01, upper_bound = 10)

General calibration functions. Handles variable creation, objective function,
optimization and post-processing. 

## Required Arguments

- `data::T`: A table of data to calibrate.

## Optional Arguments

- `silent::Bool=false`: If true, the optimization solver will not print output.
- `lower_bound::Number=.01`: The lower bound multiplier for the variables.
- `upper_bound::Number=10`: The upper bound multiplier for the variables.

## Returns

A tuple of the calibrated data and the optimization model. The calibrated data
will have the same type as the input data.

## Functions 

[`calibrate_fix_variables`](@ref) - Fix variables that should not be calibrated.
[`calibrate_constraints`](@ref) - Add constraints to the model.
"""
function calibrate(
        data::T;
        silent::Bool = false,
        lower_bound::Number = .01,
        upper_bound::Number = 10
    ) where T<:WiNDCtable

    # Create the model, variables and attach them to the data.
    M = Model(Ipopt.Optimizer)

    if silent
        set_silent(M)
    end

    @variable(M, 
        x[1:size(get_table(data),1)]
    )


    # Attach variables to dataframe
    get_table(data) |>
    x -> transform!(x,
        :value => (y -> M[:x]) => :variable
    )

    # set bounds and start values
    for row in eachrow(get_table(data))
        set_start_value(row[:variable], row[:value])
        lbd = row[:value]>0 ? row[:value]*lower_bound : row[:value]*upper_bound
        upd = row[:value]>0 ? row[:value]*upper_bound : row[:value]*lower_bound
        set_lower_bound(row[:variable], lbd)
        set_upper_bound(row[:variable], upd)
        if row[:value] == 0
            fix(row[:variable], 0; force=true)
        end
    end

    calibrate_fix_variables(M, data)


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

    calibrate_constraints(M, data; lower_bound = lower_bound, upper_bound = upper_bound)

    optimize!(M)
    
    @assert is_solved_and_feasible(M) "Error: The model was not solved to optimality."

    df = get_table(data) |>
        x -> transform(x,
            :variable => ByRow(value) => :value
        ) |>
        x -> select(x, Not(:variable))


    get_table(data) |>
        x -> select!(x, Not(:variable))

    return (T(df, data.sets), M)
end


calibrate_fix_variables(M::Model, data::WiNDCtable) = throw(ArgumentError("calibrate_fix_variables not implemented for WiNDCtable"))

calibrate_constraints(M::Model, data::WiNDCtable; lower_bound = .01, upper_bound = 10) = throw(ArgumentError("calibrate_constraints not implemented for WiNDCtable"))