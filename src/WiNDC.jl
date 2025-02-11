module WiNDC


using DataFrames, CSV, XLSX, FileIO, JuMP, Ipopt, MPSGE, JLD2

using ZipFile, Downloads

## Generic Code

include("structs.jl")

export domain, WiNDCtable, get_set, get_table, get_subtable

include("io.jl")

export save_table, load_table

include("dataframe_operations.jl")

export subset

include("calibration.jl")

export calibrate

include("api/download.jl")

## National Data

include("national/structs.jl")

export NationalTable

include("national/download.jl")

export fetch_supply_use

include("national/detailed_data.jl")


include("national/load_data.jl")

export build_national_table

include("national/calibrate.jl")

export calibrate

include("national/balance.jl")

export zero_profit, market_clearance, margin_balance

include("national/model.jl")

export national_mpsge

## State Data

include("state/structs.jl")

export StateTable

include("state/disaggregate.jl")

export disaggregate_national_to_state

include("state/calibrate.jl")


end # module WiNDC
