module WiNDC


using DataFrames, CSV, XLSX, FileIO, JuMP, Ipopt#, MPSGE

include("structs.jl")

export all_data, domain, WiNDCtable, get_set, get_table, get_subtable

include("national/structs.jl")

export NationalTable

include("national/detailed_data.jl")

export create_national_detailed_sets, create_national_detailed_subtables

include("national/calibrate.jl")

export calibrate

include("national/balance.jl")

export zero_profit, market_clearance, margin_balance


end # module WiNDC
