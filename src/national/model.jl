
function extract_subtable_df(
    data::SubDataFrame, 
    subtable::Vector{String};
    output = subtable
)
    data |>
        x -> subset(x, 
            :subtable => ByRow(∈(subtable))
        ) |>
        x -> rename(x, :value => output)
end


function extract_subtable_df(
    data::SubDataFrame, 
    subtable::String;
    output = subtable
)
    return extract_subtable_df(data, [subtable], output = output)
end




function extract_subtable_df(
    data::DataFrame, 
    subtable::Vector{String};
    output = subtable
)
    data |>
        x -> subset(x, 
            :subtable => ByRow(in(subtable))
        ) |>
        x -> rename(x, :value => output)
end

function extract_subtable_df(
    data::DataFrame, 
    subtable::String;
    output = subtable
)
    return extract_subtable_df(data, [subtable], output = output)
end



"""
    national_mpsge(data::NationalTable)

Create a MPSGE model from the given NationalTable object.

## Required Arguments

1. `data` - A NationalTable object.

## Output

Returns a MPSGEModel object.

To Do:

Describe Model
"""
function national_mpsge(data::NationalTable)
    
    M = MPSGEModel()

    sectors = get_set(data, "sectors") |> x -> x[!,:element]
    commodities = get_set(data, "commodities") |> x -> x[!,:element]

    
    margins = get_set(data, "margin_supply") |>
                    x -> subset(x, :domain => ByRow(==(:sectors))) |>
                    x -> x[:, :element]
    
    ValueAdded = get_set(data, ["labor_demand", "capital_demand"]) |>
                    x -> subset(x, :domain => ByRow(==(:commodities))) |>
                    x -> x[:, :element]

    @parameters(M, begin
        Absorption_tax[commodities], 0
        Output_tax[sectors], 0
        Margin_tax[commodities], 0
    end)

    for row in eachrow(WiNDC.absorption_tax_rate(data))
        set_value!(M[:Absorption_tax][row[:commodities]], row[:value])
    end

    for row in eachrow(WiNDC.other_tax_rate(data))
        set_value!(M[:Output_tax][row[:sectors]], row[:value])
    end

    for row in eachrow(WiNDC.import_tariff_rate(data))
        set_value!(M[:Margin_tax][row[:commodities]], row[:value])
    end
    

    @sectors(M, begin
        Y[sectors], (description = "Sectoral Production")
        A[commodities], (description = "Armington Supply")
        MS[margins], (description = "Margin Supply")
    end)

    
    @commodities(M, begin
        PA[commodities], (description = "Armington Price")
        PY[commodities], (description = "Output Price")
        PVA[ValueAdded], (description = "Value Added Price")
        PM[margins], (description = "Margin Price")
        PFX
    end)


    @consumer(M, RA, description = "Representative Agent")


    get_subtable(data, ["intermediate_supply", "intermediate_demand", "labor_demand", "capital_demand"]) |>
    x -> groupby(x, :sectors) |>
    X -> for (key, df) in pairs(X)
        sector = key[:sectors]
        @production(M, Y[sector], [t=0, s=0, va => s = 1], begin
            [@output(PY[row[:commodities]], row[:is], t, taxes = [Tax(RA, Output_tax[sector])]) for row∈eachrow(extract_subtable_df(df, "intermediate_supply", output = "is"))]...
            [@input(PA[row[:commodities]], row[:id], s) for row∈eachrow(extract_subtable_df(df, "intermediate_demand", output = "id"))]...
            [@input(PVA[row[:commodities]], row[:va], va) for row∈eachrow(extract_subtable_df(df, ["labor_demand", "capital_demand"], output = "va"))]...
        end)
    end

    get_subtable(data, "margin_supply", output = :ms) |>
        x -> groupby(x, :sectors) |>
        x -> for (key, df) in pairs(x)
            margin = key[:sectors]
            @production(M, MS[margin], [t=0,s=0], begin
                @output(PM[margin], sum(df[!,:ms]), t)
                [@input(PY[row[:commodities]], row[:ms], s) for row∈eachrow(df) if row[:ms]!=0]...
            end)
        end
        
    outerjoin(
        WiNDC.armington_supply(data; output = :as),
        get_subtable(data, "exports", output = :ex) |>
            x -> select(x, Not(:sectors)),
        get_subtable(data, "margin_demand", output = :md) |>
            x -> unstack(x, :sectors, :md), # :Trade, :Trans
        WiNDC.gross_output(data; output = :go),
        get_subtable(data, "imports", output = :im)|>
            x -> select(x, Not(:sectors)),
        WiNDC.absorption_tax_rate(data, output = :atr),
        WiNDC.import_tariff_rate(data, output = :itr),
        on = filter(y -> y!=:sectors, domain(data))
    ) |>
    x -> coalesce.(x, 0) |>
    x -> for row∈eachrow(x)
            commodity = row[:commodities]
            @production(M, A[commodity], [t=2, s=0, dm => s = 2], begin
                @output(PA[commodity], row[:as], t, taxes = [Tax(RA, Absorption_tax[commodity])], reference_price = 1 - row[:atr])
                @output(PFX, row[:ex], t)
                [@input(PM[m], row[Symbol(m)], s) for m∈margins]...
                @input(PFX, row[:im], dm, taxes = [Tax(RA, Margin_tax[commodity])], reference_price = 1 + row[:itr])
                @input(PY[commodity], row[:go] > 1e-6 ? row[:go] : 0, dm)
            end)
        end        


    PCE = get_subtable(data, "personal_consumption", output = :pce)
    HS = get_subtable(data, "household_supply", output = :hs)
    BOPDEF = WiNDC.balance_of_payments(data, output = :bopdef)
    XFD = get_subtable(data, "exogenous_final_demand", output = :xfd)
    VA = vcat(
        get_subtable(data, "labor_demand", output = :va),
        get_subtable(data, "capital_demand", output = :va)
    )

    @demand(M, RA, begin
        [@final_demand(PA[row[:commodities]], row[:pce]) for row∈eachrow(PCE)]...
        [@endowment(PY[row[:commodities]], row[:hs]) for row∈eachrow(HS)]...
        @endowment(PFX, BOPDEF[1,:bopdef])
        [@endowment(PA[row[:commodities]], -row[:xfd]) for row∈eachrow(XFD)]...
        [@endowment(PVA[row[:commodities]], row[:va]) for row∈eachrow(VA)]...
    end)


    return M
end