"""
    national_model_mcp(GU::GamsUniverse;solver = PATHSolver.Optimizer)

Run all years of the the national model. Returns a dictionary containing
each year.
"""
function national_model_mcp(GU::GamsUniverse;solver = PATHSolver.Optimizer)

    models = Dict()

    for year∈GU[:yr]
        m = national_model_mcp_year(GU,year; solver = solver)
        set_silent(m)
        optimize!(m)
        models[parse(Int,string(year))] = m

    end

    return models

end


"""
    national_model_mcp_year(GU::GamsUniverse,year::Symbol;solver = PATHSolver.Optimizer)

Run the national model for a single year.    
"""
function national_model_mcp_year(GU::GamsUniverse,year::Symbol;solver = PATHSolver.Optimizer)


    """
    Self notes:
        1. The four theta's get defined as new parameters
    """

    #################
    ### GU ##########
    #################
    VA = GU[:va]
    J = GU[:j]
    I = GU[:i]
    M = GU[:m]
    
    
    Y_ = [j for j in GU[:j] if sum(GU[:ys0][[year],[j],[i]] for i∈I)!=0]
    A_ = [i for i in GU[:i] if GU[:a0][[year],[i]]!=0]
    PY_ = [i for i in GU[:i] if sum(GU[:ys0][[year],[j],[i]] for j∈J)!=0]
    XFD = [fd for fd in GU[:fd] if fd!=:pce]
    
    
    ####################
    ## Parameters ######
    ####################
    
    va0 = GU[:va0]
    m0 = GU[:m0]
    tm0 = GU[:tm0]
    y0 = GU[:y0]
    a0 = GU[:a0]
    ta0 = GU[:ta0]
    x0 = GU[:x0]
    fd0 = GU[:fd0]
    
    
    
    ms0 = GU[:ms0]
    bopdef = GU[:bopdef0][[year]]
    fs0 = GU[:fs0]
    ys0 = GU[:ys0]
    id0 = GU[:id0]
    md0 = GU[:md0]
    
    ty = GamsParameter(GU,(:yr,:i))
    tm = GamsParameter(GU,(:yr,:i))
    ta = GamsParameter(GU,(:yr,:i))
    
    ty[:yr,:i] = GU[:ty0][:yr,:i] 
    tm[:yr,:i] = GU[:tm0][:yr,:i] #.*0 #for the counterfactual
    ta[:yr,:i] = GU[:ta0][:yr,:i] #.*0 #for the counterfactual
    
    
    thetava = GamsParameter(GU,(:va,:j)) #GU[:thetava]
    thetam = GamsParameter(GU,(:i,))     #GU[:thetam]
    thetax = GamsParameter(GU,(:i,))     #GU[:thetax]
    thetac = GamsParameter(GU,(:i,))     #GU[:thetac]
    
    
    for va∈VA, j∈J
        if va0[[year],[va],[j]]≠0
            thetava[[va],[j]] = va0[[year],[va],[j]]/sum(va0[[year],[v],[j]] for v∈VA)
        end
    end
    
    for i∈I
        if m0[[year],[i]] != 0
            thetam[[i]] = m0[[year],[i]].*(1 .+tm0[[year],[i]])./(m0[[year],[i]].*(1 .+tm0[[year],[i]] ).+ y0[[year],[i]])
        end
    end
    
    for i∈I
        if x0[[year],[i]] != 0
            thetax[[i]] = x0[[year],[i]]./(x0[[year],[i]].+a0[[year],[i]].*(1 .-ta0[[year],[i]]))
        end
    end
    
    thetac[:i] = fd0[[year],:i,[:pce]]./sum(fd0[[year],:i,[:pce]])
    
    
    #######################
    ## Model starts here ##
    #######################
    
    m = JuMP.Model(solver)
    
    @variables(m,begin
        Y[J]>=0,    (start = 1,)
        A[I]>=0,    (start = 1,)
        MS[M]>=0,   (start = 1,)
        PA[I]>=0,   (start = 1,)
        PY[I]>=0,   (start = 1,)
        PVA[VA]>=0, (start = 1,)
        PM[M]>=0,   (start = 1,)
        PFX>=0,     (start = 1,)
        RA>=0,      (start = sum(fd0[[year],:i,[:pce]]),)
    end)
    
    ####################
    ## Macros in Gams ##
    ####################
    @expressions(m, begin 
        CVA[j=J],
            prod(PVA[va]^thetava[[va],[j]] for va∈VA)
        
        PMD[i=I],
            (thetam[[i]]*(PFX*(1+tm[[year],[i]])/(1+tm0[[year],[i]]))^(1-2) + (1-thetam[[i]])*PY[i]^(1-2))^(1/(1-2))
    
        PXD[i=I],
            (thetax[[i]]*PFX^(1+2) + (1-thetax[[i]])*(PA[i]*(1-ta[[year],[i]])/(1-ta0[[year],[i]]))^(1+2))^(1/(1+2))
    
        MD[i=I],
            A[i]*m0[[year],[i]]*( (PMD[i]*(1+tm0[[year],[i]])) / (PFX*(1+tm[[year],[i]])))^2
    
        YD[i=I],
            A[i]*y0[[year],[i]]*(PMD[i]/PY[i])^2

        XS[i=I],
            A[i]*x0[[year],[i]]*(PFX/PXD[i])^2

        DS[i = I],
            A[i]*a0[[year],[i]]*(PA[i]*(1-ta[[year],[i]])/(PXD[i]*(1-ta0[[year],[i]])))^2
    end)
    
    ########################
    ## End of GAMS Macros ##
    ########################
    
    
    @constraints(m,begin
        prf_Y[j=Y_], #defined on y_(j)
            CVA[j]*sum(va0[[year],[va],[j]] for va∈VA) +
            sum(PA[i]*id0[[year],[i],[j]] for i∈I) - 
            sum(PY[i]*ys0[[year],[j],[i]] for i∈I)*(1-ty[[year],[j]]) ⟂ Y[j]
    
        prf_A[i = A_],    #defined on a_(i)
            sum(PM[m_]*md0[[year],[m_],[i]] for m_∈M) + 
            PMD[i] * 
            (y0[[year],[i]] +(1+tm0[[year],[i]])*m0[[year],[i]]) -
            PXD[i] *
            (x0[[year],[i]] + a0[[year],[i]]*(1-ta0[[year],[i]])) ⟂ A[i]
    
        prf_MS[m_ = M],
            sum(PY[i]*ms0[[year],[i],[m_]] for i∈I) - 
            PM[m_]*sum(ms0[[year],[i],[m_]] for i∈I) ⟂ MS[m_]
    
        bal_RA,
            -RA + sum(PY[i]*fs0[[year],[i]] for i∈I) + PFX*bopdef -
             sum(PA[i]*fd0[[year],[i],[xfd]] for i∈I,xfd∈XFD) + sum(PVA[va]*va0[[year],[va],[j]] for va∈VA,j∈J) +
             sum(A[i]*(a0[[year],[i]]*PA[i]*ta[[year],[i]] + PFX*MD[i]*tm[[year],[i]]) for i∈I) +
             sum(Y[j]*sum(ys0[[year],[j],[i]]*PY[i] for i∈I)*ty[[year],[j]] for j∈J) ⟂ RA
    
        mkt_PA[i = A_],
            -DS[i] + thetac[[i]] * RA/PA[i] + sum(fd0[[year],[i],[xfd]] for xfd∈XFD) +
             sum(Y[j]*id0[[year],[i],[j]] for j∈Y_) ⟂ PA[i]
    
    
        mkt_PY[i=I],
            -sum(Y[j]*ys0[[year],[j],[i]] for j∈Y_) +
             sum(MS[m_]*ms0[[year],[i],[m_]] for m_∈M) + YD[i] ⟂ PY[i]
    
        mkt_PVA[va = VA],
            -sum(va0[[year],[va],[j]] for j∈J) +
             sum(Y[j]*va0[[year],[va],[j]]*CVA[j]/PVA[va] for j∈Y_) ⟂ PVA[va]
    
        mkt_PM[m_ = M],
            MS[m_]*sum(ms0[[year],[i],[m_]] for i∈I) -
             sum(A[i]*md0[[year],[m_],[i]] for i∈I if a0[[year],[i]]≠0) ⟂ PM[m_]
    
        mkt_PFX,
            sum(XS[i] for i∈A_) + bopdef -
             sum(MD[i] for i∈A_) ⟂ PFX
    end)
    
    #############################
    ## Fix unmatched variables ##
    #############################
    
    for i∈I
        if a0[[year],[i]] == 0
            fix(A[i],0,force=true)
            fix(PA[i],0,force=true)
        end
    end

    return m
end






function national_model_mpsge_year(GU::GamsUniverse,year::Symbol)


    #################
    ### GU ##########
    #################
    VA = [va for va∈GU[:va]]
    J = [j for j∈ GU[:j]]
    I = [i for i∈ GU[:i]]
    M = [m for m∈ GU[:m]]


    Y_ = [j for j in GU[:j] if sum(GU[:ys0][[year],[j],[i]] for i∈I)!=0]
    A_ = [i for i in GU[:i] if GU[:a0][[year],[i]]!=0]
    PY_ = [i for i in GU[:i] if sum(GU[:ys0][[year],[j],[i]] for j∈J)!=0]
    XFD = [fd for fd in GU[:fd] if fd!=:pce]

    Y_ = [j for j∈GU[:j] if j∉[:oth,:use]]
    A_ = [i for i∈GU[:i] if i∉[:oth,:use,:fbt,:mvt,:gmt]]


    ####################
    ## Parameters ######
    ####################

    va0 = GU[:va0]
    m0 = GU[:m0]
    tm0 = GU[:tm0]
    y0 = GU[:y0]
    a0 = GU[:a0]
    ta0 = GU[:ta0]
    ty0 = GU[:ty0]
    x0 = GU[:x0]
    fd0 = GU[:fd0]



    ms0 = GU[:ms0]
    bopdef = GU[:bopdef0][[year]]
    fs0 = GU[:fs0]
    ys0 = GU[:ys0]
    id0 = GU[:id0]
    md0 = GU[:md0]

    ty = GamsParameter(GU,(:yr,:i))
    tm = GamsParameter(GU,(:yr,:i))
    ta = GamsParameter(GU,(:yr,:i))

    ty[:yr,:i] = GU[:ty0][:yr,:i] 
    #tm[:yr,:i] = GU[:tm0][:yr,:i] 
    #ta[:yr,:i] = GU[:ta0][:yr,:i] 




    WiNnat = MPSGE.Model()


    # parameters
    ta = add!(WiNnat, MPSGE.Parameter(:ta, indices = (I,), value=ta0[[year],:i])) #	"Tax net subsidy rate on intermediate demand",
    tm = add!(WiNnat, MPSGE.Parameter(:tm, indices = (I,), value=tm0[[year],:i])) #	"Import tariff";

    # Elasticity parameters
    t_elas_y =  add!(WiNnat, MPSGE.Parameter(:t_elas_y,  value=0.))
    elas_y =    add!(WiNnat, MPSGE.Parameter(:elas_y,    value=0.))
    elas_va =   add!(WiNnat, MPSGE.Parameter(:elas_va,   value=1.))
    t_elas_m =  add!(WiNnat, MPSGE.Parameter(:t_elas_m,  value=0.))
    elas_m =    add!(WiNnat, MPSGE.Parameter(:elas_m,    value=0.))
    t_elas_a =  add!(WiNnat, MPSGE.Parameter(:t_elas_a,  value=2.))
    elas_a =    add!(WiNnat, MPSGE.Parameter(:elas_a,    value=0.))
    elas_dm =   add!(WiNnat, MPSGE.Parameter(:elas_dm,   value=2.))
    d_elas_ra = add!(WiNnat, MPSGE.Parameter(:d_elas_ra, value=1.))

    # sectors:
    Y = add!(WiNnat, Sector(:Y, indices=(J,)))
    A = add!(WiNnat, Sector(:A, indices=(I,)))

    MS = add!(WiNnat, Sector(:MS, indices=(M,)))

    # commodities:
    # Should be filtered for sectors in $a0(i)	? Seems to work better to just loop of a_
    PA  = add!(WiNnat, Commodity(:PA, indices=(A_, ))) #	Armington price
    # Should be filtered for sectors in $py_(i)   ? py_ is the same as y_
    PY  = add!(WiNnat, Commodity(:PY, indices=(I,))) #	Supply
    PVA = add!(WiNnat, Commodity(:PVA, indices=(VA,))) #		Value-added
    PM  = add!(WiNnat, Commodity(:PM, indices=(M,))) #		Margin
    PFX = add!(WiNnat, Commodity(:PFX))	#	Foreign exchnage

    # consumers:
    RA = add!(WiNnat, Consumer(:RA, benchmark = sum(fd0[[year],:i,[:pce]]) ))

    # production functions
    for j in Y_
        @production(WiNnat, Y[j], 0., 0.,
        [	
            Output(PY[i], ys0[[year],[j],[i]], taxes=[Tax(ty0[[year],[j]], RA)]) for i in I if ys0[[year],[j],[i]]>0
        ], 
        [
            [Input(PA[i], id0[[year],[i],[j]]) for i in A_ if id0[[year],[i],[j]]>0];  # filtered to A
            [Input(Nest(
                    Symbol("VA$j"),
                    1.,
                    # :($(elas_va)*1),
                    sum(va0[[year],:va,[j]]),
                    [Input(PVA[va], va0[[year],[va],[j]]) for va in VA if va0[[year],[va],[j]]>0.] 
                ),
                    sum(va0[[year],:va,[j]] )
                )
            ]
        ]
        )
    end

    for m in M
        add!(WiNnat, Production(MS[m], 0., 0.,  
            [Output(PM[m], sum(ms0[[year],:i,[m]]) ) ],
            [Input(PY[i], ms0[[year],[i],[m]]) for i in I if ms0[[year],[i],[m]]>0])) 
    end

    for i in A_  
        @production(WiNnat, A[i], 2., 0.,
        [
            [Output(PA[i], a0[[year],[i]], taxes=[Tax(:($(ta[i])*1), RA)], price=(1-ta0[[year],[i]]))];
            [Output(PFX, x0[[year],[i]])]
        ]
        ,
        [
            [	
            Input(Nest(Symbol("dm$i"),
                2.,
                (y0[[year],[i]]+m0[[year],[i]]+m0[[year],[i]]*get_value(tm[tm[i].subindex])),
                if m0[[year],[i]]>0 && y0[[year],[i]]>0
                    [
                    Input(PY[i], y0[[year],[i]] ),
                    Input(PFX, m0[[year],[i]], taxes=[Tax(:($(tm[i])*1), RA)],  price=(1+tm0[[year],[i]]*1)  )
                    ]
                elseif y0[[year],[i]]>0
                    [Input(PY[i], y0[[year],[i]] )]
                end
                ),
            (y0[[year],[i]]+m0[[year],[i]]+m0[[year],[i]]*get_value(tm[tm[i].subindex]))) 
            ];
            [Input(PM[m], md0[[year],[m],[i]]) for m in M if md0[[year],[m],[i]]>0]
        ]
        )
    end

    add!(WiNnat, DemandFunction(RA, 1.,
        
        [Demand(PA[i], fd0[[year],[i],[:pce]]) for i in A_],
        [
            [Endowment(PY[i], fs0[[year],[i]]) for i in I];
            [Endowment(PA[i], -sum(fd0[[year],[i],[fd]] for fd in XFD)) for i in A_];  
            [Endowment(PVA[va], sum(va0[[year],[va],:j])) for va in VA];
            Endowment(PFX, bopdef)
        ]
    ))



    #Counterfactual

    MPSGE.set_value((A[(:gmt)]), 1.0)
    MPSGE.set_value((A[(:mvt)]), 1.0)
    MPSGE.set_value((A[(:fbt)]), 1.0)
    MPSGE.set_fixed!(A[(:gmt)], true)
    MPSGE.set_fixed!(A[(:mvt)], true)
    MPSGE.set_fixed!(A[(:fbt)], true)

    for i in I
        MPSGE.set_value(ta[i], 0.)
        MPSGE.set_value(tm[i], 0.)
    end

    #MPSGE.set_value(RA,  12453.8963) #So far, this updated default normalization value needs to be set, value from GAMS output. 
    #MPSGE.set_fixed!(RA, true)

    return WiNnat


end
