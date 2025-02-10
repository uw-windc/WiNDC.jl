
"""
    load_national_data_single_year(
        X::XLSX.XLSXFile,
        year,
        range,
        table_name::String;
        scale = 1_000,
        data_start_row = 2
    )

Load a single year of national data. This function is used to load data from
the supply and use tables. The data is transformed into a DataFrame with the
following columns:

- `:commodities`: The commodities in the table.
- `:sectors`: The sectors in the table.
- `:value`: The value of the commodity in the sector.
- `:year`: The year of the data.
- `:table`: The name of the table.

## Required Arguments

- `X::XLSX.XLSXFile`: The XLSXFile containing the data.
- `year`: The year of the data.
- `range`: The range of the data in the XLSXFile.
- `table_name::String`: The name of the table. Usually "use" or "supply".

## Optional Arguments

- `scale::Int = 1_000`: The scale of the data.
- `data_start_row::Int = 2`: The row in the XLSXFile where the data starts. 
    Summary tables start at 3, detailed at 2.

## Return

A DataFrame.
"""
function load_national_data_single_year(
    X::XLSX.XLSXFile,
    year,
    range,
    table_name::String;
    scale = 1_000,
    data_start_row = 2)

    U = X[year][range]

    U[1,1] = :commodities
    U[1,2] = :drop

    U[@.(!ismissing(U) && U=="...")] .= missing

    return DataFrame(U[data_start_row:end,1:end], string.(U[1,:])) |>
                x -> select(x, Not(:drop)) |>
                x -> stack(x, Not(:commodities), variable_name = :sectors) |>
                x -> coalesce.(x, 0) |>
                x -> subset(x,
                    :value => ByRow(!=(0))
                ) |>
                x -> transform(x,
                    :value => (y -> y/scale) => :value,
                    [:commodities,:sectors] .=> ByRow(string) .=> [:commodities,:sectors],
                    :commodities => ByRow(y -> parse(Int, year)) => :year,
                    :commodities => ByRow(y -> table_name) => :table
                )
end

"""
    load_national_data(
        use::XLSX.XLSXFile,
        supply::XLSX.XLSXFile;
        table_type = :detailed,
        use_range = "A6:PI417",
        supply_range = "A6:OZ409"
    )

Load the national supply and use tables. This function loads the data from the
XLSXFiles and returns a DataFrame with the following columns:

- `:commodities`: The commodities in the table.
- `:sectors`: The sectors in the table.
- `:value`: The value of the commodity in the sector.
- `:year`: The year of the data.

## Required Arguments

- `use::XLSX.XLSXFile`: The XLSXFile containing the use table.
- `supply::XLSX.XLSXFile`: The XLSXFile containing the supply table.

## Optional Arguments

- `table_type::Symbol = :detailed`: The type of table. Either `:detailed` or `:summary`.
- `use_range::String = "A6:PI417"`: The range of the use table in the XLSXFile.
- `supply_range::String = "A6:OZ409"`: The range of the supply table in the XLSXFile.

## Return

A DataFrame.
"""
function load_national_data(
    use::XLSX.XLSXFile,
    supply::XLSX.XLSXFile;
    table_type = :detailed,
    use_range = "A6:PI417",
    supply_range = "A6:OZ409"
)

    @assert XLSX.sheetnames(use) == XLSX.sheetnames(supply) "Use and supply tables do not have the same years."

    data_start_row = table_type == :detailed ? 2 : 3

    out = DataFrame()
    for year in [f for f in XLSX.sheetnames(use) if f!="NAICS Codes"]
        use_df_year = load_national_data_single_year(
            use,
            year,
            use_range,
            "use";
            data_start_row = data_start_row
        )

        supply_df_year = load_national_data_single_year(
            supply,
            year,
            supply_range,
            "supply";
            data_start_row = data_start_row
        )

        out = vcat(out, use_df_year, supply_df_year)
    end

    return out

end

"""
    build_national_table(
        file_paths::Vector{String};
        aggregation = :detailed
    )

Builds the national data from the supply and use tables. 

## Required Arguments

- `file_paths::Vector{String}`: A vector of file paths to the supply and use tables.
    Uses regex to search for the correct files. This should be the output of [`fetch_supply_use`](@ref)

## Optional Arguments

- `aggregation::Symbol = :detailed`: The type of table. Either `:detailed` or `:summary`.


## Return

A [`NationalTable`](@ref).

## Process

The data undergoes a series of transformations to create the final table. The data is loaded
from the XLSXFiles, transformed into a DataFrame, and then joined with the sets created from
the table. 

The following data tranformations take place:

1. Negative flows from `intermediate_demand` and `intermediate_supply` are reversed.
2. `subsidies` and `sector_subsidy` are negated.
3. `margin_demand` retains only positive values.
4. `margin_supply` retains only negative values, these are made positive
5. `personal_consumption` retains only positive values.
6. `household_supply` retains only negative values, these are made positive.
"""
function build_national_table(
    file_paths::Vector{String};
    aggregation = :detailed
)

    if aggregation == :detailed
        use_range = "A6:PI417"
        supply_range = "A6:OZ409"

        set_regions = Dict(
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
            "subsidies" => ("supply", ["OX5:OX6"], :sectors),
            "cif" => ("supply", ["OQ5:OQ6"], :sectors),
        )

        use_path = filter(x -> occursin(r"Use_.*_DET",x), file_paths)[1]
        supply_path = filter(x -> occursin(r"Supply_.*_DET",x), file_paths)[1]


    else
        use_range = "A6:CP90"
        supply_range = "A6:CG81"
        set_regions = Dict(
            "commodities" => ("use", ["A8:B80"], :commodities),
            "labor_demand" => ("use", ["A82:B82"], :commodities),
            "other_tax" => ("use", ["A83:B83"], :commodities),
            "sector_subsidy" => ("use", ["A84:B84"], :commodities),
            "capital_demand" => ("use", ["A85:B85"], :commodities),
            "sectors" => ("use", ["C6:BU7"], :sectors),
            "personal_consumption" => ("use", ["BW6:BW7"], :sectors),
            "household_supply" => ("use", ["BW6:BW7"], :sectors),
            "exports" => ("use", ["CC6:CC7"], :sectors),
            "exogenous_final_demand" => ("use", ["BX6:CB7","CD6:CO7"], :sectors),
            "imports" => ("supply", ["BW6:BW7"], :sectors),
            "margin_demand" => ("supply", ["BZ6:CA7"], :sectors),
            "margin_supply" => ("supply", ["BZ6:CA7"], :sectors),
            "duty" => ("supply", ["CC6:CC7"], :sectors),
            "tax" => ("supply", ["CD6:CD7"], :sectors),
            "subsidies" => ("supply", ["CE6:CE7"], :sectors),
            "cif" => ("supply", ["BX6:BX7"], :sectors),
        )

        use_path = filter(x -> occursin(r"Use_.*Summary",x), file_paths)[1]
        supply_path = filter(x -> occursin(r"Supply_.*Summary",x), file_paths)[1]

    end
    
    use = XLSX.readxlsx(use_path)
    supply = XLSX.readxlsx(supply_path)

    data = load_national_data(
            use, 
            supply; 
            table_type = aggregation,
            use_range = use_range,
            supply_range = supply_range
            )

    summary_sets = WiNDC.create_national_sets(use["2017"], supply["2017"], set_regions; table_type = aggregation)

    subtables = WiNDC.create_national_subtables(summary_sets)

    summary_data = innerjoin(
        data,
        subtables,
        on = [:commodities, :sectors, :table],
    )|>
    x -> select(x, :commodities, :sectors, :year, :subtable, :value) |>
    x -> unstack(x, :subtable, :value) |>
    x -> coalesce.(x,0) |>
    x -> transform(x, 
        [:intermediate_demand, :intermediate_supply] => ByRow(
            (d,s) -> (max(0, d - min(0, s)), max(0, s - min(0, d)))) => [:intermediate_demand, :intermediate_supply], #negative flows are reversed
        
        :margin_demand => ByRow(y ->  max(0,y)) => :margin_demand,
        :margin_supply => ByRow(y -> -min(0,y)) => :margin_supply,
        :personal_consumption => ByRow(y -> max(0,y)) => :personal_consumption,
        :household_supply => ByRow(y -> -min(0,y)) => :household_supply,
        ifelse("sector_subsidy" ∈ names(x), 
            [:subsidies, :sector_subsidy] .=> ByRow(y -> -y) .=> [:subsidies, :sector_subsidy], 
            :subsidies => ByRow(y -> -y) => :subsidies
            )
    )  |>
    x -> stack(x, Not(:commodities, :sectors, :year), variable_name = :subtable, value_name = :value) |>
    x -> subset(x, :value => ByRow(!=(0)))


    return NationalTable(summary_data, summary_sets)

end


