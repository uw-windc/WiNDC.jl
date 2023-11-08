# Introduction

Currently the entire Core module is implemented. This includes:

* Building the WiNDC database from raw-data
* The national model
* The state-level disaggregation. 



# Example
This data is hosted on the [WiNDC website](https://windc.wisc.edu/downloads/version_4_0/windc_2021_julia.zip).

## State Level Disaggregation
Code to run the state-level disaggregation and model. Currently,
this is set up to run the the counter-factual calculation where
import tariffs are zero. 

We are currently implementing a method to modify inputs and run
different shocks. 
```
using WiNDC
using JuMP

using GamsStructure
using DataFrames

data_dir = "path/to/data"

GU = WiNDC.load_state_data(data_dir)

year = Symbol(2017)

m = state_dissagregation_model_mcp_year(GU,year)

# Fix an income level to normalize prices in the MCP model 
fix(m[:RA][:CA],GU[:c0_][[year],[:CA]],force=true)

set_attribute(m, "cumulative_iteration_limit", 10_000)

optimize!(m)
```




## API Version
The API version is under development. It is being worked on and
will be available in early 2024.


# Function Listing

```@docs
national_model_mcp(GU::GamsUniverse;solver = PATHSolver.Optimizer)
```