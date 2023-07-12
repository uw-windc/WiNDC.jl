

"""
Self notes:
    1. v0_0 is multi year, va0 is single year
    2. The four theta's get defined as new parameters
"""

function national_model_mcp(GU)


    #################
    ### GU ##########
    #################

    VA = GU[:va]
    J = GU[:j]
    I = GU[:i]
    M = GU[:m]


    Y_ = [j for j in GU[:y_] if sum(GU[:ys0][[j],[i]] for i∈I)!=0]
    A_ = [i for i in GU[:a_] if GU[:a0]!=0]
    PY_ = [i for i in GU[:py_] if sum(GU[:ys0][[j],[i]] for j∈J)!=0]
    XFD = [fd for fd in GU[:xfd] if fd!=:pce]


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


    ty = GU[:ty]
    ms0 = GU[:ms0]
    bopdef = GU[:bopdef][]
    fs0 = GU[:fs0]
    ys0 = GU[:ys0]
    id0 = GU[:id0]
    md0 = GU[:md0]

    tm = GU[:tm]
    ta = GU[:ta]




    

    thetava = GamsParameter(GU,(:va,:j)) #GU[:thetava]
    thetam = GamsParameter(GU,(:i,))     #GU[:thetam]
    thetax = GamsParameter(GU,(:i,))     #GU[:thetax]
    thetac = GamsParameter(GU,(:i),)     #GU[:thetac]

    #thetava[:va,:j] = 0*GU[:thetava][:va,:j]
    #thetam[:i] = 0*GU[:thetam][:i]
    #thetax[:i] = 0*GU[:thetax][:i]
    #thetac[:i] = 0*GU[:thetac][:i]


    for va∈VA, j∈J
        if va0[[va],[j]]≠0
            thetava[[va],[j]] = va0[[va],[j]]/sum(va0[[v],[j]] for v∈VA)
        end
    end

    mask = m0.value .!=0
    thetam[mask] = m0[mask].*(1 .+tm0[mask])./(m0[mask].*(1 .+tm0[mask] ).+ y0[mask])
    
    mask = x0.value .!=0
    thetax[mask] = x0[mask]./(x0[mask].+a0[mask].*(1 .-ta0[mask]))

    thetac[:i] = fd0[:i,[:pce]]./sum(fd0[:i,[:pce]])
    

    #######################
    ## Model starts here ##
    #######################

    m = MCPModel()

    @variables(m,begin
        Y[J]>=0,    (start = 1,)
        A[I]>=0,    (start = 1,)
        MS[M]>=0,   (start = 1,)
        PA[I]>=0,   (start = 1,)
        PY[I]>=0,   (start = 1,)
        PVA[VA]>=0, (start = 1,)
        PM[M]>=0,   (start = 1,)
        PFX>=0,     (start = 1,)
        RA>=0,      (start = 1000,)
    end)

    ####################
    ## Macros in Gams ##
    ####################
    @mapping(m, CVA[j=J],
        prod(PVA[va]^thetava[[va],[j]] for va∈VA)
    )

    @mapping(m, PMD[i=I],
        (thetam[[i]]*(PFX*(1+tm[[i]])/(1+tm0[[i]]))^(1-2) + (1-thetam[[i]])*PY[i]^(1-2))^(1/(1-2))
    )

    @mapping(m, PXD[i=I],
        (thetax[[i]]*PFX^(1+2) + (1-thetax[[i]])*(PA[i]*(1-ta[[i]])/(1-ta0[[i]]))^(1+2))^(1/(1+2))
    )

    @mapping(m, MD[i=I],
        A[i]*m0[[i]]*( (PMD[i]*(1+tm0[[i]])) / (PFX*(1+tm[[i]])))^2
    )

    @mapping(m, YD[i=I],
        A[i]*y0[[i]]*(PMD[i]/PY[i])^2
    )

    @mapping(m, XS[i=I],
        A[i]*x0[[i]]*(PFX/PXD[i])^2
    )

    @mapping(m, DS[i = I],
        A[i]*a0[[i]]*(PA[i]*(1-ta[[i]])/(PXD[i]*(1-ta0[[i]])))^2
    )

    ########################
    ## End of GAMS Macros ##
    ########################

    #defined on y_(j)
    @mapping(m,prf_Y[j=Y_],
       CVA[j]*sum(va0[[va],[j]] for va∈VA) +sum(PA[i]*id0[[i],[j]] for i∈I) - sum(PY[i]*ys0[[j],[i]] for i∈I)*(1-ty[[j]])
    )


    
    #defined on a_(i)
    @mapping(m,prf_A[i = A_],
        sum(PM[m_]*md0[[m_],[i]] for m_∈M) + 
        PMD[i] * 
        (y0[[i]] +(1+tm0[[i]])*m0[[i]]) -
        PXD[i] *
        (x0[[i]] + a0[[i]]*(1-ta0[[i]]))
    )


    @mapping(m,prf_MS[m_ = M],
        sum(PY[i]*ms0[[i],[m_]] for i∈I) - 
        PM[m_]*sum(ms0[[i],[m_]] for i∈I)
    )


    @mapping(m,bal_RA,
        -RA + sum(PY[i]*GU[:fs0][[i]] for i∈I) + PFX*bopdef
        - sum(PA[i]*fd0[[i],[xfd]] for i∈I,xfd∈XFD) + sum(PVA[va]*va0[[va],[j]] for va∈VA,j∈J)
        + sum(A[i]*(a0[[i]]*PA[i]*ta[[i]] + PFX*MD[i]*tm[[i]]) for i∈I)
        + sum(Y[j]*sum(ys0[[j],[i]]*PY[i] for i∈I)*ty[[j]] for j∈J)
    )

    @mapping(m, mkt_PA[i = A_],
        -DS[i] + thetac[[i]] * RA/PA[i] + sum(fd0[[i],[xfd]] for xfd∈XFD)
        + sum(Y[j]*id0[[i],[j]] for j∈Y_)
    )

    @mapping(m, mkt_PY[i=I],
        -sum(Y[j]*ys0[[j],[i]] for j∈Y_)
        + sum(MS[m_]*ms0[[i],[m_]] for m_∈M) + YD[i]
    )


    @mapping(m, mkt_PVA[va = VA],
        -sum(va0[[va],[j]] for j∈J)
        + sum(Y[j]*va0[[va],[j]]*CVA[j]/PVA[va] for j∈Y_)
    )

    @mapping(m, mkt_PM[m_ = M],
        MS[m_]*sum(ms0[[i],[m_]] for i∈I)
        - sum(A[i]*md0[[m_],[i]] for i∈I if a0[[i]]≠0)
    )

    @mapping(m, mkt_PFX,
        sum(XS[i] for i∈A_) + bopdef
        - sum(MD[i] for i∈A_)
    )


    @complementarity(m, prf_Y, Y)
    @complementarity(m, prf_A, A)
    @complementarity(m, prf_MS, MS)
    @complementarity(m, bal_RA, RA)
    @complementarity(m, mkt_PA, PA)
    @complementarity(m, mkt_PY, PY)
    @complementarity(m, mkt_PVA, PVA)
    @complementarity(m, mkt_PM, PM)
    @complementarity(m, mkt_PFX, PFX)


    return m
end