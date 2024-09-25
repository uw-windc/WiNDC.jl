abstract type WiNDCtable end;

domain(data::WiNDCtable) = throw(ArgumentError("domain not implemented for WiNDCtable"))

function _extract_and_filter(base_table::DataFrame, filter::Vector{Pair{Symbol, T}}) where {T<:Any}
    X = base_table
    for (key, value) in filter
        #@assert key∈domain(X) "Error: $key not in domain of table"
        X = subset(X, key => ByRow(==(value)))
    end
    return X
end

extract_set(data::WiNDCtable, set_name::String) = 
    _extract_and_filter(data.sets, [:datatype => set_name]) #|> x -> select(x, Not(:datatype))


"""
    all_data(data::WiNDCtable; filter::Vector{Pair{Symbol, T}} = Vector{Pair{Symbol,Any}}()) where {T<:Any}

Return the raw DataFrame of the given table.

The `filter` keyword argument can be used to filter the data by column values. For example, to filter
the data to only include rows where the `year` column is equal to 2022, use `filter = [:year => 2022]`.
This may change to a dictionary in the future.
"""
all_data(data::WiNDCtable; filter::Vector{Pair{Symbol, T}} = Vector{Pair{Symbol,Any}}()) where {T<:Any} = 
    _extract_and_filter(data.table, filter)


#################
## Base Tables ##
#################

intermediate_demand(
    io::WiNDCtable;
    filter::Vector{Pair{Symbol, T}} = Vector{Pair{Symbol,Any}}(),
    column = :value,
    output = :value
    ) where {T<:Any} = 
        all_data(io; filter = [:datatype => "intermediate_demand", filter...]) |>
            x -> rename(x, column => output)

value_added(
    io::WiNDCtable;
    filter::Vector{Pair{Symbol, T}} = Vector{Pair{Symbol,Any}}(),
    column = :value,
    output = :value
    ) where {T<:Any} = 
        all_data(io; filter = [:datatype => "value_added", filter...]) |>
            x -> rename(x, column => output)

final_demand(
    io::WiNDCtable;
    filter::Vector{Pair{Symbol, T}} = Vector{Pair{Symbol,Any}}(),
    column = :value,
    output = :value
    ) where {T<:Any} = 
        all_data(io; filter = [:datatype => "final_demand", filter...]) |>
            x -> rename(x, column => output)

intermediate_supply(
    io::WiNDCtable;
    filter::Vector{Pair{Symbol, T}} = Vector{Pair{Symbol,Any}}(),
    column = :value,
    output = :value
    ) where {T<:Any} = 
        all_data(io; filter = [:datatype => "intermediate_supply", filter...]) |>
            x -> rename(x, column => output)

supply_extras(
    io::WiNDCtable;
    filter::Vector{Pair{Symbol, T}} = Vector{Pair{Symbol,Any}}(),
    column = :value,
    output = :value
    ) = 
        all_data(io, filter = [:datatype => "supply_extras", filter...]) |> 
            x -> rename(x, column => output)

######################
## Aggregate Tables ##
######################

household_supply(data::WiNDCtable; column = :value, output = :value) = 
    final_demand(data) |>
        x -> subset(x,
            :sectors => ByRow(==("F010")) # personal_consumption_code = "F010"
        ) |>
        x -> transform(x,
            [:value,column] => ByRow((v,y) -> v>0 ? 0 : -y) => output
        ) |>
        x -> select(x, [:commodities, :state, :year, output])


gross_output(data::WiNDCtable; column = :value, output = :value) =
    outerjoin(
        intermediate_supply(data) |>
            x -> groupby(x, [:commodities,:state,:year]) |>
            x -> combine(x, column => sum => :is),

        household_supply(data; column = column, output = :hs) |>
            x -> select(x, :commodities, :state, :year, :hs),

        margin_supply(data; column = column, output = :ms) |>
            x -> groupby(x, [:commodities,:state,:year]) |>
            x -> combine(x, :ms => sum => :ms),
        on = [:commodities,:state,:year]
    ) |>
    x -> coalesce.(x, 0) |>
    x -> transform(x, 
        [:is, :hs, :ms] => ByRow((i,h,m) -> i+h-m) => output
    ) |>
    x -> select(x, :commodities, :state, :year, output)


armington_supply(data::WiNDCtable; column = :value, output = :value) = 
    outerjoin(
        intermediate_demand(data) |>
            x -> select(x, Not(:datatype)) |>
            x -> groupby(x, [:commodities, :state, :year]) |>
            x -> combine(x, column => sum => :id),

        final_demand(data) |>
            x -> select(x, Not(:datatype)) |>
            x -> groupby(x, [:commodities, :state, :year]) |>
            x -> combine(x, column => sum => :fd),
        on = [:commodities, :state, :year]
    )|>
    x -> coalesce.(x, 0) |>
    x -> transform(x, 
        [:id, :fd] => ByRow((i,f) -> i+f) => output
    ) |>
    x -> select(x, :commodities, :state, :year, output)

margin_supply(data::WiNDCtable; column = :value, output = :value) = 
    supply_extras(data; columns = ["margin_supply"]) |>
        x -> select(x, Not(:datatype)) |>
        x -> rename(x, column => output) |>
        x -> select(x, [:commodities, :sectors, :state, :year, output])

margin_demand(data::WiNDCtable; column = :value, output = :value) = 
    supply_extras(data; columns = ["margin_demand"]) |>
        x -> select(x, Not(:datatype)) |>
        x -> rename(x, column => output) |>
        x -> select(x, [:commodities, :sectors, :state, :year, output])


import_tariff(data::WiNDCtable; column = :value, output = :value) = 
    supply_extras(data; columns = ["duty"]) |>
        x -> select(x, [:commodities, :datatype, :state, :year, column]) |>
        x -> rename(x, column => output)
        
import_tariff_rate(data::WiNDCtable; column = :value, output = :value) = 
    supply_extras(data; columns = ["duty", "imports"]) |>
        x -> select(x, [:commodities, :datatype, :state, :year, column]) |>
        x -> unstack(x, :datatype, column) |>
        x -> coalesce.(x, 0) |>
        x -> transform(x, 
            [:imports, :duty] => ByRow((i,d) -> i == 0 ? 0 : d/i) => output
        ) |>
        x -> select(x, Not(:imports, :duty)) |>
        x -> subset(x, output => ByRow(!=(0)))

absorption_tax(data::WiNDCtable; column = :value, output = :value) = 
    supply_extras(data; columns = ["tax","subsidies"]) |>
        x -> select(x, :commodities, :datatype, :state, :year, column) |>
        x -> unstack(x, :datatype, column) |>
        x -> coalesce.(x, 0) |>
        x -> transform(x,
            [:tax, :subsidies] => ByRow((t,s) -> t-s) => output
        ) |>
        x -> select(x, Not(:tax, :subsidies))

absorption_tax_rate(data::WiNDCtable; column = :value, output = :value) =     
    outerjoin(
        absorption_tax(data; column = column, output = :total_tax),
        armington_supply(data; column = column, output = :arm_sup),
        on = [:commodities, :state, :year]
    )|>
    x -> coalesce.(x, 0) |>
    x -> transform(x,
        [:arm_sup, :total_tax] => ByRow((v,t) -> v == 0 ? 0 : t/v) => output
    ) |>
    x -> select(x, Not(:total_tax, :arm_sup)) |>
    x -> subset(x, output => ByRow(!=(0)))


output_tax(data::WiNDCtable; column = :value, output = :value) = 
    all_data(data; filter = [:datatype => "other_tax"]) |>
        x -> select(x, [:sectors, :state, :year, column]) |>
        x -> rename(x, column => output)

output_tax_rate(data::WiNDCtable; column = :value, output = :value) = 
    outerjoin(
        intermediate_supply(data) |>
            x -> select(x, Not(:datatype)) |>
            x -> groupby(x, [:sectors, :state, :year]) |>
            x -> combine(x, :value => sum => :is),

        all_data(data; filter = [:commodities => "T00OTOP"]) |>
            x -> select(x, [:sectors, :state, :year, column]),
        on = [:sectors, :state, :year]
    )|>
    
    x -> coalesce.(x, 0) |>
    x -> transform(x, 
        [column, :is] => ByRow((v, i) -> i == 0 ? 0 : v/i) => output
    ) |>
    x -> select(x, [:sectors, :state, :year, output]) |>
    x -> subset(x, output => ByRow(>(0)))



exports(data::WiNDCtable; column = :value, output=:value, return_cols = [output]) = 
    all_data(data) |>
        x -> subset(x,
            :datatype => ByRow(==("exports"))
        ) |>
        x -> rename(x, column => output) |>
        x -> select(x, [:commodities, :state, :year, return_cols...])

imports(data::WiNDCtable; column = :value, output = :value, return_cols = [output]) = 
    supply_extras(data, columns = ["imports"]) |>
        x -> rename(x, column => output) |>
        x -> select(x, [:commodities, :state, :year, return_cols...])


balance_of_payments(data::WiNDCtable; column = :value, output = :value) = 
    outerjoin(
        imports(data; column = column, output = :im),
        exports(data; column = column, output = :ex),
        armington_supply(data; column = column, output = :as),
        on = [:commodities, :state, :year]
    ) |>
    x -> coalesce.(x,0) |>
    x -> transform(x,
        [:im, :ex, :as] => ByRow((im, ex, a) -> a!= 0 ? im - ex : 0) => output
    ) |>
    x -> groupby(x, [:state, :year]) |>
    x -> combine(x, output => sum => output)