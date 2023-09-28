include("./bea_api/bea_api.jl")
include("./calibrate.jl")

function _bea_io_initialize_universe(set_path="./windc_sets")

    GU = load_universe(set_path)

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


    return GU
end

function _bea_io_fill_parameter!(GU,df_full,parm,col_set_link,additional_filters)
    df = deepcopy(df_full)

    for s in domain(GU[parm])
        col = col_set_link[s]
        filter!(col => x-> x in GU[s], df)
    end

    if parm in keys(additional_filters)
        
        col, good = additional_filters[parm]
        filter!(col => x-> x == good, df)
    end

    columns = [col_set_link[e] for e in domain(GU[parm])]
    for row in eachrow(df)
        d = [[row[e]] for e∈columns]
        GU[parm][d...] = row[:DataValue]
    end

end



struct WiNDC_notation
    data::DataFrame
    default::Symbol
end

struct notation_link
    data::WiNDC_notation
    dirty::Symbol
    clean::Symbol
end


function apply_notation!(df, notation)
    windc_data = notation.data
    data = windc_data.data
    default = windc_data.default

    dirty = notation.dirty
    clean = notation.clean

    if default != clean
        cols = [clean,default]
    else
        cols = [clean]
    end

    df = innerjoin(data[!,cols],df,on = clean => dirty)

    if default != clean
        select!(df,Not(clean))
    end

    return df

end


"""
    load_bea_data_api(api_key::String,set_path,data_defines_path)

Load the the BEA data using the BEA API. 

In order to use this you must have an api key from the BEA. [Register here](https://apps.bea.gov/api/signup/)
to obtain an key.

Currently (Septerber 28, 2023) this will only return years 2017-2022 due
to the BEA restricting the API. 
"""
function load_bea_data_api(api_key::String,set_path,data_defines_path)

    GU = _bea_io_initialize_universe(set_path)


    load_supply_use_api!(GU,api_key,data_defines_path)

    _bea_data_break!(GU)

    calibrate_national!(GU)

    return GU

end

"""
    load_bea_data_local(use_path::String,
                        supply_path::String,
                        set_path::String,
                        map_path::String)

Load the BEA data from a local XLSX file. This data is available
[at the WiNDC webpage](https://windc.wisc.edu/downloads.html). The use table is

    windc_2021/BEA/IO/Use_SUT_Framework_1997-2021_SUM.xlsx 
    
and the supply table is

    windc_2021/BEA/IO/Supply_Tables_1997-2021_SUM.xlsx
"""
function load_bea_data_local(use_path::String,
                             supply_path::String,
                             set_path::String,
                             map_path::String)

    #set_path = "./windc_sets"
    #map_path = "./bea_io/bea_all.csv"

    GU = _bea_io_initialize_universe(set_path)

     #BEA Map

     X = CSV.File(map_path,stringtype = String)
     codes = [row[:bea_code] for row in X]
     windc_label = Symbol.([row[:windc_label] for row in X])
     bea_map = Dict(zip(codes,windc_label));
 
 
     #Read use/supply tables.
 
     use = XLSX.readxlsx(use_path)
     supply = XLSX.readxlsx(supply_path)
 
     for year in GU[:yr]
         load_use_year!(GU,use,year,bea_map)
         load_supply_year!(GU,supply,year,bea_map)
     end

     _bea_data_break!(GU)

     calibrate_national!(GU)

     return GU


end


function _bea_data_break!(GU)

    # Define parameters

    GU[:id0][:yr,:i,:j] = GU[:id0][:yr,:i,:j] .- permutedims(min.(0,GU[:ys0][:yr,:j,:i]),[1,3,2])
    GU[:ys0][:yr,:j,:i] = GU[:ys0][:yr,:j,:i] - min.(0,permutedims(GU[:id0][:yr,:i,:j],[1,3,2]))

    GU[:ys0][:yr,:j,:i] = max.(0,GU[:ys0][:yr,:j,:i])
    GU[:id0][:yr,:i,:j] = max.(0,GU[:id0][:yr,:i,:j])


    iₘ  = [e for e ∈GU[:i] if e!=:ins]

    GU[:trn0][:yr,iₘ] = GU[:trn0][:yr,iₘ] .+ GU[:cif0][:yr,iₘ]
    GU[:m0][:yr,[:ins]] = GU[:m0][:yr,[:ins]] .+ GU[:cif0][:yr,[:ins]]

    # Second phase

    # More parameters

    @create_parameters(GU,begin
        :s0, (:yr,:j), "Aggregate Supply"
        :ms0, (:yr,:i,:m), "Margin Supply"
        :md0, (:yr,:m,:i), "Margin Demand"
        :fs0, (:yr,:i), "Household Supply"
        :y0, (:yr,:i), "Gross Output"
        :a0, (:yr,:i), "Armington Supply"
        :tm0, (:yr,:i), "Tax net subsidy rate on intermediate demand"
        :ta0, (:yr,:i), "Import Tariff"
        :ty0, (:yr,:j), "Output tax rate"
    end);

    GU[:s0][:yr,:j] = sum(GU[:ys0][:yr,:j,:i],dims=2);

    GU[:ms0][:yr,:i,[:trd]] = -min.(0, GU[:mrg0][:yr,:i])
    GU[:ms0][:yr,:i,[:trn]] = -min.(0, GU[:trn0][:yr,:i])

    GU[:md0][:yr,[:trd],:i] = max.(0, GU[:mrg0][:yr,:i])
    GU[:md0][:yr,[:trn],:i] = max.(0, GU[:trn0][:yr,:i])

    GU[:fs0][:yr,:i] = -min.(0, GU[:fd0][:yr,:i,[:pce]])




    GU[:y0][:yr,:i] = dropdims(sum(GU[:ys0][:yr,:j,:i],dims=2),dims=2) + GU[:fs0][:yr,:i] - dropdims(sum(GU[:ms0][:yr,:i,:m],dims=3),dims=3)

    GU[:a0][:yr,:i] = sum(GU[:id0][:yr,:i,:j],dims=3) + sum(GU[:fd0][:yr,:i,:fd],dims=3)


    mask = GU[:m0][:yr,:i] .>0
    GU[:tm0][mask] = GU[:duty0][mask]./GU[:m0][mask]

    mask = GU[:a0][:yr,:i] .!= 0
    GU[:ta0][mask] = (GU[:tax0][mask] - GU[:sbd0][mask]) ./ GU[:a0][mask]

    mask = dropdims(sum(GU[:ys0][:yr,:j,:i],dims=3) .!= 0,dims=3)
    othtax = GU[:va0][:yr,[:othtax],:i]
    s0 = dropdims(sum(GU[:ys0][:yr,:j,:i],dims=3),dims=3)
    GU[:ty0][mask]  = othtax[mask] ./ s0[mask]


    #####################
    ## Negative Values ##
    #####################


    GU[:a0][:yr,:i] = max.(0, GU[:a0][:yr,:i])
    GU[:x0][:yr,:i] = max.(0, GU[:x0][:yr,:i])
    GU[:y0][:yr,:i] = max.(0, GU[:y0][:yr,:i])



    GU[:fd0][:yr,:i,[:pce]] = max.(0, GU[:fd0][:yr,:i,[:pce]]);

    #THis is stupid.
    GU[:duty0][GU[:m0].==0] = (GU[:duty0][GU[:m0].==0] .=1);

    m_shr = GamsParameter(GU,(:i,))
    va_shr = GamsParameter(GU,(:va,:j))

    m_shr[:i] = transpose(sum(GU[:m0][:yr,:i],dims = 1)) ./ sum(GU[:m0][:yr,:i])
    va_shr[:va,:j] = dropdims(sum(GU[:va0][:yr,:va,:j],dims=1) ./ sum(GU[:va0][:yr,:va,:j],dims=(1,2)),dims=1)

    for yr∈GU[:yr],i∈GU[:i]
        GU[:m0][[yr],[i]] = GU[:m0][[yr],[i]]<0 ? m_shr[[i]]*sum(GU[:m0][[yr],:]) : GU[:m0][[yr],[i]] 
    end

    for year∈GU[:yr]
        #mask = GU[:m0][[year],:i] .< 0
        #GU[:m0][[year],mask] = m_shr[mask]*sum(GU[:m0][[year],mask])

        for va∈GU[:va], j∈GU[:j]
            GU[:va0][[year],[va],[j]] = GU[:va0][[year],[va],[j]]<0 ? va_shr[[va],[j]]*sum(GU[:va0][[year],:va,[j]]) : GU[:va0][[year],[va],[j]]
        end
    end

    # Non-tracked marginal categories.

    IMRG = [:mvt,:fbt,:gmt]


    for yr∈GU[:yr],i∈IMRG
        GU[:y0][[yr],[i]] = 0
        GU[:a0][[yr],[i]] = 0
        GU[:tax0][[yr],[i]] = 0
        GU[:sbd0][[yr],[i]] = 0
        GU[:x0][[yr],[i]] = 0
        GU[:m0][[yr],[i]] = 0
        GU[:duty0][[yr],[i]] = 0
        for m∈GU[:m]    
            GU[:md0][[yr],[m],[i]] = 0
        end
    end
    
    #I disagree with this. I don't recall why, I'll figure it out.
    for yr∈GU[:yr],j∈GU[:j]
        GU[:va0][[yr],[:othtax],[j]] = 0
    end

    return GU

end





function load_supply_use_api!(GU,api_key::String, data_defines_path::String)

    use = get_bea_io_table(api_key,:use)
    supply = get_bea_io_table(api_key,:supply);

    include(data_defines_path)
    notations = []
    push!(notations,notation_link(bea_commodity,:RowCode,:bea_code))
    push!(notations,notation_link(bea_industry,:ColCode,:bea_code))

    for notation in notations
        use = apply_notation!(use,notation)
        supply = apply_notation!(supply,notation)
    end
    
    use[!,:industry] = Symbol.(use[!,:industry])
    use[!,:commodity] = Symbol.(use[!,:commodity])
    use[!,:Year] = Symbol.(use[!,:Year]);
    
    supply[!,:industry] = Symbol.(supply[!,:industry])
    supply[!,:commodity] = Symbol.(supply[!,:commodity])
    supply[!,:Year] = Symbol.(supply[!,:Year]);


    col_set_link = Dict(:yr => :Year, 
                    :j => :industry, 
                    :i => :commodity,
                    :fd => :industry,
                    :va => :commodity,
                    :ts => :commodity
    )

    additional_filters = Dict(
        :othtax => (:commodity,:othtax),
        :x0 => (:industry, :exports),

        :m0 => (:industry, :imports),
        :mrg0 => (:industry, :Margins),
        :trn0 => (:industry, :TrnCost),
        :cif0 => (:industry, :ciffob),
        :duty0 => (:industry, :Duties),
        :tax0 => (:industry, :Tax),
        :sbd0 => (:industry, :subsidies)
    )

    #Use
    for parm in [:id0,:fd0,:va0,:ts0,:othtax,:x0]
        _bea_io_fill_parameter!(GU, use, parm, col_set_link, additional_filters)
    end



    #Supply
    for parm in [:ys0,:m0,:mrg0,:trn0,:cif0,:duty0,:tax0,:sbd0]
        _bea_io_fill_parameter!(GU, supply, parm, col_set_link, additional_filters)
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
    value_added = get.(Ref(bea_map),row_labels[82:83],missing)
    push!(value_added, get(bea_map, row_labels[85],missing))
    final_demand = get.(Ref(bea_map),column_labels[fd_range],missing)
    tax_labels = get.(Ref(bea_map), row_labels[88:89],missing)

    GU[:id0][[year],commodities,industries] = Float64.(Y[8:80,3:73])/1_000;
    GU[:va0][[year],value_added,industries] = Float64.(Y[82:84,3:73])/1_000;
    GU[:fd0][[year],commodities,final_demand] = Float64.(Y[8:80,fd_range])/1_000;
    GU[:x0][[year],commodities] = Float64.(Y[8:80,81])/1_000;
    GU[:ts0][[year],tax_labels,industries] = Float64.(Y[87:88,3:73])/1_000;

    GU[:ts0][[year],[:subsidies],:j] = - GU[:ts0][[year],[:subsidies],:j]

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

