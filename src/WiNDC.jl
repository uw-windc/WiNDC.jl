module WiNDC


using JuMP
using PATHSolver
#using Complementarity
using GamsStructure
using CSV 
using XLSX

export national_model_mcp,load_bea_data,state_dissagregation_model_mcp_year


include("core/nationalmodel.jl")
include("data/PartitionBEA.jl")

end # module WiNDC
