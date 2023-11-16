module WiNDC


using JuMP
using PATHSolver
using Ipopt
using GamsStructure
using CSV 
using XLSX
using DataFrames
using HTTP
using JSON
using MPSGE

export generate_report

export national_model_mcp, national_model_mcp_year,  
       state_disaggregation_model_mcp,state_disaggregation_model_mcp_year

export load_national_data,load_state_data



include("helper_functions.jl")
include("data/notations.jl")



include("data/core/bea_api/bea_api.jl")

#Models
include("core/nationalmodel.jl")
include("core/state_disaggregation_model.jl")

#Data
include("data/core/core_data_defines.jl")
include("data/core/bea_io/PartitionBEA.jl")
include("data/core/bea_gsp/bea_gsp.jl")
include("data/core/bea_pce/bea_pce.jl")
include("data/core/census_sgf/census_sgf.jl")
include("data/core/faf/faf.jl")
include("data/core/usa_trade/usa_trade.jl")
include("data/core/state_disaggregation.jl")

include("data/core/core_data.jl")


end # module WiNDC
