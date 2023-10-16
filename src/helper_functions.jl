extract_variable_ref(v::NonlinearExpr) = v.args[1]
extract_variable_ref(v::AffExpr) = collect(keys(v.terms))[1]
extract_variable_ref(v::QuadExpr) = extract_variable_ref(v.aff)

function generate_report(m::JuMP.Model;decimals::Int = 4)

    mapping = Dict()
    for ci in all_constraints(m; include_variable_in_set_constraints = false)
        c = constraint_object(ci)
        mapping[extract_variable_ref(c.func[2])] = c.func[1]
    end

    out = "var_name\t value\t\t margin\n"
    for elm in all_variables(m)

        val = round(value(elm),digits = decimals)
        margin = "."
        try
            margin = round(value(mapping[elm]),digits = decimals)
        catch
            margin = "."
        end
        

        out = out*"$elm\t\t $val\t\t $margin\n"
    end

    return(out)
end

function verify_calibration(m::JuMP.Model)
    sum([abs(a) for (a,b) in value.(all_constraints(m; include_variable_in_set_constraints = false))])
end

function apply_notations(df, notations)
    for notation in notations
        df = WiNDC.apply_notation!(df,notation)
    end
    return df
end