function load_bea_data(use_path::String,supply_path::String)


    GU = load_universe("windc_sets")

    #########
    ## Use ##
    #########

    @create_parameters(GU,begin
        :id0, (:yr,:i,:j), "Intermediate Demand"
        :fd0, (:yr,:i,:fd), "Final Demand"
        :x0, (:yr,:i), "Exports"
        :va0, (:yr, :va,:j), "Value Added"
        :ts0, (:yr,:ts,:j), "Taxes and Subsidies"
        :othtax, (:yr,:j), "Other taxes"
    end);

    X = CSV.File("mappings/BEA/bea_all.csv",stringtype = String)
    codes = [row[:bea_code] for row in X]
    windc_label = Symbol.([row[:windc_label] for row in X])
    bea_map = Dict(zip(codes,windc_label));


    use = XLSX.readxlsx(use_path)

    for year in GU[:yr]
        load_use_year!(GU,use,year,bea_map)
    end



    return GU

end









function load_use_year!(GU::GamsUniverse,use_table,year::Symbol,bea_map)

    yr = String(year)
    #year = Symbol(yr)

    Y = use_table[yr][:]

    row_labels = Y[:,1]
    column_labels = Y[6,:]

    fd_range = [i for i in 75:93 if i!=81]

    id0 = Y[8:80,3:73]
    id0[id0 .== "..."] .=0.0
    id0 = Float64.(id0)/1_000

    va0 = Y[82:84,3:73]
    va0[va0 .== "..."] .=0.0
    va0 = Float64.(va0)/1_000

    fd0 = Y[8:80,fd_range]
    fd0[fd0 .== "..."] .=0.0
    fd0 = Float64.(fd0)/1_000

    x0 = Y[8:80,81]
    x0[x0 .== "..."] .= 0.0
    x0 = Float64.(x0)/1_000

    tax = Y[87:88,3:73]
    tax[tax.=="..."].=0.0
    tax = Float64.(tax)

    commodities = get.(Ref(bea_map),row_labels[8:80],missing)
    industries = get.(Ref(bea_map),column_labels[3:73],missing)
    value_added = get.(Ref(bea_map),row_labels[82:84],missing)
    final_demand = get.(Ref(bea_map),column_labels[fd_range],missing)
    tax_labels = get.(Ref(bea_map), row_labels[87:88],missing)


    GU[:id0][[year],commodities,industries] = id0;
    GU[:va0][[year],value_added,industries] = va0;
    GU[:fd0][[year],commodities,final_demand] = fd0;
    GU[:x0][[year],commodities] = x0;
    GU[:ts0][[year],tax_labels,industries] = tax;

    return GU

end

1;
