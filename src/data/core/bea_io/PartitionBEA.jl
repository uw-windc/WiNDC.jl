#include("./bea_api/bea_api.jl")
include("./calibrate.jl")
#include("./data_defines.jl")



function _bea_io_initialize_universe!(GU)


    @parameters(GU,begin
        #Use
        id0, (:yr,:i,:j), (description = "Intermediate Demand",)
        fd0, (:yr,:i,:fd), (description = "Final Demand",)
        x0, (:yr,:i), (description = "Exports",)
        va0, (:yr, :va,:j), (description = "Value Added",)
        ts0, (:yr,:ts,:j), (description = "Taxes and Subsidies",)
        othtax, (:yr,:j), (description = "Other taxes",)

        #Supply
        ys0, (:yr,:j,:i), (description = "Intermediate Supply",)
        m0, (:yr,:i),   (description = "Imports",)
        mrg0, (:yr,:i), (description = "Trade Margins",)
        trn0, (:yr,:i), (description = "Transportation Costs",)
        cif0, (:yr,:i)
        duty0,(:yr,:i), (description = "Import Duties",)
        tax0, (:yr,:i), (description = "Taxes on Products",)
        sbd0, (:yr,:i), (description = "Subsidies",)
    end);


    return GU
end




"""
    load_bea_data_api(GU::GamsUniverse,api_key::String)

Load the the BEA data using the BEA API. 

In order to use this you must have an api key from the BEA. [Register here](https://apps.bea.gov/api/signup/)
to obtain an key.

Currently (Septerber 28, 2023) this will only return years 2017-2022 due
to the BEA restricting the API. 
"""
function load_bea_data_api(GU::GamsUniverse,api_key::String)

    _bea_io_initialize_universe!(GU)

    load_supply_use_api!(GU,api_key)

    _bea_data_break!(GU)

    calibrate_national!(GU)

    return GU

end

"""
    load_bea_io!(GU::GamsUniverse,
                 data_dir::String,
                 info_dict
                 )

Load the BEA data from a local XLSX file. This data is available
[at the WiNDC webpage](https://windc.wisc.edu/downloads.html). The use table is

    windc_2021/BEA/IO/Use_SUT_Framework_1997-2021_SUM.xlsx 
    
and the supply table is

    windc_2021/BEA/IO/Supply_Tables_1997-2021_SUM.xlsx
"""
function load_bea_io!(GU::GamsUniverse,
                     data_dir::String,
                     info_dict
                     )

    _bea_io_initialize_universe!(GU)

    use_path = joinpath(data_dir,info_dict["use"])
    use = _load_table_local(use_path)

    supply_path = joinpath(data_dir,info_dict["supply"])
    supply = _load_table_local(supply_path)

    _bea_apply_notations!(GU,use,supply)

    _bea_data_break!(GU)

    (_,models) = calibrate_national!(GU)

    return (GU, models)


end


function load_supply_use_api!(GU,api_key::String)

    use = get_bea_io_table(api_key,:use)
    supply = get_bea_io_table(api_key,:supply);

    _bea_apply_notations!(GU,use,supply)

    return GU
end




function _bea_apply_notations!(GU,use,supply)


    notations = bea_io_notations()

    use = apply_notations(use,notations)
    supply = apply_notations(supply,notations)

    
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
        :sbd0 => (:industry, :Subsidies)
    )


    #Use
    for parm in [:id0,:fd0,:va0,:ts0,:othtax,:x0]
       fill_parameter!(GU, use, parm, col_set_link, additional_filters)
    end



    #Supply
    for parm in [:ys0,:m0,:mrg0,:trn0,:cif0,:duty0,:tax0,:sbd0]
        fill_parameter!(GU, supply, parm, col_set_link, additional_filters)
    end

    GU[:sbd0][:yr,:i] = - GU[:sbd0][:yr,:i]

    return GU
end




function _load_table_local(path::String)
    X = XLSX.readxlsx(path);

    df = DataFrame()
    
    for sheet in XLSX.sheetnames(X)
        Y = X[sheet][:]
        rows,cols = size(Y)
        Y[(Y .== "...") .& (.!ismissing.(Y))] .= missing
    
        col_names = ["RowCode","RowDescription"]
        append!(col_names,vec(Y[6,3:cols]))

        df1 = DataFrame(Y[8:rows,1:cols], col_names)
        df1 = stack(df1, Not([:RowCode,:RowDescription]),variable_name = :ColCode, value_name = :value)
        df1[!,:Year] .= sheet
        df1 = df1[.!ismissing.(df1[!,:value]),[:Year,:RowCode,:ColCode,:value]]  
        df1[!,:value] = df1[!,:value]./1_000
        df = vcat(df,df1)
    end
    
    return df

end




function _bea_data_break!(GU)

    # Define parameters

    
    GU[:ys0][:yr,:j,:i] = GU[:ys0][:yr,:j,:i] - min.(0,permutedims(GU[:id0][:yr,:i,:j],[1,3,2]))


    GU[:id0][:yr,:i,:j] = max.(0,GU[:id0][:yr,:i,:j])

    GU[:ts0][:yr,[:subsidies],:j] = -GU[:ts0][:yr,[:subsidies],:j]

    

    # Adjust transport margins for transport sectors according to CIF/FOB
    # adjustments. Insurance imports are specified as net of adjustments.
    iₘ  = [e for e ∈GU[:i] if e!=:ins]

    GU[:trn0][:yr,iₘ] = GU[:trn0][:yr,iₘ] .+ GU[:cif0][:yr,iₘ]
    GU[:m0][:yr,[:ins]] = GU[:m0][:yr,[:ins]] .+ GU[:cif0][:yr,[:ins]]


 

    # Second phase

    # More parameters

    @parameters(GU,begin
        s0, (:yr,:j), (description = "Aggregate Supply",)
        ms0, (:yr,:i,:m), (description = "Margin Supply",)
        md0, (:yr,:m,:i), (description = "Margin Demand",)
        fs0, (:yr,:i), (description = "Household Supply",)
        y0, (:yr,:i), (description = "Gross Output",)
        a0, (:yr,:i), (description = "Armington Supply",)
        tm0, (:yr,:i), (description = "Tax net subsidy rate on intermediate demand",)
        ta0, (:yr,:i), (description = "Import Tariff",)
        ty0, (:yr,:j), (description = "Output tax rate",)
    end);

    GU[:s0][:yr,:j] = sum(GU[:ys0][:yr,:j,:i],dims=2);

    GU[:ms0][:yr,:i,[:trd]] = -min.(0, GU[:mrg0][:yr,:i])
    GU[:ms0][:yr,:i,[:trn]] = -min.(0, GU[:trn0][:yr,:i])

    GU[:md0][:yr,[:trd],:i] = max.(0, GU[:mrg0][:yr,:i])
    GU[:md0][:yr,[:trn],:i] = max.(0, GU[:trn0][:yr,:i])

    GU[:fs0][:yr,:i] = -min.(0, GU[:fd0][:yr,:i,[:pce]])
    GU[:y0][:yr,:i] = dropdims(sum(GU[:ys0][:yr,:j,:i],dims=2),dims=2) + GU[:fs0][:yr,:i] - dropdims(sum(GU[:ms0][:yr,:i,:m],dims=3),dims=3)




    GU[:a0][:yr,:i] = sum(GU[:id0][:yr,:i,:j],dims=3) + sum(GU[:fd0][:yr,:i,:fd],dims=3)


    IMRG = [:mvt,:fbt,:gmt]

    GU[:y0][:yr,IMRG] = 0*GU[:y0][:yr,IMRG]
    GU[:a0][:yr,IMRG] = 0*GU[:a0][:yr,IMRG]
    GU[:tax0][:yr,IMRG] = 0*GU[:tax0][:yr,IMRG]
    GU[:sbd0][:yr,IMRG] = 0*GU[:sbd0][:yr,IMRG]
    GU[:x0][:yr,IMRG] = 0*GU[:x0][:yr,IMRG]
    GU[:m0][:yr,IMRG] = 0*GU[:m0][:yr,IMRG]
    GU[:md0][:yr,:m,IMRG] = 0*GU[:md0][:yr,:m,IMRG]
    GU[:duty0][:yr,IMRG] = 0*GU[:duty0][:yr,IMRG]

    #mask = GU[:m0][:yr,:i] .>0
    #mask = Mask(GU,(:yr,:i))
    #mask[:yr,:i] = (GU[:m0][:yr,:i] .> 0)
    #GU[:tm0][mask] = GU[:duty0][mask]./GU[:m0][mask]

    #mask = GU[:a0][:yr,:i] .!= 0
    #mask[:yr,:i] = (GU[:a0][:yr,:i] .!= 0)
    #GU[:ta0][mask] = (GU[:tax0][mask] - GU[:sbd0][mask]) ./ GU[:a0][mask]


    for yr∈GU[:yr],i∈GU[:i]
        if GU[:m0][yr,i] > 0
            GU[:tm0][yr,i] = GU[:duty0][yr,i]/GU[:m0][yr,i]
        end
        if GU[:a0][yr,i] != 0
            GU[:ta0][yr,i] = (GU[:tax0][yr,i] - GU[:sbd0][yr,i]) / GU[:a0][yr,i]
        end
    end



    #####################
    ## Negative Values ##
    #####################

    GU[:id0][:yr,:i,:j] = GU[:id0][:yr,:i,:j] .- permutedims(min.(0,GU[:ys0][:yr,:j,:i]),[1,3,2])
    GU[:ys0][:yr,:j,:i] = max.(0,GU[:ys0][:yr,:j,:i])

    GU[:a0][:yr,:i] = max.(0, GU[:a0][:yr,:i])
    GU[:x0][:yr,:i] = max.(0, GU[:x0][:yr,:i])
    GU[:y0][:yr,:i] = max.(0, GU[:y0][:yr,:i])



    GU[:fd0][:yr,:i,[:pce]] = max.(0, GU[:fd0][:yr,:i,[:pce]]);

    #THis is stupid.
    #GU[:duty0][GU[:m0].==0] = (GU[:duty0][GU[:m0].==0] .=1);
    for yr∈GU[:yr],i∈GU[:i]
        if GU[:m0][yr,i] == 0
            GU[:duty0][yr,i] = 1
        end
    end




    m_shr = GamsStructure.Parameter(GU,(:i,))
    va_shr = GamsStructure.Parameter(GU,(:j,:va))


    deactivate(GU,:i,:use,:oth)
    deactivate(GU,:j,:use,:oth)

    m_shr[:i] = transpose(sum(GU[:m0][:yr,:i],dims = 1)) ./ sum(GU[:m0][:yr,:i])
    va_shr[:j,:va] = permutedims(sum(GU[:va0][:yr,:va,:j],dims=1)./ sum(GU[:va0][:yr,:va,:j],dims=(1,2)),(3,2,1))

    for yr∈GU[:yr],i∈GU[:i]
        GU[:m0][[yr],[i]] = GU[:m0][[yr],[i]]<0 ? m_shr[[i]]*sum(GU[:m0][[yr],:i]) : GU[:m0][[yr],[i]] 
    end

    for year∈GU[:yr],va∈GU[:va], j∈GU[:j]
        GU[:va0][[year],[va],[j]] = GU[:va0][[year],[va],[j]]<0 ? va_shr[[j],[va]]*sum(GU[:va0][[year],:va,[j]]) : GU[:va0][[year],[va],[j]]
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

    GU[:ty0][:yr,:j] = GU[:othtax][:yr,:j] ./ sum(GU[:ys0][:yr,:j,:i],dims=3)

    for yr∈GU[:yr],j∈GU[:j]
        GU[:va0][[yr],[:othtax],[j]] = 0
    end

    return GU

end