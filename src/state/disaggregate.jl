function load_single_sagdp_data_file(data_path, file, name)
    return CSV.read(
        joinpath(data_path, file), 
        DataFrame, 
        footerskip = 4,
        types = Dict(:GeoFIPS => String),
        missingstring = [
            "(NA)", #Not Available
            "(D)", #Not shown to avoid disclosure of confidential information; estimates are included in higher-level totals.
            "(NM)", #Not Meaningful
            "(L)", #Below $50,000
            "(T)", #The estimate is suppressed to cover corresponding estimate for earnings in state personal income. Estimates for this item are included in the total.
        ]
    ) |>
    x -> select(x, Not(:GeoName, :Region, :TableName, :IndustryClassification)) |> #, :Description
    x -> stack(x, Not(:GeoFIPS, :LineCode, :Unit, :Description), variable_name = :year, value_name = :value) |>
    x -> dropmissing(x) |>
    x -> transform(x, 
        :year => ByRow(x -> parse(Int, x)) => :year,
        :LineCode => ByRow(y -> name) => :table,
        :value => ByRow(y -> isa(y,AbstractString) ? parse(Float64, y) : y) => :value
    ) |>
    x -> transform(x,
        [:Unit, :value] => ByRow((x,y) -> x == "Thousands of dollars" ? ("Millions of current dollars", y / 1_000) : (x,y)) => [:Unit,:value]
    ) |>
    x -> select(x, Not(:Unit))
end


function load_raw_sagdp_data(data_path, files)
    tables = []
    for (file, name) in files
        push!(tables, load_single_sagdp_data_file(data_path, file, name))
    end

    return vcat(tables...)
end


function load_industry_codes(
        data_path, 
        summary_map; 
        file_name = "industry_codes.csv",
        aggregation = :detailed
        )
    
    
    df = CSV.read(
        joinpath(data_path, file_name),
        DataFrame
    ) |>
    x -> select(x, :LineCode, :naics) |>
    x -> dropmissing(x) 
    
    
    if aggregation == :detailed 
        df = df|>
            x -> leftjoin(
                x,
                summary_map,
                on = :naics => :summary
            ) |>
            x -> select(x, Not(:naics)) |>
            x -> rename(x, :detailed => :naics)
    end

    return df
end


function load_state_fips(data_path; file_name = "state_fips.csv")
    return CSV.read(
        joinpath(data_path, file_name), 
        DataFrame,
        types = String
    ) 
end


function load_sagdp_data(
    data_path::String,
    files::Vector{Tuple{String,String}},
    summary_map;
    industry_codes = "industry_codes.csv",
    state_fips = "state_fips.csv",
    aggregation = :detailed
)

    raw_sagdp = load_raw_sagdp_data(data_path, files)

    state_fips = load_state_fips(data_path; file_name = state_fips)
    industry_codes = load_industry_codes(
            data_path, 
            summary_map; 
            file_name = industry_codes, 
            aggregation = aggregation
            )

    return innerjoin(
        raw_sagdp,
        state_fips,
        on = :GeoFIPS => :fips
    ) |>
    x -> select(x, Not(:GeoFIPS)) |>
    x -> innerjoin(
        x,
        industry_codes,
        on = :LineCode,
        makeunique = true
    ) |>
    x -> select(x, :naics, :state, :year, :table, :value) |>
    x -> subset(x, :value => ByRow(x -> x != 0)) 

end




### What do we do with the naics codes that are missing? They'll be missing states too
### What I did was equal shares over the states. Seems fair. 
### 
### This works! And it matches the old data. So that's cool.
#### Subtables to disaggregate 
# "other_tax" - gdp



#### Subtables Done Satisfactorily
# "intermediate_demand" - gdp
# "intermediate_supply" - gdp
# "tax"                 - tax 
# "subsidies"           - subsidies 
# "labor_demand"        - compensation
# "capital_demand"      - surplus


#### Subtables done, but could be better
# "personal_consumption"   - gdp
# "household_supply"       - gdp
# "exogenous_final_demand" - gdp
# "exports"                - gdp
# "imports"                - gdp
# "margin_demand"          - gdp
# "margin_supply"          - gdp
# "duty"                   - gdp
# "other_tax"              - gdp

"""
    disaggregate_national_to_state(
        data::NationalTable,
        data_path::String,
        files::Vector{Tuple{String,String}},
        summary_map;
        industry_codes = "industry_codes.csv",
        state_fips = "state_fips.csv",
        aggregation = :detailed
    )

This function disaggregates the national data to the state level. It takes in 
the national data, the path to the state data, the files that contain the state 
data, a summary map that maps the national data to the state data, and the 
industry codes. It returns a StateTable.

"""
function disaggregate_national_to_state(
    data::NationalTable,
    data_path::String,
    files::Vector{Tuple{String,String}},
    summary_map;
    industry_codes = "industry_codes.csv",
    state_fips = "state_fips.csv",
    aggregation = :detailed
)

    

    sagdp = load_sagdp_data(
        data_path, 
        files,
        summary_map;
        industry_codes = industry_codes,
        state_fips = state_fips,
        aggregation = aggregation
    )

    state_fips = load_state_fips(data_path; file_name = state_fips)

    state_level = innerjoin(
        get_table(data),
        crossjoin(
            get_set(data, ["commodities", "labor_demand", "capital_demand","other_tax"]) |>
                x -> select(x, :element),
            state_fips |>
                x -> select(x, :state),
        ),
        on = :commodities => :element
        )  


    intermediate = leftjoin(
        state_level |>
            x -> subset(x, 
                :subtable => ByRow(x -> in(x, [
                    "intermediate_demand",
                    "intermediate_supply",
                    "personal_consumption",
                    "household_supply",
                    "exogenous_final_demand",
                    "exports",
                    "imports",
                    "margin_demand",
                    "margin_supply",
                    "duty",
                    ])),
            ),
        sagdp |>
            x -> subset(x, 
                :table => ByRow(x -> x == "gdp"),
                :year => ByRow(x -> x<2023)
            ),
        on = [:commodities => :naics, :year, :state],
        renamecols = "" => "_gdp"
    ) |>
    x -> rename(x, :value_gdp => :gdp) |>
    x -> select(x, Not(:table_gdp)) |>
    x -> coalesce.(x,1) |>
    x -> groupby(x, [:commodities, :sectors, :year, :subtable]) |>
    x -> combine(x,
        :state .=> identity .=> :state,
        [:value, :gdp] => ((v,g) -> g.*v./sum(g)) => :value
    ) |>
    x -> subset(x, :value => ByRow(x -> x != 0))

    subsidies = leftjoin(
        state_level |>
            x -> subset(x,
                :subtable => ByRow(==("subsidies"))
            ),
        sagdp |>
            x -> subset(x, 
                :table => ByRow(==("subsidies"))
            ) |>
            x -> transform(x, :value => ByRow(x -> -x) => :sub) |>
            x -> select(x, Not(:value)),
        on = [:commodities => :naics, :year, :state],
    ) |>
    x -> coalesce.(x,1) |>
    x -> groupby(x, [:commodities, :sectors, :year, :subtable]) |>
    x -> combine(x,
        :state .=> identity .=> :state,
        [:value, :sub] => ((v,g) -> g.*v./sum(g)) => :value
    ) |>
    x -> subset(x, :value => ByRow(x -> abs(x) > 1e-5))|>
    x -> sort(x, :value)

        
    taxes = leftjoin(
        state_level |>
            x -> subset(x,
                :subtable => ByRow(==("tax"))
            ),
        sagdp |>
            x -> subset(x, 
                :table => ByRow(==("tax"))
            ) |>
            x -> rename(x, :value => :tax),
        on = [:commodities => :naics, :year, :state],
    ) |>
    x -> coalesce.(x,1) |>
    x -> groupby(x, [:commodities, :sectors, :year, :subtable]) |>
    x -> combine(x,
        :state .=> identity .=> :state,
        [:value, :tax] => ((v,g) -> g.*v./sum(g)) => :value
    ) |>
    x -> subset(x, :value => ByRow(x -> abs(x) > 1e-5))



    capital_demand = leftjoin(
        state_level |>
            x -> subset(x,
                :subtable => ByRow(==("capital_demand"))
            ),
        sagdp |>
            x -> subset(x, 
                :table => ByRow(==("surplus"))
            ) |>
            x -> rename(x, :value => :surplus),
        on = [:sectors => :naics, :year, :state],
    ) |>
    x -> coalesce.(x,1) |>
    x -> groupby(x, [:commodities, :sectors, :year, :subtable]) |>
    x -> combine(x,
        :state .=> identity .=> :state,
        [:value, :surplus] => ((v,g) -> g.*v./sum(g)) => :value
    ) |>
    x -> subset(x, :value => ByRow(x -> abs(x) > 1e-5))

    labor_demand = leftjoin(
        state_level |>
            x -> subset(x,
                :subtable => ByRow(==("labor_demand"))
            ),
        sagdp |>
            x -> subset(x, 
                :table => ByRow(==("compensation"))
            ) |>
            x -> rename(x, :value => :compensation),
        on = [:sectors => :naics, :year, :state],
    ) |>
    x -> coalesce.(x,1) |>
    x -> groupby(x, [:commodities, :sectors, :year, :subtable]) |>
    x -> combine(x,
        :state .=> identity .=> :state,
        [:value, :compensation] => ((v,g) -> g.*v./sum(g)) => :value
    ) |>
    x -> subset(x, :value => ByRow(x -> abs(x) > 1e-5))


    other_tax = leftjoin(
        state_level |>
            x -> subset(x,
                :subtable => ByRow(==("other_tax"))
            ),
        sagdp |>
            x -> subset(x, 
                :table => ByRow(==("gdp"))
            ) |>
            x -> rename(x, :value => :tax),
        on = [:sectors => :naics, :year, :state],
    ) |>
    x -> coalesce.(x,1) |>
    x -> groupby(x, [:commodities, :sectors, :year, :subtable]) |>
    x -> combine(x,
        :state .=> identity .=> :state,
        [:value, :tax] => ((v,g) -> g.*v./sum(g)) => :value
    ) |>
    x -> subset(x, :value => ByRow(x -> abs(x) > 1e-5))


    return StateTable(
        vcat(intermediate, taxes, subsidies, capital_demand, labor_demand, other_tax),
        data.sets
    )
end
