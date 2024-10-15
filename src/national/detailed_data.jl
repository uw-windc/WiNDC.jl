"""
    create_national_detailed_sets(use::XLSX.Worksheet, supply::XLSX.Worksheet)

This function creates the sets for the detailed national data.
"""
function create_national_detailed_sets(use::XLSX.Worksheet, supply::XLSX.Worksheet)



    aggregate_sets = DataFrame(
        [
        ("labor_demand", "Labor Demand", "value_added"),
        ("capital_demand", "Capital Demand", "value_added"),
        ("other_tax", "Other taxes on production", "value_added"),
        ("exogenous_final_demand", "Exogenous portion of final demand", "final_demand"),
        ("exports", "Exports of goods and services", "final_demand"),
        ("personal_consumption", "Personal consumption expenditures", "final_demand"),
        ("intermediate_demand", "", "intermediate_demand"),
        ("labor_demand", "", "labor_demand"),
        ("capital_demand", "", "capital_demand"),
        ("other_tax", "", "other_tax"),
        ("personal_consumption", "Personal consumption expenditures", "personal_consumption"),
        ("exogenous_final_demand","", "exogenous_final_demand"),
        ("exports", "", "exports"),
        ("intermediate_supply", "", "intermediate_supply"),
        ("imports", "", "imports"),
        ("household_supply", "Personal consumption expenditures, values <0", "household_supply"),
        ("margin_demand", "", "margin_demand"),
        ("margin_supply", "", "margin_supply"),
        ("duty", "", "duty"),
        ("tax", "", "tax"),
        ("subsidies", "", "subsidies"),
        ],
    [:element, :description, :set]
    )

    return vcat(
        aggregate_sets,
        DataFrame(use["A7:B408"], [:element, :description])|>
            x -> transform(x, :element => ByRow(x -> "commodities") => :set),
        DataFrame(use["A410:B410"], [:element, :description]) |>
            x -> transform(x, :element => ByRow(x -> "labor_demand") => :set),
        DataFrame(use["A411:B411"], [:element, :description]) |>
            x -> transform(x, :element => ByRow(x -> "other_tax") => :set),
        DataFrame(use["A412:B412"], [:element, :description]) |>
            x -> transform(x, :element => ByRow(x -> "capital_demand") => :set),
        DataFrame(permutedims(use["C5:ON6"], (2,1)), [:description, :element])|>
            x -> transform(x, :element => ByRow(x -> "sectors") => :set),
        DataFrame(permutedims(use["OP5:OP6"], (2,1)), [:description, :element]) |>
            x -> transform(x, :element => ByRow(x -> "personal_consumption") => :set),
        DataFrame(permutedims(use["OP5:OP6"], (2,1)), [:description, :element]) |>
            x -> transform(x, :element => ByRow(x -> "household_supply") => :set),
        DataFrame(permutedims(use["OQ5:PH6"], (2,1)), [:description, :element]) |>
            x -> transform(x, :element => ByRow(x -> x== "F04000" ? "exports" : "exogenous_final_demand") => :set),
        DataFrame(permutedims(supply["OP5:OP6"], (2,1)), [:description, :element]) |>
            x -> transform(x, :element => ByRow(x -> "imports") => :set),
        DataFrame(permutedims(supply["OS5:OT6"], (2,1)), [:description, :element]) |>
            x -> transform(x, :element => ByRow(x -> "margin_demand") => :set),
        DataFrame(permutedims(supply["OS5:OT6"], (2,1)), [:description, :element]) |>
            x -> transform(x, :element => ByRow(x -> "margin_supply") => :set),
        DataFrame(permutedims(supply["OV5:OV6"], (2,1)), [:description, :element]) |>
            x -> transform(x, :element => ByRow(x -> "duty") => :set),
        DataFrame(permutedims(supply["OW5:OW6"], (2,1)), [:description, :element]) |>
            x -> transform(x, :element => ByRow(x -> "tax") => :set),
        DataFrame(permutedims(supply["OX5:OX6"], (2,1)), [:description, :element]) |>
        x -> transform(x, :element => ByRow(x -> "subsidies") => :set)
    ) |>
    x -> transform(x,
        [:element, :set] .=> ByRow(x -> string(x)) .=> [:element, :set]
    )
end


"""
    make_subtable(sets, rows, columns, table, subtable)

A helper function for extracting subtables.
"""
function make_subtable(sets, rows, columns, table, subtable)
    return crossjoin(
        sets |>
            x -> subset(x,:set => ByRow(==(rows))) |>
            x -> select(x, :element) |>
            x -> rename(x, :element => :commodities),
        sets |>
            x -> subset(x,:set => ByRow(==(columns))) |>
            x -> select(x, :element) |>
            x -> rename(x, :element => :sectors)
    ) |>
    x -> transform(x, :commodities => ByRow(x -> (table,subtable)) => [:table,:subtable]) 
end

"""
    create_national_detailed_subtables(sets)

This function creates the subtables for the detailed national data.
"""
function create_national_detailed_subtables(sets)
    return vcat(
        make_subtable(sets, "commodities", "sectors", "use", "intermediate_demand"),
        make_subtable(sets, "labor_demand", "sectors", "use", "labor_demand"),
        make_subtable(sets, "other_tax", "sectors", "use", "other_tax"),
        make_subtable(sets, "capital_demand", "sectors", "use", "capital_demand"),
        make_subtable(sets, "commodities", "personal_consumption", "use", "personal_consumption"),
        make_subtable(sets, "commodities", "household_supply", "use", "household_supply"),
        make_subtable(sets, "commodities", "exogenous_final_demand", "use", "exogenous_final_demand"),
        make_subtable(sets, "commodities", "exports", "use", "exports"),
        make_subtable(sets, "commodities", "sectors", "supply", "intermediate_supply"),
        make_subtable(sets, "commodities", "imports", "supply", "imports"),
        make_subtable(sets, "commodities", "cif", "supply", "cif"),
        make_subtable(sets, "commodities", "margin_demand", "supply", "margin_demand"),
        make_subtable(sets, "commodities", "margin_supply", "supply", "margin_supply"),
        make_subtable(sets, "commodities", "duty", "supply", "duty"),
        make_subtable(sets, "commodities", "tax", "supply", "tax"),
        make_subtable(sets, "commodities", "subsidies", "supply", "subsidies"),
    )
end

























