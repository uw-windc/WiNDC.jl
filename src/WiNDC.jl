module WiNDC


using JuMP
using Complementarity
using GamsStructure
using CSV 
using XLSX

export national_model_mcp


include("core/nationalmodel.jl")


end # module WiNDC
