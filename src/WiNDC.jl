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

include("data/PartitionBEA.jl")
include("core/nationalmodel.jl")



end # module WiNDC