module WiNDC


using JuMP
using PATHSolver
using Ipopt
#using Complementarity
using GamsStructure
using CSV 
using XLSX
using DataFrames
using HTTP
using JSON

export national_model_mcp,load_bea_data_api,load_bea_data_local, verify_calibration, generate_report

#,state_dissagregation_model_mcp_year


include("helper_functions.jl")
include("data/notations.jl")
include("data/core/bea_api/bea_api.jl")

include("data/core/PartitionBEA.jl")
include("core/nationalmodel.jl")

include("data/core/bea_gsp/bea_gsp.jl")
include("data/core/bea_pce/bea_pce.jl")
include("data/core/census_sgf/census_sgf.jl")
include("data/core/faf/faf.jl")
include("data/core/usa_trade/usa_trade.jl")



end # module WiNDC
