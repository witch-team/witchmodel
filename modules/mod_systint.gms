*-------------------------------------------------------------------------------
* System Integration:
* - Capacity constraint
* - Flexibility constraint
* - Grid Investment
* - Capacity growth constraint
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

$setglobal capacity_constraint 'low'
$if %baseline%=='ssp1' $setglobal capacity_constraint 'high'
$if %baseline%=='ssp4' $setglobal capacity_constraint 'high'

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

* Renewable CES
set jintren(j) / /;   # also used in the grid part

* Capacity constraint
set jel_firm(jel) 'Firm, non intermittent technologies' /
    elpc_new, elpc_old, elpc_late elcigcc, elpc_ccs, elpc_oxy, eloil_new, eloil_old, elgastr_new,
    elgastr_old, elgasccs, elhydro_new, elhydro_old /;

* Grid
set jel_stdgrid(jel) 'Technologies requiring standard grid infrastructure (i.e. no W&S)' /
    elpc_new, elpc_old, elpc_late elcigcc, elpc_ccs, elpc_oxy, eloil_new, eloil_old, elgastr_new,
    elgastr_old, elgasccs, elhydro_new, elhydro_old /;

set share_coeff / mult, exp /;

set jtn_incompatible_with_mkt_growth_cap(jinv,t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

* Capacity constraint

scalar cv_coeff / 0.9 /;
scalar cv_exp / -2.05 /;
scalar peak_load_fraction / 2 /;

parameter firm_coeff(n);

* Flexibility constraint

parameter flex_coeff(*) 'Flexibility constraint coefficient' /
elgastr_old        0.5
elgastr_new        0.5
elgasccs           0.5
elhydro_old        0.5
elhydro_new        0.5
elpb_new           0.3
elpb_old           0.3
elbigcc            0.3
elpc_old           0.15
elpc_new           0.15
elpc_late          0.15
elcigcc            0.15
elpc_ccs           0.15
elpc_oxy           0.15
eloil_old          0.15
eloil_new          0.15
elcsp              0
elnuclear_new      0  
elnuclear_old      0 
elpv              -0.05
elwindon          -0.08
elwindoff         -0.08
load              -0.1
/;

scalar storage_eff;
$if %capacity_constraint%=='low'  storage_eff = 0.85;
$if %capacity_constraint%=='high' storage_eff = 1;

* Grid

scalar grid_cost 'Cost of transmission and distribution lines [$/W]';
grid_cost = 0.4;

parameter grid_coeff(jintren,*) /
elpv.mult   1
elpv.exp    1.5
elwind.mult 1
elwind.exp  1.5
/;

parameter grid_delta(t,n) 'Depreciation rate of the grid';
lifetime('grid',n) = 60; # Lifetime of 60 years 
grid_delta(t,n) = depreciation_rate('grid');

* Transmission cost

parameter grid_trans_cost(*,*) 'Additional transmission cost[$/W]' /
elwindon.near   0
elwindon.inter  0.12
elwindon.far    0.4
elwindoff.near  0
elwindoff.inter 0.2
elwindoff.far   0.4
elpv.far        0.2
elcsp.far       0.2
/;

* Capacity growth constraint

$gdxin '%datapath%data_mod_systint'

parameter el_free_cap(n) 'Annual freely allowed capacity addition for the capacity growth constraint';
$loaddc el_free_cap
$gdxin

parameter mkt_growth_rate(jinv,t,n) 'Annual growth rate of power technologies capacity for the capacity growth constraint';

* elwindon
mkt_growth_rate('elwindon',t,n)$(year(t) ge 2020) = 0.12;
mkt_growth_rate('elwindoff',t,n)$(year(t) ge 2020) = 0.15;

* elnuclear
mkt_growth_rate('elnuclear_new',t,n) = 0.1;

* elsolar
mkt_growth_rate('elpv',t,n)$(year(t) ge 2020) = 0.2;
mkt_growth_rate('elcsp',t,n)                  = 0.2;

* elcss
mkt_growth_rate(jinv,t,n)$(xiny(jinv,jccs) and xiny(jinv,jel)) = 0.075;

* No constraint before 2010, for CCS before 2005
mkt_growth_rate(jinv,t,n)$(year(t) le 2010 ) = 0;
mkt_growth_rate(jinv,t,n)$(xiny(jinv,jccs) and xiny(jinv,jel) and year(t) ge 2010 and year(t) le 2030) = 0.02;

* Relax the constraint after 2100
mkt_growth_rate(jinv,t,n)$(year(t) gt 2100)  = 0;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_dynamic_calibration_data'

execute_load '%tfpgdx%', firm_coeff;

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

* Flexibility constraint
variable Q_EL_FLEX(t,n) 'Flexible energy generation [TWh]';
loadvarbnd(Q_EL_FLEX,'(t,n)',sum(jel,Q_EN.l(jel,t,n) * flex_coeff(jel)) + Q_EN.l('el',t,n) * flex_coeff('load'),0,Q_EN.up('el',t,n));

* Grid
variable K_EN_GRID(t,n) 'Capital in electric grid [TW]';
loadvarbnd(K_EN_GRID,'(t,n)',sum(jel, K_EN.l(jel,t,n)),1e-6,1e7);

variable I_EN_GRID(t,n) 'Investment in electric grid [T$]';
loadvarbnd(I_EN_GRID,'(t,n)',0.01,1e-7,1);

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eqq_elintren_%clt%
eqflex_%clt%
eqk_en_grid_%clt%
eqk_en_grid_to_k_en_%clt%
eqfirm_capacity_%clt%
eqcap_growth_%clt%

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'


* Renewable CES

* Definition of the renewable CES
eqq_elintren_%clt%(t,n)$(mapn_th('%clt%'))..
    Q('ces_elintren',t,n) =e= ces3('elintren', 'elwind', Q('ces_elwind',t,n), 'elpv', Q('ces_elpv',t,n), 'elcsp', Q('ces_elcsp',t,n));

* Capacity constraint

$ifthen.x %capacity_constraint%=='low'
eqfirm_capacity_%clt%(t,n)$(mapn('%clt%') and (not tfix(t)) and year(t) gt 2005)..
                 sum(jel_firm, K_EN(jel_firm,t,n))
                 + (sum((wind_dist,wind_class),K_EN_WINDON(wind_dist,wind_class,t,n) * cap_factor(wind_class)) + 
                    sum((wind_dist,wind_depth,wind_class),K_EN_WINDOFF(wind_dist,wind_depth,wind_class,t,n) * cap_factor(wind_class))) *
                        cv_coeff * exp(cv_exp * Q_EN('elwind',t,n) / Q_EN.l('el',t,n))
                 + sum((solar_dist,solar_class),K_EN_PV(solar_dist,solar_class,t,n) * solar_mu(solar_class,'elpv') / yearly_hours) * 
                        cv_coeff * exp(cv_exp * Q_EN('elpv',t,n) / Q_EN.l('el',t,n))
                 =g= firm_coeff(n) * (Q_EN('el',t,n) -
                     sum(ices_el, QEL_OUT('edv',ices_el,t,n)) -
                     sum(ices_el, QEL_OUT('edvfr',ices_el,t,n))
                                     ) / yearly_hours
;
$elseif.x %capacity_constraint%=='high'
eqfirm_capacity_%clt%(t,n)$(mapn('%clt%') and (not tfix(t)) and year(t) gt 2005)..
                 sum(jel_firm, K_EN(jel_firm,t,n)) +
                     K_EN('elwindon',t,n) +
                     K_EN('elwindoff',t,n) + 
                     K_EN('elpv',t,n)
                 =g= firm_coeff(n) * (Q_EN('el',t,n) -
                     sum(ices_el, QEL_OUT('edv',ices_el,t,n)) -
                     sum(ices_el, QEL_OUT('edvfr',ices_el,t,n))
                                     ) / yearly_hours
;
$else.x
$stop no capacity constraint! [capacity_constraint=='%capacity_constraint%' unsupported]
$endif.x

* Flexibility constraint
eqflex_%clt%(t,n)$(mapn_th('%clt%'))..
        Q_EL_FLEX(t,n) =e= sum(jel,Q_EN(jel,t,n) * flex_coeff(jel)) + 
                           ( Q_EN('el',t,n) -
                           sum(ices_el,QEL_OUT('edv',ices_el,t,n)) -
                           sum(ices_el,QEL_OUT('edvfr',ices_el,t,n))
                           ) * flex_coeff('load') 
;

* Grid

** Grid depreciation and investments
eqk_en_grid_%clt%(t,tp1,n)$(mapn_th1('%clt%'))..
                K_EN_GRID(tp1,n) =e= K_EN_GRID(t,n)*(1-grid_delta(tp1,n))**tlen(t)
                                      + tlen(t) * I_EN_GRID(t,n) / grid_cost;

** Grid adjustment to power capacity
eqk_en_grid_to_k_en_%clt%(t,n)$(mapn_th('%clt%'))..
                K_EN_GRID(t,n) =e= sum(jel_stdgrid, K_EN(jel_stdgrid,t,n)) +
                                   ( sum((wind_dist,wind_class), K_EN_WINDON(wind_dist,wind_class,t,n) * grid_trans_cost('elwindon',wind_dist) +
                                     sum(wind_depth,K_EN_WINDOFF(wind_dist,wind_depth,wind_class,t,n) * grid_trans_cost('elwindoff',wind_dist))) +
                                     sum(solar_class,K_EN_PV('far',solar_class,t,n) * grid_trans_cost('elpv','far'))+
                                     sum(solar_class,K_EN_CSP('far',solar_class,t,n) * grid_trans_cost('elcsp','far'))
                                   ) / grid_cost +
                                   (K_EN('elwindon',t,n) + K_EN('elwindoff',t,n)) * (1 + grid_coeff('elwind','mult') * (Q_EN('elwind',t,n) / Q_EN.l('el',t,n))**grid_coeff('elwind','exp')) +
                                    K_EN('elpv',t,n) * (1 + grid_coeff('elpv','mult') * (Q_EN('elpv',t,n) / Q_EN.l('el',t,n))**grid_coeff('elpv','exp')) +
                                    K_EN('elcsp',t,n);
** CSP accounts for itself without markups because the mark up here is related to the need for integration of VREs, but it is not a VRE...

* Capacity growth constraint
eqcap_growth_%clt%(jinv,t,tp1,tp2,n)$(mapn_th2('%clt%') and mkt_growth_rate(jinv,tp1,n))..
                    I_EN(jinv,tp1,n) / MCOST_INV(jinv,tp1,n) =l= (I_EN(jinv,t,n) / MCOST_INV(jinv,t,n)) *
                    (1 + mkt_growth_rate(jinv,tp1,n))**tlen(t) + tlen(t) * el_free_cap(n) / 1e3;

*-------------------------------------------------------------------------------
$elseif %phase%=='fix_variables'

tfix1var(I_EN_GRID,'(t,n)')
tfixvar(K_EN_GRID,'(t,n)')
tfixvar(Q_EL_FLEX,'(t,n)')

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

* If
* - K_EN.lo is not -infinity
* - K_EN(t) and K_EN(t+1) are fixed
* - a mkt_growth_rate is set
* then make sure that the minimum additional capacity in t+1 is compatible with
* with the necessary capacity to go from K_EN(t) to K_EN(t+1). If this is not the case,
* disable the mkt growth constraint, assuming that the K_EN.lo/fx override
* the mkt growth assumptions.
loop((jinv,n,t,tp1,tp2)$(mkt_growth_rate(jinv,tp2,n) and
    (K_EN.lo(jinv,tp2,n) gt 0) and
    (K_EN.lo(jinv,tp1,n) eq K_EN.up(jinv,tp1,n)) and
    (K_EN.lo(jinv,t,n) eq K_EN.up(jinv,t,n)) and
    pre(t,tp1) and pre(tp1,tp2)),
    jtn_incompatible_with_mkt_growth_cap(jinv,tp1,n) = yes$(((K_EN.lo(jinv,tp2,n)-K_EN.lo(jinv,tp1,n)*(1-delta_en(jinv,tp2,n))**tlen(tp1))/tlen(tp1)) ge 
        (((K_EN.lo(jinv,tp1,n)-K_EN.lo(jinv,t,n)*(1-delta_en(jinv,tp1,n))**tlen(t))/tlen(t))*(1 + mkt_growth_rate(jinv,tp1,n))**tlen(t) + tlen(t) * el_free_cap(n) / 1e3)
        );
    mkt_growth_rate(jinv,tp1,n)$jtn_incompatible_with_mkt_growth_cap(jinv,tp1,n) = 0;
);

*-------------------------------------------------------------------------------
$elseif %phase%=='dynamic_calibration'

* Capacity constraint coefficient
firm_coeff(n) = min(sum(jel, valuein(2005,K_EN.l(jel,tt,n))) / (valuein(2005,Q_EN.l('el',tt,n)) / yearly_hours),peak_load_fraction);

*-------------------------------------------------------------------------------
$elseif %phase%=='tfpgdx_items'

firm_coeff

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Sets
jel_firm
jel_stdgrid
jintren
jtn_incompatible_with_mkt_growth_cap

* Parameters
cv_coeff
cv_exp
el_free_cap
flex_coeff
grid_coeff
grid_cost
grid_delta
peak_load_fraction
mkt_growth_rate

* Variables
Q_EL_FLEX
K_EN_GRID
I_EN_GRID

$endif
