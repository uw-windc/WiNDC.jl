# [National Dataset](@id core_national_dataset)

## Sets 

|Set Name | Description |
|---|---|
|[yr](@ref core_national_years) | Years in dataset|
|[i,j](@ref core_national_sectors) | BEA Goods and sectors categories|
|[va](@ref core_national_va)| BEA Value added categories|
|[fd](@ref core_national_fd) | BEA Final demand categories|
|[ts](@ref core_national_ts) | BEA Taxes and subsidies categories|
|[m](@ref core_national_margins) | Margins|

## Parameters

|Parameter Name| Domain | Description |
|---|---|---|
|id0 |yr, i, j | Intermediate Demand|
|ys0 |yr, j, i | Intermediate Supply|
|fd0 |yr, i, fd | Final Demand|
|va0 |yr, va, j | Value Added|
|md0 |yr, m, i | Margin Demand|
|s0 |yr, j | Aggregate Supply|
|m0 |yr, i | Imports|
|trn0 |yr, i | Transportation Costs|
|tm0 |yr, i | Tax net subsidy rate on intermediate demand|
|ta0 |yr, i | Import Tariff|
|othtax |yr, j | Other taxes|
|y0 |yr, i | Gross Output|
|mrg0 |yr, i | Trade Margins|
|bopdef0 |yr | |
|x0 |yr, i | Exports|
|tax0 |yr, i | Taxes on Products|
|ms0 |yr, i, m | Margin Supply|
|duty0 |yr, i | Import Duties|
|fs0 |yr, i | Household Supply|
|ts0 |yr, ts, j | Taxes and Subsidies|
|cif0 |yr, i | |
|sbd0 |yr, i | Subsidies|
|a0 |yr, i | Armington Supply|
|ty0 |yr, j | Output tax rate|


# Set Listing

## [Years in WiNDC Database](@id core_national_years)


|yr| |yr|
|---|---|---|
|1997| |2010|
|1998| |2011|
|1999| |2011|
|2000| |2012|
|2001| |2013|
|2002| |2014|
|2003| |2015|
|2004| |2016|
|2005| |2017|
|2006| |2018|
|2007| |2019|
|2008| |2020| 
|2009| |2021|

## [BEA Goods and sectors categories & Commodities employed in margin supply](@id core_national_sectors)

| i, j  | Description                                                                           |
|:------|:--------------------------------------------------------------------------------------|
| agr   | Farms (111-112)                                                                       |
| fof   | Forestry, fishing, and related activities (113-115)                                   |
| oil   | Oil and gas extraction (211)                                                          |
| min   | Mining, except oil and gas (212)                                                      |
| smn   | Support activities for mining (213)                                                   |
| uti   | Utilities (22)                                                                        |
| con   | Construction (23)                                                                     |
| wpd   | Wood products manufacturing (321)                                                     |
| nmp   | Nonmetallic mineral products manufacturing (327)                                      |
| pmt   | Primary metals manufacturing (331)                                                    |
| fmt   | Fabricated metal products (332)                                                       |
| mch   | Machinery manufacturing (333)                                                         |
| cep   | Computer and electronic products manufacturing (334)                                  |
| eec   | Electrical equipment, appliance, and components manufacturing (335)                   |
| mot   | Motor vehicles, bodies and trailers, and parts manufacturing (3361-3363)              |
| ote   | Other transportation equipment manufacturing (3364-3366, 3369)                        |
| fpd   | Furniture and related products manufacturing (337)                                    |
| mmf   | Miscellaneous manufacturing (339)                                                     |
| fbp   | Food and beverage and tobacco products manufacturing (311-312)                        |
| tex   | Textile mills and textile product mills (313-314)                                     |
| alt   | Apparel and leather and allied products manufacturing (315-316)                       |
| ppd   | Paper products manufacturing (322)                                                    |
| pri   | Printing and related support activities (323)                                         |
| pet   | Petroleum and coal products manufacturing (324)                                       |
| che   | Chemical products manufacturing (325)                                                 |
| pla   | Plastics and rubber products manufacturing (326)                                      |
| wht   | Wholesale trade (42)                                                                  |
| mvt   | Motor vehicle and parts dealers (441)                                                 |
| fbt   | Food and beverage stores (445)                                                        |
| gmt   | General merchandise stores (452)                                                      |
| ott   | Other retail (4A0)                                                                    |
| air   | Air transportation (481)                                                              |
| trn   | Rail transportation (482)                                                             |
| wtt   | Water transportation (483)                                                            |
| trk   | Truck transportation (484)                                                            |
| grd   | Transit and ground passenger transportation (485)                                     |
| pip   | Pipeline transportation (486)                                                         |
| otr   | Other transportation and support activities (487-488, 492)                            |
| wrh   | Warehousing and storage (493)                                                         |
| pub   | Publishing industries, except Internet (includes software) (511)                      |
| mov   | Motion picture and sound recording industries (512)                                   |
| brd   | Broadcasting and telecommunications (515, 517)                                        |
| dat   | Data processing, internet publishing, and other information services (518, 519)       |
| bnk   | Federal Reserve banks, credit intermediation, and related services (521-522)          |
| sec   | Securities, commodity contracts, and investments (523)                                |
| ins   | Insurance carriers and related activities (524)                                       |
| fin   | Funds, trusts, and other financial vehicles (525)                                     |
| hou   | Housing (HS)                                                                          |
| ore   | Other real estate (ORE)                                                               |
| rnt   | Rental and leasing services and lessors of intangible assets (532-533)                |
| leg   | Legal services (5411)                                                                 |
| com   | Computer systems design and related services (5415)                                   |
| tsv   | Miscellaneous professional, scientific, and technical services (5412-5414, 5416-5419) |
| man   | Management of companies and enterprises (55)                                          |
| adm   | Administrative and support services (561)                                             |
| wst   | Waste management and remediation services (562)                                       |
| edu   | Educational services (61)                                                             |
| amb   | Ambulatory health care services (621)                                                 |
| hos   | Hospitals (622)                                                                       |
| nrs   | Nursing and residential care facilities (623)                                         |
| soc   | Social assistance (624)                                                               |
| art   | Performing arts, spectator sports, museums, and related activities (711-712)          |
| rec   | Amusements, gambling, and recreation industries (713)                                 |
| amd   | Accommodation (721)                                                                   |
| res   | Food services and drinking places (722)                                               |
| osv   | Other services, except government (81)                                                |
| fdd   | Federal general government (defense) (GFGD)                                           |
| fnd   | Federal general government (nondefense) (GFGN)                                        |
| fen   | Federal government enterprises (GFE)                                                  |
| slg   | State and local general government (GSLG)                                             |
| sle   | State and local government enterprises (GSLE)                                         |


## [BEA Value added categories](@id core_national_va)

|va | Description|
|---|---|
|othtax | Other taxes on production (T00OTOP)|
|surplus | Gross operating surplus (V003)|
|compen | Compensation of employees (V001)|


## [BEA Final demand categories](@id core_national_fd)

|fd | Description|
|---|---|
|fed_structures | Federal nondefense: Gross investment in structures|
|def_equipment | Federal national defense: Gross investment in equipment|
|changinv | Change in private inventories|
|def_structures | Federal national defense: Gross investment in structures|
|state_equipment | State and local: Gross investment in equipment|
|def_intelprop | Federal national defense: Gross investment in intellectual|
|nondefense | Nondefense: Consumption expenditures|
|fed_equipment | Federal nondefense: Gross investment in equipment|
|state_invest | State and local: Gross investment in structures|
|structures | Nonresidential private fixed investment in structures|
|defense | National defense: Consumption expenditures|
|residential | Residential private fixed investment|
|equipment | Nonresidential private fixed investment in equipment|
|state_intelprop | State and local: Gross investment in intellectual|
|intelprop | Nonresidential private fixed investment in intellectual|
|pce | Personal consumption expenditures|
|state_consume | State and local government consumption expenditures|
|fed_intelprop | Federal nondefense: Gross investment in intellectual prop|


## [BEA Taxes and subsidies categories](@id core_national_ts)

|ts | Description|
|---|---|
|taxes | taxes|
|subsidies | subsidies|


## [Margins](@id core_national_margins)

|m | Description|
|---|---|
|trn | Transport|
|trd | Trade|
