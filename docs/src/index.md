# Introduction

Currently only the National model is implemented. In time the plan 
is to rewrite the entire WiNDC build stream in Julia. 




# Example



# Function Listing

```@docs
load_bea_data_api(api_key::String,set_path,data_defines_path)
load_bea_data_local(use_path::String,
                             supply_path::String,
                             set_path::String,
                             map_path::String)
national_model_mcp(GU::GamsUniverse;solver = PATHSolver.Optimizer)
```