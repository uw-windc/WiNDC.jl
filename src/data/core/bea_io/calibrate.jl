

"""
    calibrate_national!(GU::GamsUniverse)

Calibrate the national BEA IO data.
"""
function calibrate_national!(GU::GamsUniverse)

    parms_to_update = [(:ys0,:ys0_),
                       (:id0,:id0_),
                       (:ms0,:ms0_),
                       (:y0,:y0_),
                       (:fd0,:fd0_),
                       (:a0,:a0_),
                       (:x0,:x0_),
                       (:m0,:m0_),
                       (:md0,:md0_),
                       (:va0,:va0_),
                       (:fs0,:fs0_)
    ]


    models = Dict()

    for year∈GU[:yr]
        m = calibrate_national_model(GU,year)

        models[year] = m

        set_silent(m)
        optimize!(m)

        for (old,new)∈parms_to_update
            sets = [[elm for elm in GU[s]] for s∈domain(GU[old])[2:end]]
            for element in Iterators.product(sets...)
                
                elm = [[year]]         
                push!(elm,[[e] for e∈element]...)
                GU[old][elm...] = value(m[new][element...])
            end
        end
    end


    # A couple of parameters get created/updated after calibration
    @parameters(GU,begin
        bopdef0, (:yr,)
    end)

    for yr∈GU[:yr]
        GU[:bopdef0][[yr]] = sum(GU[:m0][[yr],[i]]-GU[:x0][[yr],[i]] for i∈GU[:i] if GU[:a0][[yr],[i]]!=0;init=0)

        for j∈GU[:j]
            GU[:s0][[yr],[j]] = sum(GU[:ys0][[yr],[j],:i])
        end

    end

    P = calibrate_zero_profit(GU)
    @assert sum(abs.(P[:yr,:j,:tmp])) ≈ 0 "Calibration has failed to satisfy the zero profit condition."

    

    P = calibrate_market_clearance(GU)
    @assert sum(abs.(P[:yr,:i,:tmp])) ≈ 0 "Calibration has failed to satisfy the market clearance condition."



    return (GU,models)

end


function calibrate_national_model(GU::GamsUniverse,year::Symbol)
    #year = Symbol(1997)


    #May go elsewhere
    deactivate(GU,:i,:use,:oth)
    deactivate(GU,:j,:use,:oth)
    

    I       = [i for i in GU[:i]]
    J       = [j for j in GU[:j]]
    M       = [m_ for m_ in GU[:m]]
    FD      = [fd for fd in GU[:fd]]
    VA      = [va for va in GU[:va]]
    PCE_FD  = [:pce]
    OTHFD   = [fd for fd in GU[:fd] if fd != :pce]

    IMRG = [:mvt,:fbt,:gmt]

    ys0 = GU[:ys0]
    id0 = GU[:id0]
    fd0 = GU[:fd0]
    va0 = GU[:va0]
    fs0 = GU[:fs0]
    ms0 = GU[:ms0]
    y0  = GU[:y0]
    id0 = GU[:id0]
    a0  = GU[:a0]
    x0  = GU[:x0]
    m0  = GU[:m0]
    md0 = GU[:md0]
    ty0 = GU[:ty0]
    ta0 = GU[:ta0]
    tm0 = GU[:tm0]


    lob = 0.01 #Lower bound ratio
    upb = 10 #upper bound ratio
    newnzpenalty = 1e3

    m = JuMP.Model(Ipopt.Optimizer)


    @variables(m,begin
        ys0_[j=J,i=I]   >= max(0,lob*ys0[[year],[j],[i]])	#"Calibrated variable ys0."
        ms0_[i=I,m_=M]  >= max(0,lob*ms0[[year],[i],[m_]]) #"Calibrated variable ms0." 
        y0_[i=I]        >= max(0,lob*y0[[year],[i]])		#"Calibrated variable y0."
        id0_[i=I,j=J]   >= max(0,lob*id0[[year],[i],[j]])  #"Calibrated variable id0."
        fd0_[i=I,fd=FD] >= max(0,lob*fd0[[year],[i],[fd]])	#"Calibrated variable fd0."
        a0_[i=I]        >= max(0,lob*a0[[year],[i]])     #"Calibrated variable a0."
        x0_[i=I]        >= max(0,lob*x0[[year],[i]])	    #"Calibrated variable x0."
        m0_[i=I]        >= max(0,lob*m0[[year],[i]])		#"Calibrated variable m0."
        md0_[m_=M,i=I]  >= max(0,lob*md0[[year],[m_],[i]]) #"Calibrated variable md0." 
        va0_[va=VA,j=J] >= max(0,lob*va0[[year],[va],[j]])	#"Calibrated variable va0."
        fs0_[I]         >= 0	                #"Calibrated variable fs0."
    end)





    function _set_upb(var,parm,sets...)
        for idx ∈ Iterators.product(sets...)
            ind = [[e] for e in idx]
            if parm[[year],ind...] != 0
                set_upper_bound(var[idx...],abs(upb*parm[[year],ind...]))
            end
        end
    end       

    _set_upb(ys0_,ys0,J,I)
    _set_upb(ms0_,ms0,I,M)
    _set_upb(y0_,y0,I)
    _set_upb(id0_,id0,I,J)
    _set_upb(fd0_,fd0,I,FD)
    _set_upb(a0_,a0,I)
    _set_upb(x0_,x0,I)
    _set_upb(m0_,m0,I)
    _set_upb(md0_,md0,M,I)
    _set_upb(va0_,va0,VA,J)


    function _fix(var,parm,sets...)
        for idx ∈ Iterators.product(sets...)
            ind = [[e] for e in idx]
            if parm[[year],ind...] == 0
                fix(var[idx...],0,force=true)
            end
        end
    end

    # Assume zero values remain zero values for multi-dimensional parameters:

    _fix(ys0_,ys0,J,I)
    _fix(id0_,id0,I,J)
    _fix(fd0_,fd0,I,FD)
    _fix(ms0_,ms0,I,M)
    _fix(va0_,va0,VA,J)

    # Fix certain parameters -- exogenous portions of final demand, value
    # added, imports, exports and household supply.
    

    for i∈I
        fix.(fs0_[i],fs0[year,i],force=true)
        fix.(m0_[i] ,m0[year,i] ,force=true)
        fix.(x0_[i] ,x0[year,i] ,force=true)
    end

    # Fix labor compensation to target NIPA table totals.

    fix.(va0_[:compen,J],va0[[year],[:compen],J],force=true)


    # No margin inputs to goods which only provide margins:

    fix.(md0_[M,IMRG] ,0,force=true)
    fix.(y0_[IMRG]    ,0,force=true)
    fix.(m0_[IMRG]    ,0,force=true)
    fix.(x0_[IMRG]    ,0,force=true)
    fix.(a0_[IMRG]    ,0,force=true)
    fix.(id0_[IMRG,J] ,0,force=true)
    fix.(fd0_[IMRG,FD],0,force=true)




    @expression(m,NEWNZ,
        sum(ys0_[j,i]  for j∈J,i∈I   if ys0[[year],[j],[i]]==0      ) 
        + sum(fs0_[i]    for i∈I       if fs0[[year],[i]]==0        ) 
        + sum(ms0_[i,m_] for i∈I,m_∈M  if ms0[[year],[i],[m_]]==0   ) 
        + sum(y0_[i]     for i∈I       if y0[[year],[i]]==0         ) 
        + sum(id0_[i,j]  for i∈I,j∈J   if id0[[year],[i],[j]]==0    ) 
        + sum(fd0_[i,fd] for i∈I,fd∈FD if fd0[[year],[i],[fd]]==0   ) 
        + sum(va0_[va,j] for va∈VA,j∈J if va0[[year],[va],[j]]==0   ) 
        + sum(a0_[i]     for i∈I       if a0[[year],[i]]==0         ) 
        + sum(x0_[i]     for i∈I       if x0[[year],[i]]==0         ) 
        + sum(m0_[i]     for i∈I       if m0[[year],[i]]==0         ) 
        + sum(md0_[m_,i] for m_∈M,i∈I  if md0[[year],[m_],[i]]==0   )
    )


    @objective(m,Min, 
        sum(abs(ys0[[year],[j],[i]])  * (ys0_[j,i]/ys0[[year],[j],[i]]-1)^2   for i∈I,j∈J       if ys0[[year],[j],[i]]!=0       )
        + sum(abs(id0[[year],[i],[j]])  * (id0_[i,j]/id0[[year],[i],[j]]-1)^2   for i∈I,j∈J       if id0[[year],[i],[j]]!=0     )
        + sum(abs(fd0[[year],[i],[fd]]) * (fd0_[i,fd]/fd0[[year],[i],[fd]]-1)^2 for i∈I,fd∈PCE_FD if fd0[[year],[i],[fd]]!=0    )
        + sum(abs(va0[[year],[va],[j]]) * (va0_[va,j]/va0[[year],[va],[j]]-1)^2 for va∈VA,j∈J     if va0[[year],[va],[j]]!=0    )

        + sum(abs(fd0[[year],[i],[fd]]) * (fd0_[i,fd]/fd0[[year],[i],[fd]]-1)^2 for i∈I,fd∈OTHFD  if fd0[[year],[i],[fd]]!=0    )
        + sum(abs(fs0[[year],[i]])      * (fs0_[i]/fs0[[year],[i]]-1)^2         for i∈I           if fs0[[year],[i]]!=0         )
        + sum(abs(ms0[[year],[i],[m_]]) * (ms0_[i,m_]/ms0[[year],[i],[m_]]-1)^2 for i∈I,m_∈M      if ms0[[year],[i],[m_]]!=0    )
        + sum(abs(y0[[year],[i]])       * (y0_[i]/y0[[year],[i]]-1)^2           for i∈I           if y0[[year],[i]]!=0          )
        + sum(abs(a0[[year],[i]])       * (a0_[i]/a0[[year],[i]]-1)^2           for i∈I           if a0[[year],[i]]!=0          )
        + sum(abs(x0[[year],[i]])       * (x0_[i]/x0[[year],[i]]-1)^2           for i∈I           if x0[[year],[i]]!=0          )
        + sum(abs(m0[[year],[i]])       * (m0_[i]/m0[[year],[i]]-1)^2           for i∈I           if m0[[year],[i]]!=0          )
        + sum(abs(md0[[year],[m_],[i]]) * (md0_[m_,i]/md0[[year],[m_],[i]]-1)^2 for m_∈M,i∈I      if md0[[year],[m_],[i]]!=0    )

        + newnzpenalty * NEWNZ
    )


    @constraints(m,begin
    mkt_py[i=I], 
        sum(ys0_[J,i]) + fs0_[i] == sum(ms0_[i,M]) + y0_[i]
    mkt_pa[i=I],
        a0_[i] == sum(id0_[i,J]) + sum(fd0_[i,FD])
    mkt_pm[m_=M],
        sum(ms0_[I,m_]) == sum(md0_[m_,I])
    prf_y[j=J],
        (1-ty0[[year],[j]])*sum(ys0_[j,I]) == sum(id0_[I,j]) + sum(va0_[VA,j])
    prf_a[i=I],
        a0_[i]*(1-ta0[[year],[i]]) + x0_[i] == y0_[i] + m0_[i]*(1+tm0[[year],[i]]) + sum(md0_[M,i])
    end)

    1;


    return m

end



function calibrate_zero_profit(GU::GamsUniverse)
    G = deepcopy(GU)

    @set(G,tmp,"tmp",begin
        Y,""
        A,""
    end)

    @parameters(G,begin
        profit, (:yr,:j,:tmp), (description = "Zero profit condidtions",)
    end)

    YR = G[:yr]
    J = G[:j]
    I = G[:i]
    VA = G[:va]
    M = G[:m]

    parm = G[:profit]



    for yr∈YR,j∈J
        parm[[yr],[j],[:Y]] = G[:s0][[yr],[j]] !=0 ? round((1-G[:ty0][[yr],[j]]) * sum(G[:ys0][[yr],[j],I]) - sum(G[:id0][[yr],I,[j]]) - sum(G[:va0][[yr],VA,[j]]),digits = 6) : 0

        parm[[yr],[j],[:A]] = round(G[:a0][[yr],[j]]*(1-G[:ta0][[yr],[j]]) + G[:x0][[yr],[j]] - G[:y0][[yr],[j]] - G[:m0][[yr],[j]]*(1+G[:tm0][[yr],[j]]) - sum(G[:md0][[yr],M,[j]]), digits = 6)

    end

    return parm

end



function calibrate_market_clearance(GU::GamsUniverse)
    G = deepcopy(GU)

    @set(G,tmp,"tmp",begin
        PA,""
        PY,""
    end)

    @parameters(G,begin
        market, (:yr,:i,:tmp), (description = "Market clearance condition",)
    end)

    YR = G[:yr]
    J = G[:j]
    I = G[:i]
    FD = G[:fd]
    M = G[:m]

    parm = G[:market]



    for yr∈YR,i∈I
        parm[[yr],[i],[:PA]] = round( G[:a0][[yr],[i]] - sum(G[:fd0][[yr],[i],FD];init=0)- sum(G[:id0][[yr],[i],[j]] for j∈J if G[:s0][[yr],[j]]!=0;init=0),digits = 6)
        parm[[yr],[i],[:PY]] = round( sum(G[:ys0][[yr],[j],[i]] for j∈J if G[:s0][[yr],[j]]!=0;init=0) + G[:fs0][[yr],[i]] - G[:y0][[yr],[i]] - sum(G[:ms0][[yr],[i],M];init=0),digits=6)
    end

    return parm

end