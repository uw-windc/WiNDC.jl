gsp_industry_id = DataFrame([
    [4,5,7,8,9,10,11,14,15,16,17,18,19,20,21,22,23,24,26,
    27,28,29,30,31,32,33,34,35,37,38,39,40,41,42,43,44,
    46,47,48,49,52,53,54,55,57,58,61,62,63,64,66,67,69,
    71,72,73,76,77,79,80,81,83,84,85,]
],[:gsp_industry_id])

gsp_industry_id = WiNDC_notation(gsp_industry_id,:gsp_industry_id);


bea_gsp_map = DataFrame([
("Gross domestic product (GDP) by state","gdp"),
("Taxes on production and imports less subsidies","taxsbd"),
("Compensation of employees","cmp"),
("Subsidies","sbd"),
("Taxes on production and imports","tax"),
("Gross operating surplus","gos"),
("Quantity indexes for real GDP by state (2012=100.0)","qty"),
("Real GDP by state","rgdp")],
[:bea_code,:gdpcat])

bea_gsp_map = WiNDC_notation(bea_gsp_map,:gdpcat)

regions = DataFrame([
    ("Alabama", "AL", "1"),
    ("Alaska", "AK", "2"),
    ("Arizona", "AZ", "4"),
    ("Arkansas", "AR", "5"),
    ("California", "CA", "6"),
    ("Colorado", "CO", "8"),
    ("Connecticut", "CT", "9"),
    ("Delaware", "DE", "10"),
    ("District of Columbia", "DC", "11"),
    ("Florida", "FL", "12"),
    ("Georgia", "GA", "13"),
    ("Hawaii", "HI", "15"),
    ("Idaho", "ID", "16"),
    ("Illinois", "IL", "17"),
    ("Indiana", "IN", "18"),
    ("Iowa", "IA", "19"),
    ("Kansas", "KS", "20"),
    ("Kentucky", "KY", "21"),
    ("Louisiana", "LA", "22"),
    ("Maine", "ME", "23"),
    ("Maryland", "MD", "24"),
    ("Massachusetts", "MA", "25"),
    ("Michigan", "MI", "26"),
    ("Minnesota", "MN", "27"),
    ("Mississippi", "MS", "28"),
    ("Missouri", "MO", "29"),
    ("Montana", "MT", "30"),
    ("Nebraska", "NE", "31"),
    ("Nevada", "NV", "32"),
    ("New Hampshire", "NH", "33"),
    ("New Jersey", "NJ", "34"),
    ("New Mexico", "NM", "35"),
    ("New York", "NY", "36"),
    ("North Carolina", "NC", "37"),
    ("North Dakota", "ND", "38"),
    ("Ohio", "OH", "39"),
    ("Oklahoma", "OK", "40"),
    ("Oregon", "OR", "41"),
    ("Pennsylvania", "PA", "42"),
    ("Rhode Island", "RI", "44"),
    ("South Carolina", "SC", "45"),
    ("South Dakota", "SD", "46"),
    ("Tennessee", "TN", "47"),
    ("Texas", "TX", "48"),
    ("Utah", "UT", "49"),
    ("United States", "US", "00"),
    ("Vermont", "VT", "50"),
    ("Virginia", "VA", "51"),
    ("Washington", "WA", "53"),
    ("West Virginia", "WV", "54"),
    ("Wisconsin", "WI", "55"),
    ("Wyoming", "WY", "56"),
],[:region_fullname,:region_abbv,:fips_state])

states = WiNDC_notation(DataFrame(regions,[:region_fullname,:region_abbv,:fips_state]),:region_abbv)