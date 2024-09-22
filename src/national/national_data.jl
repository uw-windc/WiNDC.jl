"""
    adjust_negative_values!(data::DataFrame, df::DataFrame)

Adjusts negative values in a DataFrame by calculating the share of the value of a commodity in a sector and state
relative to the total value of the sector and state. The share is then multiplied by the total value to get the
adjusted value.
"""
adjust_negative_values!(data::DataFrame, df::DataFrame) = 
    outerjoin(
        df |>
            x -> groupby(x, [:sectors, :state]) |>
            x -> combine(x, :value => sum => :total_value),

        df |>
            x -> groupby(x, [:commodities, :sectors, :state]) |>
            x -> combine(x, :value => sum => :commodity_value),

        df |>
            x -> groupby(x, [:year, :sectors, :state]) |>
            x -> combine(x, :value => sum => :va_value),
        on = [:sectors, :state]
    ) |>
    x -> transform(x,
        [:total_value, :commodity_value, :va_value] => ByRow((t,c,v) -> t == 0 ? 0 : (c*v)/t) => :value
    ) |>
    x -> select(x, :commodities, :sectors, :state, :year, :value)  |>
    x -> leftjoin!(data, x, on = [:commodities, :sectors, :state, :year], makeunique=true) |>
    x -> transform!(x,
        [:value, :value_1] => ByRow((v0,v1) -> ismissing(v1) || v0 >0 ? v0 : v1) => :value
    ) |>
    x -> select!(x, Not(:value_1))



function load_raw_national_summary_data(raw_data_directory)

    data_path = "BEA"

    subtables = CSV.read(
        joinpath(raw_data_directory, data_path, "subtables_summary.csv"), 
        DataFrame, 
        stringtype = String
        )

    marginal_goods = ["441", "445", "452"]

    use = __load_full_io_table(
        joinpath(raw_data_directory, data_path, "use_summary.xlsx"),
        "A6:CP90",
        "use",
    ) |>
        x -> subset(x, 
            :commodities => ByRow(∉(marginal_goods)) 
    )
    

    insurance_code = "524"

    supply = __load_full_io_table(
        joinpath(raw_data_directory, data_path, "supply_summary.xlsx"),
        "A6:CG81",
        "supply",
    ) |>
        x -> unstack(x, :sectors, :value) |>
        x -> coalesce.(x, 0) |>
        x -> transform(x, 
                # adjust transport margins for transport sectors according to CIF/FOP 
                # adjustments. Insurance imports are specified as net of adjustments.
            [:commodities, :Trans, :MADJ] => ByRow((c,t,f) -> c==insurance_code ? t : t+f) => :Trans,
            [:commodities, :MCIF, :MADJ] => ByRow((c,i,f) -> c==insurance_code ? i+f : i) => :MCIF,
        ) |>
        x -> select(x, Not(:MADJ)) |>
        x -> stack(x, Not(:commodities, :state, :year,:table), variable_name = :sectors, value_name = :value) |>
        x -> subset(x, :value => ByRow(!=(0))) |>
        x -> select(x, :commodities, :sectors, :state, :year, :table, :value)

    sets = CSV.read(
        joinpath(raw_data_directory, data_path, "sets_summary.csv"), 
        DataFrame, 
        stringtype = String
        )




    df = vcat(use, supply) |> 
            x -> innerjoin(x, subtables, on = [:commodities, :sectors, :table]) |>
            x -> select(x, :commodities, :sectors, :state, :year, :datatype, :value) |>
            x -> unstack(x, :datatype, :value) |>
            x -> coalesce.(x, 0) |>
            x -> transform(x,
                [:intermediate_demand, :intermediate_supply] => ByRow(
                    (d,s) -> (max(0, d - min(0, s)), max(0, s - min(0, d)))) => [:intermediate_demand, :intermediate_supply], #negative flows are reversed
                :subsidies => ByRow(y -> -y) => :subsidies,
                :margin_demand => ByRow(y ->  max(0,y)) => :margin_demand,
                :margin_supply => ByRow(y -> -min(0,y)) => :margin_supply
            ) |>
            x -> stack(x, Not(:commodities, :sectors, :state, :year), variable_name = :datatype, value_name = :value) |>
            x -> subset(x, :value => ByRow(!=(0))) |>
            x -> select(x, :commodities, :sectors, :state, :year, :datatype, :value) |>
            x -> adjust_negative_values!(x, subset(x, :datatype => ByRow(==("value_added")))) |>
            x -> adjust_negative_values!(x, subset(x, :sectors => ByRow(==("MCIF")))) #|>
            x -> subset(x, 
                :commodities => ByRow(∉(marginal_goods)) 
        )

    return WiNDCtable(df, [:commodities, :sectors, :state, :year], sets)

end


function __load_full_io_table(
    data_path, 
    data_range,
    table_name; 
    sheets_to_ignore = []
    )

    X = XLSX.readxlsx(data_path)

    df = DataFrame()
    for sheet in [f for f∈XLSX.sheetnames(X) if f∉sheets_to_ignore]
    year_df = __load_year_io_table(
                    X, 
                    sheet, 
                    data_range;
                    scale = 1000,
                    replace_missing = true,
                    data_start_row = 3)

    df = vcat(df, year_df)
    end

    df[!,:table] .= table_name

    return df

end


function __load_year_io_table(
    X::XLSX.XLSXFile, 
    year, 
    range; 
    scale = 1_000, 
    replace_missing = false, 
    data_start_row = 2
    )

    U = X[year][range]

    U[1,1] = :commodities
    U[1,2] = :drop

    if replace_missing
    U[U.=="..."] .= missing
    end

    int_year = parse(Int, year)

    #end = size(U,1)

    return DataFrame(U[data_start_row:end,1:end], string.(U[1,:])) |>
                x -> select(x, Not(:drop)) |>
                x -> stack(x, Not("commodities"), variable_name = :sectors) |>
                x -> dropmissing(x) |>
                x -> subset(x,
                    :value => ByRow(!=(0))
                ) |>
                x -> transform(x,
                    :value => (y -> y/scale) => :value,
                    [:commodities,:sectors] .=> ByRow(string) .=> [:commodities,:sectors],
                    :commodities => ByRow(y -> "national") => :state,
                    :commodities => ByRow(y -> int_year) => :year
                )
end