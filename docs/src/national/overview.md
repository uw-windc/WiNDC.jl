# National Module

The national module has two aggregations available:

* summary
* detailed

The summary aggregation is loaded directly from the summary tables provided by the BEA. The detailed aggregation is an extrapolation of the summary tables using the detailed tables. 

## Build Process

### Download Data

```julia
sut_files = fetch_supply_use()
```

### Detailed Data

```julia
detailed_data = build_national_table(sut_files)

DD, _ = calibrate(detailed_data)
save_table("detailed_data_partial.jld2", DD)
```

### Summary Data

```julia
summary_data = build_national_table(sut_files; aggregation = :summary)

SD,M = calibrate(summary_data)
save_table("summary_data.jld2", SD)
```

### Disaggregated Detailed Data

```julia
summary_map = WiNDC.detailed_summary_map(sut_files[1])

summary_data = load_table("summary_data.jld2")
detailed_data = load_table("detailed_data_partial.jld2")

detailed_yearly = WiNDC.national_disaggragate_summary_to_detailed(detailed_data, summary_data, summary_map)

DD, _ = calibrate(detailed_yearly)

save_table("detailed_data.jld2", DD)
```
