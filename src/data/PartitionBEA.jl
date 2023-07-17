
"""


At the moment several paths are hard coded. This will need to change.

I suggest making a directory with a helper JSON to point to all the necessary 
data. 
"""
function load_bea_data(use_path::String,supply_path::String)


    GU = load_universe("./windc_sets")

    @create_parameters(GU,begin
        #Use
        :id0, (:yr,:i,:j), "Intermediate Demand"
        :fd0, (:yr,:i,:fd), "Final Demand"
        :x0, (:yr,:i), "Exports"
        :va0, (:yr, :va,:j), "Value Added"
        :ts0, (:yr,:ts,:j), "Taxes and Subsidies"
        :othtax, (:yr,:j), "Other taxes"

        #Supply
        :ys0, (:yr,:j,:i), "Intermediate Supply"
        :m0, (:yr,:i),   "Imports"
        :mrg0, (:yr,:i), "Trade Margins"
        :trn0, (:yr,:i), "Transportation Costs"
        :cif0, (:yr,:i), ""
        :duty0,(:yr,:i), "Import Duties"
        :tax0, (:yr,:i), "Taxes on Products"
        :sbd0, (:yr,:i), "Subsidies"
    end);


    #BEA Map

    X = CSV.File("./mappings/BEA/bea_all.csv",stringtype = String)
    codes = [row[:bea_code] for row in X]
    windc_label = Symbol.([row[:windc_label] for row in X])
    bea_map = Dict(zip(codes,windc_label));


    use = XLSX.readxlsx(use_path)
    supply = XLSX.readxlsx(supply_path)

    for year in GU[:yr]
        load_use_year!(GU,use,year,bea_map)
        load_supply_year!(GU,supply,year,bea_map)
    end



    return GU

end









function load_use_year!(GU::GamsUniverse,use_table,year::Symbol,bea_map)

    yr = String(year)
    #year = Symbol(yr)

    Y = use_table[yr][:]

    Y[(Y .== "...") .& (.!ismissing.(Y))] .=0

    row_labels = Y[:,1]
    column_labels = Y[6,:]

    fd_range = [i for i in 75:93 if i!=81]


    commodities = get.(Ref(bea_map),row_labels[8:80],missing)
    industries = get.(Ref(bea_map),column_labels[3:73],missing)
    value_added = get.(Ref(bea_map),row_labels[82:84],missing)
    final_demand = get.(Ref(bea_map),column_labels[fd_range],missing)
    tax_labels = get.(Ref(bea_map), row_labels[87:88],missing)


    GU[:id0][[year],commodities,industries] = Float64.(Y[8:80,3:73])/1_000;
    GU[:va0][[year],value_added,industries] = Float64.(Y[82:84,3:73])/1_000;
    GU[:fd0][[year],commodities,final_demand] = Float64.(Y[8:80,fd_range])/1_000;
    GU[:x0][[year],commodities] = Float64.(Y[8:80,81])/1_000;
    GU[:ts0][[year],tax_labels,industries] = Float64.(Y[87:88,3:73]);

    return GU

end


function load_supply_year!(GU::GamsUniverse,supply_table,year::Symbol,bea_map)

    yr = String(year)
    #year = Symbol(yr)
    
    Y = supply_table[yr][:]
    
    Y[(Y .== "...") .& (.!ismissing.(Y))] .=0
    
    row_labels = Y[:,1]
    column_labels = Y[6,:]
    
    commodities = get.(Ref(bea_map),row_labels[8:80],missing)
    industries = get.(Ref(bea_map),column_labels[3:73],missing)
    
    GU[:ys0][[year],industries,commodities] = transpose(Float64.(Y[8:80,3:73])/1_000);
    GU[:m0][[year],commodities]    = Float64.(Y[8:80,75])/1_000;
    GU[:cif0][[year],commodities]  = Float64.(Y[8:80,76])/1_000;
    GU[:mrg0][[year],commodities]  = Float64.(Y[8:80,78])/1_000
    GU[:trn0][[year],commodities]  = Float64.(Y[8:80,79])/1_000
    GU[:duty0][[year],commodities] = Float64.(Y[8:80,81])/1_000
    GU[:tax0][[year],commodities]  = Float64.(Y[8:80,82])/1_000
    GU[:sbd0][[year],commodities]  = -Float64.(Y[8:80,83])/1_000
    
    return GU

end

