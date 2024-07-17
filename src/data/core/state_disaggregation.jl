
function state_dissagregation(GU::GamsUniverse)

    #Construct new universe
    G = GamsUniverse()

    sets_to_transfer = Dict(
        :yr => :yr,
        :m => :m,
        :i => :s,
        :r => :r
    )
    
    #yr,r,s,m,gm,
    
    for (s,new_name) in sets_to_transfer
        elements = [e for e in GU[s].elements if e.active]
        add_set(G,new_name,GamsSet(elements,GU[s].description))
    end
    
    alias(G,:s,:g)

    @parameters(G,begin
        
        #Production Data
        ys0_,	(:yr, :r, :s, :g),	(description = "Regional sectoral output",)
        ld0_,	(:yr, :r, :s),	(description = "Labor demand",)
        kd0_,	(:yr, :r, :s),	(description = "Capital demand",)
        id0_,	(:yr, :r, :g, :s),	(description = "Regional intermediate demand",)
        ty0_,	(:yr, :r, :s),	(description = "Production tax rate",)

        #Consumption Data
        yh0_,	(:yr, :r, :s),	(description = "Household production",)
        fe0_,	(:yr, :r),	(description = "Total factor supply",)
        cd0_,	(:yr, :r, :s),	(description = "Consumption demand",)
        c0_,	(:yr, :r),	(description = "Total final household consumption",)
        i0_,	(:yr, :r, :s),	(description = "Investment demand",)
        g0_,	(:yr, :r, :s),	(description = "Government demand",)
        bopdef0_,	(:yr, :r),	(description = "Balance of payments (closure parameter)",)
        hhadj0_,	(:yr, :r),	(description = "Household adjustment parameter",)
        
        #Trade Data
        s0_,	(:yr, :r, :g),	(description = "Total supply",)
        xd0_,	(:yr, :r, :g),	(description = "Regional supply to local market",)
        xn0_,	(:yr, :r, :g),	(description = "Regional supply to national market",)
        x0_,	(:yr, :r, :g),	(description = "Foreign Exports",)
        rx0_,	(:yr, :r, :g),	(description = "Re-exports",)
        a0_,	(:yr, :r, :g),	(description = "Domestic absorption",)
        nd0_,	(:yr, :r, :g),	(description = "Regional demand from national market",)
        dd0_,	(:yr, :r, :g),	(description = "Regional demand from local market",)
        m0_,	(:yr, :r, :g),	(description = "Foreign Imports",)
        ta0_,	(:yr, :r, :g),	(description = "Absorption taxes",)
        tm0_,	(:yr, :r, :g),	(description = "Import taxes",)

        #Margins
        md0_,	(:yr, :r, :m, :g),	(description = "Margin demand",)
        dm0_,	(:yr, :r, :g, :m),	(description = "Margin supply from the local market",)
        nm0_,	(:yr, :r, :g, :m),	(description = "Margin demand from the national market",)
        
        #GDP
        gdp0_,	(:yr, :r),	(description = "Aggregate GDP",)
    end);



    #Regionalize production data using iomacro shares and GSP data:
    va0_ = GamsStructure.Parameter(G,(:yr,:r,:s);description = "Value Added")

    for r∈G[:r],s∈G[:s],g∈G[:g]
        G[:ys0_][:yr,[r],[s],[g]] = GU[:region_shr][:yr,[r],[s]] .* GU[:ys0][:yr,[s],[g]]
        G[:id0_][:yr,[r],[g],[s]] = GU[:region_shr][:yr,[r],[s]] .* GU[:id0][:yr,[g],[s]]
    end
    
    for r∈G[:r]
        va0_[:yr,[r],:s] = GU[:region_shr][:yr,[r],:i] .* (GU[:va0][:yr,[:compen],:i] .+ GU[:va0][:yr,[:surplus],:i])
    
        G[:ty0_][:yr,[r],:s] = GU[:ty0][:yr,:i];
    
        G[:ld0_][:yr,[r],:s] = GU[:labor_shr][:yr,[r],:i] .* va0_[:yr,[r],:s]
        G[:kd0_][:yr,[r],:s] = va0_[:yr,[r],:s] - G[:ld0_][:yr,[r],:s];
    
    end
    
    #sum(abs.(sum(G[:ys0_][:yr,:r,:s,[g]] for g∈G[:g]) .* (1 .- G[:ty0_][:yr,:r,:s]) .- (G[:ld0_][:yr,:r,:s] + G[:kd0_][:yr,:r,:s] + sum(G[:id0_][:yr,:r,[g],:s] for g∈G[:g]))))


    # Aggregate final demand categories:
    g_cat = [:defense,:def_structures,:def_equipment,:def_intelprop,:nondefense,:fed_structures,:fed_equipment,:fed_intelprop,:state_consume,:state_invest,:state_equipment,:state_intelprop]
    i_cat = [:structures,:equipment,:intelprop,:residential,:changinv]

    for r∈G[:r]

        G[:yh0_][:yr,[r],:s] = GU[:fs0][:yr,:i] .* GU[:region_shr][:yr,[r],:i]
        G[:fe0_][:yr,[r]] = sum(va0_[:yr,[r],[s]] for s∈G[:s])

        #* Use PCE and government demand data rather than region_shr:

        G[:cd0_][:yr,[r],:g] = GU[:pce_shr][:yr,[r],:j] .* sum(GU[:fd0][:yr,:j,[:pce]],dims=3);
        G[:g0_][:yr,[r],:g] = GU[:sgf_shr][:yr,[r],:j] .* sum(GU[:fd0][:yr,:j,[fd]] for fd∈g_cat)
        G[:i0_][:yr,[r],:g] = GU[:region_shr][:yr,[r],:j] .* sum(GU[:fd0][:yr,:j,[fd]] for fd∈i_cat)
        G[:c0_][:yr,[r]] = sum(G[:cd0_][:yr,[r],[g]] for g∈G[:g])

    end



    # Use export shares from USA Trade Online for included sectors. For those
    # not included, use gross state product shares:
    for yr∈G[:yr],g∈G[:g]
        if sum(GU[:usatrd_shr][[yr],:r,[g],[:exports]]) != 0
            G[:x0_][[yr],:r,[g]] = GU[:usatrd_shr][[yr],:r,[g],[:exports]] .* GU[:x0][[yr],[g]]
        else
            G[:x0_][[yr],:r,[g]] = GU[:region_shr][[yr],:r,[g]] * GU[:x0][[yr],[g]]
        end
    end


    # No longer subtracting margin supply from gross output. This will be allocated
    # through the national and local markets.
    for r∈G[:r]
        G[:s0_][:yr,[r],:g] = sum(G[:ys0_][:yr,[r],[s],:g] for s∈G[:s]) + G[:yh0_][:yr,[r],:g]
        G[:a0_][:yr,[r],:g] = G[:cd0_][:yr,[r],:g] + G[:g0_][:yr,[r],:g] + G[:i0_][:yr,[r],:g] + sum(G[:id0_][:yr,[r],:g,[s]] for s∈G[:s]);
    
        G[:tm0_][:yr,[r],:g] = GU[:tm0][:yr,:i]
        G[:ta0_][:yr,[r],:g] = GU[:ta0][:yr,:i]
    end

    thetaa = GamsStructure.Parameter(G,(:yr,:r,:g);description = "Share of regional absorption")

    for yr∈G[:yr],g∈G[:g]
        if sum((1 .- G[:ta0_][[yr],[r],[g]]) .* G[:a0_][[yr],[r],[g]] for r∈G[:r]) !=0
            thetaa[[yr],:r,[g]] = G[:a0_][[yr],:r,[g]] ./ sum(G[:a0_][[yr],[r],[g]] for r∈G[:r])
        end
    end

    for r∈G[:r]
        G[:m0_][:yr,[r],:g] = thetaa[:yr,[r],:g] .* GU[:m0][:yr,:i]
    end

    for r∈G[:r],m∈G[:m]
        G[:md0_][:yr,[r],[m],:g] = thetaa[:yr,[r],:g] .* GU[:md0][:yr,[m],:i];
    end

    # Note that s0_ - x0_ is negative for the other category. md0 is zero for that
    # category and: a + x = s + m. This means that some part of the other goods
    # imports are directly re-exported. Note, re-exports are defined as the maximum
    # between s0_-x0_ and the zero profit condition for the Armington
    # composite. This is due to balancing issues when defining domestic and national
    # demands. Particularly in the other goods sector which is a composite of the
    # "fudge" factor in the national IO accounts.
    #return G
    mask = Mask(G,(:yr,:r,:g))
    mask[:yr,:r,:g] = (G[:s0_][:yr,:r,:g] .- G[:x0_][:yr,:r,:g] .< 0)
    G[:rx0_][mask] =  G[:x0_][mask] .- G[:s0_][mask];

    # Initial level of rx0_ makes the armington supply zero profit condition
    # negative meaning it is too small (imports + margins > supply +
    # re-exports). Adjust rx0_ upward for these enough to make these conditions
    # zeroed out. Then subsequently adjust parameters through the circular economy.

    diff = GamsStructure.Parameter(G,(:yr,:r,:g);description = "Negative numbers still exist due to sharing parameter")

    diff[:yr,:r,:g] = X = - min.(0,(1 .- G[:ta0_][:yr,:r,:g]).*G[:a0_][:yr,:r,:g] .+ G[:rx0_][:yr,:r,:g] .-  ((1 .+G[:tm0_][:yr,:r,:g]).*G[:m0_][:yr,:r,:g] .+ sum(G[:md0_][:yr,:r,[m],:g] for m∈G[:m])))

    G[:rx0_][:yr,:r,:g]     = G[:rx0_][:yr,:r,:g] + diff[:yr,:r,:g]
    G[:x0_][:yr,:r,:g]      = G[:x0_][:yr,:r,:g] + diff[:yr,:r,:g]
    G[:s0_][:yr,:r,:g]      = G[:s0_][:yr,:r,:g] + diff[:yr,:r,:g]
    G[:yh0_][:yr,:r,:g]     = G[:yh0_][:yr,:r,:g] + diff[:yr,:r,:g]
    G[:bopdef0_][:yr,:r]   = sum(G[:m0_][:yr,:r,[g]] - G[:x0_][:yr,:r,[g]] for g∈G[:g]);


    s = [G[:g][e] for e∈G[:g] if (.!isapprox.(sum(GU[:ms0][[yr],[e],[m]] for yr∈G[:yr],m∈G[:m]),0,atol=1e-6)) .|| (.!isapprox.(sum(GU[:md0][[yr],[m],[e]] for yr∈GU[:yr],m∈GU[:m]),0,atol=1e-6))]

    add_set(G,:gm,GamsSet(s,"Commodities employed in margin supply"));

    dd0max = GamsStructure.Parameter(G,(:yr,:r,:g);description = "Maximum regional demand from local market")


    dd0max[:yr,:r,:g] = min.((1 .- G[:ta0_][:yr,:r,:g]).*G[:a0_][:yr,:r,:g] .+ G[:rx0_][:yr,:r,:g] .-
                            ((1 .+ G[:tm0_][:yr,:r,:g]).*G[:m0_][:yr,:r,:g] + sum(G[:md0_][:yr,:r,[m],:g] for m∈G[:m])),
                            G[:s0_][:yr,:r,:g] - (G[:x0_][:yr,:r,:g] - G[:rx0_][:yr,:r,:g]));


    rpc = GamsStructure.Parameter(G,(:yr,:r,:g);description = "Regional purchase coefficients")

    rpc[:yr,:r,:g] = GU[:rpc][:yr,:r,:i]
    
    G[:dd0_][:yr,:r,:g] = rpc[:yr,:r,:g] .* dd0max[:yr,:r,:g]
    G[:nd0_][:yr,:r,:g] = (1 .- G[:ta0_][:yr,:r,:g]).*G[:a0_][:yr,:r,:g] + G[:rx0_][:yr,:r,:g] -
                        (G[:dd0_][:yr,:r,:g] + G[:m0_][:yr,:r,:g].*(1 .+ G[:tm0_][:yr,:r,:g]) 
                        + sum(G[:md0_][:yr,:r,[m],:g] for m∈G[:m]));




    # Assume margins come both from local and national production. Assign like
    # dd0. Use information on national margin supply to enforce other identities.
    totmargsupply = GamsStructure.Parameter(G,(:yr,:r,:m,:g);description =  "Designate total supply of margins")
    margshr = GamsStructure.Parameter(G, (:yr,:r,:m);description = 	"Share of margin demand by region")
    shrtrd = GamsStructure.Parameter(G, (:yr,:r,:m,:g);description =  "Share of margin total by margin type")
    
    #$sum((g,rr), md0_(yr,rr,m,g))
    margshr[:yr,:r,:m] = permutedims(permutedims(sum(G[:md0_][:yr,:r,:m,[g]] for g∈G[:g]),(1,3,2)) ./ sum( G[:md0_][:yr,[r],:m,[g]] for r∈G[:r],g∈G[:g]),(1,3,2))
    
    for m∈G[:m],g∈G[:g]
        totmargsupply[:yr,:r,[m],[g]] = margshr[:yr,:r,[m]] .* GU[:ms0][:yr,[g],[m]]
    end
    
    for yr∈G[:yr],r∈G[:r],gm∈G[:gm]
        t = sum(totmargsupply[[yr],[r],[m],[gm]] for m∈G[:m])
        if t!=0
            #shrtrd[:yr,:r,:m,:gm] = permutedims(permutedims(totmargsupply[:yr,:r,:m,:gm],(1,2,4,3)) ./ sum(totmargsupply[:yr,:r,[m],:gm] for m∈G[:m]),(1,2,4,3));
            shrtrd[[yr],[r],:m,[gm]] = totmargsupply[[yr],[r],:m,[gm]] ./ sum(totmargsupply[[yr],[r],[m],[gm]] for m∈G[:m]);
        end
    end


    for m∈G[:m]
        G[:dm0_][:yr,:r,:gm,[m]] = min.( rpc[:yr,:r,:gm].*totmargsupply[:yr,:r,[m],:gm],
                    shrtrd[:yr,:r,[m],:gm].*(G[:s0_][:yr,:r,:gm] - G[:x0_][:yr,:r,:gm] + G[:rx0_][:yr,:r,:gm] - G[:dd0_][:yr,:r,:gm]));
    end
    
    G[:nm0_][:yr,:r,:gm,:m] = permutedims(totmargsupply[:yr,:r,:m,:gm],(1,2,4,3)) - G[:dm0_][:yr,:r,:gm,:m];


    G[:xd0_][:yr,:r,:g] = sum(G[:dm0_][:yr,:r,:g,[m]] for m∈G[:m]) + G[:dd0_][:yr,:r,:g]
    G[:xn0_][:yr,:r,:g] = G[:s0_][:yr,:r,:g] + G[:rx0_][:yr,:r,:g] - G[:xd0_][:yr,:r,:g] - G[:x0_][:yr,:r,:g]

    # Remove small numbers
    for (name,parm) in parameters(G)
        d = domain(parm)
        mask = Mask(G, d)
        mask[d...] = isapprox.(parm[d...],0,atol=1e-8)
        parm[mask] = 0
    end


    #Set Household adjustments
    ibal_inc = GamsStructure.Parameter(G,(:yr,:r))
    ibal_inc[:yr,:r] = sum(va0_[:yr,:r,[s]] for s∈G[:s]) + #E_RA_PL + E_RA_PK
                    sum(G[:yh0_][:yr,:r,[s]] for s∈G[:s]) + #E_RA_PY
                    G[:bopdef0_][:yr,:r] - # + hhadj[[r]] # E_RA_PFX
                    sum(G[:g0_][:yr,:r,[s]] + G[:i0_][:yr,:r,[s]] for s∈G[:s]) #E_RA_PA

    ibal_taxrev = GamsStructure.Parameter(G,(:yr,:r))
    ibal_taxrev[:yr,:r] = sum(
                        G[:ta0_][:yr,:r,[s]] .* G[:a0_][:yr,:r,[s]] + G[:tm0_][:yr,:r,[s]].*G[:m0_][:yr,:r,[s]] + #R_A_RA
                        G[:ty0_][:yr,:r,[s]] .* sum(G[:ys0_][:yr,:r,[s],[g]] for g∈G[:g]) #R_Y_RA
                            for s∈G[:s]) 


    ibal_balance = GamsStructure.Parameter(G,(:yr,:r))
    ibal_balance[:yr,:r] = G[:c0_][:yr,:r] .- ibal_inc[:yr,:r] .- ibal_taxrev[:yr,:r]

    G[:hhadj0_][:yr,:r] = ibal_balance[:yr,:r]

    G[:gdp0_][:yr,:r] = G[:c0_][:yr,:r] + sum(G[:i0_][:yr,:r,:g] + G[:g0_][:yr,:r,:g],dims=3) - G[:hhadj0_][:yr,:r] - G[:bopdef0_][:yr,:r];

    Y,A,X,M = _state_zero_profit(G)

    @assert isapprox(Y,0,atol=1e-4) "State Level Zero Profit fails. Check Y -> $Y."
    @assert isapprox(A,0,atol=1e-4) "State Level Zero Profit fails. Check A -> $A."
    @assert isapprox(X,0,atol=1e-4) "State Level Zero Profit fails. Check X -> $X."
    @assert isapprox(M,0,atol=1e-4) "State Level Zero Profit fails. Check M -> $M."


    I = _state_income_balance(G,va0_)
    @assert isapprox(I,0,atol=1e-4) "State Level Income Balance fails. Check I -> $I."

    PA,PN,PY,PFX = _state_market_clearance(G)
    @assert isapprox(PA,0,atol=1e-4) "State Level Market Clearance fails. Check PA -> $PA."
    @assert isapprox(PN,0,atol=1e-4) "State Level Market Clearance fails. Check PN -> $PN."
    @assert isapprox(PY,0,atol=1e-4) "State Level Market Clearance fails. Check PY -> $PY."
    @assert isapprox(PFX,0,atol=1e-4) "State Level Market Clearance fails. Check PFX -> $PFX."


    return G
end


function _state_zero_profit(G::GamsUniverse)
    Y = sum(abs.(1 .- G[:ty0_][:yr,:r,:s]) .* sum(G[:ys0_][:yr,:r,:s,[g]] for g∈G[:g]) - sum(G[:id0_][:yr,:r,[g],:s] for g∈G[:g]) - G[:ld0_][:yr,:r,:s] - G[:kd0_][:yr,:r,:s])
    A = sum(abs.((1 .- G[:ta0_][:yr,:r,:g]).*G[:a0_][:yr,:r,:g] + G[:rx0_][:yr,:r,:g] - 
                (G[:nd0_][:yr,:r,:g] + G[:dd0_][:yr,:r,:g] + (1 .+ G[:tm0_][:yr,:r,:g]).*G[:m0_][:yr,:r,:g] + sum(G[:md0_][:yr,:r,[m],:g] for m∈G[:m]))))
    X = sum(abs.(G[:s0_][:yr,:r,:g] - G[:xd0_][:yr,:r,:g] - G[:xn0_][:yr,:r,:g] - G[:x0_][:yr,:r,:g] + G[:rx0_][:yr,:r,:g]))
    M = sum(abs.(sum(G[:nm0_][:yr,:r,[s],:m] + G[:dm0_][:yr,:r,[s],:m] for s∈G[:s]) - sum(G[:md0_][:yr,:r,:m,[g]] for g∈G[:g])))

    return (Y,A,X,M)

end

function _state_income_balance(G::GamsUniverse,va0_::GamsStructure.Parameter)

    ibal_inc = GamsStructure.Parameter(G,(:yr,:r))
    ibal_inc[:yr,:r] = sum(va0_[:yr,:r,[s]] for s∈G[:s]) + #E_RA_PL + E_RA_PK
                    sum(G[:yh0_][:yr,:r,[s]] for s∈G[:s]) + #E_RA_PY
                    G[:bopdef0_][:yr,:r] - # + hhadj[[r]] # E_RA_PFX
                    sum(G[:g0_][:yr,:r,[s]] + G[:i0_][:yr,:r,[s]] for s∈G[:s]) + #E_RA_PA
                    G[:hhadj0_][:yr,:r]

    #	Tax revenues are expressed as values per unit activity, so we
    #	need multiply these by the activity level to compute total income:

    ibal_taxrev = GamsStructure.Parameter(G,(:yr,:r))
    ibal_taxrev[:yr,:r] = sum(
                        G[:ta0_][:yr,:r,[s]] .* G[:a0_][:yr,:r,[s]] + G[:tm0_][:yr,:r,[s]].*G[:m0_][:yr,:r,[s]] + #R_A_RA
                        G[:ty0_][:yr,:r,[s]] .* sum(G[:ys0_][:yr,:r,[s],[g]] for g∈G[:g]) #R_Y_RA
                            for s∈G[:s]) 


    ibal_balance = GamsStructure.Parameter(G,(:yr,:r))


    ibal_balance[:yr,:r] = G[:c0_][:yr,:r] - ibal_inc[:yr,:r] - ibal_taxrev[:yr,:r]

    return sum(abs.(ibal_balance[:yr,:r]))
end


function _state_market_clearance(G::GamsUniverse)

    PA = sum(abs.(G[:a0_][:yr,:r,:g] - (sum(G[:id0_][:yr,:r,:g,[s]] for s∈G[:s]) + G[:cd0_][:yr,:r,:g] + G[:g0_][:yr,:r,:g] + G[:i0_][:yr,:r,:g])))
    PN = sum(abs.(sum(G[:xn0_][:yr,[r],:g] for r∈G[:r]) - sum(G[:nm0_][:yr,[r],:g,[m]] for r∈G[:r],m∈G[:m]) - sum(G[:nd0_][:yr,[r],:g] for r∈G[:r])))
    PY = sum(abs.(sum(G[:ys0_][:yr,:r,[s],:g] for s∈G[:s]) + G[:yh0_][:yr,:r,:g] - G[:s0_][:yr,:r,:g]))
    PFX = sum(abs.(sum(sum(G[:x0_][:yr,[r],[s]] for s∈G[:s]) + G[:hhadj0_][:yr,[r]] + G[:bopdef0_][:yr,[r]] - sum(G[:m0_][:yr,[r],[s]] for s∈G[:s]) for r∈G[:r])))

    return (PA,PN,PY,PFX)
end
