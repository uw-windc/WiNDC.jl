module WiNDC


using DataFrames, CSV, XLSX, FileIO, JuMP, Ipopt, MPSGE

include("structs.jl")

export all_data, domain, WiNDCtable, get_set, get_table, get_subtable

include("national/structs.jl")

export NationalTable

include("national/detailed_data.jl")

export national_tables

include("national/calibrate.jl")

export calibrate

include("national/balance.jl")

export zero_profit, market_clearance, margin_balance

include("national/model.jl")

export national_mpsge


include("state/structs.jl")

export StateTable

include("state/disaggregate.jl")

export disaggregate_national_to_state

include("state/calibrate.jl")


end # module WiNDC
