*-------------------------------------------------------------------------------
* Carbon Capture and Sequestration
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Assumption for leakage in % per year --leak_input=0.0001
$setglobal leak_input 0

* Value estimates to consider (low,best,high)
$setglobal ccs_stor_cost 'best'
$setglobal ccs_stor_cap_max 'best'

*-------------------------------------------------------------------------------

$elseif %phase%=='sets'

set e /
    ccs        # Sequestered CO2
    co2leak    # CO2 leakages
    ccs_plant  # Sequestered CO2 from power plants and industry
/;

set map_e(e,ee) 'Relationships between Sectoral Emissions' /
    co2.co2leak
    ccs.ccs_plant
/;
set sink /
    ccs_plant
/;

set jccs(jfed) 'Electrical Actual Energy Technology Sectors with CCS' /
    elcigcc
    elbigcc
    elgasccs
    elpc_ccs
    elpc_oxy
/;

set cce(e) 'Emissions-related entities that cost' /
    ccs_plant
/;

* --learning curves -- *
set jlccs(jinv) 'Set of Electrical CCS technology with learning by doing' /
    elcigcc
    elbigcc
    elgasccs
    elpc_ccs
    elpc_oxy
/;

alias(jlccs,jllccs);

* -- Storage -- *
set ccs_stor   'different storage technologies' /
    aqui_on
    aqui_off
    oil_gas_no_eor_on
    oil_gas_no_eor_off
    eor_on
    eor_off
    ecbm
/;

set ccs_stor_aqui(ccs_stor) 'aquifer storage ON and OFF'/
    aqui_on
    aqui_off
/;

set ccs_stor_og_eor 'oil and gas storage ON and OFF, including eor'/
    oil_gas_on
    oil_gas_off
/;

set ccs_stor_og(ccs_stor) 'oil and gas storage ON and OFF, excluding eor'/
    oil_gas_no_eor_on
    oil_gas_no_eor_off
/;

set ccs_stor_eor(ccs_stor) ' eor'/
    eor_on
    eor_off
/;

set ccs_stor_estim 'low, best, high case of storage capacity'/
    low
    best
    high
/;

set ccs_stor_dist_cat 'how distances are referred to in the make data file' /
    aquif
    oil_gas_onshore
    oil_gas_offshore
    coal_beds
/;

set map_ccs_stor_og(ccs_stor_og,ccs_stor_og_eor,ccs_stor_eor) /
 oil_gas_no_eor_on.oil_gas_on.eor_on
 oil_gas_no_eor_off.oil_gas_off.eor_off
/
;

set map_ccs_stor_eor(ccs_stor_eor,ccs_stor_og_eor) /
eor_on.oil_gas_on
eor_off.oil_gas_off
/
;

set map_ccs_stor_dist_cat(ccs_stor_dist_cat,ccs_stor) /
    aquif.(aqui_on,aqui_off)
    oil_gas_onshore.(oil_gas_no_eor_on,eor_on)
    oil_gas_offshore.(oil_gas_no_eor_off,eor_off)
    coal_beds.ecbm
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_mod_ccs'

parameter ccs_capture_eff(jfed);
$loaddc ccs_capture_eff

parameter ccs_emi_capt(fuel);
$loaddc ccs_emi_capt

* Definition of floor costs for each country and technology
parameter ccs_floor_cost(*, n) 'Floor Investment Cost [T$/TW]';
$loaddc ccs_floor_cost

parameter ccs_stor_cap_aqui(n,*) 'Storage capacity for aquifers storage';
$loaddc ccs_stor_cap_aqui

parameter ccs_stor_cap_ecbm(n,*) 'Storage capacity for coal bed storage';
$loaddc ccs_stor_cap_ecbm

parameter ccs_stor_cap_og(n,*) 'Storage capacity for oil and gas fields storage';
$loaddc ccs_stor_cap_og

parameter ccs_stor_cap_eor(n) 'Storage capacity for eor storage';
$loaddc ccs_stor_cap_eor

parameter ccs_stor_share_onoff(n,*) 'Share of storage capacity ONshore and OFFshore';
$loaddc ccs_stor_share_onoff

parameter ccs_stor_dist(n,*) 'average distance in the country for different storage types in [km]';
$loaddc ccs_stor_dist

* LEARNING

parameter ccs_spill_factor(jlccs,jllccs) 'Matrix of share in learning contribution between ccs technologies';
$loaddc ccs_spill_factor

* Table of learning coefficient for each tech
parameter ccs_learn0(jlccs);
$loaddc ccs_learn0

parameter ccs_learn(jlccs,t);
ccs_learn(jlccs,t) = ccs_learn0(jlccs);

parameter ccs_wcum0(jlccs) 'minimum installed cumulated capacity after which learning starts [TW]';
$loaddc ccs_wcum0

parameter ccs_wcum_spill(jlccs,t) 'installed capacity at each time step considering spillover effect among technologies [TW]'
;

* STORAGE

parameter ccs_stor_dist_avg(n,ccs_stor) 'Avg distance from CCS power plants to storage sites [km] from Hendriks 2004';

loop((ccs_stor_dist_cat,ccs_stor)$(map_ccs_stor_dist_cat(ccs_stor_dist_cat,ccs_stor)),
    ccs_stor_dist_avg(n,ccs_stor) = ccs_stor_dist(n,ccs_stor_dist_cat)
);

parameter ccs_stor_cost_estim(ccs_stor,ccs_stor_estim) 'storage cost, [T$/GtonCO2]';
$loaddc ccs_stor_cost_estim
$gdxin

parameter ccs_stor_cost(ccs_stor,n) 'storage cost, [T$/GtonCO2]';
ccs_stor_cost(ccs_stor,n) = ccs_stor_cost_estim(ccs_stor,'%ccs_stor_cost%');

scalar ccs_transp_coeff 'coefficients of transport costs, considering that it is almost constant for large mass flow rates [$/(tonCO2*km)]' / 0.006667034 /
;

parameter ccs_stor_cap_og_onoff(n,ccs_stor_estim,ccs_stor_og_eor) 'storage capacity of oil and gas fields divided into ONshore and OFFshore GtCO2';
parameter ccs_stor_cap_max(n,ccs_stor_estim,ccs_stor)             'storage capacity of each storage type GtCO2';
parameter ccs_leak_rate(ccs_stor,t,n)                             '%/yr of cumulated stored CO2 leakages';

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

* Storage capacity: total of aquifer dividing into ON and OFF
ccs_stor_cap_max(n,ccs_stor_estim,ccs_stor_aqui) = ccs_stor_cap_aqui(n,ccs_stor_estim) * ccs_stor_share_onoff(n,ccs_stor_aqui);

* Storage capacity: total of og, eor included
ccs_stor_cap_og_onoff(n,ccs_stor_estim,ccs_stor_og_eor) = ccs_stor_cap_og(n,ccs_stor_estim) * ccs_stor_share_onoff(n,ccs_stor_og_eor);

* Storage capacity: total of ecbm which is ON only
ccs_stor_cap_max(n,ccs_stor_estim,'ecbm') = ccs_stor_cap_ecbm(n,ccs_stor_estim);

* Storage capacity: total of eor dividing into ON and OFF
loop((ccs_stor_eor,ccs_stor_og_eor)$(map_ccs_stor_eor(ccs_stor_eor,ccs_stor_og_eor)),
     ccs_stor_cap_max(n,ccs_stor_estim,ccs_stor_eor) = ccs_stor_cap_eor(n)*ccs_stor_share_onoff(n,ccs_stor_og_eor)
);

* Storage capacity: total of og, eor excluded
loop((ccs_stor_og,ccs_stor_og_eor,ccs_stor_eor)$(map_ccs_stor_og(ccs_stor_og,ccs_stor_og_eor,ccs_stor_eor)),
   ccs_stor_cap_max(n,ccs_stor_estim,ccs_stor_og) = max(ccs_stor_cap_og_onoff(n,ccs_stor_estim,ccs_stor_og_eor)-ccs_stor_cap_max(n,ccs_stor_estim,ccs_stor_eor),1e-7)
);

* Emission factors fix
ccs_emi_capt('coal') = emi_st('coal');
ccs_emi_capt('gas') = emi_st('gas');

ccs_leak_rate(ccs_stor,t,n) = %leak_input%;

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

positive variable MCOST_EMI(e,t,n) 'Average cost of emission-related entities [T$/GTonC]';
loadvarbnd(MCOST_EMI,'(e,t,n)',1e-5,1e-8,+inf);

positive variable Q_CCS(sink,ccs_stor,t,n) 'quantity of co2 that is stored for each storage type [GtonC]';
loadvarbnd(Q_CCS, '(sink, ccs_stor,t,n)',1e-8,1e-8,+inf);

positive variable CUM_Q_CCS(ccs_stor,t,n) 'cumulative quantity of co2 that is stored for each storage type [GtonC]';
loadvarbnd(CUM_Q_CCS, '(ccs_stor,t,n)',1e-8,1e-8,+inf);

Q_EMI.lo('ccs_plant',t,n) = 0;
COST_EMI.fx('ccs_plant',tfirst,n) = 0;
I_EN.up(jlccs,t,n)$(year(t) le 2010) = I_EN.lo(jlccs,t,n);
Q_CCS.fx(sink,ccs_stor,tfirst,n) = 1e-8;
CUM_Q_CCS.fx(ccs_stor,tfirst,n) =  sum(sink, tlen(tfirst) * Q_CCS.lo(sink,ccs_stor,tfirst,n));
CUM_Q_CCS.up(ccs_stor,tnofirst(t),n) = max(ccs_stor_cap_max(n,'%ccs_stor_cap_max%',ccs_stor) / c2co2,1e-5);

* Maximum CCS until 2030 1GtCO2
Q_EMI.up('ccs_plant',t,n)$(year(t) le 2025) = 0.5 / c2co2 * sum(ccs_stor,ccs_stor_cap_max(n,'%ccs_stor_cap_max%',ccs_stor)) / sum((ccs_stor,nn),ccs_stor_cap_max(nn,'%ccs_stor_cap_max%',ccs_stor));
Q_EMI.up('ccs_plant',t,n)$(year(t) eq 2030) = 1 / c2co2 * sum(ccs_stor,ccs_stor_cap_max(n,'%ccs_stor_cap_max%',ccs_stor)) / sum((ccs_stor,nn),ccs_stor_cap_max(n,'%ccs_stor_cap_max%',ccs_stor));

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eqq_emi_ccs_%clt%
eqcost_emi_sinks_%clt%
eq_stor_ccs_cum_%clt%
eq_emi_stor_ccs_%clt%
eq_emi_leak_ccs_%clt%

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

eqq_emi_ccs_%clt%(t,n)$(mapn_th('%clt%') and tnofirst(t))..
                Q_EMI('ccs_plant',t,n) =e=
                                 sum((fuel,jfed)$(jccs(jfed) and csi(fuel,jfed,t,n)),
                                     Q_IN(fuel,jfed,t,n) * emi_sys('co2ffi',t,n) * ccs_emi_capt(fuel) * ccs_capture_eff(jfed))
;

eqcost_emi_sinks_%clt%(t,n)$(mapn_th('%clt%') and tnofirst(t))..
                COST_EMI('ccs_plant',t,n) =e=
                         sum(ccs_stor, Q_CCS('ccs_plant',ccs_stor,t,n) * ccs_transp_coeff * c2co2 * 1e-3 * ccs_stor_dist_avg(n,ccs_stor) +
                                       Q_CCS('ccs_plant',ccs_stor,t,n) * ccs_stor_cost(ccs_stor,n) * c2co2)
;

eq_stor_ccs_cum_%clt%(ccs_stor,tp1,t,n)$(mapn_th1('%clt%') and tnofirst(t))..
                CUM_Q_CCS(ccs_stor,tp1,n) =e= CUM_Q_CCS(ccs_stor,t,n) * (1 - ccs_leak_rate(ccs_stor,t,n))**tlen(t) + sum(sink, tlen(t) * Q_CCS(sink,ccs_stor,t,n))
;

eq_emi_stor_ccs_%clt%(t,n)$(mapn_th('%clt%'))..
                Q_EMI('ccs_plant',t,n) =e= sum(ccs_stor, Q_CCS('ccs_plant',ccs_stor,t,n))
;

eq_emi_leak_ccs_%clt%(t,n)$(mapn_th('%clt%'))..
                Q_EMI('co2leak',t,n) =e= sum(ccs_stor, (1 - (1 - ccs_leak_rate(ccs_stor,t,n))**tlen(t)) * CUM_Q_CCS(ccs_stor,t,n)) / tlen(t);

*-------------------------------------------------------------------------------
$elseif %phase%=='fix_variables'

tfixvar(MCOST_EMI,'(e,t,n)')
tfixvar(Q_CCS,'(sink,ccs_stor,t,n)')
tfixvar(CUM_Q_CCS,'(ccs_stor,t,n)')

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

MCOST_EMI.fx('ccs',t,n) = div0(COST_EMI.l('ccs',t,n), Q_EMI.l('ccs',t,n));
MCOST_EMI.fx('ccs_plant',t,n) = div0(COST_EMI.l('ccs_plant',t,n), Q_EMI.l('ccs_plant',t,n));

* World capital in CCS plant
wcum(jlccs,tfirst) = sum(n,K_EN.l(jlccs,tfirst,n));
loop((tnofirst(t),tm1)$pre(tm1,t),
wcum(jlccs,t) = wcum(jlccs,tm1) + tlen(tm1) * sum(n, I_EN.l(jlccs,tm1,n) / MCOST_INV.l(jlccs,tm1,n));
);

ccs_wcum_spill(jlccs,t)=sum(jllccs, ccs_spill_factor(jlccs,jllccs)*(wcum(jllccs,t)));

MCOST_INV.fx(jlccs,t,n)$(ccs_wcum_spill(jlccs,t) gt ccs_wcum0(jlccs)) = max(ccs_floor_cost(jlccs,n), mcost_inv0(jlccs,n) * (ccs_wcum_spill(jlccs,t)/ccs_wcum0(jlccs))**(-ccs_learn(jlccs,t)));

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Sets
jccs
jlccs

* Parameters
ccs_capture_eff
ccs_emi_capt
ccs_leak_rate
ccs_learn
ccs_stor_cap_max
ccs_stor_cap_og_onoff
ccs_stor_cost
ccs_stor_dist_avg
ccs_wcum0
ccs_wcum_spill

* Variables
CUM_Q_CCS
MCOST_EMI
Q_CCS

$endif
