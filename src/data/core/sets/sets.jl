

function initialize_sets(years = 1997:2021)

	GU = GamsUniverse()

	initialize_sets!(GU,years)

    return GU
end

function initialize_sets!(GU, years = 1997:2021)

    margins!(GU)
    bea_value_added!(GU)
    bea_final_demand!(GU)
    bea_taxes_subsidies!(GU)
    bea_goods_sectors!(GU)
    alias(GU,:i,:j)

	WiNDC_regions!(GU)

    years!(GU, years)

    return GU
end


function margins!(GU)
	@set(GU,m,"Margins",begin
		trn,	"Transport"
		trd,	"Trade"
	end)
    GU
end

function bea_value_added!(GU)
	@set(GU, va, "BEA Value added categories",begin
		othtax,	"Other taxes on production (T00OTOP)"
		surplus,	"Gross operating surplus (V003)"
		compen,	"Compensation of employees (V001)"
	end)
    GU
end

function bea_final_demand!(GU)
	@set(GU, fd, "BEA Final demand categories",begin
		fed_structures,	"Federal nondefense: Gross investment in structures"
		def_equipment,	"Federal national defense: Gross investment in equipment"
		changinv,	"Change in private inventories"
		def_structures,	"Federal national defense: Gross investment in structures"
		state_equipment,	"State and local: Gross investment in equipment"
		def_intelprop,	"Federal national defense: Gross investment in intellectual"
		nondefense,	"Nondefense: Consumption expenditures"
		fed_equipment,	"Federal nondefense: Gross investment in equipment"
		state_invest,	"State and local: Gross investment in structures"
		structures,	"Nonresidential private fixed investment in structures"
		defense,	"National defense: Consumption expenditures"
		residential,	"Residential private fixed investment"
		equipment,	"Nonresidential private fixed investment in equipment"
		state_intelprop,	"State and local: Gross investment in intellectual"
		intelprop,	"Nonresidential private fixed investment in intellectual"
		pce,	"Personal consumption expenditures"
		state_consume,	"State and local government consumption expenditures"
		fed_intelprop,	"Federal nondefense: Gross investment in intellectual prop"
	end)
    GU
end

function bea_taxes_subsidies!(GU)
	TS = GamsSet([
			GamsElement(:taxes, "taxes"),
			GamsElement(:subsidies, "subsidies")
		], "BEA Taxes and subsidies categories")

	add_set(GU,:ts, TS)
	
    GU
end

function years!(GU, years)
	year_set = GamsSet(GamsElement.(years),"Years in dataset")

    add_set(GU, :yr, year_set)
end

function bea_goods_sectors!(GU)
	add_set(GU, :i, GamsSet([
		GamsElement(:ppd,	"Paper products manufacturing (322)"),
		GamsElement(:res,	"Food services and drinking places (722)"),
		GamsElement(:com,	"Computer systems design and related services (5415)"),
		GamsElement(:amb,	"Ambulatory health care services (621)"),
		GamsElement(:fbp,	"Food and beverage and tobacco products manufacturing (311-312)"),
		GamsElement(:rec,	"Amusements, gambling, and recreation industries (713)"),
		GamsElement(:con,	"Construction (23)"),
		GamsElement(:agr,	"Farms (111-112)"),
		GamsElement(:eec,	"Electrical equipment, appliance, and components manufacturing (335)"),
		GamsElement(:use,	"Scrap, used and secondhand goods"),
		GamsElement(:fnd,	"Federal general government (nondefense) (GFGN)"),
		GamsElement(:pub,	"Publishing industries, except Internet (includes software) (511)"),
		GamsElement(:hou,	"Housing (HS)"),
		GamsElement(:fbt,	"Food and beverage stores (445)"),
		GamsElement(:ins,	"Insurance carriers and related activities (524)"),
		GamsElement(:tex,	"Textile mills and textile product mills (313-314)"),
		GamsElement(:leg,	"Legal services (5411)"),
		GamsElement(:fen,	"Federal government enterprises (GFE)"),
		GamsElement(:uti,	"Utilities (22)"),
		GamsElement(:nmp,	"Nonmetallic mineral products manufacturing (327)"),
		GamsElement(:brd,	"Broadcasting and telecommunications (515, 517)"),
		GamsElement(:bnk,	"Federal Reserve banks, credit intermediation, and related services (521-522)"),
		GamsElement(:ore,	"Other real estate (ORE)"),
		GamsElement(:edu,	"Educational services (61)"),
		GamsElement(:ote,	"Other transportation equipment manufacturing (3364-3366, 3369)"),
		GamsElement(:man,	"Management of companies and enterprises (55)"),
		GamsElement(:mch,	"Machinery manufacturing (333)"),
		GamsElement(:dat,	"Data processing, internet publishing, and other information services (518, 519)"),
		GamsElement(:amd,	"Accommodation (721)"),
		GamsElement(:oil,	"Oil and gas extraction (211)"),
		GamsElement(:hos,	"Hospitals (622)"),
		GamsElement(:rnt,	"Rental and leasing services and lessors of intangible assets (532-533)"),
		GamsElement(:pla,	"Plastics and rubber products manufacturing (326)"),
		GamsElement(:fof,	"Forestry, fishing, and related activities (113-115)"),
		GamsElement(:fin,	"Funds, trusts, and other financial vehicles (525)"),
		GamsElement(:tsv,	"Miscellaneous professional, scientific, and technical services (5412-5414, 5416-5419)"),
		GamsElement(:nrs,	"Nursing and residential care facilities (623)"),
		GamsElement(:sec,	"Securities, commodity contracts, and investments (523)"),
		GamsElement(:art,	"Performing arts, spectator sports, museums, and related activities (711-712)"),
		GamsElement(:mov,	"Motion picture and sound recording industries (512)"),
		GamsElement(:fpd,	"Furniture and related products manufacturing (337)"),
		GamsElement(:slg,	"State and local general government (GSLG)"),
		GamsElement(:pri,	"Printing and related support activities (323)"),
		GamsElement(:grd,	"Transit and ground passenger transportation (485)"),
		GamsElement(:pip,	"Pipeline transportation (486)"),
		GamsElement(:sle,	"State and local government enterprises (GSLE)"),
		GamsElement(:osv,	"Other services, except government (81)"),
		GamsElement(:trn,	"Rail transportation (482)"),
		GamsElement(:smn,	"Support activities for mining (213)"),
		GamsElement(:fmt,	"Fabricated metal products (332)"),
		GamsElement(:pet,	"Petroleum and coal products manufacturing (324)"),
		GamsElement(:mvt,	"Motor vehicle and parts dealers (441)"),
		GamsElement(:cep,	"Computer and electronic products manufacturing (334)"),
		GamsElement(:wst,	"Waste management and remediation services (562)"),
		GamsElement(:mot,	"Motor vehicles, bodies and trailers, and parts manufacturing (3361-3363)"),
		GamsElement(:adm,	"Administrative and support services (561)"),
		GamsElement(:soc,	"Social assistance (624)"),
		GamsElement(:alt,	"Apparel and leather and allied products manufacturing (315-316)"),
		GamsElement(:pmt,	"Primary metals manufacturing (331)"),
		GamsElement(:trk,	"Truck transportation (484)"),
		GamsElement(:fdd,	"Federal general government (defense) (GFGD)"),
		GamsElement(:gmt,	"General merchandise stores (452)"),
		GamsElement(:wtt,	"Water transportation (483)"),
		GamsElement(:wpd,	"Wood products manufacturing (321)"),
		GamsElement(:wht,	"Wholesale trade (42)"),
		GamsElement(:oth,	"Noncomparable imports and rest-of-the-world adjustment"),
		GamsElement(:wrh,	"Warehousing and storage (493)"),
		GamsElement(:ott,	"Other retail (4A0)"),
		GamsElement(:che,	"Chemical products manufacturing (325)"),
		GamsElement(:air,	"Air transportation (481)"),
		GamsElement(:mmf,	"Miscellaneous manufacturing (339)"),
		GamsElement(:otr,	"Other transportation and support activities (487-488, 492)"),
		GamsElement(:min,	"Mining, except oil and gas (212)"),],
	"BEA Goods and sectors categories"
	))

    GU
end

function WiNDC_regions!(GU)
	@set(GU, r,"States in the WiNDC database",begin                
        AL, "Alabama"
        AK, "Alaska"
        AZ, "Arizona"
        AR, "Arkansas"
        CA, "California"
        CO, "Colorado"
        CT, "Connecticut"
        DE, "Delaware"
        DC, "District of Columbia"
        FL, "Florida"
        GA, "Georgia"
        HI, "Hawaii"
        ID, "Idaho"
        IL, "Illinois"
        IN, "Indiana"
        IA, "Iowa"
        KS, "Kansas"
        KY, "Kentucky"
        LA, "Louisiana"
        ME, "Maine"
        MD, "Maryland"
        MA, "Massachusetts"
        MI, "Michigan"
        MN, "Minnesota"
        MS, "Mississippi"
        MO, "Missouri"
        MT, "Montana"
        NE, "Nebraska"
        NV, "Nevada"
        NH, "New Hampshire"
        NJ, "New Jersey"
        NM, "New Mexico"
        NY, "New York"
        NC, "North Carolina"
        ND, "North Dakota"
        OH, "Ohio"
        OK, "Oklahoma"
        OR, "Oregon"
        PA, "Pennsylvania"
        RI, "Rhode Island"
        SC, "South Carolina"
        SD, "South Dakota"
        TN, "Tennessee"
        TX, "Texas"
        UT, "Utah"
        VT, "Vermont"
        VA, "Virginia"
        WA, "Washington"
        WV, "West Virginia"
        WI, "Wisconsin"
        WY, "Wyoming"
    end)

	GU
end