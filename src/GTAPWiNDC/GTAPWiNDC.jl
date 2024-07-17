

m = Model(PATHSolver.Optimizer)

@variables(m,begin
    #	$sectors:
    Y[G,R,S]>=0 #		Production (includes I and G)
    C[R,S,H]>=0 #		Consumption 
    X[I,R,S]>=0 #		Disposition
    Z[I,R,S]>=0 #		Armington demand
    FT[F,R,S]>=0 #		Specific factor transformation
    M[I,R]>=0 #			Import
    YT[J]>=0 #			Transport

    #	$commodities:
    PY[G,R,S]>=0 #		Output price
    PZ[I,R,S]>=0 #		Armington composite price
    PD[I,R,S]>=0 #		Local goods price
    P[I,R]>=0 #			National goods price
    PC[R,S,H]>=0 #		Consumption price 
    PF[F,R,S]>=0 #		Primary factors rent
    PS[F,G,R,S]>=0 #		Sector-specific primary factors
    PM[I,R]>=0 #			Import price
    PT[J]>=0 #			Transportation services

    #	$consumer:
    RH[R,S,H]>=0 #		Representative household
    GOVT[R]>=0 #			Public expenditure
    INV[R]>=0 #			Investment
end)


theta_pl_y_va = GamsParameter(GU, (:r,:s), "Labor value share")
theta_PFX_X = GamsParameter(GU, (:r,:g), "Export value share")
theta_PN_X = GamsParameter(GU, (:r,:g), "National value share")
theta_PD_X = GamsParameter(GU, (:r,:g), "Domestic value share")
theta_PN_A_d = GamsParameter(GU, (:r,:g), "National value share in nest d")
theta_PFX_A_dm = GamsParameter(GU, (:r,:g), "Imported value share in nest dm")
thetac = GamsParameter(GU, (:r,:g,:h), "Consumption value share")
betaks = GamsParameter(GU, (:r,:s), "Capital supply value share")
theta_PC_RA = GamsParameter(GU, (:r,:h), "Value share of PC in RA")

#=
theta_pl_y_va[:r,:s]$ld0[:r,:s] = ld0[:r,:s]/(ld0[:r,:s]+kd0[:r,:s]*(1+tk0[:r]))
theta_PFX_X[:r,:g]$x_[:r,:g] = (x0[:r,:g]-rx0[:r,:g])/(x0[:r,:g]-rx0[:r,:g] + xn0[:r,:g] + xd0[:r,:g])
theta_PN_X[:r,:g]$x_[:r,:g] = xn0[:r,:g]/(x0[:r,:g]-rx0[:r,:g] + xn0[:r,:g] + xd0[:r,:g])
theta_PD_X[:r,:g]$x_[:r,:g] = xd0[:r,:g]/(x0[:r,:g]-rx0[:r,:g] + xn0[:r,:g] + xd0[:r,:g])
theta_PN_A_d[:r,:g]$a_[:r,:g] = nd0[:r,:g]/(nd0[:r,:g]+dd0[:r,:g])
theta_PFX_A_dm[:r,:g]$a_[:r,:g] = m0[:r,:g]*(1+tm0[:r,:g])/(m0[:r,:g]*(1+tm0[:r,:g])+nd0[:r,:g]+dd0[:r,:g])
thetac[:r,:g,:h] = cd0_h[:r,:g,:h]/sum(cd0_h[:r,[g],:h] for g in G)
betaks[:r,:s] = kd0[:r,:s] / sum(kd0[[r],[s]] for r in R,s in S)
theta_PC_RA[:r,:h] = c0_h[:r,:h]/(c0_h[:r,:h]+lsr0[:r,:h])

=#



@expressions(m,begin
	PI_Y_VA[r=R,s=S],
		(PL[r]^theta_pl_y_va[[r],[s]] * (RK[r,s]*(1+tk[[r],[s]])/(1+tk0[[r]]))^(1-theta_pl_y_va[[r],[s]]))
	O_Y_PY[r=R,g=G,s=S],
		ys0[[r],[s],[g]]
	I_PA_Y[r=R,g=G,s=S],
		id0[[r],[g],[s]]
	I_PL_Y[r=R,s=S],
		(ld0[[r],[s]] * PI_Y_VA[r,s] / PL[r])
	I_RK_Y[r=R,s=S],
		(kd0[[r],[s]] * PI_Y_VA[r,s]*(1+tk0[[r]])/(RK[r,s]*(1+tk[[r],[s]])))
	PI_X[r=R,g=G],
		((theta_PFX_X[r,g]*PFX^(1+4) + theta_PN_X[r,g]*PN[g]^(1+4) + theta_PD_X[r,g]*PD[r,g]^(1+4))^(1/(1+4)))
	O_X_PFX[r=R,g=G],
		((x0[[r],[g]]-rx0[[r],[g]])*(PFX/PI_X[r,g])^4)
	O_X_PN[g=G,r=R],
		(xn0[[r],[g]]*(PN[g]/PI_X[r,g])^4)
	O_X_PD[r=R,g=G],
		(xd0[[r],[g]]*(PD[r,g]/PI_X[r,g])^4)
	I_PY_X[r=R,g=G],
		s0[[r],[g]]
	PI_A_D[r=R,g=G],
		((theta_PN_A_d[[r],[g]]*PN[g]^(1-2)+(1-theta_PN_A_d[[r],[g]])*PD[r,g]^(1-2))^(1/(1-2)))
	PI_A_DM[r=R,g=G],
		((theta_PFX_A_dm[[r],[g]]*(PFX*(1+tm[[r],[g]])/(1+tm0[[r],[g]]))^(1-4)+(1-theta_PFX_A_dm[[r],[g]])*PI_A_D[r,g]^(1-4))^(1/(1-4)))
	O_A_PA[r=R,g=G],
		a0[[r],[g]]
	O_A_PFX[r=R,g=G],
		rx0[[r],[g]]
	I_PN_A[g=G,r=R],
		(nd0[[r],[g]]*(PI_A_DM[r,g]/PI_A_D[r,g])^4 * (PI_A_D[r,g]/PN[g])^2)
	I_PD_A[r=R,g=G],
		(dd0[[r],[g]]*(PI_A_DM[r,g]/PI_A_D[r,g])^4 * (PI_A_D[r,g]/PD[r,g])^2)
	I_PFX_A[r=R,g=G],
		(m0[[r],[g]]*(PI_A_DM[r,g]*(1+tm0[[r],[g]])/(PFX*(1+tm[[r],[g]])))^4)
	I_PM_A[r=R,m=M,g=G],
		md0[[r],[m],[g]]
	O_MS_PM[r=R,m=M],
		(sum(md0[[r],[m],[gm]] for gm = GM))
	I_PN_MS[gm=GM,r=R,m=M],
		(nm0[[r],[gm],[m]])
	I_PD_MS[r=R,gm=GM,m=M],
		(dm0[[r],[gm],[m]])
	PI_C[r=R,h=H],
		(prod(PA[r,g]^thetac[[r],[g],[h]] for g = G))
	O_C_PC[r=R,h=H],
		(c0_h[[r],[h]])
	I_PA_C[r=R,g=G,h=H],
		(cd0_h[[r],[g],[h]]*PI_C[r,h]/PA[r,g]) #! N.B. Set g enters PI_C but is local to that macro
	O_LS_PL[q=Q,r=R,h=H],
		(le0[[r],[q],[h]])
	I_PLS_LS[r=R,h=H],
		(ls0[[r],[h]])
	PI_KS,
		(sum((r,s),betaks[[r],[s]]*RK[r,s]^(1+etak))^(1/(1+etak)))
	O_KS_RK[r=R,s=S],
		(kd0[[r],[s]]*(RK[r,s]/PI_KS)^etak)
	I_RKS_KS,
		(sum((r,s),kd0[[r],[s]]))
	PI_RA[r=R,h=H],
		((theta_PC_RA[r,h]*PC[r,h]^(1-esubL[[r],[h]]) + (1-theta_PC_RA[r,h])*PLS[r,h]^(1-esubL[[r],[h]]))^(1/(1-esubL[[r],[h]])))
	W_RA[r=R,h=H],
		(RA[r,h]/((c0_h[[r],[h]]+lsr0[[r],[h]])*PI_RA[r,h]))
	D_PC_RA[r=R,h=H],
		(c0_h[[r],[h]] * W_RA[r,h] * (PI_RA[r,h]/PC[r,h])^esubL[[r],[h]])
	D_PLS_RA[r=R,h=H],
		(lsr0[[r],[h]] * W_RA[r,h] * (PI_RA[r,h]/PLS[r,h])^esubL[[r],[h]])
	E_RA_PLS[r=R,h=H],
		(ls0[[r],[h]]+lsr0[[r],[h]])
	E_RA_PK[r=R,h=H],
		(ke0[[r],[h]])
	E_RA_PFX[r=R,h=H],
		(TRANS*sum(hhtrn0[[r],[h],[trn]] for trn = TRN)-SAVRATE*sav0[[r],[h]])
	D_PK_NYSE,
		(NYSE/PK)
	E_NYSE_PY[r=R,g=G],
		(yh0[[r],[g]])
	E_NYSE_RKS,
		(SSK*sum([r,s],kd0[[r],[s]]))
	D_PA_INVEST[r=R,g=G],
		(i0[[r],[g]] * INVEST/sum((r,g),PA[r,g]*i0[[r],[g]]))
	E_INVEST_PFX,
		(fsav0+SAVRATE*totsav0) 
	D_PA_GOVT[r=R,g=G],
		(g0[[r],[g]]*GOVT/sum((r,g),PA[r,g]*g0[[r],[g]]))
	E_GOVT_PFX,
		(govdef0-TRANS*sum([r,h],trn0[[r],[h]]))
end)

@constraints(m, begin
    prf_Y[r=R,s=S;y_[[r],[s]]!=0],
        sum(PA[r,g]*I_PA_Y[r,g,s] for g in G) + I_PL_Y[r,s]*PL[r] + I_RK_Y[r,s]*RK[r,s]*(1+tk[[r],[s]])  - 
        ( sum(PY[r,g]*O_Y_PY[r,g,s]*(1-ty[[r],[s]]) for g in G) )
    prf_X[r=R,g=G;x_[[r],[g]]!=0],
        PY[r,g]*I_PY_X[r,g]  - ( PFX*O_X_PFX[r,g] + PN[g]*O_X_PN[g,r] + PD[r,g]*O_X_PD[r,g] )
    prf_a[r=R,g=G;a_[[r],[g]]!=0],
        sum(PM[r,m]*I_PM_A[r,m,g] for m in M) + PFX*(1+tm[[r],[g]])*I_PFX_A[r,g] + PD[r,g]*I_PD_A[r,g] + 
        PN[g]*I_PN_A[g,r]  - ( PFX*O_A_PFX[r,g] + PA[r,g]*O_A_PA[r,g]*(1-ta[[r],[g]]) )
    prf_MS[r=R,m=M],
        sum(gm, PD[r,gm]*I_PD_MS[r,gm,m] + PN[gm]*I_PN_MS[gm,r,m])  - ( PM[r,m]*O_MS_PM[r,m] )
    prf_c[r=R,h=H],
        sum( PA[r,g]*I_PA_C[r,g,h] for g in G)  - ( PC[r,h]*O_C_PC[r,h] )
    prf_LS[r=R,h=H],
        PLS[r,h]*I_PLS_LS[r,h]  - ( sum( PL[q]*O_LS_PL[q,r,h]*(1-tl[[r],[h]]) for q in Q) )
    prf_ks,
        RKS*I_RKS_KS  - ( sum( RK[r,s]*O_KS_RK[r,s] for r in R, s in S) )
    bal_ra[r=R,h=H],
        RA[r,h]  - ( PLS[r,h] * E_RA_PLS[r,h] + PFX * E_RA_PFX[r,h] + PK * E_RA_PK[r,h] )
    bal_NYSE,
        NYSE  - ( sum(PY[r,g]*E_NYSE_PY[r,g] for r in R, g in G) + RKS*E_NYSE_RKS )
    bal_INVEST,
        INVEST  - ( PFX*fsav0 + SAVRATE*PFX*totsav0 )
    bal_GOVT,
        GOVT  - ( PFX*(govdef0 - TRANS*sum(trn0[[r],[h]]) for r in R, h in H) + 
        sum( Y[r,s] * (sum(PY[r,g]*ys0[[r],[s],[g]]*ty[[r],[s]] for g in G for r in R, s in S if y_[[r],[s]]!=0) + 
        I_RK_Y[r,s]*RK[r,s]*tk[[r],[s]])) + sum(a_[r,g], A[r,g] * (PA[r,g]*ta[[r],[g]]*a0[[r],[g]] + PFX*I_PFX_A[r,g]*tm[[r],[g]])) + 
        sum([r,h,q],   LS[r,h] * PL[q] * O_LS_PL[q,r,h] * tl[[r],[h]]) )
    aux_ssk,
        sum(i0[[r],[g]]*PA[r,g] for r in R, g in G)  - ( sum(i0[[r],[g]] for r in R, g in G)*RKS )
    aux_savrate,
        INVEST  - ( sum( PA[r,g]*i0[[r],[g]] for r in R, g in G)*SSK )
    aux_trans,
        GOVT  - ( sum(PA[r,g]*g0[[r],[g]] for r in R, g in G) )
    mkt_PA[r=R,g=G;a0[[r],[g]]!=0],
        sum( A[r,g]*O_A_PA[r,g] for r in R, g in G if a_[[r],[g]]!=0)  - 
        ( sum( Y[r,s]*I_PA_Y[r,g,s] for r in R, s in S if y_[[r],[s]]!=0) + 
        sum( C[r,h]*I_PA_C[r,g,h] for h in H) + D_PA_INVEST[r,g] + D_PA_GOVT[r,g] )
    mkt_PY[r=R,g=G;s0[[r],[g]]!=0],
        sum( Y[r,s]*O_Y_PY[r,g,s] for r in R, s in S if y_[[r],[s]]!=0) + E_NYSE_PY[r,g]  - ( 
            sum( X[r,g]*I_PY_X[r,g] for r in R, g in G if x_[[r],[g]]!=0) )
    mkt_PD[r=R,g=G],
        sum( X[r,g]*O_X_PD[r,g] for r in R, g in G if x_[[r],[g]]!=0)  - ( 
            sum( A[r,g]*I_PD_A[r,g] for r in R, g in G if a_[[r],[g]]!=0) + 
            sum( MS[r,m]*I_PD_MS[r,gm,m] for m in M, gm in GM) )
    mkt_RK[r=R,s=S;kd0[[r],[s]]!=0],
        KS*O_KS_RK[r,s]  - ( Y[r,s]*I_RK_Y[r,s] )
    mkt_RKS,
        E_NYSE_RKS  - ( KS*I_RKS_KS )
    mkt_PM[r=R,m=M],
        MS[r,m]*O_MS_PM[r,m]  - ( sum(A[r,g]*I_PM_A[r,m,g] for r in R, g in G if a_[[r],[g]]!=0) )
    mkt_PC[r=R,h=H],
        C[r,h]*O_C_PC[r,h]  - ( D_PC_RA[r,h] )
    mkt_PN[g=G],
        sum( X[r,g]*O_X_PN[g,r] for r in R, g in G if x_[[r],[g]]!=0)  - ( 
            sum( A[r,g]*I_PN_A[g,r] for r in R, g in G if a_[[r],[g]]!=0) + 
            sum([r,m,gm], MS[r,m]*I_PN_MS[gm,r,m]) )
    mkt_PLS[r=R,h=H],
        E_RA_pls[[r],[h]]  - ( D_PLS_RA[r,h] + LS[r,h] * I_PLS_LS[r,h] )
    mkt_PL[r=R],
        sum( LS[r,h]*O_LS_PL[q,r,h] for q in Q, r in R, h in H)  - ( 
            sum( Y[r,s]*I_PL_Y[r,s] for r in R, s in S if y_[[r],[s]]!=0) )
    mkt_PK,
        sum( E_RA_PK[r,h] for r in R, h in H)  - ( D_PK_NYSE )
    mkt_PFX,
        sum( X[r,g]*O_X_PFX[r,g] for r in R, g in G if x_[[r],[g]]!=0) + 
        sum( A[r,g]*O_A_PFX[r,g] for r in R, g in G if a_[[r],[g]]!=0) + 
        sum(E_RA_PFX[r,h] for r in R, h in H) + E_INVEST_PFX + E_GOVT_PFX  - ( 
        sum( A[r,g]*I_PFX_A[r,g] for r in R, g in G if a_[[r],[g]]!=0) )
end)