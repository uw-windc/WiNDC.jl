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

export national_model_mcp,load_bea_data_api,load_bea_data_local,calibrate_national!

#,state_dissagregation_model_mcp_year


include("core/nationalmodel.jl")
include("data/calibrate.jl")
include("data/PartitionBEA.jl")


end # module WiNDC
