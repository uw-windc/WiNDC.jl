# Introduction

Currently only the National model is implemented. In time the plan 
is to rewrite the entire WiNDC build stream in Julia. 




# Example

## API Version
Currently (Sept 28, 2023) the API only gives data for years
2017 - 2022. 

In order to use this you must have an api key from the 
BEA. [Register here](https://apps.bea.gov/api/signup/)
to obtain an key.
```
using WiNDC
using GamsStructure

api_key = #paste API key here
GU = load_bea_data_api(api_key;years = 1997:2021);


models = national_model_mcp(GU)
```

## Local Version
This data is hosted on the [WiNDC website](https://windc.wisc.edu/data_stream.html).
Download and extract the zip file `windc_2021.zip`. The tables
are located in the directory: 

`BEA/IO`

```
using WiNDC
using GamsStructure

GU = load_bea_data_local("path_to_use_table",
                         "path_to_supply_table",
);


models = national_model_mcp(GU)
```

## Accessing Models

```
m = models[1997]

print(generate_report(m))
```

# Function Listing

```@docs
load_bea_data_api(api_key::String;year=1997:2021)
load_bea_data_local(use_path::String,
                             supply_path::String;
                             year=1997;2021)
national_model_mcp(GU::GamsUniverse;solver = PATHSolver.Optimizer)
```