
# Core Data Sources



As of November 9, 2023, the BEA is restricting their data to be 2017 - Present. 
This is due to the release of the detailed 2017 IO table. They are using the
detailed table to back-update the summary tables. 

## Bureau of Economic Analysis - Summary Input/Output Tables

[Link](https://www.bea.gov/industry/input-output-accounts-data)


## Bureau of Economic Analysis - Gross Domestic Product by State

[Link](https://apps.bea.gov/regional/downloadzip.cfm)

In the `Gross Domestic Product (GDP)`, select the `SAGDP: annual GDP by state` option.

## Bureau of Economic Analysis -- Personal Consumer Expenditures

[Link](https://apps.bea.gov/regional/downloadzip.cfm)

In the `Personal consumption expenditures (PCE) by state`, select the 
`SAPCE: personal consumption expenditures (PCE) by state` option. 

## US Census Bureau - Annual Survey of State Government Finances 

[Link](https://www.census.gov/programs-surveys/state/data/datasets.All.List_75006027.html)

Heavily encoded TXT files.

## Bureau of Transportation Statistics - Freight Analysis Framework

[Link](https://www.bts.gov/faf)

We use two data files, `FAF5.5.1_State.zip` and `FAF5.5.1_Reprocessed_1997-2012_State.zip`

Currently, we are using version 5.5.1.


## US Census Bureau - USA Trade Online 

[Link](https://usatrade.census.gov/)

This requires a log-in. For both `Imports` and `Exports` we want NAICS data. When
selecting data, we want every state (this is different that All States), the most
disaggregated commodities (third level), and for `Exports` we want `World Total`
and `Imports` we want both `World Total` and `Canada` in the Countries column.

There is one more file we use, [Commodity_detail_by_state_cy.xlsx](https://www.ers.usda.gov/webdocs/DataFiles/100812/)
This is probably a fragile link.