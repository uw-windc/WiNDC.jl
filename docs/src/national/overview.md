# National Module

The national module has two aggregations available:

* summary
* detailed

The summary aggregation is loaded directly from the summary tables provided by the BEA. The detailed aggregation is an extrapolation of the summary tables using the detailed tables. 

## Build
### Download Data
The following code will download the necessary data from the BEA website. It only needs to be run once.

```julia
sut_files = fetch_supply_use()
```

Subsequent runs can pull the file names from the directory.

```julia
data_path = "data/national"
sut_files = joinpath.(pwd(), data_path, readdir(data_path))
```



### Summary Data

The following code will build the summary-level tables, calibrate, save them to a file, load a specific year, and run a model. Assumes the data has been downloaded.

```julia
using WiNDC, MPSGE

data_path = "data/national"
sut_files = joinpath.(pwd(), data_path, readdir(data_path))

summary_data = build_national_table(sut_files; aggregation = :summary)

SD,M = calibrate(summary_data; lower_bound = .5, upper_bound = 1.5)
save_table("summary_data.jld2", SD)

year = 2023
summary_year = load_table("summary_data.jld2", year)

# Initialize the model and solve a benchmark
M = national_mpsge(summary_year);
solve!(M, cumulative_iteration_limit=0)

# Set a counterfactual, in this case `Output_tax` to 10%
set_value!.(M[:Output_tax], .1)

solve!(M)

generate_report(M)
```


### Detailed Data

```julia
using WiNDC, MPSGE

sut_files = fetch_supply_use()

data_path = "data/national"
sut_files = joinpath.(pwd(), data_path, readdir(data_path))

detail_data = build_national_table(sut_files)

SD,M = calibrate(detail_data; lower_bound = .5, upper_bound = 1.5)
save_table("detailed_data_partial.jld2", SD)


detail_year = load_table("detailed_data_partial.jld2", 2017)

M = national_mpsge(detail_year);

solve!(M, cumulative_iteration_limit=0)

set_value!.(M[:Output_tax], .1)

solve!(M)

generate_report(M)
```

### Disaggregated Detailed Data
This assumes both the summary and detailed data have been built and saved.

```julia
using WiNDC, MPSGE

#sut_files = fetch_supply_use()

data_path = "data/national"
sut_files = joinpath.(pwd(), data_path, readdir(data_path))

summary_data = load_table("summary_data.jld2")
detailed_partial = load_table("detailed_data_partial.jld2")
summary_map = WiNDC.detailed_summary_map(sut_files[1])

detailed_yearly = WiNDC.national_disaggragate_summary_to_detailed(detailed_partial, summary_data, summary_map)

DD, _ = calibrate(detailed_yearly; lower_bound = .01, upper_bound = 100)

save_table("detailed_data.jld2", DD)


detail_year = load_table("detailed_data_partial.jld2", 2017)

M = national_mpsge(detail_year);

solve!(M, cumulative_iteration_limit=0)

set_value!.(M[:Output_tax], .1)

solve!(M)

generate_report(M)
```
