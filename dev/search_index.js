var documenterSearchIndex = {"docs":
[{"location":"#Introduction","page":"Introduction","title":"Introduction","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Currently only the National model is implemented. In time the plan  is to rewrite the entire WiNDC build stream in Julia. ","category":"page"},{"location":"#Example","page":"Introduction","title":"Example","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Coming soon","category":"page"},{"location":"#Function-Listing","page":"Introduction","title":"Function Listing","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"load_bea_data_api(api_key::String,set_path,data_defines_path)\nload_bea_data_local(use_path::String,\n                             supply_path::String,\n                             set_path::String,\n                             map_path::String)\nnational_model_mcp(GU::GamsUniverse;solver = PATHSolver.Optimizer)","category":"page"},{"location":"#WiNDC.load_bea_data_api-Tuple{String, Any, Any}","page":"Introduction","title":"WiNDC.load_bea_data_api","text":"load_bea_data_api(api_key::String,set_path,data_defines_path)\n\nLoad the the BEA data using the BEA API. \n\nIn order to use this you must have an api key from the BEA. Register here to obtain an key.\n\nCurrently (Septerber 28, 2023) this will only return years 2017-2022 due to the BEA restricting the API. \n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.load_bea_data_local-NTuple{4, String}","page":"Introduction","title":"WiNDC.load_bea_data_local","text":"load_bea_data_local(use_path::String,\n                    supply_path::String,\n                    set_path::String,\n                    map_path::String)\n\nLoad the BEA data from a local XLSX file. This data is available at the WiNDC webpage. The use table is\n\nwindc_2021/BEA/IO/Use_SUT_Framework_1997-2021_SUM.xlsx\n\nand the supply table is\n\nwindc_2021/BEA/IO/Supply_Tables_1997-2021_SUM.xlsx\n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.national_model_mcp-Tuple{GamsUniverse}","page":"Introduction","title":"WiNDC.national_model_mcp","text":"national_model_mcp(GU::GamsUniverse;solver = PATHSolver.Optimizer)\n\nRun all years of the the national model. Returns a dictionary containing each year.\n\n\n\n\n\n","category":"method"}]
}
