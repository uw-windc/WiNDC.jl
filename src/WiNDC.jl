module WiNDC


using JuMP
using Complementarity
using GamsStructure
using CSV 
using XLSX

export national_model_mcp,load_bea_data


include("core/nationalmodel.jl")
include("data/PartitionBEA.jl")

end # module WiNDC
