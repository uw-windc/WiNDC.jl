

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
	@create_set!(GU,:m,"Margins",begin
		trn,	"Transport"
		trd,	"Trade"
	end)
    GU
end

function bea_value_added!(GU)
	@create_set!(GU,:va,"BEA Value added categories",begin
		othtax,	"Other taxes on production (T00OTOP)"
		surplus,	"Gross operating surplus (V003)"
		compen,	"Compensation of employees (V001)"
	end)
    GU
end

function bea_final_demand!(GU)
	@create_set!(GU,:fd,"BEA Final demand categories",begin
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
	@create_set!(GU,:ts,"BEA Taxes and subsidies categories",begin
		taxes,	"taxes"
		subsidies,	"subsidies"
	end)
    GU
end

function years!(GU, years)
	year_set = GamsSet(GamsElement.(years),"Years in dataset")

    add_set(GU, :yr, year_set)
end

function bea_goods_sectors!(GU)
	@create_set!(GU,:i,"BEA Goods and sectors categories",begin
		ppd,	"Paper products manufacturing (322)"
		res,	"Food services and drinking places (722)"
		com,	"Computer systems design and related services (5415)"
		amb,	"Ambulatory health care services (621)"
		fbp,	"Food and beverage and tobacco products manufacturing (311-312)"
		rec,	"Amusements, gambling, and recreation industries (713)"
		con,	"Construction (23)"
		agr,	"Farms (111-112)"
		eec,	"Electrical equipment, appliance, and components manufacturing (335)"
		use,	"Scrap, used and secondhand goods"
		fnd,	"Federal general government (nondefense) (GFGN)"
		pub,	"Publishing industries, except Internet (includes software) (511)"
		hou,	"Housing (HS)"
		fbt,	"Food and beverage stores (445)"
		ins,	"Insurance carriers and related activities (524)"
		tex,	"Textile mills and textile product mills (313-314)"
		leg,	"Legal services (5411)"
		fen,	"Federal government enterprises (GFE)"
		uti,	"Utilities (22)"
		nmp,	"Nonmetallic mineral products manufacturing (327)"
		brd,	"Broadcasting and telecommunications (515, 517)"
		bnk,	"Federal Reserve banks, credit intermediation, and related services (521-522)"
		ore,	"Other real estate (ORE)"
		edu,	"Educational services (61)"
		ote,	"Other transportation equipment manufacturing (3364-3366, 3369)"
		man,	"Management of companies and enterprises (55)"
		mch,	"Machinery manufacturing (333)"
		dat,	"Data processing, internet publishing, and other information services (518, 519)"
		amd,	"Accommodation (721)"
		oil,	"Oil and gas extraction (211)"
		hos,	"Hospitals (622)"
		rnt,	"Rental and leasing services and lessors of intangible assets (532-533)"
		pla,	"Plastics and rubber products manufacturing (326)"
		fof,	"Forestry, fishing, and related activities (113-115)"
		fin,	"Funds, trusts, and other financial vehicles (525)"
		tsv,	"Miscellaneous professional, scientific, and technical services (5412-5414, 5416-5419)"
		nrs,	"Nursing and residential care facilities (623)"
		sec,	"Securities, commodity contracts, and investments (523)"
		art,	"Performing arts, spectator sports, museums, and related activities (711-712)"
		mov,	"Motion picture and sound recording industries (512)"
		fpd,	"Furniture and related products manufacturing (337)"
		slg,	"State and local general government (GSLG)"
		pri,	"Printing and related support activities (323)"
		grd,	"Transit and ground passenger transportation (485)"
		pip,	"Pipeline transportation (486)"
		sle,	"State and local government enterprises (GSLE)"
		osv,	"Other services, except government (81)"
		trn,	"Rail transportation (482)"
		smn,	"Support activities for mining (213)"
		fmt,	"Fabricated metal products (332)"
		pet,	"Petroleum and coal products manufacturing (324)"
		mvt,	"Motor vehicle and parts dealers (441)"
		cep,	"Computer and electronic products manufacturing (334)"
		wst,	"Waste management and remediation services (562)"
		mot,	"Motor vehicles, bodies and trailers, and parts manufacturing (3361-3363)"
		adm,	"Administrative and support services (561)"
		soc,	"Social assistance (624)"
		alt,	"Apparel and leather and allied products manufacturing (315-316)"
		pmt,	"Primary metals manufacturing (331)"
		trk,	"Truck transportation (484)"
		fdd,	"Federal general government (defense) (GFGD)"
		gmt,	"General merchandise stores (452)"
		wtt,	"Water transportation (483)"
		wpd,	"Wood products manufacturing (321)"
		wht,	"Wholesale trade (42)"
		oth,	"Noncomparable imports and rest-of-the-world adjustment"
		wrh,	"Warehousing and storage (493)"
		ott,	"Other retail (4A0)"
		che,	"Chemical products manufacturing (325)"
		air,	"Air transportation (481)"
		mmf,	"Miscellaneous manufacturing (339)"
		otr,	"Other transportation and support activities (487-488, 492)"
		min,	"Mining, except oil and gas (212)"
	end)
    GU
end

function WiNDC_regions!(GU)
	@create_set!(GU,:r,"States in the WiNDC database",begin                
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