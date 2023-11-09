include("./sets/sets.jl")

"""
    load_national_data(data_dir)

Load and balance the national BEA Input/Output summary tables. 

To Do:

1. Verify calibration 
2. Add option to run MCP model to ensure calibration
"""
function load_national_data(data_dir)

    J = JSON.parsefile("$data_dir\\data_information.json")

    core_dir = joinpath(data_dir,"core")
    
    core_info = J["core"]

    GU = WiNDC.initialize_sets();
    WiNDC.load_bea_io!(GU,core_dir,core_info["bea_io"]);

    return GU
end


"""
    load_state_data(data_dir)

Disaggregate the national dataset to the state level. This will
check that the resulting dataset is balanced.

To Do:

1. Add option to run MCP model to ensure calibration
"""
function load_state_data(data_dir)

    J = JSON.parsefile("$data_dir\\data_information.json")

    core_dir = joinpath(data_dir,"core")
    
    core_info = J["core"]

    GU = WiNDC.initialize_sets();
    WiNDC.load_bea_io!(GU,core_dir,core_info["bea_io"]);
    WiNDC.load_bea_gsp!(GU,core_dir,core_info["bea_gsp"]);
    WiNDC.load_bea_pce!(GU,core_dir,core_info["bea_pce"]);
    WiNDC.load_sgf_data!(GU,core_dir,core_info["census_sgf"]);
    WiNDC.load_faf_data!(GU,core_dir,core_info["faf"])
    WiNDC.load_usa_trade!(GU,core_dir,core_info["usatrd"])

    GU = state_dissagregation(GU)

    return GU
end