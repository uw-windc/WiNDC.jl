pce_map = DataFrame([
    ("Personal consumption expenditures", "pce")
    ("Goods", "gds")
    ("Durable goods", "dur")
    ("Motor vehicles and parts", "mvp")
    ("Furnishings and durable household equipment", "hdr")
    ("Recreational goods and vehicles", "rec")
    ("Other durable goods", "odg")
    ("Nondurable goods", "ndr")
    ("Food and beverages purchased for off-premises consumption", "foo")
    ("Clothing and footwear", "clo")
    ("Gasoline and other energy goods", "enr")
    ("Other nondurable goods", "ong")
    ("Services", "ser")
    ("Household consumption expenditures (for services)", "hce")
    ("Housing and utilities", "utl")
    ("Health care", "hea")
    ("Transportation services", "trn")
    ("Recreation services", "rsr")
    ("Food services and accommodations", "htl")
    ("Financial services and insurance", "fsr")
    ("Other services", "osr")
    ("Final consumption expenditures of nonprofit institutions serving households (NPISHs)", "npish")
    ("Gross output of nonprofit institutions", "npi")
    ("Less: Receipts from sales of goods and services by nonprofit institutions", "nps")
], [:pce_description, :pce]
)

pce_map = WiNDC.WiNDC_notation(pce_map,:pce);


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
    ("Vermont", "VT", "50"),
    ("Virginia", "VA", "51"),
    ("Washington", "WA", "53"),
    ("West Virginia", "WV", "54"),
    ("Wisconsin", "WI", "55"),
    ("Wyoming", "WY", "56"),
],[:region_fullname,:region_abbv,:fips_state])

pce_states = WiNDC.WiNDC_notation(regions,:region_abbv)



pce_map_gams = DataFrame([
    ("agr","foo"),
    ("fof","rec"),
    ("oil","enr"),
    ("min","enr"),
    ("smn","ong"),
    ("uti","utl"),
    ("con","odg"),
    ("fbp","foo"),
    ("tex","clo"),
    ("alt","clo"),
    ("wpd","hdr"),
    ("ppd","odg"),
    ("pri","odg"),
    ("pet","odg"),
    ("che","odg"),
    ("pla","odg"),
    ("nmp","odg"),
    ("pmt","odg"),
    ("fmt","odg"),
    ("mch","odg"),
    ("cep","rec"),
    ("eec","rec"),
    ("mot","mvp"),
    ("ote","mvp"),
    ("fpd","hdr"),
    ("mmf","odg"),
    ("wht","odg"),
    ("mvt","mvp"),
    ("fbt","foo"),
    ("gmt","ong"),
    ("ott","ong"),
    ("air","trn"),
    ("trn","trn"),
    ("wtt","trn"),
    ("trk","trn"),
    ("grd","trn"),
    ("pip","trn"),
    ("otr","trn"),
    ("wrh","osr"),
    ("pub","osr"),
    ("mov","osr"),
    ("brd","osr"),
    ("dat","osr"),
    ("bnk","fsr"),
    ("sec","fsr"),
    ("ins","fsr"),
    ("fin","fsr"),
    ("hou","utl"),
    ("ore","utl"),
    ("rnt","rsr"),
    ("leg","osr"),
    ("com","osr"),
    ("tsv","osr"),
    ("man","osr"),
    ("adm","osr"),
    ("wst","utl"),
    ("edu","hce"),
    ("amb","hea"),
    ("hos","hea"),
    ("nrs","hea"),
    ("soc","hea"),
    ("art","rsr"),
    ("rec","rsr"),
    ("amd","rsr"),
    ("res","htl"),
    ("osv","osr"),
    ("fdd","npi"),
    ("fnd","npi"),
    ("fen","npi"),
    ("slg","npi"),
    ("sle","npi"),
    ("use","npi"),
    ("oth","npi")
    ],[:i,:pce])

pce_map_gams = WiNDC.WiNDC_notation(pce_map_gams,:i)
