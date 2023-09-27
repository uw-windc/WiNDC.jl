

function state_dissagregation_model_mcp_year(GU::GamsUniverse,year::Symbol)

    model = Model(PATHSolver.Optimizer)

    R = [r for r∈GU[:r]]
    S = [s for s∈GU[:s]]
    G = [g for g∈GU[:g]]
    M = [m for m∈GU[:m]]
    GM = [gm for gm∈GU[:gm]]

    ys0 = GamsParameter(GU,(:r,:s,:g))
    ys0[:r,:s,:g] = GU[:ys0_][[year],:r,:s,:g]
    
    id0 = GamsParameter(GU,(:r,:g,:s))
    id0[:r,:g,:s] = GU[:id0_][[year],:r,:g,:s]
    
    ld0 = GamsParameter(GU,(:r,:s))
    ld0[:r,:s] = GU[:ld0_][[year],:r,:s]
    
    kd0 = GamsParameter(GU,(:r,:s))
    kd0[:r,:s] = GU[:kd0_][[year],:r,:s]
    
    ty0 = GamsParameter(GU,(:r,:s))
    ty0[:r,:s] = GU[:ty0_][[year],:r,:s]

    ty = ty0
    
    m0 = GamsParameter(GU,(:r,:g))
    m0[:r,:g] = GU[:m0_][[year],:r,:g]
    
    x0 = GamsParameter(GU,(:r,:g))
    x0[:r,:g] = GU[:x0_][[year],:r,:g]
    
    rx0 = GamsParameter(GU,(:r,:g))
    rx0[:r,:g] = GU[:rx0_][[year],:r,:g]
    
    md0 = GamsParameter(GU,(:r,:m,:g))
    md0[:r,:m,:g] = GU[:md0_][[year],:r,:m,:g]
    
    nm0 = GamsParameter(GU,(:r,:g,:m))
    nm0[:r,:g,:m] = GU[:nm0_][[year],:r,:g,:m]
    
    dm0 = GamsParameter(GU,(:r,:g,:m))
    dm0[:r,:g,:m] = GU[:dm0_][[year],:r,:g,:m]
    
    s0 = GamsParameter(GU,(:r,:g))
    s0[:r,:g] = GU[:s0_][[year],:r,:g]
    
    a0 = GamsParameter(GU,(:r,:g))
    a0[:r,:g] = GU[:a0_][[year],:r,:g]
    
    ta0 = GamsParameter(GU,(:r,:g))
    ta0[:r,:g] = GU[:ta0_][[year],:r,:g]
    
    ta = ta0

    tm0 = GamsParameter(GU,(:r,:g))
    tm0[:r,:g] = GU[:tm0_][[year],:r,:g]

    tm = tm0
    
    cd0 = GamsParameter(GU,(:r,:g))
    cd0[:r,:g] = GU[:cd0_][[year],:r,:g]
    
    c0 = GamsParameter(GU,(:r,))
    c0[:r] = GU[:c0_][[year],:r]
    
    yh0 = GamsParameter(GU,(:r,:g))
    yh0[:r,:g] = GU[:yh0_][[year],:r,:g]
    
    bopdef0 = GamsParameter(GU,(:r,))
    bopdef0[:r] = GU[:bopdef0_][[year],:r]
    
    g0 = GamsParameter(GU,(:r,:g))
    g0[:r,:g] = GU[:g0_][[year],:r,:g]
    
    i0 = GamsParameter(GU,(:r,:g))
    i0[:r,:g] = GU[:i0_][[year],:r,:g]
    
    xn0 = GamsParameter(GU,(:r,:g))
    xn0[:r,:g] = GU[:xn0_][[year],:r,:g]
    
    xd0 = GamsParameter(GU,(:r,:g))
    xd0[:r,:g] = GU[:xd0_][[year],:r,:g]
    
    dd0 = GamsParameter(GU,(:r,:g))
    dd0[:r,:g] = GU[:dd0_][[year],:r,:g]
    
    nd0 = GamsParameter(GU,(:r,:g))
    nd0[:r,:g] = GU[:nd0_][[year],:r,:g]
    
    hhadj = GamsParameter(GU,(:r,))
    hhadj[:r] = GU[:hhadj_][[year],:r]


    @variables(model,begin
        Y[R,S]>=0, (start = 1,)
        X[R,G]>=0, (start =1,)
        A[R,G]>=0, (start =1,)
        C[R]>=0, (start =1,)
        MS[R,M]>=0, (start =1,)

        PA[R,G]>=0, (start =1,)
        PY[R,G]>=0, (start =1,)
        PD[R,G]>=0, (start =1,)
        PN[G]>=0, (start =1,)
        PL[R]>=0, (start =1,)
        PK[R,S]>=0, (start =1,)
        PM[R,M]>=0, (start =1,)
        PC[R]>=0, (start =1,)
        PFX>=0, (start =1,)
        
        RA[r=R]>=0, (start = c0[[r]],)
    end)

    for r∈R,s∈S
        if kd0[[r],[s]] ≠ 0
            set_lower_bound(PK[r,s],1e-5)
        end
    end

    for r∈R,g∈G
        if a0[[r],[g]] == 0
            fix(PA[r,g],0,force=true)
        end

        if s0[[r],[g]] == 0
            fix(PY[r,g],0,force=true)
            fix(X[r,g],0,force=true)
        end

        if xd0[[r],[g]] == 0
            fix(PD[r,g],0,force=true)
        end

        #s and g are aliases
        if kd0[[r],[g]] == 0
            fix(PK[r,g],0,force=true)
        end

        if sum(ys0[[r],[g],:g]) > 0
            fix(Y[r,g],0,force=true)
        end

        if a0[[r],[g]] + rx0[[r],[g]] == 0
            fix(A[r,g],0,force=true)
        end

    end
       
    lvs = GamsParameter(GU,(:r,:s))

    lvs[:r,:s] = ld0[:r,:s]./(ld0[:r,:s] + kd0[:r,:s])


    @expressions(model,begin
        PI_Y[r=R,s=S], PL[r]^lvs[[r],[s]]*PK[r,s]^(1-lvs[[r],[s]])
        O_Y_PY[r=R,g=G,s=S], ys0[[r],[s],[g]]
        I_PA_Y[r=R,g=G,s=S], id0[[r],[g],[s]]
        I_PL_Y[r=R,s=S], ld0[[r],[s]]*(PI_Y[r,s]/PL[r]) #if ld0[[r],[s]]!=0
        I_PK_Y[r=R,s=S], kd0[[r],[s]]*(PI_Y[r,s]/PK[r,s]) #if kd0[[r],[s]]!=0
        R_Y_RA[r=R,s=S], sum(PY[r,g]*ty[[r],[s]]*O_Y_PY[r,g,s] for g∈G)
    end)

    theta_X_PD = GamsParameter(GU,(:r,:g))
    theta_X_PD[:r,:g] = xd0[:r,:g]./s0[:r,:g]

    theta_X_PN = GamsParameter(GU,(:r,:g))
    theta_X_PN[:r,:g] = xn0[:r,:g]./s0[:r,:g]

    theta_X_PFX = GamsParameter(GU,(:r,:g))
    theta_X_PFX[:r,:g] = (x0[:r,:g] - rx0[:r,:g])./s0[:r,:g]

    @expressions(model,begin
        PI_X[r=R,g=G],    (theta_X_PD[[r],[g]] * PD[r,g]^(1+4) + theta_X_PN[[r],[g]] * PN[g]^(1+4) + theta_X_PFX[[r],[g]] * PFX^(1+4) )^(1/(1+4))
        O_X_PFX[r=R,g=G], (x0[[r],[g]]-rx0[[r],[g]])*((PFX/PI_X[r,g])^4) #$(x0(r,g)-rx0(r,g)))
        O_X_PN[g=G,r=R],  xn0[[r],[g]]*((PN[g]/PI_X[r,g])^4)#$xn0(r,g))
    end)


    theta_ident = GamsParameter(GU,(:r,:g))

    mask = isapprox.(theta_X_PD[:r,:g],1,atol=1e-6)
    theta_ident[mask] = (theta_ident[mask] .= 1)

    #O_X_PD(r,g)	(xd0(r,g)*((((PD(r,g)/PI_X(r,g))**4)$round(1-theta_X_PD(r,g),6) + (1)$(not round(1-theta_X_PD(r,g),6))))$xd0(r,g))
    @expression(model,
        O_X_PD[r=R,g=G], xd0[[r],[g]]*PD[r,g]/PI_X[r,g]*(1-theta_ident[[r],[g]]) + xd0[[r],[g]]*theta_ident[[r],[g]]
    )

    @expression(model,
        I_PY_X[r=R,g=G], s0[[r],[g]]
    )

    theta_PN_A = GamsParameter(GU,(:r,:g))
    theta_PD_A = GamsParameter(GU,(:r,:g))
    theta_PFX_A = GamsParameter(GU,(:r,:g))

    theta_PFX_A[:r,:g] = m0[:r,:g].*(1 .+ tm0[:r,:g])./(m0[:r,:g].*(1 .+ tm0[:r,:g])+nd0[:r,:g]+dd0[:r,:g])
    theta_PN_A[:r,:g] = nd0[:r,:g] ./(nd0[:r,:g]+dd0[:r,:g])
    theta_PD_A[:r,:g] = dd0[:r,:g] ./(nd0[:r,:g]+dd0[:r,:g])

    @expressions(model,begin
        PI_PFX_A[r=R,g=G], PFX*(1+tm[[r],[g]])/(1+tm0[[r],[g]])

        PI_A_D[r=R,g=G],   (theta_PN_A[[r],[g]]*(PN[g]^(1-4)) + theta_PD_A[[r],[g]]*(PD[r,g]^(1-4)))^(1/(1-4))
        PI_A_DM[r=R,g=G],  (theta_PFX_A[[r],[g]]*(PI_PFX_A[r,g]^(1-2)) + (1-theta_PFX_A[[r],[g]])*(PI_A_D[r,g]^(1-2)))^(1/(1-2))

        O_A_PA[r=R,g=G],	a0[[r],[g]]
        O_A_PFX[r=R,g=G],	rx0[[r],[g]]

        I_PN_A[g=G,r=R],	nd0[[r],[g]]*((PI_A_DM[r,g]/PI_A_D[r,g])^2*(PI_A_D[r,g]/PN[g])^4)
        I_PD_A[r=R,g=G],	dd0[[r],[g]]*((PI_A_DM[r,g]/PI_A_D[r,g])^2*(PI_A_D[r,g]/PD[r,g])^4)
        I_PFX_A[r=R,g=G],	m0[[r],[g]]*((PI_A_DM[r,g]/PI_PFX_A[r,g])^2)

        I_PM_A[r=R,m=M,g=G],md0[[r],[m],[g]]

        R_A_RA[r=R,g=G],		ta[[r],[g]]*PA[r,g]*O_A_PA[r,g] + tm[[r],[g]]*PFX*I_PFX_A[r,g]


        O_MS_PM[r=R,m=M],	sum(md0[[r],[m],[gm]] for gm∈GM )
        I_PN_MS[gm=GM,r=R,m=M],	nm0[[r],[gm],[m]]
        I_PD_MS[r=R,gm=GM,m=M],	dm0[[r],[gm],[m]]
    end)



    theta_PA_C = GamsParameter(GU,(:r,:g))
    theta_PA_C[:r,:g] = cd0[:r,:g]./sum(cd0[:r,:g],dims=2)

    @expressions(model,begin
        PI_C[r=R],	    prod(PA[r,g]^theta_PA_C[[r],[g]] for g∈G)

        O_C_PC[r=R],	    c0[[r]]
        I_PA_C[r=R,g=G],	cd0[[r],[g]]*(PI_C[r]/PA[r,g])
        
        
        
        E_RA_PY[r=R,g=G],	yh0[[r],[g]]
        E_RA_PFX[r=R],	bopdef0[[r]]+hhadj[[r]]
        E_RA_PA[r=R,g=G],   -g0[[r],[g]]-i0[[r],[g]]
        E_RA_PL[r=R],	    sum(ld0[[r],[s]] for s∈S)
        E_RA_PK[r=R,s=S],	kd0[[r],[s]]
        D_PC_RA[r=R],	    RA[r]/PC[r]
    end)


    ########################
    ## Start of Equations ##
    ########################
        
    @constraints(model,begin
        #	Zero profit condition: value of inputs from national market (PN[g]), domestic market (PD[r,g]) 
        #	and imports (PFX) plus tax liability equals the value of supply to the PA[r,g] market and
        #	re-exports to the PFX market:
        prf_Y[r=R,s=S],
                sum(PA[r,g]*I_PA_Y[r,g,s] for g∈G) +
        
                    PL[r]*I_PL_Y[r,s] + PK[r,s]*I_PK_Y[r,s]  + R_Y_RA[r,s] - 
        
                         sum(PY[r,g]*O_Y_PY[r,g,s] for g∈G) ⟂ Y[r,s]

        
                        
        
        prf_X[r=R,g=G],
                    PY[r,g]*I_PY_X[r,g] - (PFX*O_X_PFX[r,g] + PN[g]*O_X_PN[g,r] + PD[r,g]*O_X_PD[r,g]) ⟂ X[r,g]
                    
        prf_A[r=R,g=G],

                PN[g]*I_PN_A[g,r] + PD[r,g]*I_PD_A[r,g] + PFX*I_PFX_A[r,g] + sum(PM[r,m]*I_PM_A[r,m,g] for m∈M) + R_A_RA[r,g] -

                         (PA[r,g]*O_A_PA[r,g] + PFX * O_A_PFX[r,g]) ⟂ A[r,g]

        prf_MS[r=R,m=M],	sum(PN[gm]*I_PN_MS[gm,r,m] + PD[r,gm]*I_PD_MS[r,gm,m] for gm∈GM) - PM[r,m]*O_MS_PM[r,m] ⟂ MS[r,m]
        
        prf_C[r=R],	sum(PA[r,g]*I_PA_C[r,g] for g∈G) - PC[r]*O_C_PC[r] ⟂ C[r]

        
        #	Market clearance conditions: production outputs plus consumer endowments equal production inputs
        #	plus consumer demand.

        #	Aggregate absorption associated with intermediate and consumer demand:

        mkt_PA[r=R,g=G],		A[r,g]*O_A_PA[r,g] + E_RA_PA[r,g] -( 

                    sum(Y[r,s]*I_PA_Y[r,g,s] for s∈S) + I_PA_C[r,g]*C[r]) ⟂ PA[r,g]

        #	Producer output supply and demand:

        mkt_PY[r=R,g=G],		sum(Y[r,s]*O_Y_PY[r,g,s] for s∈S) + E_RA_PY[r,g] - X[r,g] * I_PY_X[r,g] ⟂ PY[r,g]

        #	Regional market for goods:

        mkt_PD[r=R,g=G],		X[r,g]*O_X_PD[r,g] - (A[r,g]*I_PD_A[r,g] + sum(MS[r,m]*I_PD_MS[r,g,m] for m∈M)) ⟂ PD[r,g]       #$gm[g])

        #	National market for goods:

        mkt_PN[g=G],		sum(X[r,g] * O_X_PN[g,r] for r∈R) - (

                    sum(A[r,g] * I_PN_A[g,r] for r∈R) + sum(MS[r,m]*I_PN_MS[g,r,m] for r∈R,m∈M))  ⟂ PN[g]      #$gm[g]

        #	Foreign exchange:

        mkt_PFX,		sum(X[r,g]*O_X_PFX[r,g] for r∈R,g∈G if s0[[r],[g]]!=0) + sum(A[r,g]*O_A_PFX[r,g] for r∈R,g∈G) + sum(E_RA_PFX[r] for r∈R) -

                             sum(A[r,g] * I_PFX_A[r,g] for r∈R,g∈G) ⟂ PFX
                    
        #	Labor market:

        mkt_PL[r=R],		E_RA_PL[r] - sum(Y[r,s]*I_PL_Y[r,s] for s∈S) ⟂ PL[r]

        #	Capital stocks:

        mkt_PK[r=R,s=S],		E_RA_PK[r,s] - Y[r,s]*I_PK_Y[r,s] ⟂ PK[r,s]

        #	Margin supply and demand:

        mkt_PM[r=R,m=M],		MS[r,m]*O_MS_PM[r,m] - sum(A[r,g] * I_PM_A[r,m,g] for g∈G) ⟂ PM[r,m]

        #	Consumer demand:

        mkt_PC[r=R],		C[r]*O_C_PC[r] - D_PC_RA[r] ⟂ PC[r]


 
        
        #	Income balance:

        bal_RA[r=R],	RA[r] - (

        #	Endowment income from yh0[r,g]:

                    sum(PY[r,g]*E_RA_PY[r,g] for g∈G) +

        #	Wage income from ld0:

                     PL[r]*E_RA_PL[r] +

        #	Income associated with bopdef[r] and hhadj[r]:

                     PFX*E_RA_PFX[r] +

        #	Government and investment demand (g0[r,g] + i0[r,g]):

                     sum(PA[r,g]*E_RA_PA[r,g] for g∈G) +

        #	Capital earnings (kd0[r,s]):

                     sum(PK[r,s]*E_RA_PK[r,s] for s∈S) +

        #	Tax revenues are expressed as values per unit activity, so we
        #	need multiply these by the activity level to compute total income:

                     sum(R_Y_RA[r,s]*Y[r,s] for r∈R,s∈S if sum(ys0[[r],[s],:g]) > 0) +
                     sum(R_A_RA[r,g]*A[r,g] for r∈R,g∈G if a0[[r],[g]] + rx0[[r],[g]] == 0) 
        )⟂ RA[r]
    

    end)

 

    return model



end