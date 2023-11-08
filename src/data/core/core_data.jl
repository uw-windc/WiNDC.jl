include("./sets/sets.jl")



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