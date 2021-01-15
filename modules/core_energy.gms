*-------------------------------------------------------------------------------
* Energy sector
*-------------------------------------------------------------------------------

$ifthen %phase%=='sets'

set fuel       'All energy carriers' / oil, coal, gas, uranium /
    f(fuel)    'Primary energy sources' / oil, coal, gas, uranium /
    s(fuel)    'Secondary energy sources' / /
    extract(f) 'Primary energy fuels with an extraction sector'
    f_mkt(f)   'Fuel markets' / oil /;

set j 'Energy Sectors and Technologies' /
    en         'Energy'
    el         'Power supply sector'
    elcoalwbio
    elp       'Power plant | Coal/Biomass | w/o CCS | All' 
    eligcc    'Power plant | Coal/Biomass | CCS | All'
    elpc      'Power plant | Coal | w/o CCS | All'
    elpc_new  'Power plant | Coal | w/o CCS | New'
    elpc_old  'Power plant | Coal | w/o CCS | Old'
    elpc_late 'Power plant | Coal | w/o CCS | Recent'
    elpc_ccs  'Power plant | Coal | CCS | Standard'
    elpc_oxy  'Power plant | Coal | CCS | Oxy-fuel'
    elcigcc   'Power plant | Coal | CCS | Integrated gasification combined cycle'
    elnuclearback,
    elnuclear_old 'Power plant | Nuclear | Old'
    elnuclear_new 'Power plant | Nuclear | New'
    eloil         'Power plant | Oil | All'
    eloil_new     'Power plant | Oil | New'
    eloil_old     'Power plant | Oil | Oil'
    elgas         'Power plant | Gas | All'
    elgastr       'Power plant | Gas | w/o CCS | All'
    elgastr_new   'Power plant | Gas | w/o CCS | New'
    elgastr_old   'Power plant | Gas | w/o CCS | Old'
    elgasccs      'Power plant | Gas | CCS'
    nel     'Non-electric sectors'
    neloilback
    neloil  'End-use | Oil'
    nelgas  'End-use | Gas'
    nelcoal 'End-use | Coal'
    nelbio  'End-use | Biomass'
/;
alias(j,jj);
set jreal(j) 'Real Energy Technologies' /
    elpc_new, elpc_old, elpc_late, elpc_ccs, elpc_oxy, elcigcc, 
    elnuclear_old, elnuclear_new,
    eloil_new, eloil_old, 
    elgastr_new, elgastr_old, elgasccs,
    neloil, 
    nelgas,
    nelcoal
/;
set jel(jreal) 'Power plants' /
    elpc_new, elpc_old, elpc_late, elcigcc, elpc_ccs, elpc_oxy,
    eloil_new, eloil_old, 
    elgastr_new, elgastr_old, elgasccs
/;
alias(jel,jel2);
set jnel(jreal) 'Non-electric Technologies' /
    neloil, nelgas, nelcoal
/;
set jfed(jreal) 'Technologies fed by primary energy sources' /
    elpc_new, elpc_old, elpc_late, elcigcc, elpc_ccs, elpc_oxy,
    eloil_new, eloil_old, elgastr_new,
    elgastr_old, elgasccs,
    neloil, nelgas, nelcoal
/;
set jold(jel) 'Old technologies' /
    elpc_old, eloil_old, elgastr_old
/;
set jinv(jreal) 'Investable technologies' /
    elpc_new, elpc_late, elcigcc, eloil_new, elgastr_new, elgasccs, elpc_ccs, elpc_oxy
/;

set jpenalty(j) 'Technologies with cost on consumption' / /;

set jel_ren(jel) 'Renewable power plants' / /;
set jnel_ren(jreal) 'Renewable technologies for non-electrical' / /;

set jmcost_inv(jreal) 'Energy sectors with non fixed m.cost of investments';

sets
    jreal_to_scale(jreal) 'Technology sectors subject to a 1e3 scale in K_EN during optimization' / /
    j_to_scale(j) 'Technology sectors subject to a 1e3 scale in Q_EN during optimization' / /
    jinv_to_scale(jinv) 'Technology sectors subject to a 1e3 scale in I_EN during optimization' / /;
;

set map_j(j,jj) 'Tree of Energy Sectors and Technologies' /
    en.(el, nel)
    el.(elcoalwbio, eloil, elgas, elnuclearback)
    elcoalwbio.(elp, eligcc)
    elp.elpc
    elpc.(elpc_new, elpc_old, elpc_late)
    eligcc.(elcigcc, elpc_ccs, elpc_oxy)
    eloil.(eloil_new, eloil_old)
    elgas.(elgastr, elgasccs)
    elgastr.(elgastr_new, elgastr_old)
    nel.(neloilback, nelgas, nelcoal, nelbio)
    neloilback.neloil
/;

set jel_own_mu(jel) / /;
set jinv_own_k(jinv) / /;

set ices_el(iq) /ces_elnuclearback, ces_elcoalwbio, ces_eloil,ces_elgas /;

set map_ices_el(ices_el,j)/
ces_elnuclearback.elnuclearback
ces_elcoalwbio.elcoalwbio
ces_eloil.eloil
ces_elgas.elgas
/;

set jcalib /
    elpc
    elnuclear
    elgastr
    eloil
/;

set map_calib(jcalib,jreal) /
elpc.(elpc_old, elpc_late)
elgastr.(elgastr_new,elgastr_old)
elnuclear.(elnuclear_new,elnuclear_old)
eloil.(eloil_new,eloil_old)
/;

set el_out(*) 'Electricity demand to withdraw from the production tree [TWh]'/
/;

set nel_out(*) 'Non electricity demand to withdraw from the production tree [TWh]'/
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

* Calibration parameters
parameters 
    mcost_inv0(j,n)
    p_mkup0(fuel,n)       'Constant regional price markup [T$/TWh]'
    oem0(jreal,n)
    mu0(jel,n)            'Capacity factor of maximum production [TWh/TW]'
    csi0(fuel,jfed,n)     'Sectoral efficiency ratio [TWh/TWh]'
    k_en0(jel,n)
    delta_en0(jreal,n)    'Yearly depreciation of capital of power technologies'
    k_en_valid_old(*,t,n)
    k_en_valid_tot(*,t,n)
;

$ifthen.cg set calibgdx
$gdxin '%calibgdx%'
$load mcost_inv0 p_mkup0 oem0 mu0 csi0 k_en0 delta_en0 k_en_valid_tot k_en_valid_old
$gdxin
$endif.cg

$gdxin %datapath%data_validation
parameter k_en_valid_gcpt(*,t,n);
$loaddc k_en_valid_gcpt
parameter k_en_valid_iaea(*,t,n);
$loaddc k_en_valid_iaea
$gdxin

$gdxin '%datapath%data_core_energy'

parameter lifetime(*,n) 'Lifetime of capital [Years]'
$loaddc lifetime

parameter csi_max_2100(fuel,jfed,n) 'Maximum Sectoral efficiency achievable in 2100 [TWh/TWh]';
$loaddc csi_max_2100

* -> cexs Coefficients for fuels supply curves
* a      'Marginal cost of extraction'
* b      'Coefficient on quadratic term'
* c      'Coefficient on cumulative extraction'
* exp    'Power of cumulative extraction'
* cum0   'Cumulative extraction at time zero [millions TWh]'
* res0   'Start ult.ly rec. resources [Millions TWh]'
* resgr0 'Fixed annual growth rate of tot.ult.rec.res.'
* fast   'Fraction of tot res at which price grows fast'
* scl    'Scale up parameter from 2002 to 2005 prices'
* pfirst 'International price at 2002'
* extra  'Extra costs (e.g. conversion and enrichment for uranium)'
parameter cexs(f,*) 'Coefficients for oil, coal, gas and uranium supply curves';
$loaddc cexs

parameter el_old_start_depreciation_year(jreal,n) 'Starting period for vintaging old capital';
$loaddc el_old_start_depreciation_year

parameter p_mkup_adjust(fuel,t,n) 'Fuel/time/regions adjustment for p_mkup';
$loaddc p_mkup_adjust

parameter noeloil(n) 'Regional flag for noeloil';
$loaddc noeloil

$gdxin

parameters mu(jel,t,n)  'Capacity factor of maximum production [TWh/TW]';

parameter wcum(*,t) 'World cumulated quantities';

parameter tpes(t,n) 'Primary Energy Supply - Total (Direct use concept for non fossil fuels: primary energy=final energy) [TWh]';

scalar twh2ej;
twh2ej = 3.6 * 1e-3;

parameter prodpp(f,t,n);
parameter cum_prodpp(f,t,n);

parameter delta_en(jreal,t,n);
parameter delta_lcost(jreal,t,n);

parameter csi(fuel,jfed,t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='include_dynamic_calibration_data'

mu(jel,t,n)$(not jel_own_mu(jel)) = mu0(jel,n);

parameter mucalib(jel,t,n);
$gdxin '%tfpgdx%'
$loaddc mucalib=mu
$gdxin
loop((jel,jcalib)$(xiny(jel,jold) and xiny(jel,jreal) and map_calib(jcalib,jel)),
  mu(jel,t,n)$(year(t) eq 2005) = mu0(jel,n);
  mu(jel,t,n)$(year(t) ge 2010) = mucalib(jel,t,n);
);
mu('elpc_late',t,n)$(year(t) ge 2010) = mucalib('elpc_late',t,n);
mu('elgastr_new',t,n)$(year(t) ge 2010) = mucalib('elgastr_new',t,n);
mu('elgastr_old',t,n)$(year(t) ge 2010) = mucalib('elgastr_old',t,n);
mu('elnuclear_new',t,n)$(year(t) ge 2010) = mucalib('elnuclear_new',t,n);
mu('elnuclear_old',t,n)$(year(t) ge 2010) = mucalib('elnuclear_old',t,n);
mu('eloil_new',t,n)$(year(t) ge 2010) = mucalib('eloil_new',t,n);
mu('eloil_old',t,n)$(year(t) ge 2010) = mucalib('eloil_old',t,n);

parameter csicalib(fuel,jfed,t,n);
$gdxin '%tfpgdx%'
$loaddc csicalib=csi
$gdxin
csi(fuel,jfed,t,n) = csi0(fuel,jfed,n);
csi(fuel,jfed,t,n)$csi_max_2100(fuel,jfed,n) = min((csi0(fuel,jfed,n)*(2100-year(t)) + csi_max_2100(fuel,jfed,n)*(year(t)-year(tfirst))) / (2100-year(tfirst)),  csi_max_2100(fuel,jfed,n));
csi('coal','elpc_late',t,n)$(year(t) ge 2010) = csicalib('coal','elpc_late',t,n);
csi('coal','elpc_old',t,n)$(year(t) ge 2010) = csicalib('coal','elpc_old',t,n);
csi('gas','elgastr_old',t,n)$(year(t) ge 2010) = csicalib('gas','elgastr_old',t,n);
csi('gas','elgastr_new',t,n)$(year(t) ge 2010) = csicalib('gas','elgastr_new',t,n);
csi('oil','eloil_old',t,n)$(year(t) ge 2010) = csicalib('oil','eloil_old',t,n);
csi('oil','eloil_new',t,n)$(year(t) ge 2010) = csicalib('oil','eloil_new',t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

$ifthen.c set dynamic_calibration
mu(jel,t,n)$(not jel_own_mu(jel)) = mu0(jel,n);
csi(fuel,jfed,t,n) = csi0(fuel,jfed,n);
csi(fuel,jfed,t,n)$csi_max_2100(fuel,jfed,n) = min((csi0(fuel,jfed,n)*(2100-year(t)) + csi_max_2100(fuel,jfed,n)*(year(t)-year(tfirst))) / (2100-year(tfirst)),  csi_max_2100(fuel,jfed,n));
$endif.c

delta_en(jreal,t,n) = delta_en0(jreal,n);
delta_lcost(jreal,t,n) = delta_en0(jreal,n);

loop((jreal,jcalib)$(map_calib(jcalib,jreal) and xiny(jreal,jold)),
    delta_en(jreal,t,n)$(year(t) eq 2005) = 0;
    delta_en(jreal,t,n)$(year(t) eq 2010) = 1 - (k_en_valid_old(jcalib,t,n) / k_en_valid_old(jcalib,tfirst,n))**(1/5);
    loop((t,tm1)$((year(t) eq 2015) and pre(tm1,t)), delta_en(jreal,t,n) = 0.5*(delta_en(jreal,tm1,n)+delta_en0(jreal,n)));
);

parameter p_mkup(fuel,t,n) 'Temporal-regional price markup [T$/TWh]';
p_mkup(fuel,t,n)$p_mkup0(fuel,n) = p_mkup0(fuel,n)*p_mkup_adjust(fuel,t,n);
    
parameter oem(jreal,t,n);
oem(jreal,t,n) = oem0(jreal,n);
oem(jfed,t,n)$(csi('coal',jfed,t,n) or csi('wbio',jfed,t,n)) = oem(jfed,t,n) + localpll(t,n);

wcum(f,tfirst) = cexs(f,'cum0');

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

variable COST_FUEL(fuel,t,n) 'Energy sources costs [T$]';
loadvarbnd(COST_FUEL,'(fuel,t,n)',1e-5,-inf,+inf);

variable COST_EN(j,t,n) 'Energy costs [T$]';
loadvarbnd(COST_EN,'(j,t,n)',0,-inf,+inf);

* Mean costs
positive variable MCOST_INV(jreal,t,n) 'Average cost of investment [T$/TW] ([T$/million vehicles] for LDVs, [$/kWh] for batteries)';
loadvarbnd(MCOST_INV,'(jreal,t,n)',1e-5,1e-8,+inf);
MCOST_INV.fx(jreal,t,n)$(not jmcost_inv(jreal)) = mcost_inv0(jreal,n);

positive variable MCOST_FUEL(fuel,t,n) 'Average cost of energy sources [T$/TWh]';
loadvarbnd(MCOST_FUEL,'(fuel,t,n)',1e-5,1e-12,+inf);

* Investments
positive variable I_EN(jinv,t,n) 'Investments in Energy sectors [T$]';
loadvarbnd(I_EN,'(jinv,t,n)',1e-5,1e-7,+inf);
I_EN.scale(jinv_to_scale,t,n) = 1e-3;

I_EN.up('elpc_new',t,n)$(year(t) lt 2015)  = I_EN.lo('elpc_new',t,n);     
I_EN.up('elpc_late',t,n)$(year(t) ge 2015) = I_EN.lo('elpc_late',t,n);

positive variable Q_IN(fuel,jfed,t,n) 'Imported/consumed PES [TWh]';
loadvarbndcond(Q_IN,'(fuel,jfed,t,n)','csi(fuel,jfed,t,n)',1e-5,1e-12,+inf);
Q_IN.l(fuel,jfed,t,n)$(csi(fuel,jfed,t,n) eq 0) = 0;
Q_IN.lo(fuel,jfed,t,n)$(csi(fuel,jfed,t,n) eq 0) = 0;
Q_IN.up(fuel,jfed,t,n)$(csi(fuel,jfed,t,n) eq 0) = 0;

positive variable Q_FUEL(fuel,t,n) 'Total amount of Energy Sources consumed [TWh]';
loadvarbnd(Q_FUEL,'(fuel,t,n)',1e-5,0,+inf);

positive variable Q_EN(j,t,n) 'Energy supply/generation/demand for different sectors [TWh]';
loadvarbnd(Q_EN,'(j,t,n)',1e-5,1e-8,+inf);
Q_EN.l(j,t,n)$(Q_EN.l(j,t,n) eq 0) = 1e-8;
Q_EN.lo('en',t,n) = 2e-4;
Q_EN.lo('el',t,n) = 1e-4;
Q_EN.lo('nel',t,n) = 1e-4;
Q_EN.scale(j_to_scale,t,n) = 1e-3;

positive variable K_EN(jreal,t,n) 'Capital in energy technologies [TW] ([million vehicles] for light duty vehicles)';
loadvar(K_EN,'(jreal,t,n)',1e-5);
K_EN.lo(jel,t,n) = 1e-8;
K_EN.up(jel,t,n) = 100;
K_EN.fx(jel,tfirst,n) = k_en0(jel,n);
K_EN.scale(jreal_to_scale,t,n) = 1e-3;

* Fix old capital with depreciation and ensure that levels are not higher than statistics
loop((tnofirst(t),tm1)$pre(tm1,t),
    K_EN.fx(jold,t,n) = K_EN.l(jold,tm1,n) * (1-delta_en(jold,t,n))**tlen(tm1);
    K_EN.fx(jold,t,n)$(year(t) le 2015 and sum(jcalib$map_calib(jcalib,jold),k_en_valid_old(jcalib,t,n)) gt 0) = min(K_EN.up(jold,t,n), sum(jcalib$map_calib(jcalib,jold), k_en_valid_old(jcalib,t,n)));
    Q_EN.up(jold,t,n) = mu(jold,t,n) * K_EN.up(jold,t,n);
    Q_EN.fx(jold,t,n)$( Q_EN.up(jold,t,n) - Q_EN.lo(jold,t,n) le 1e-7 ) = Q_EN.up(jold,t,n);
);

* Fix K_EN in 2010 given existing old
loop((jreal,jcalib)$(map_calib(jcalib,jreal) and (not sameas(jreal,jcalib)) and (not xiny(jreal,jold))),
    K_EN.fx(jreal,t,n)$(year(t) eq 2010) = max(k_en_valid_tot(jcalib,t,n) - k_en_valid_old(jcalib,t,n), 1e-6);   
);

* Fix manually K_EN in 2015 given existing old
K_EN.fx('elpc_late',t,n)$(year(t) eq 2015) = max(k_en_valid_tot('elpc',t,n) - K_EN.lo('elpc_old',t,n), 1e-6);
K_EN.fx('elgastr_new',t,n)$(year(t) eq 2015) = max(k_en_valid_tot('elgastr',t,n) - K_EN.lo('elgastr_old',t,n), 1e-6);
K_EN.fx('elnuclear_new',t,n)$(year(t) eq 2015) = max(k_en_valid_tot('elnuclear',t,n) - K_EN.lo('elnuclear_old',t,n), 1e-6);
K_EN.fx('eloil_new',t,n)$(year(t) eq 2015) = max(k_en_valid_tot('eloil',t,n) - K_EN.l('eloil_old',t,n), 1e-6);
K_EN.fx('elhydro_new',t,n)$(year(t) eq 2015) = max(k_en_valid_tot('elhydro',t,n) - K_EN.l('elhydro_old',t,n), 1e-6);

* Fix manually K_EN in 2020 for coal power plant and nuclear
K_EN.lo('elpc_late',t,n)$(year(t) eq 2020) = valuein(2015,K_EN.lo('elpc_late',tt,n) * (1-delta_en('elpc_late',tt,n))**tlen(tt));
K_EN.lo('elpc_new',t,n)$(year(t) eq 2020) = max(k_en_valid_gcpt('elpc',t,n) - K_EN.lo('elpc_old',t,n) - K_EN.lo('elpc_late',t,n), 1e-6);
K_EN.fx('elnuclear_new',t,n)$(year(t) eq 2020) = max(k_en_valid_tot('elnuclear',t,n) - K_EN.lo('elnuclear_old',t,n), 1e-6);

* No investment in new oil power plant in noeloil region
loop((t,tp1)$(pre(t,tp1) and (year(t) ge 2015) and (not tfix(tp1))),
I_EN.fx('eloil_new',t,n)$noeloil(n) = I_EN.lo('eloil_new',t,n);
);

positive variable QEL_OUT(el_out,ices_el,t,n) 'Consumption of electricity outside production function [TWh]';
loadvarbnd(QEL_OUT,'(el_out,ices_el,t,n)',1e-5,0,1e5);

positive variable QNEL_OUT(j,nel_out,t,n) 'Consumption of non electric energy outside production function [TWh]';
loadvarbnd(QNEL_OUT,'(j,nel_out,t,n)',1e-10,0,1e5);

* Nodes with a Q to be scaled by 1e3 during optimization
Q.scale('ces_elintren',t,n) = 1e-3;

* Fuel price
Positive variable FPRICE(fuel,t) 'World fuel prices [T$/TWh]';
loadvarbnd(FPRICE,'(fuel,t)',0,0,+Inf);

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eq_mkt_clearing_oil_%clt%
eqcost_pes_%clt%
eqcost_ses_%clt%
eqk_en_%clt%
eqq_ces_el_%clt%
eqq_ces_nelgas_%clt%
eqq_el2_%clt%
eqq_el_%clt%
eqq_elff_%clt%
eqq_en_%clt%
eqq_en_in_%clt%
eqq_en_mu_%clt%
eqq_en_tree_%clt%
eqq_nel_%clt%
eqq_nelog_%clt%
eqq_fuel_%clt%
eqq_elffren_%clt%

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

*-------------------------------------------------------------------------------
* Production - Energy sector
*-------------------------------------------------------------------------------

eqq_en_%clt%(t,n)$(mapn_th('%clt%'))..
    Q('en',t,n)  =e= ces('en', 'el', Q('el',t,n), 'nel', Q('nel',t,n));

*-------------------------------------------------------------------------------
* Production - Electrical sector
*-------------------------------------------------------------------------------

eqq_el_%clt%(t,n)$(mapn_th('%clt%'))..
    Q('el',t,n) =e= lin('el', 'el2', Q('el2',t,n), 'elhydro', Q('ces_elhydro',t,n));

eqq_el2_%clt%(t,n)$(mapn_th('%clt%'))..
    Q('el2',t,n) =e= ces('el2', 'elffren', Q('elffren',t,n), 'elnuclearback', Q('ces_elnuclearback',t,n));

eqq_elffren_%clt%(t,n)$(mapn_th('%clt%'))..
    Q('elffren',t,n) =e= ces('elffren','elff',Q('elff',t,n),'elintren',Q('ces_elintren',t,n));
eqq_elff_%clt%(t,n)$(mapn_th('%clt%'))..
    Q('elff',t,n) =e= ces3('elff', 'elcoalwbio', Q('ces_elcoalwbio',t,n), 'eloil', Q('ces_eloil',t,n), 'elgas', Q('ces_elgas',t,n));

eqq_ces_el_%clt%(ices_el,t,n)$(mapn_th('%clt%') and (sum(j$map_ices_el(ices_el,j),1) gt 0))..
    Q(ices_el,t,n) =e= sum(j$map_ices_el(ices_el,j), Q_EN(j,t,n)) - sum(el_out, QEL_OUT(el_out,ices_el,t,n))
;

*-------------------------------------------------------------------------------
* Production - Non-electrical sector
*-------------------------------------------------------------------------------

eqq_nel_%clt%(t,n)$(mapn_th('%clt%'))..
    Q('nel',t,n) =e= lin3('nel', 'nelcoal', Q_EN('nelcoal',t,n), 'nelog', Q('nelog',t,n), 'neltrbiomass', Q_EN('neltrbiomass',t,n));

eqq_nelog_%clt%(t,n)$(mapn_th('%clt%'))..
    Q('nelog',t,n) =e= ces('nelog', 'neloil', Q_EN('neloilback',t,n), 'nelgas', Q('ces_nelgas',t,n))
;
eqq_ces_nelgas_%clt%(t,n)$(mapn_th('%clt%'))..
    Q('ces_nelgas',t,n) =e= Q_EN('nelgas',t,n) - sum(nel_out,QNEL_OUT('nelgas',nel_out,t,n));

*-------------------------------------------------------------------------------
* PES and fuels
*-------------------------------------------------------------------------------

eqq_fuel_%clt%(fuel,t,n)$(mapn_th('%clt%') and (not sameas(fuel, 'wbio')))..
    Q_FUEL(fuel,t,n) =e= sum(jfed$(csi(fuel,jfed,t,n)), Q_IN(fuel,jfed,t,n));

*-------------------------------------------------------------------------------
* Cost
*-------------------------------------------------------------------------------

* Net cost of Primary Energy Supplies
eqcost_pes_%clt%(f,t,n)$(mapn_th('%clt%') and (not sameas(f,'wbio')))..
    COST_FUEL(f,t,n) =e= MCOST_FUEL(f,t,n) * Q_FUEL(f,t,n) -
                            (FPRICE.l(f,t) * Q_OUT(f,t,n))$(extract(f));

* Net cost of Secondary Energy Supplies
eqcost_ses_%clt%(s,t,n)$(mapn_th('%clt%'))..
    COST_FUEL(s,t,n) =e= MCOST_FUEL(s,t,n) * Q_FUEL(s,t,n);


*-------------------------------------------------------------------------------
* Market balances
*-------------------------------------------------------------------------------

eq_mkt_clearing_oil_%clt%(t,'%clt%')$(internal('oil'))..
    sum( n$(mapn('%clt%') and trading_t('oil',t,n)),
        Q_FUEL('oil',t,n) - Q_OUT('oil',t,n)
    ) =e= 0;

*-------------------------------------------------------------------------------
* New capital in the energy sector
*-------------------------------------------------------------------------------

* Electrical generation plants (new)
eqk_en_%clt%(jinv,t,tp1,n)$(mapn_th1('%clt%') and (not jinv_own_k(jinv)) and pre(t,tp1))..
    K_EN(jinv,tp1,n) =e= K_EN(jinv,t,n) * (1 - delta_en(jinv,tp1,n))**tlen(t) + 
                            tlen(t) * I_EN(jinv,t,n) / MCOST_INV(jinv,t,n);

*-------------------------------------------------------------------------------
* ENERGY
*-------------------------------------------------------------------------------

* Capacity limits in the electrical sector
eqq_en_mu_%clt%(jel,t,n)$(mapn_th('%clt%') and (not jel_own_mu(jel)))..
    Q_EN(jel,t,n) =l= mu(jel,t,n) * K_EN(jel,t,n);

* Efficiency of energy technology sector
eqq_en_in_%clt%(jfed,t,n)$(mapn_th('%clt%') and (sum(fuel$csi(fuel,jfed,t,n),1)))..
    Q_EN(jfed,t,n) =e= sum(fuel$csi(fuel,jfed,t,n), 
                        csi(fuel,jfed,t,n) * Q_IN(fuel,jfed,t,n));

* Energy generation "tree"
eqq_en_tree_%clt%(j,t,n)$(mapn_th('%clt%') and (sum(jj$map_j(j,jj),1))) ..
    Q_EN(j,t,n) =e= sum(jj$map_j(j,jj), Q_EN(jj,t,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='fix_variables'

tfix1var(I_EN,'(jinv,t,n)')
tfixvar(COST_EN,'(j,t,n)')
tfixvar(COST_FUEL,'(f,t,n)')
tfixvar(K_EN,'(jreal,t,n)')
tfixvar(MCOST_INV,'(jreal,t,n)')
tfixvar(MCOST_FUEL,'(f,t,n)')
tfixvar(Q_EN,'(j,t,n)')
tfixvar(QEL_OUT,'(el_out,ices_el,t,n)')
tfixvar(QNEL_OUT,'(j,nel_out,t,n)')
tfixvar(Q_IN,'(f,jfed,t,n)')
tfixvar(Q_FUEL,'(f,t,n)')
tfixvar(FPRICE,'(f,t)')

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

* World cumulative fuel demand
loop((tnofirst(t),tm1)$pre(tm1,t),
    wcum(f,t) = wcum(f,tm1) + tlen(t) * sum(n, Q_FUEL.l(f,tm1,n) * 1e-6);
);

tpes(t,n) = sum(f, Q_FUEL.l(f,t,n)) + Q_EN.l('elhydro',t,n) + Q_EN.l('elwind',t,n) + Q_EN.l('elsolar',t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='dynamic_calibration'

* Calibration of old technologies in 2010
loop((jel,jcalib)$(xiny(jel,jold) and xiny(jel,jreal) and map_calib(jcalib,jel)),
    loop((t,tt)$((year(t) ge 2010) and (year(tt) eq 2010)),
    mu(jel,t,n) = max(1, min(round((q_en_valid_dyn(jcalib,tt,n) - sum(jel2$((not sameas(jel,jel2)) and map_calib(jcalib,jel2)), Q_EN.l(jel2,tt,n))) / ((1-delta_en(jel,tt,n)) * k_en0(jel,n))),8760));
    Q_EN.l(jel,t,n) = K_EN.l(jel,t,n) * mu(jel,t,n);
);
);

* Manual calibration of mu for elpc in 2010-2015
mu('elpc_late',t,n)$(year(t) ge 2010 and year(t) le 2015) = max(1,min(round(( q_en_valid_dyn('elpc',t,n) - Q_EN.l('elpc_new',t,n) ) / ( K_EN.lo('elpc_late',t,n) + K_EN.lo('elpc_old',t,n))), 8760));
mu('elpc_old',t,n)$(year(t) ge 2010 and year(t) le 2015) = mu('elpc_late',t,n);
mu('elpc_late',t,n)$(year(t) gt 2015) = valuein(2015,mu('elpc_late',tt,n));
mu('elpc_old',t,n)$(year(t) gt 2015) = valuein(2015,mu('elpc_old',tt,n));

mu('elgastr_new',t,n)$(year(t) ge 2010 and year(t) le 2015) = max(1,min(round(q_en_valid_dyn('elgastr',t,n) / ( K_EN.lo('elgastr_new',t,n) + K_EN.lo('elgastr_old',t,n))), 8760));
mu('elgastr_old',t,n)$(year(t) ge 2010 and year(t) le 2015) = mu('elgastr_new',t,n);
mu('elgastr_old',t,n)$(year(t) gt 2015) = valuein(2015,mu('elgastr_old',tt,n));

mu('elnuclear_new',t,n)$(year(t) ge 2010 and year(t) le 2015) = max(1,min(round(q_en_valid_dyn('elnuclear',t,n) / ( K_EN.lo('elnuclear_new',t,n) + K_EN.lo('elnuclear_old',t,n))), 8760));
mu('elnuclear_old',t,n)$(year(t) ge 2010 and year(t) le 2015) = mu('elnuclear_new',t,n);
mu('elnuclear_old',t,n)$(year(t) gt 2015) = valuein(2015,mu('elnuclear_old',tt,n));
mu('elnuclear_new',t,n)$(year(t) eq 2020) = valuein(2015,mu('elnuclear_old',tt,n));
mu('elnuclear_new',t,n)$(year(t) eq 2025) = (valuein(2020,mu('elnuclear_new',tt,n)) + mu0('elnuclear_new',n)) / 2;
mu('elnuclear_new',t,n)$(year(t) eq 2030) = (valuein(2025,mu('elnuclear_new',tt,n)) + mu0('elnuclear_new',n)) / 2;
mu('elnuclear_new',t,n)$(year(t) eq 2035) = (valuein(2030,mu('elnuclear_new',tt,n)) + mu0('elnuclear_new',n)) / 2;
mu('elnuclear_new',t,n)$(year(t) gt 2035) = mu0('elnuclear_new',n);

mu('eloil_new',t,n)$(year(t) ge 2010 and year(t) le 2015) = max(1,min(round(q_en_valid_dyn('eloil',t,n) / ( K_EN.lo('eloil_new',t,n) + K_EN.lo('eloil_old',t,n))), 8760));
mu('eloil_old',t,n)$(year(t) ge 2010 and year(t) le 2015) = mu('eloil_new',t,n);
mu('eloil_old',t,n)$(year(t) gt 2015) = valuein(2015,mu('eloil_old',tt,n));
mu('eloil_new',t,n)$(year(t) gt 2015) = valuein(2015,mu('eloil_new',tt,n));

mu('elhydro_new',t,n)$(year(t) ge 2010 and year(t) le 2015) = max(1,min(round(q_en_valid_dyn('elhydro',t,n) / ( K_EN.l('elhydro_new',t,n) + K_EN.lo('elhydro_old',t,n))), 8760));
mu('elhydro_old',t,n)$(year(t) ge 2010 and year(t) le 2015) = mu('elhydro_new',t,n);
mu('elhydro_old',t,n)$(year(t) gt 2015) = valuein(2015,mu('elhydro_old',tt,n));
mu('elhydro_new',t,n)$(year(t) gt 2015) = valuein(2015,mu('elhydro_new',tt,n));

csi('coal','elpc_old',t,n)$(year(t) ge 2010 and year(t) le 2015 and q_in_valid_dyn('elpc', t, n)) = 
    (q_en_valid_dyn('elpc', t, n) - Q_EN.l('elpc_new',t,n)) / 
    (q_in_valid_dyn('elpc', t, n) - Q_IN.l('coal','elpc_new',t,n));
csi('coal','elpc_late',t,n)$(year(t) ge 2010 and year(t) le 2015) = csi('coal','elpc_old',t,n);
csi('coal','elpc_old',t,n)$(year(t) gt 2015) = valuein(2015,csi('coal','elpc_old',tt,n));
csi('coal','elpc_late',t,n)$(year(t) gt 2015) = valuein(2015,csi('coal','elpc_late',tt,n));

csi('gas','elgastr_old',t,n)$(year(t) ge 2010 and year(t) le 2015 and q_in_valid_dyn('elgastr', t, n)) = 
    (q_en_valid_dyn('elgastr', t, n)) / (q_in_valid_dyn('elgastr', t, n));
csi('gas','elgastr_new',t,n)$(year(t) ge 2010 and year(t) le 2015) = csi('gas','elgastr_old',t,n);
csi('gas','elgastr_old',t,n)$(year(t) gt 2015) = valuein(2015,csi('gas','elgastr_old',tt,n));

csi('oil','eloil_old',t,n)$(year(t) ge 2010 and year(t) le 2015 and q_in_valid_dyn('eloil', t, n)) = 
    (q_en_valid_dyn('eloil', t, n)) / (q_in_valid_dyn('eloil', t, n));
csi('oil','eloil_new',t,n)$(year(t) ge 2010 and year(t) le 2015) = csi('oil','eloil_old',t,n);
csi('oil','eloil_old',t,n)$(year(t) gt 2015) = valuein(2015,csi('oil','eloil_old',tt,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='tfpgdx_items'

mu
csi

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Sets
extract
fuel
f
s
f_mkt
ices_el
j
j_to_scale
jel
jel_own_mu
jel_ren
jfed
jinv
jinv_own_k
jinv_to_scale
jmcost_inv
jnel
jnel_ren
jold
jpenalty
jreal
jreal_to_scale
map_ices_el
map_j

* Parameters
cexs
csi
csi0
cum_prodpp
delta_en
delta_en0
delta_lcost
lifetime
k_en0
localpll
mcost_inv0
mu
mu0
oem
oem0
p_mkup
p_mkup0
prodpp
twh2ej
wcum
tpes
noeloil

* Variables
COST_EN
COST_FUEL
FPRICE
I_EN
K_EN
MCOST_FUEL
MCOST_INV
QEL_OUT
QNEL_OUT
Q_EN
Q_FUEL
Q_IN

$endif
