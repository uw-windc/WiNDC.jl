"""
    create_national_sets(
        use::XLSX.Worksheet, 
        supply::XLSX.Worksheet,
        set_regions)

This function creates the sets for the detailed national data.

set regions for detailed table

    Dict(
        "commodities" => ("use", ["A7:B408"], :commodities),
        "labor_demand" => ("use", ["A410:B410"], :commodities),
        "other_tax" => ("use", ["A411:B411"], :commodities),
        "capital_demand" => ("use", ["A412:B412"], :commodities),
        "sectors" => ("use", ["C5:ON6"], :sectors),
        "personal_consumption" => ("use", ["OP5:OP6"], :sectors),
        "household_supply" => ("use", ["OP5:OP6"], :sectors),
        "exports" => ("use", ["OV5:OV6"], :sectors),
        "exogenous_final_demand" => ("use", ["OQ5:OU6","OW5:PH6"], :sectors),
        "imports" => ("supply", ["OP5:OP6"], :sectors),
        "margin_demand" => ("supply", ["OS5:OT6"], :sectors),
        "margin_supply" => ("supply", ["OS5:OT6"], :sectors),
        "duty" => ("supply", ["OV5:OV6"], :sectors),
        "tax" => ("supply", ["OW5:OW6"], :sectors),
        "subsidies" => ("supply", ["OX5:OX6"], :sectors)
    )
"""
function create_national_sets(
        use::XLSX.Worksheet, 
        supply::XLSX.Worksheet,
        set_regions;
        table_type = :detailed)

    aggregate_sets = DataFrame(
        [
        ("labor_demand", "Labor Demand", "value_added", :composite),
        ("capital_demand", "Capital Demand", "value_added", :composite),
        ("sector_subsidy", "", "value_added", :composite),
        ("other_tax", "Other taxes on production", "value_added", :composite),
        ("exogenous_final_demand", "Exogenous portion of final demand", "final_demand", :composite),
        ("exports", "Exports of goods and services", "final_demand", :composite),
        ("personal_consumption", "Personal consumption expenditures", "final_demand", :composite),
        ("intermediate_demand", "", "intermediate_demand", :composite),
        ("labor_demand", "", "labor_demand", :composite),
        ("capital_demand", "", "capital_demand", :composite),
        ("sector_subsidy", "Introduced after Covid", "sector_subsidty", :composite), 
        ("other_tax", "", "other_tax", :composite),
        ("personal_consumption", "Personal consumption expenditures", "personal_consumption", :composite),
        ("exogenous_final_demand","", "exogenous_final_demand", :composite),
        ("exports", "", "exports", :composite),
        ("intermediate_supply", "", "intermediate_supply", :composite),
        ("imports", "", "imports", :composite),
        ("household_supply", "Personal consumption expenditures, values <0", "household_supply", :composite),
        ("margin_demand", "", "margin_demand", :composite),
        ("margin_supply", "", "margin_supply", :composite),
        ("duty", "", "duty", :composite),
        ("tax", "", "tax", :composite),
        ("subsidies", "", "subsidies", :composite),
        ("cif", "", "cif", :composite),
        ],
    [:element, :description, :set, :domain]
    )

    S = [aggregate_sets]
    for (key, (sheet, range, dom)) in set_regions
        if sheet == "use"
            table = use
        else
            table= supply
        end
        if dom == :sectors # flip the table if the domain is sectors
            region = hcat([table[x] for x in range]...)
            region = permutedims(region, (2,1))
            if table_type == :detailed # The detailed table and summary tables flip the location of the naics codes and descriptions
                region[:,1], region[:,2] = region[:,2], region[:,1]
            end
        else
            region = vcat([table[x] for x in range]...)
        end
        df = DataFrame(region, [:element, :description]) |>
            x -> transform!(x, 
                :element => ByRow(x -> key) => :set,
                :element => ByRow(x -> dom) => :domain
            )
        push!(S, df)
    end

    return vcat(
            S...
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
    create_national_subtables(sets)

This function creates the subtables for the detailed national data.
"""
function create_national_subtables(sets)
    return vcat(
        make_subtable(sets, "commodities", "sectors", "use", "intermediate_demand"),
        make_subtable(sets, "labor_demand", "sectors", "use", "labor_demand"),
        make_subtable(sets, "other_tax", "sectors", "use", "other_tax"),
        make_subtable(sets, "sector_subsidy", "sectors", "use", "sector_subsidy"),
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




############################
#### Disagregation Code ####
############################
"""
    down_fill(X)

This function fills in the missing values in a column with the last non-missing value.
"""
function down_fill(X)
    output = Vector{Any}()
    current_value = X[1]
    for row in X
        if !ismissing(row)
            current_value = row
        end
        push!(output, current_value)
    end
    return output
end

"""
    detailed_summary_map(detailed_path)

This function reads the detailed table and returns a DataFrame that maps the detailed
sectors to the summary sectors. The first sheet of the detailed table is a map between
the detailed sectors and the summary sectors. In addition this maps value added, final
demand and supply extras to the summary sectors.
"""
function detailed_summary_map(detailed_path::String)

    detailed_xlsx = XLSX.readdata(detailed_path, "NAICS Codes", "B5:E1022")

    df = detailed_xlsx |>
        x -> DataFrame(x[4:end,:], [x[1,1:end-1]..., "description"]) |>
        x -> select(x, Not("U.Summary")) |>
        x -> transform(x,
            :Summary => down_fill => :Summary,
            :Detail => down_fill => :Detail
        ) |>
        x -> dropmissing(x) |>
        x -> rename(x, :Summary => :summary, :Detail => :detailed) |>
        x -> transform(x,
            [:summary,:detailed] .=> ByRow(string) .=> [:summary,:detailed]
        )

        df = vcat(df, 
            DataFrame([
                (summary = "T00OTOP", detailed = "T00OTOP", description = "Other taxes on production"),
                (summary = "V003", detailed = "V00300", description = "Gross operating surplus"),
                (summary = "V001", detailed = "V00100", description = "Compensation of employees"),
                (summary = "F010", detailed = "F01000", description = "Personal consumption expenditures"),
                (summary = "F02E", detailed = "F02E00", description = "Nonresidential private fixed investment in equipment"),
                (summary = "F02N", detailed = "F02N00", description = "Nonresidential private fixed investment in intellectual property products"),
                (summary = "F02R", detailed = "F02R00", description = "Residential private fixed investment"),
                (summary = "F02S", detailed = "F02S00", description = "Nonresidential private fixed investment in structures"),
                (summary = "F030", detailed = "F03000", description = "Change in private inventories"),
                (summary = "F040", detailed = "F04000", description = "Exports of goods and services"),
                (summary = "F06C", detailed = "F06C00", description = "National defense: Consumption expenditures"),
                (summary = "F06E", detailed = "F06E00", description = "Federal national defense: Gross investment in equipment"),
                (summary = "F06N", detailed = "F06N00", description = "Federal national defense: Gross investment in intellectual property products"),
                (summary = "F06S", detailed = "F06S00", description = "Federal national defense: Gross investment in structures"),
                (summary = "F07C", detailed = "F07C00", description = "Nondefense: Consumption expenditures"),
                (summary = "F07E", detailed = "F07E00", description = "Federal nondefense: Gross investment in equipment"),
                (summary = "F07N", detailed = "F07N00", description = "Federal nondefense: Gross investment in intellectual property products"),
                (summary = "F07S", detailed = "F07S00", description = "Federal nondefense: Gross investment in structures"),
                (summary = "F10C", detailed = "F10C00", description = "State and local government consumption expenditures"),
                (summary = "F10E", detailed = "F10E00", description = "State and local: Gross investment in equipment"),
                (summary = "F10N", detailed = "F10N00", description = "State and local: Gross investment in intellectual property products"),
                (summary = "F10S", detailed = "F10S00", description = "State and local: Gross investment in structures"),
                (summary = "MCIF", detailed = "MCIF", description = "Imports"),
                (summary = "MADJ", detailed = "MADJ", description = "CIF/FOB Adjustments on Imports"),
                (summary = "Trade", detailed = "TRADE ", description = "Trade margins"),
                (summary = "Trans", detailed = "TRANS", description = "Transport margins"),
                (summary = "MDTY", detailed = "MDTY", description = "Import duties"),
                (summary = "TOP", detailed = "TOP", description = "Tax on products"),
                (summary = "SUB", detailed = "SUB", description = "Subsidies on products"),
                ])
        )
    return df
end


"""
    weight_function(year_detail, year_summary, minimum_detail, maximum_detail)

Create the weight function for the interpolation of the detailed table to the summary table
based solely on the year.
"""
function weight_function(year_detail::Int, year_summary::Int, minimum_detail::Int, maximum_detail::Int)
    if year_detail == minimum_detail && year_summary < year_detail
        return 1
    elseif year_detail == maximum_detail && year_summary > year_detail
        return 1
    elseif abs(year_detail.-year_summary) < 5
        return 1 .-abs.(year_detail.-year_summary)/5
    else
        return 0
    
    end
end


function national_disaggragate_summary_to_detailed(detailed::NationalTable, summary::NationalTable, summary_map::DataFrame)

    min_detail_year = minimum(get_table(detailed)[!, :year])
    max_detail_year = maximum(get_table(detailed)[!, :year])

#1111A0 111CA
#1111B0 111CA


    detailed_value_share = get_table(detailed) |>
        x -> innerjoin(x, summary_map, on = :commodities => :detailed, renamecols = "" => "_commodities") |>
        x -> innerjoin(x, summary_map, on = :sectors => :detailed, renamecols = "" => "_sectors") |>
        x -> groupby(x, [:summary_sectors,:summary_commodities,:year, :subtable]) |>
        x -> combine(x,
            :value => (y -> y./sum(y)) => :value_share,
            [:commodities, :sectors] .=> identity .=> [:commodities, :sectors]
        ) |>
        x -> select(x, :commodities, :summary_commodities, :sectors, :summary_sectors, :year, :subtable, :value_share)

    df = innerjoin(
            detailed_value_share,
            get_table(summary),
            on = [:summary_commodities => :commodities, :summary_sectors => :sectors, :subtable],
            renamecols = "" => "_summary"
        ) |>
        x -> transform(x,
            [:year, :year_summary, :value_share, :value_summary] => 
                ByRow((dy,y,share,summary) -> WiNDC.weight_function(dy,y,min_detail_year,max_detail_year)*share*summary) => 
                :value
        ) |>
        x -> groupby(x, [:commodities, :sectors, :year_summary, :subtable]) |>
        x -> combine(x, :value => sum => :value) |>
        x -> rename(x, :year_summary => :year) |>
        x -> subset(x, :value => ByRow(!=(0)))    


    return NationalTable(df, get_set(detailed))

end
