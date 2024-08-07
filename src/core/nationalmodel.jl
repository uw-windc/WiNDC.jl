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
    ## GamsStructure.Parameters ######
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
    
    ty = GamsStructure.Parameter(GU,(:yr,:i))
    tm = GamsStructure.Parameter(GU,(:yr,:i))
    ta = GamsStructure.Parameter(GU,(:yr,:i))
    
    ty[:yr,:i] = GU[:ty0][:yr,:i] 
    tm[:yr,:i] = GU[:tm0][:yr,:i].*0 #for the counterfactual
    ta[:yr,:i] = GU[:ta0][:yr,:i].*0 #for the counterfactual
    
    
    thetava = GamsStructure.Parameter(GU,(:va,:j)) #GU[:thetava]
    thetam = GamsStructure.Parameter(GU,(:i,))     #GU[:thetam]
    thetax = GamsStructure.Parameter(GU,(:i,))     #GU[:thetax]
    thetac = GamsStructure.Parameter(GU,(:i,))     #GU[:thetac]
    
    
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
    

        #thetac[:i] = fd0[[year],:i,[:pce]]./sum(fd0[[year],:i,[:pce]])
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

