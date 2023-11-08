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

export generate_report

export national_model_mcp,  state_disaggregation_model_mcp_year


#load_bea_data_api, load_bea_data_local, verify_calibration,

#,state_dissagregation_model_mcp_year


include("helper_functions.jl")
include("data/notations.jl")

include("data/core/bea_api/bea_api.jl")

#Models
include("core/nationalmodel.jl")
include("core/state_dissagregation_model.jl")

#Data
include("data/core/bea_io/PartitionBEA.jl")
include("data/core/bea_gsp/bea_gsp.jl")
include("data/core/bea_pce/bea_pce.jl")
include("data/core/census_sgf/census_sgf.jl")
include("data/core/faf/faf.jl")
include("data/core/usa_trade/usa_trade.jl")
include("data/core/state_dissagregation.jl")

include("data/core/core_data.jl")


end # module WiNDC
