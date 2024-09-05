module WiNDC


using DataFrames, CSV, XLSX, FileIO, JuMP, Ipopt#, MPSGE

include("structs.jl")

export all_data, domain, WiNDCtable, extract_set

include("national/national_data.jl")

export load_raw_national_summary_data

include("national/calibrate.jl")

export calibrate

include("national/balance.jl")

export zero_profit, market_clearance, margin_balance

end # module WiNDC
