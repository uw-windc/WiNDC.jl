var documenterSearchIndex = {"docs":
[{"location":"core/national_model/#National-Disaggregation-Model","page":"National Disaggregation Model","title":"National Disaggregation Model","text":"","category":"section"},{"location":"core/national_model/","page":"National Disaggregation Model","title":"National Disaggregation Model","text":"","category":"page"},{"location":"core/overview/#Core-Module-Overview","page":"Core Module Overview","title":"Core Module Overview","text":"","category":"section"},{"location":"core/overview/","page":"Core Module Overview","title":"Core Module Overview","text":"We provide methods to build two datasets, the national dataset and state level dataset. The national dataset is based on the BEA summary IO tables. The state level dataset uses the remaining data sources to disaggregate the national  dataset to a the state-level.","category":"page"},{"location":"core/overview/#National-Dataset","page":"Core Module Overview","title":"National Dataset","text":"","category":"section"},{"location":"core/overview/","page":"Core Module Overview","title":"Core Module Overview","text":"To Do: Discuss creation and assignment of the national dataset.","category":"page"},{"location":"core/overview/#State-Level-Dataset","page":"Core Module Overview","title":"State Level Dataset","text":"","category":"section"},{"location":"core/overview/","page":"Core Module Overview","title":"Core Module Overview","text":"To Do: Discuss creation and assignment of the State level dataset.","category":"page"},{"location":"core/state_model/#State-Disaggregation-Model","page":"State Disaggregation Model","title":"State Disaggregation Model","text":"","category":"section"},{"location":"core/state_model/","page":"State Disaggregation Model","title":"State Disaggregation Model","text":"","category":"page"},{"location":"core/state_model/","page":"State Disaggregation Model","title":"State Disaggregation Model","text":"To Do:","category":"page"},{"location":"data/overview/#Data-Module","page":"Data Module","title":"Data Module","text":"","category":"section"},{"location":"data/overview/","page":"Data Module","title":"Data Module","text":"We have assembled all of this data for download to run locally. This information is provided if you are interested in updating  data early, without using the API.","category":"page"},{"location":"data/overview/","page":"Data Module","title":"Data Module","text":"When manually updating data, you may need to modify the file data_information.json with  updated paths to the files. A JSON file is raw text and can be modified in any text editor. It should be straight forward to open the file and determine what needs updating. ","category":"page"},{"location":"data/overview/#API-Access","page":"Data Module","title":"API Access","text":"","category":"section"},{"location":"data/overview/","page":"Data Module","title":"Data Module","text":"This is currently not available, but under active development. Expect updates in early 2024.","category":"page"},{"location":"national/overview/#National-Module","page":"National Module","title":"National Module","text":"","category":"section"},{"location":"national/overview/","page":"National Module","title":"National Module","text":"The national module has two aggregations available:","category":"page"},{"location":"national/overview/","page":"National Module","title":"National Module","text":"summary\ndetailed","category":"page"},{"location":"national/overview/","page":"National Module","title":"National Module","text":"The summary aggregation is loaded directly from the summary tables provided by the BEA. The detailed aggregation is an extrapolation of the summary tables using the detailed tables. ","category":"page"},{"location":"national/overview/","page":"National Module","title":"National Module","text":"Years not currently calibrating:","category":"page"},{"location":"national/overview/","page":"National Module","title":"National Module","text":"1997\n1998\n1999\n2000\n2001\n2002\n2008\n2011\n2013\n2014\n2015\n2016","category":"page"},{"location":"data/core/#core_data_sources","page":"Core Data Sources","title":"Core Data Sources","text":"","category":"section"},{"location":"data/core/","page":"Core Data Sources","title":"Core Data Sources","text":"As of November 9, 2023, the BEA is restricting their data to be 2017 - Present.  This is due to the release of the detailed 2017 IO table. They are using the detailed table to back-update the summary tables. ","category":"page"},{"location":"data/core/#Bureau-of-Economic-Analysis-Summary-Input/Output-Tables","page":"Core Data Sources","title":"Bureau of Economic Analysis - Summary Input/Output Tables","text":"","category":"section"},{"location":"data/core/","page":"Core Data Sources","title":"Core Data Sources","text":"Link","category":"page"},{"location":"data/core/#Bureau-of-Economic-Analysis-Gross-Domestic-Product-by-State","page":"Core Data Sources","title":"Bureau of Economic Analysis - Gross Domestic Product by State","text":"","category":"section"},{"location":"data/core/","page":"Core Data Sources","title":"Core Data Sources","text":"Link","category":"page"},{"location":"data/core/","page":"Core Data Sources","title":"Core Data Sources","text":"In the Gross Domestic Product (GDP), select the SAGDP: annual GDP by state option.","category":"page"},{"location":"data/core/#Bureau-of-Economic-Analysis-–-Personal-Consumer-Expenditures","page":"Core Data Sources","title":"Bureau of Economic Analysis – Personal Consumer Expenditures","text":"","category":"section"},{"location":"data/core/","page":"Core Data Sources","title":"Core Data Sources","text":"Link","category":"page"},{"location":"data/core/","page":"Core Data Sources","title":"Core Data Sources","text":"In the Personal consumption expenditures (PCE) by state, select the  SAPCE: personal consumption expenditures (PCE) by state option. ","category":"page"},{"location":"data/core/#US-Census-Bureau-Annual-Survey-of-State-Government-Finances","page":"Core Data Sources","title":"US Census Bureau - Annual Survey of State Government Finances","text":"","category":"section"},{"location":"data/core/","page":"Core Data Sources","title":"Core Data Sources","text":"Link","category":"page"},{"location":"data/core/","page":"Core Data Sources","title":"Core Data Sources","text":"Heavily encoded TXT files.","category":"page"},{"location":"data/core/#Bureau-of-Transportation-Statistics-Freight-Analysis-Framework","page":"Core Data Sources","title":"Bureau of Transportation Statistics - Freight Analysis Framework","text":"","category":"section"},{"location":"data/core/","page":"Core Data Sources","title":"Core Data Sources","text":"Link","category":"page"},{"location":"data/core/","page":"Core Data Sources","title":"Core Data Sources","text":"We use two data files, FAF5.5.1_State.zip and FAF5.5.1_Reprocessed_1997-2012_State.zip","category":"page"},{"location":"data/core/","page":"Core Data Sources","title":"Core Data Sources","text":"Currently, we are using version 5.5.1.","category":"page"},{"location":"data/core/#US-Census-Bureau-USA-Trade-Online","page":"Core Data Sources","title":"US Census Bureau - USA Trade Online","text":"","category":"section"},{"location":"data/core/","page":"Core Data Sources","title":"Core Data Sources","text":"Link","category":"page"},{"location":"data/core/","page":"Core Data Sources","title":"Core Data Sources","text":"This requires a log-in. For both Imports and Exports we want NAICS data. When selecting data, we want every state (this is different that All States), the most disaggregated commodities (third level), and for Exports we want World Total and Imports we want both World Total and Canada in the Countries column.","category":"page"},{"location":"data/core/","page":"Core Data Sources","title":"Core Data Sources","text":"There is one more file we use, Commodity_detail_by_state_cy.xlsx This is probably a fragile link.","category":"page"},{"location":"#Introduction","page":"Introduction","title":"Introduction","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"This package is currently under active development. The final goal is to have several modules.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"National\nState\nHousehold\nBilateral Trade\nGTAP","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"Currently, the only available module is the National module. ","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"Modules = [WiNDC]\nOrder   = [:type, :function]","category":"page"},{"location":"#DataFrames.subset-Union{Tuple{T}, Tuple{T, Vararg{Any}}} where T<:WiNDCtable","page":"Introduction","title":"DataFrames.subset","text":"subset(\n        data::T, \n        @nospecialize(args...)\n    ) where T <: WiNDCtable\n\nReturn a subset of data based on the conditions given in args. This will  subset both the main table and the set table.\n\nRequired Arguments\n\ndata::T: The WiNDCtable to subset.\nargs::Tuple: Pairs of the form set_name => boolean function. \n\nReturn\n\nA table of type T.\n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.aggregate-Union{Tuple{T}, Tuple{T, Vararg{Any}}} where T<:WiNDCtable","page":"Introduction","title":"WiNDC.aggregate","text":"function aggregate(\n    data::T,\n    aggregations...\n) where T<:WiNDCtable\n\nRequired Arguments\n\ndata::T: The WiNDCtable to aggregate.\naggregations: Takes the form set_name => (X, original => new)). \nset_name is a symbol, the name of the set to aggregate.\nX a dataframe with the columns original and new.\noriginal is the name of the column in with the elements to be aggregated.\nnew is the name of the column with the aggregated names.\n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.calibrate-Tuple{T} where T<:WiNDC.AbstractNationalTable","page":"Introduction","title":"WiNDC.calibrate","text":"calibrate(data::AbstractNationalTable)\n\nThis is currently geared toward calibrating the national dataset. I'll be working to make this be a general calibration function.\n\nReturns a new AbstractNationalTable with the calibrated values and the model.\n\nThere are three primary balancing operations:\n\nZero Profit - Column sums are equal\nMarket Clearance - Row sums are equal\nMargin Balance - The margins balance\n\nThe three tax rates are fixed. The tax rates are:\n\nOutput Tax Rate\nAbsorption Tax Rate\nImport Tariff Rate\n\nThe following are fixed:\n\nLabor Compensation\nImports\nExports\nHousehold Supply\n\nAny zero values will remain zero. \n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.calibrate-Tuple{T} where T<:WiNDC.AbstractRegionalTable","page":"Introduction","title":"WiNDC.calibrate","text":"calibrate(data::AbstractNationalTable)\n\nThis is currently geared toward calibrating the national dataset. I'll be working to make this be a general calibration function.\n\nReturns a new AbstractNationalTable with the calibrated values and the model.\n\nThere are three primary balancing operations:\n\nZero Profit - Column sums are equal\nMarket Clearance - Row sums are equal\nMargin Balance - The margins balance\n\nThe three tax rates are fixed. The tax rates are:\n\nOutput Tax Rate\nAbsorption Tax Rate\nImport Tariff Rate\n\nThe following are fixed:\n\nLabor Compensation\nImports\nExports\nHousehold Supply\n\nAny zero values will remain zero. \n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.create_national_sets-Tuple{XLSX.Worksheet, XLSX.Worksheet, Any}","page":"Introduction","title":"WiNDC.create_national_sets","text":"create_national_sets(\n    use::XLSX.Worksheet, \n    supply::XLSX.Worksheet,\n    set_regions)\n\nThis function creates the sets for the detailed national data.\n\nset regions for detailed table\n\nDict(\n    \"commodities\" => (\"use\", [\"A7:B408\"], false, :commodities),\n    \"labor_demand\" => (\"use\", [\"A410:B410\"], false, :commodities),\n    \"other_tax\" => (\"use\", [\"A411:B411\"], false, :commodities),\n    \"capital_demand\" => (\"use\", [\"A412:B412\"], false, :commodities),\n    \"sectors\" => (\"use\", [\"C5:ON6\"], true, :sectors),\n    \"personal_consumption\" => (\"use\", [\"OP5:OP6\"], true, :sectors),\n    \"household_supply\" => (\"use\", [\"OP5:OP6\"], true, :sectors),\n    \"exports\" => (\"use\", [\"OV5:OV6\"], true, :sectors),\n    \"exogenous_final_demand\" => (\"use\", [\"OQ5:OU6\",\"OW5:PH6\"], true, :sectors),\n    \"imports\" => (\"supply\", [\"OP5:OP6\"], true, :sectors),\n    \"margin_demand\" => (\"supply\", [\"OS5:OT6\"], true, :sectors),\n    \"margin_supply\" => (\"supply\", [\"OS5:OT6\"], true, :sectors),\n    \"duty\" => (\"supply\", [\"OV5:OV6\"], true, :sectors),\n    \"tax\" => (\"supply\", [\"OW5:OW6\"], true, :sectors),\n    \"subsidies\" => (\"supply\", [\"OX5:OX6\"], true, :sectors)\n)\n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.create_national_subtables-Tuple{Any}","page":"Introduction","title":"WiNDC.create_national_subtables","text":"create_national_subtables(sets)\n\nThis function creates the subtables for the detailed national data.\n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.detailed_summary_map-Tuple{String}","page":"Introduction","title":"WiNDC.detailed_summary_map","text":"detailed_summary_map(detailed_path)\n\nThis function reads the detailed table and returns a DataFrame that maps the detailed sectors to the summary sectors. The first sheet of the detailed table is a map between the detailed sectors and the summary sectors. In addition this maps value added, final demand and supply extras to the summary sectors.\n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.down_fill-Tuple{Any}","page":"Introduction","title":"WiNDC.down_fill","text":"down_fill(X)\n\nThis function fills in the missing values in a column with the last non-missing value.\n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.get_set-Union{Tuple{T}, Tuple{T, String}} where T<:WiNDCtable","page":"Introduction","title":"WiNDC.get_set","text":"get_set(data::T) where T<:WiNDCtable  \n\nget_set(data::T, set_name::String) where T<:WiNDCtable\n\nget_set(data::T, set_name::Vector{String}) where T<:WiNDCtable\n\nReturn the elements of the given sets. If no set is given, return all sets.\n\nRequired Arguments\n\ndata - A WiNDCtable-like object. \nset_name - A string or vector of strings representing the set names to be extracted.\n\nReturns\n\nReturns a DataFrame with three columns, :element, :set and :description\n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.get_subtable-Tuple{WiNDCtable, String, Vector{Symbol}}","page":"Introduction","title":"WiNDC.get_subtable","text":"get_subtable(data::T, subtable::String, column::Vector{Symbol}; negative::Bool = false, keep_all_columns = false) where T<:WiNDCtable\n\nget_subtable(data::T, subtable::String; column::Symbol = :value, output::Symbol = :value, negative = false) where T<:WiNDCtable\n\nget_subtable(data::T, subtable::Vector{String}) where T<:WiNDCtable\n\nReturn the subtables requested as a DataFrame\n\nRequired Arguments\n\ndata - A WiNDCtable-like object.\nsubtable - A string or vector of strings representing the subtable names to be extracted.\n\nOptional Arguments\n\ncolumn - A symbol representing the column to be extracted. Default is :value.\noutput - A symbol representing the output column name. Default is :value.\nnegative - A boolean representing whether the values should be negated. Default is false.\n\nReturns\n\nReturns a DataFrame with the requested subtables and columns.\n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.get_table-Tuple{T} where T<:WiNDCtable","page":"Introduction","title":"WiNDC.get_table","text":"get_table(data::T) where T<:WiNDCtable\n\nReturn the main table of the WiNDCtable object as a DataFrame\n\nRequired Arguments\n\ndata - A WiNDCtable-like object.\n\nOutput\n\nReturns a DataFrame with columns domain(data), subtable, and value.\n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.load_table-Tuple{String, Vararg{Int64}}","page":"Introduction","title":"WiNDC.load_table","text":"load_table(\n    file_path::String\n    years::Int...;\n)\n\nLoad a WiNDCtable from a file. \n\nRequired Arguments\n\nfile_path::String: The path to the file.\nyears::Int...: The years to load. If no years are provided, all years in the file   will be loaded.\n\nReturns\n\nA subtype of a WiNDCtable, with the data and sets loaded from the file.\n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.make_subtable-NTuple{5, Any}","page":"Introduction","title":"WiNDC.make_subtable","text":"make_subtable(sets, rows, columns, table, subtable)\n\nA helper function for extracting subtables.\n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.save_table-Union{Tuple{T}, Tuple{String, T}} where T<:WiNDCtable","page":"Introduction","title":"WiNDC.save_table","text":"save_table(\n    output_path::String\n    MU::T,\n) where T<:WiNDCtable\n\nSave a WiNDCtable to a file. The file format is HDF5, which can be opened in any other language. The file will have the following structure:\n\nyear - DataFrame - The data for each year in the WiNDCtable sets - DataFrame - The sets of the WiNDCtable columns - Array - The column names of each yearly DataFrame\n\nRequired Arguments\n\noutput_path::String: The path to save the file.\nMU::WiNDCtable: The WiNDCtable to save.\n\n\n\n\n\n","category":"method"},{"location":"#WiNDC.weight_function-NTuple{4, Int64}","page":"Introduction","title":"WiNDC.weight_function","text":"weight_function(year_detail, year_summary, minimum_detail, maximum_detail)\n\nCreate the weight function for the interpolation of the detailed table to the summary table based solely on the year.\n\n\n\n\n\n","category":"method"},{"location":"core/national_set_list/#core_national_dataset","page":"National Dataset","title":"National Dataset","text":"","category":"section"},{"location":"core/national_set_list/#Sets","page":"National Dataset","title":"Sets","text":"","category":"section"},{"location":"core/national_set_list/","page":"National Dataset","title":"National Dataset","text":"Set Name Description\nyr Years in dataset\ni,j BEA Goods and sectors categories\nva BEA Value added categories\nfd BEA Final demand categories\nts BEA Taxes and subsidies categories\nm Margins","category":"page"},{"location":"core/national_set_list/#Parameters","page":"National Dataset","title":"Parameters","text":"","category":"section"},{"location":"core/national_set_list/","page":"National Dataset","title":"National Dataset","text":"Parameter Name Domain Description\nid0 yr, i, j Intermediate Demand\nys0 yr, j, i Intermediate Supply\nfd0 yr, i, fd Final Demand\nva0 yr, va, j Value Added\nmd0 yr, m, i Margin Demand\ns0 yr, j Aggregate Supply\nm0 yr, i Imports\ntrn0 yr, i Transportation Costs\ntm0 yr, i Tax net subsidy rate on intermediate demand\nta0 yr, i Import Tariff\nothtax yr, j Other taxes\ny0 yr, i Gross Output\nmrg0 yr, i Trade Margins\nbopdef0 yr \nx0 yr, i Exports\ntax0 yr, i Taxes on Products\nms0 yr, i, m Margin Supply\nduty0 yr, i Import Duties\nfs0 yr, i Household Supply\nts0 yr, ts, j Taxes and Subsidies\ncif0 yr, i \nsbd0 yr, i Subsidies\na0 yr, i Armington Supply\nty0 yr, j Output tax rate","category":"page"},{"location":"core/national_set_list/#Set-Listing","page":"National Dataset","title":"Set Listing","text":"","category":"section"},{"location":"core/national_set_list/#core_national_years","page":"National Dataset","title":"Years in WiNDC Database","text":"","category":"section"},{"location":"core/national_set_list/","page":"National Dataset","title":"National Dataset","text":"yr  yr\n1997  2010\n1998  2011\n1999  2011\n2000  2012\n2001  2013\n2002  2014\n2003  2015\n2004  2016\n2005  2017\n2006  2018\n2007  2019\n2008  2020\n2009  2021","category":"page"},{"location":"core/national_set_list/#core_national_sectors","page":"National Dataset","title":"BEA Goods and sectors categories & Commodities employed in margin supply","text":"","category":"section"},{"location":"core/national_set_list/","page":"National Dataset","title":"National Dataset","text":"i, j Description\nagr Farms (111-112)\nfof Forestry, fishing, and related activities (113-115)\noil Oil and gas extraction (211)\nmin Mining, except oil and gas (212)\nsmn Support activities for mining (213)\nuti Utilities (22)\ncon Construction (23)\nwpd Wood products manufacturing (321)\nnmp Nonmetallic mineral products manufacturing (327)\npmt Primary metals manufacturing (331)\nfmt Fabricated metal products (332)\nmch Machinery manufacturing (333)\ncep Computer and electronic products manufacturing (334)\neec Electrical equipment, appliance, and components manufacturing (335)\nmot Motor vehicles, bodies and trailers, and parts manufacturing (3361-3363)\note Other transportation equipment manufacturing (3364-3366, 3369)\nfpd Furniture and related products manufacturing (337)\nmmf Miscellaneous manufacturing (339)\nfbp Food and beverage and tobacco products manufacturing (311-312)\ntex Textile mills and textile product mills (313-314)\nalt Apparel and leather and allied products manufacturing (315-316)\nppd Paper products manufacturing (322)\npri Printing and related support activities (323)\npet Petroleum and coal products manufacturing (324)\nche Chemical products manufacturing (325)\npla Plastics and rubber products manufacturing (326)\nwht Wholesale trade (42)\nmvt Motor vehicle and parts dealers (441)\nfbt Food and beverage stores (445)\ngmt General merchandise stores (452)\nott Other retail (4A0)\nair Air transportation (481)\ntrn Rail transportation (482)\nwtt Water transportation (483)\ntrk Truck transportation (484)\ngrd Transit and ground passenger transportation (485)\npip Pipeline transportation (486)\notr Other transportation and support activities (487-488, 492)\nwrh Warehousing and storage (493)\npub Publishing industries, except Internet (includes software) (511)\nmov Motion picture and sound recording industries (512)\nbrd Broadcasting and telecommunications (515, 517)\ndat Data processing, internet publishing, and other information services (518, 519)\nbnk Federal Reserve banks, credit intermediation, and related services (521-522)\nsec Securities, commodity contracts, and investments (523)\nins Insurance carriers and related activities (524)\nfin Funds, trusts, and other financial vehicles (525)\nhou Housing (HS)\nore Other real estate (ORE)\nrnt Rental and leasing services and lessors of intangible assets (532-533)\nleg Legal services (5411)\ncom Computer systems design and related services (5415)\ntsv Miscellaneous professional, scientific, and technical services (5412-5414, 5416-5419)\nman Management of companies and enterprises (55)\nadm Administrative and support services (561)\nwst Waste management and remediation services (562)\nedu Educational services (61)\namb Ambulatory health care services (621)\nhos Hospitals (622)\nnrs Nursing and residential care facilities (623)\nsoc Social assistance (624)\nart Performing arts, spectator sports, museums, and related activities (711-712)\nrec Amusements, gambling, and recreation industries (713)\namd Accommodation (721)\nres Food services and drinking places (722)\nosv Other services, except government (81)\nfdd Federal general government (defense) (GFGD)\nfnd Federal general government (nondefense) (GFGN)\nfen Federal government enterprises (GFE)\nslg State and local general government (GSLG)\nsle State and local government enterprises (GSLE)","category":"page"},{"location":"core/national_set_list/#core_national_va","page":"National Dataset","title":"BEA Value added categories","text":"","category":"section"},{"location":"core/national_set_list/","page":"National Dataset","title":"National Dataset","text":"va Description\nothtax Other taxes on production (T00OTOP)\nsurplus Gross operating surplus (V003)\ncompen Compensation of employees (V001)","category":"page"},{"location":"core/national_set_list/#core_national_fd","page":"National Dataset","title":"BEA Final demand categories","text":"","category":"section"},{"location":"core/national_set_list/","page":"National Dataset","title":"National Dataset","text":"fd Description\nfed_structures Federal nondefense: Gross investment in structures\ndef_equipment Federal national defense: Gross investment in equipment\nchanginv Change in private inventories\ndef_structures Federal national defense: Gross investment in structures\nstate_equipment State and local: Gross investment in equipment\ndef_intelprop Federal national defense: Gross investment in intellectual\nnondefense Nondefense: Consumption expenditures\nfed_equipment Federal nondefense: Gross investment in equipment\nstate_invest State and local: Gross investment in structures\nstructures Nonresidential private fixed investment in structures\ndefense National defense: Consumption expenditures\nresidential Residential private fixed investment\nequipment Nonresidential private fixed investment in equipment\nstate_intelprop State and local: Gross investment in intellectual\nintelprop Nonresidential private fixed investment in intellectual\npce Personal consumption expenditures\nstate_consume State and local government consumption expenditures\nfed_intelprop Federal nondefense: Gross investment in intellectual prop","category":"page"},{"location":"core/national_set_list/#core_national_ts","page":"National Dataset","title":"BEA Taxes and subsidies categories","text":"","category":"section"},{"location":"core/national_set_list/","page":"National Dataset","title":"National Dataset","text":"ts Description\ntaxes taxes\nsubsidies subsidies","category":"page"},{"location":"core/national_set_list/#core_national_margins","page":"National Dataset","title":"Margins","text":"","category":"section"},{"location":"core/national_set_list/","page":"National Dataset","title":"National Dataset","text":"m Description\ntrn Transport\ntrd Trade","category":"page"},{"location":"core/set_listing/#core_state_disaggregation","page":"State Level Disaggregation","title":"State Level Disaggregation","text":"","category":"section"},{"location":"core/set_listing/#Sets","page":"State Level Disaggregation","title":"Sets","text":"","category":"section"},{"location":"core/set_listing/","page":"State Level Disaggregation","title":"State Level Disaggregation","text":"Set Name Description\nyr Years in WiNDC Database\nr Regions in WiNDC Database\ns, g BEA Goods and sectors categories\nm Margins (trade or transport)\ngm Commodities employed in margin supply","category":"page"},{"location":"core/set_listing/#Parameters","page":"State Level Disaggregation","title":"Parameters","text":"","category":"section"},{"location":"core/set_listing/","page":"State Level Disaggregation","title":"State Level Disaggregation","text":"Parameter Name Domain Description\nys0_ yr, r, s, g Regional sectoral output\nld0_ yr, r, s Labor demand\nkd0_ yr, r, s Capital demand\nid0_ yr, r, g, s Regional intermediate demand\nty0_ yr, r, s Production tax rate\nyh0_ yr, r, s Household production\nfe0_ yr, r Total factor supply\ncd0_ yr, r, s Consumption demand\nc0_ yr, r Total final household consumption\ni0_ yr, r, s Investment demand\ng0_ yr, r, s Government demand\nbopdef0_ yr, r Balance of payments (closure parameter)\nhhadj0_ yr, r Household adjustment parameter\ns0_ yr, r, g Total supply\nxd0_ yr, r, g Regional supply to local market\nxn0_ yr, r, g Regional supply to national market\nx0_ yr, r, g Foreign Exports\nrx0_ yr, r, g Re-exports\na0_ yr, r, g Domestic absorption\nnd0_ yr, r, g Regional demand from national marke\ndd0_ yr, r, g Regional demand from local market\nm0_ yr, r, g Foreign Imports\nta0_ yr, r, g Absorption taxes\ntm0_ yr, r, g Import taxes\nmd0_ yr, r, m, g Margin demand\nnm0_ yr, r, g, m Margin demand from the national market\ndm0_ yr, r, g, m Margin supply from the local market\ngdp0_ yr, r Aggregate GDP","category":"page"},{"location":"core/set_listing/#Set-Listing","page":"State Level Disaggregation","title":"Set Listing","text":"","category":"section"},{"location":"core/set_listing/#core_years","page":"State Level Disaggregation","title":"Years in WiNDC Database","text":"","category":"section"},{"location":"core/set_listing/","page":"State Level Disaggregation","title":"State Level Disaggregation","text":"yr  yr\n1997  2010\n1998  2011\n1999  2011\n2000  2012\n2001  2013\n2002  2014\n2003  2015\n2004  2016\n2005  2017\n2006  2018\n2007  2019\n2008  2020\n2009  2021","category":"page"},{"location":"core/set_listing/#core_regions","page":"State Level Disaggregation","title":"Regions in WiNDC Database","text":"","category":"section"},{"location":"core/set_listing/","page":"State Level Disaggregation","title":"State Level Disaggregation","text":"r Description  r Description\nAK Alaska  MT Montana\nAL Alabama  NC North Carolina\nAR Arkansas  ND North Dakota\nAZ Arizona  NE Nebraska\nCA California  NH New Hampshire\nCO Colorado  NJ New Jersey\nCT Connecticut  NM New Mexico\nDC District of Columbia  NV Nevada\nDE Delaware  NY New York\nFL Florida  OH Ohio\nGA Georgia  OK Oklahoma\nHI Hawaii  OR Oregon\nIA Iowa  PA Pennsylvania\nID Idaho  RI Rhode Island\nIL Illinois  SC South Carolina\nIN Indiana  SD South Dakota\nKS Kansas  TN Tennessee\nKY Kentucky  TX Texas\nLA Louisiana  UT Utah\nMA Massachusetts  VA Virginia\nMD Maryland  VT Vermont\nME Maine  WA Washington\nMI Michigan  WI Wisconsin\nMN Minnesota  WV West Virginia\nMO Missouri  WY Wyoming\nMS Mississippi   ","category":"page"},{"location":"core/set_listing/#core_sectors","page":"State Level Disaggregation","title":"BEA Goods and sectors categories & Commodities employed in margin supply","text":"","category":"section"},{"location":"core/set_listing/","page":"State Level Disaggregation","title":"State Level Disaggregation","text":"s, g gm Description\nagr agr Farms (111-112)\nfof fof Forestry, fishing, and related activities (113-115)\noil oil Oil and gas extraction (211)\nmin min Mining, except oil and gas (212)\nsmn - Support activities for mining (213)\nuti - Utilities (22)\ncon - Construction (23)\nwpd wpd Wood products manufacturing (321)\nnmp nmp Nonmetallic mineral products manufacturing (327)\npmt pmt Primary metals manufacturing (331)\nfmt fmt Fabricated metal products (332)\nmch mch Machinery manufacturing (333)\ncep cep Computer and electronic products manufacturing (334)\neec eec Electrical equipment, appliance, and components manufacturing (335)\nmot mot Motor vehicles, bodies and trailers, and parts manufacturing (3361-3363)\note ote Other transportation equipment manufacturing (3364-3366, 3369)\nfpd fpd Furniture and related products manufacturing (337)\nmmf mmf Miscellaneous manufacturing (339)\nfbp fbp Food and beverage and tobacco products manufacturing (311-312)\ntex tex Textile mills and textile product mills (313-314)\nalt alt Apparel and leather and allied products manufacturing (315-316)\nppd ppd Paper products manufacturing (322)\npri pri Printing and related support activities (323)\npet pet Petroleum and coal products manufacturing (324)\nche che Chemical products manufacturing (325)\npla pla Plastics and rubber products manufacturing (326)\nwht wht Wholesale trade (42)\nmvt mvt Motor vehicle and parts dealers (441)\nfbt fbt Food and beverage stores (445)\ngmt gmt General merchandise stores (452)\nott ott Other retail (4A0)\nair air Air transportation (481)\ntrn trn Rail transportation (482)\nwtt wtt Water transportation (483)\ntrk trk Truck transportation (484)\ngrd - Transit and ground passenger transportation (485)\npip pip Pipeline transportation (486)\notr otr Other transportation and support activities (487-488, 492)\nwrh - Warehousing and storage (493)\npub pub Publishing industries, except Internet (includes software) (511)\nmov mov Motion picture and sound recording industries (512)\nbrd - Broadcasting and telecommunications (515, 517)\ndat - Data processing, internet publishing, and other information services (518, 519)\nbnk - Federal Reserve banks, credit intermediation, and related services (521-522)\nsec - Securities, commodity contracts, and investments (523)\nins - Insurance carriers and related activities (524)\nfin - Funds, trusts, and other financial vehicles (525)\nhou - Housing (HS)\nore - Other real estate (ORE)\nrnt - Rental and leasing services and lessors of intangible assets (532-533)\nleg - Legal services (5411)\ncom - Computer systems design and related services (5415)\ntsv - Miscellaneous professional, scientific, and technical services (5412-5414, 5416-5419)\nman - Management of companies and enterprises (55)\nadm - Administrative and support services (561)\nwst - Waste management and remediation services (562)\nedu - Educational services (61)\namb - Ambulatory health care services (621)\nhos - Hospitals (622)\nnrs - Nursing and residential care facilities (623)\nsoc - Social assistance (624)\nart - Performing arts, spectator sports, museums, and related activities (711-712)\nrec - Amusements, gambling, and recreation industries (713)\namd - Accommodation (721)\nres - Food services and drinking places (722)\nosv - Other services, except government (81)\nfdd - Federal general government (defense) (GFGD)\nfnd - Federal general government (nondefense) (GFGN)\nfen - Federal government enterprises (GFE)\nslg - State and local general government (GSLG)\nsle - State and local government enterprises (GSLE)","category":"page"},{"location":"core/set_listing/#core_margins","page":"State Level Disaggregation","title":"Margins (trade or transport)","text":"","category":"section"},{"location":"core/set_listing/","page":"State Level Disaggregation","title":"State Level Disaggregation","text":"m Description\ntrn transport\ntrd trade","category":"page"}]
}
