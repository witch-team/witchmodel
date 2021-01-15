*-------------------------------------------------------------------------------
* Wind energy module
* - onshore and offshore
*-------------------------------------------------------------------------------

$ifthen %phase%=='sets'

set j                      / elwind, elwindon, elwindoff /;
set jreal(j)               / elwindon, elwindoff /;
set jel(jreal)             / elwindon, elwindoff /;
set jinv(jreal)            / elwindon, elwindoff /;

set jel_own_mu(jel)        / elwindon, elwindoff /;
set jinv_own_k(jinv)       / elwindon, elwindoff /;

set jel_ren(jel)           / elwindon, elwindoff /;
set jreal_to_scale(jreal)  / elwindon, elwindoff /;
set j_to_scale(j)          / elwind, elwindon, elwindoff /;
set jinv_to_scale(jinv)    / elwindon, elwindoff /;

set jel_wind(jel)          / elwindon, elwindoff /;
set jreal_wind(jreal)      / elwindon, elwindoff /;
set jinv_wind(jinv)        / elwindon, elwindoff /;

set map_j(j,jj) 'Relationships between Energy Technology Sectors' /
        el.elwind
        elwind.(elwindon,elwindoff)
/;

set jmcost_inv(jreal)      / elwindon, elwindoff /;

set iq                     / ces_elwind/;
set ices_el(iq)            / ces_elwind/;

set map_ices_el(ices_el,j) / ces_elwind.elwind /;

set wind_dist              / near, inter, far /;
set wind_depth             / shallow, trans, deep /;
set wind_class             / c1*c9 /;
alias(wind_class,wind_class2);
set wind_type              / onshore, offshore /;

set jintren(j) / elwind /;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

scalar yearly_hours / 8760 /;

* overall renewables parameters
parameter floor_cost(jreal) 'Floor cost for non-constant cost technologies [$/W]';

$gdxin '%datapath%data_mod_wind'

parameter windon_pot(n,wind_dist,wind_class) 'Onshore wind potential [TW]';
$loaddc windon_pot

parameter windoff_pot(n,wind_dist,wind_depth,wind_class) 'Offshore wind potential [TW]';
$loaddc windoff_pot

parameter cap_factor(wind_class) 'Wind capacity factors';
$loaddc cap_factor

parameter k_en0_windon(wind_class,t,n) 'Onshore wind installed/baseline capacity (associated to the proper wind class) [TW]';
parameter k_en0_windoff(wind_class,t,n) 'Offshore wind installed/baseline capacity (associated to the proper wind class) [TW]';
$loaddc k_en0_windon
$loaddc k_en0_windoff

parameter windcap_update(t,n) 'Onshore wind 2010/2015 capacity [TW]';

parameter n_oem_wind_high(n) 'regions with high oem costs for wind';
$loaddc n_oem_wind_high

parameter windcap_offshore(t, n) 'Offshore wind 2010/2015 capacity [TW]';

$gdxin

$gdxin '%datapath%data_validation.gdx'
parameter q_en_valid_wind(*,t,n);
parameter k_en_valid_wind(*,t,n);
parameter mcost_inv_valid_wind(jreal,t,n);
$loaddc q_en_valid_wind=q_en_valid_irena
$loaddc k_en_valid_wind=k_en_valid_irena
$loaddc mcost_inv_valid_wind=mcost_inv_valid_irena
$gdxin

* for 2005 compute linear extrapolation backwards from 2010
mcost_inv_valid_wind(jreal,t,n)$(year(t) eq 2005) = 2 * valuein(2010,mcost_inv_valid_wind(jreal,tt,n)) - valuein(2015,mcost_inv_valid_wind(jreal,tt,n));

parameter windoff_costinv(wind_depth) 'Multiplier coefficient for investment cost between depth'; 
windoff_costinv('trans') = 1; 
windoff_costinv('deep') = 1 + (1 / 13); 
windoff_costinv('shallow') = 1 - (1 / 13); 

* Floor costs
floor_cost('elwindon') = 0.5;
floor_cost('elwindoff') = 0.9;
* The offshore wind floor cost is meant to be the near one: the intermediate and far ones always feature the fix transmission cost

* learning rates (updated from IRENA Power Generation Costs in 2019 report, LCOE based) 
* 10% for offshore wind, 23% for onshore wind, 23% for CSP and 36% for solar PV.
* Learning by doing coefficients, converted from learning rates
rd_coef('elwindon','lbd') = log2(1 - 0.23);
rd_coef('elwindoff','lbd') = log2(1 - 0.10);

scalar wind_spill_wcum 'Share of the on/offshore wcum contributing to off/onshore learning';
wind_spill_wcum = 0.8 ;

parameter oem_wind(n);
oem_wind(n)$(n_oem_wind_high(n)) = 0.03046;
oem_wind(n)$(not n_oem_wind_high(n)) = 0.02538;

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

parameter wind_mu(wind_class);
wind_mu(wind_class) = cap_factor(wind_class) * yearly_hours;

delta_en(jreal_wind,t,n)=delta_en0(jreal_wind,n);
delta_lcost(jreal_wind,t,n)=delta_en0(jreal_wind,n);

oem('elwindon',t,n) = oem_wind(n);
oem('elwindoff',t,n) = 2*oem_wind(n);

k_en0('elwindon',n) = max(1e-8,sum(wind_class,valuein(2005, k_en0_windon(wind_class,tt,n))));
k_en0('elwindoff',n) = max(1e-8,sum(wind_class,valuein(2005, k_en0_windoff(wind_class,tt,n))));

mu('elwindon',tfirst,n) = sum(wind_class, wind_mu(wind_class)*max(1e-8,valuein(2005, k_en0_windon(wind_class,tt,n))))/k_en0('elwindon',n);
mu('elwindoff',tfirst,n) = sum(wind_class, wind_mu(wind_class)*max(1e-8,valuein(2005, k_en0_windoff(wind_class,tt,n))))/k_en0('elwindoff',n);

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

variable I_EN_WINDON(wind_dist,wind_class,t,n);
loadvarbnd(I_EN_WINDON,'(wind_dist,wind_class,t,n)',1e-8,1e-12,1e8);
I_EN_WINDON.up(wind_dist,wind_class,t,n) = max(1e-6,windon_pot(n,wind_dist,wind_class) * valuein(2005,mcost_inv_valid_wind('elwindon',tt,n)));

variable I_EN_WINDOFF(wind_dist,wind_depth,wind_class,t,n);
loadvarbnd(I_EN_WINDOFF,'(wind_dist,wind_depth,wind_class,t,n)',1e-8,1e-12,1e8);
I_EN_WINDOFF.up(wind_dist,wind_depth,wind_class,t,n) = max(1e-6,windoff_pot(n,wind_dist,wind_depth,wind_class) * valuein(2005,mcost_inv_valid_wind('elwindoff',tt,n)) * windoff_costinv(wind_depth));

variable K_EN_WINDON(wind_dist,wind_class,t,n);
loadvarbnd(K_EN_WINDON,'(wind_dist,wind_class,t,n)',1e-6,1e-6,1e6);
K_EN_WINDON.fx(wind_dist,wind_class,t,n)$((year(t) le 2015) and (sameas(wind_dist, 'near'))) = max(1e-6, k_en0_windon(wind_class,t,n));
K_EN_WINDON.fx(wind_dist,wind_class,t,n)$((year(t) le 2015) and (not sameas(wind_dist, 'near'))) = 1e-6;
K_EN_WINDON.lo(wind_dist,wind_class,t,n)$(year(t) gt 2015) = valuein(2015, K_EN_WINDON.l(wind_dist,wind_class,tt,n));
K_EN_WINDON.up(wind_dist,wind_class,t,n)$(year(t) gt 2015) = max(K_EN_WINDON.lo(wind_dist,wind_class,t,n),windon_pot(n,wind_dist,wind_class));

variable K_EN_WINDOFF(wind_dist,wind_depth,wind_class,t,n);
loadvarbnd(K_EN_WINDOFF,'(wind_dist,wind_depth,wind_class,t,n)',1e-6,1e-6,1e6);
K_EN_WINDOFF.fx(wind_dist,wind_depth,wind_class,t,n)$((year(t) le 2015) and (sameas(wind_dist, 'near')) and (sameas(wind_depth, 'shallow'))) = max(1e-6,k_en0_windoff(wind_class,t,n));
K_EN_WINDOFF.fx(wind_dist,wind_depth,wind_class,t,n)$((year(t) le 2015) and (not ((sameas(wind_dist, 'near')) and (sameas(wind_depth, 'shallow'))))) = 1e-6;
K_EN_WINDOFF.lo(wind_dist,wind_depth,wind_class,t,n)$(year(t) gt 2015) = valuein(2015, K_EN_WINDOFF.l(wind_dist,wind_depth,wind_class,tt,n));
K_EN_WINDOFF.up(wind_dist,wind_depth,wind_class,t,n)$(year(t) gt 2015) = max(K_EN_WINDOFF.lo(wind_dist,wind_depth,wind_class,t,n), windoff_pot(n,wind_dist,wind_depth,wind_class));

K_EN.lo(jel_wind,t,n)$((K_EN.lo(jel_wind,t,n) lt K_EN.up(jel_wind,t,n)) and (year(t) ge 2020)) = valuein(2020, k_en_valid_tot(jel_wind,t,n));
K_EN.up(jel_wind,t,n)$((K_EN.lo(jel_wind,t,n) lt K_EN.up(jel_wind,t,n)) and (year(t) eq 2020) and sameas(jel_wind,'elwindon')) = valuein(2020, k_en_valid_tot(jel_wind,t,n)) * 1.1;

variable Q_EN_WINDON(wind_dist,wind_class,t,n);
loadvarbnd(Q_EN_WINDON,'(wind_dist,wind_class,t,n)',1e-8,1e-8,1e8);
Q_EN_WINDON.up(wind_dist,wind_class,t,n) = max(1e-8,windon_pot(n,wind_dist,wind_class) * wind_mu(wind_class));

variable Q_EN_WINDOFF(wind_dist,wind_depth,wind_class,t,n);
loadvarbnd(Q_EN_WINDOFF,'(wind_dist,wind_depth,wind_class,t,n)',1e-8,1e-8,1e8);
Q_EN_WINDOFF.up(wind_dist,wind_depth,wind_class,t,n) = max(1e-8,windoff_pot(n,wind_dist,wind_depth,wind_class) * wind_mu(wind_class));

positive variable MCOST_INV_WINDOFF(wind_depth,t,n);
loadvar(MCOST_INV_WINDOFF,'(wind_depth,t,n)',1e-8);

* Link core variables upper bounds to module specific upper bounds
Q_EN.up('elwindon',t,n) = sum((wind_dist,wind_class),(Q_EN_WINDON.up(wind_dist,wind_class,t,n)));
Q_EN.up('elwindoff',t,n) = sum((wind_dist,wind_depth,wind_class),(Q_EN_WINDOFF.up(wind_dist,wind_depth,wind_class,t,n)));
K_EN.up('elwindon',t,n) = min(K_EN.up('elwindon',t,n),sum((wind_dist,wind_class),K_EN_WINDON.up(wind_dist,wind_class,t,n)));
K_EN.up('elwindoff',t,n) = min(K_EN.up('elwindoff',t,n),sum((wind_dist,wind_depth,wind_class),K_EN_WINDOFF.up(wind_dist,wind_depth,wind_class,t,n)));
I_EN.up('elwindon',t,n) = sum((wind_dist,wind_class),I_EN_WINDON.up(wind_dist,wind_class,t,n));
I_EN.up('elwindoff',t,n) = sum((wind_dist,wind_depth,wind_class),I_EN_WINDOFF.up(wind_dist,wind_depth,wind_class,t,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eqq_en_mu_windon_%clt%
eqq_en_mu_windoff_%clt%
eqk_en_windon_%clt%
eqk_en_windoff_%clt%
eqq_en_windon_sum_%clt%
eqq_en_windoff_sum_%clt%
eqk_en_windon_sum_%clt%
eqk_en_windoff_sum_%clt%
eqi_en_windon_sum_%clt%
eqi_en_windoff_sum_%clt%

$elseif %phase%=='eqs'

* Capacity limits in the wind onshore electrical sector
eqq_en_mu_windon_%clt%(wind_dist,wind_class,t,n)$(mapn_th('%clt%') and windon_pot(n,wind_dist,wind_class))..
    Q_EN_WINDON(wind_dist,wind_class,t,n) =l= wind_mu(wind_class) * K_EN_WINDON(wind_dist,wind_class,t,n);

* Capacity limits in the wind offshore electrical sector
eqq_en_mu_windoff_%clt%(wind_dist,wind_depth,wind_class,t,n)$(mapn_th('%clt%') and windoff_pot(n,wind_dist,wind_depth,wind_class))..
    Q_EN_WINDOFF(wind_dist,wind_depth,wind_class,t,n) =l= wind_mu(wind_class) * K_EN_WINDOFF(wind_dist,wind_depth,wind_class,t,n);

* Wind onshore electrical generation plants (new)
eqk_en_windon_%clt%(wind_dist,wind_class,t,tp1,n)$(mapn_th1('%clt%') and windon_pot(n,wind_dist,wind_class))..
    K_EN_WINDON(wind_dist,wind_class,tp1,n) =e= K_EN_WINDON(wind_dist,wind_class,t,n) * (1 - delta_en('elwindon',t,n))**tlen(t) +
                                                tlen(t) * I_EN_WINDON(wind_dist,wind_class,t,n) / MCOST_INV('elwindon',t,n);

* Wind offshore electrical generation plants (new)
eqk_en_windoff_%clt%(wind_dist,wind_depth,wind_class,t,tp1,n)$(mapn_th1('%clt%') and windoff_pot(n,wind_dist,wind_depth,wind_class))..
    K_EN_WINDOFF(wind_dist,wind_depth,wind_class,tp1,n) =e= K_EN_WINDOFF(wind_dist,wind_depth,wind_class,t,n) * (1 - delta_en('elwindoff',t,n))**tlen(t) + 
                                                            tlen(t) * I_EN_WINDOFF(wind_dist,wind_depth,wind_class,t,n) / MCOST_INV_WINDOFF(wind_depth,t,n);

* Total onshore wind energy production
eqq_en_windon_sum_%clt%(t,n)$(mapn_th('%clt%'))..
                Q_EN('elwindon',t,n) =e= sum((wind_dist,wind_class),Q_EN_WINDON(wind_dist,wind_class,t,n));

* Total offshore wind energy production
eqq_en_windoff_sum_%clt%(t,n)$(mapn_th('%clt%'))..
                Q_EN('elwindoff',t,n) =e= sum((wind_dist,wind_depth,wind_class),Q_EN_WINDOFF(wind_dist,wind_depth,wind_class,t,n));

* Total onshore wind capacity
eqk_en_windon_sum_%clt%(t,n)$(mapn_th('%clt%') and tnofirst(t))..
                K_EN('elwindon',t,n) =e= sum((wind_dist,wind_class),K_EN_WINDON(wind_dist,wind_class,t,n));

* Total offshore wind capacity
eqk_en_windoff_sum_%clt%(t,n)$(mapn_th('%clt%') and tnofirst(t))..
                K_EN('elwindoff',t,n) =e= sum((wind_dist,wind_depth,wind_class),K_EN_WINDOFF(wind_dist,wind_depth,wind_class,t,n));

* Total onshore wind investment
eqi_en_windon_sum_%clt%(t,tp1,n)$(mapn_th1_last('%clt%'))..
                I_EN('elwindon',t,n) =e= sum((wind_dist,wind_class),I_EN_WINDON(wind_dist,wind_class,t,n));

* Total offshore wind investment
eqi_en_windoff_sum_%clt%(t,tp1,n)$(mapn_th1_last('%clt%'))..
                I_EN('elwindoff',t,n) =e= sum((wind_dist,wind_depth,wind_class),I_EN_WINDOFF(wind_dist,wind_depth,wind_class,t,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='fix_variables'

tfix1var(I_EN_WINDON,'(wind_dist,wind_class,t,n)')
tfix1var(I_EN_WINDOFF,'(wind_dist,wind_depth,wind_class,t,n)')
tfixvar(K_EN_WINDON,'(wind_dist,wind_class,t,n)')
tfixvar(K_EN_WINDOFF,'(wind_dist,wind_depth,wind_class,t,n)')
tfixvar(Q_EN_WINDON,'(wind_dist,wind_class,t,n)')
tfixvar(Q_EN_WINDOFF,'(wind_dist,wind_depth,wind_class,t,n)')
tfixvar(MCOST_INV_WINDOFF,'(wind_depth,t,n)')

*-------------------------------------------------------------------------------
$elseif %phase%=='before_nashloop'

wcum(jreal_wind,tfirst) = sum(n,K_EN.l(jreal_wind,tfirst,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

loop((tnofirst(t),tm1)$pre(tm1,t),
wcum(jinv_wind,t) = wcum(jinv_wind,tm1) + tlen(t) * sum(n, I_EN.l(jinv_wind,tm1,n) / MCOST_INV.l(jinv_wind,tm1,n));
);

MCOST_INV.fx('elwindon',t,n)$(not tfix(t) and year(t) le 2020) = mcost_inv_valid_wind('elwindon',t,n);
MCOST_INV_WINDOFF.fx(wind_depth,t,n)$(not tfix(t) and year(t) le 2020) = mcost_inv_valid_wind('elwindoff',t,n) * windoff_costinv(wind_depth);

MCOST_INV.fx('elwindon',t,n)$(not tfix(t) and year(t) gt 2020) = max(floor_cost('elwindon'),
                                           valuein(2020,MCOST_INV.l('elwindon',tt,n)) * 
                                           ((wcum('elwindon',t) + wind_spill_wcum * (wcum('elwindoff',t))) / 
                                            (valuein(2020,wcum('elwindon',tt)) + wind_spill_wcum * (valuein(2020,wcum('elwindoff',tt)))))**rd_coef('elwindon','lbd'));
MCOST_INV_WINDOFF.fx(wind_depth,t,n)$(not tfix(t) and year(t) gt 2020) = max(floor_cost('elwindoff'),
                                           valuein(2020,MCOST_INV_WINDOFF.l(wind_depth,tt,n)) *
                                           ((wcum('elwindoff',t) + wind_spill_wcum*(wcum('elwindon',t))) / 
                                            (valuein(2020,wcum('elwindoff',tt)) + wind_spill_wcum * (valuein(2020,wcum('elwindon',tt)))))**rd_coef('elwindoff','lbd'));

MCOST_INV.fx('elwindoff',t,n)$((not tfix(t)) and (K_EN.l('elwindoff',t,n) ne 0)) = sum(wind_depth,MCOST_INV_WINDOFF.l(wind_depth,t,n) * sum((wind_dist,wind_class),K_EN_WINDOFF.l(wind_dist,wind_depth,wind_class,t,n))) / K_EN.l('elwindoff',t,n);
MCOST_INV.fx('elwindoff',t,n)$((not tfix(t)) and (K_EN.l('elwindoff',t,n) eq 0)) = smin(wind_depth,MCOST_INV_WINDOFF.l(wind_depth,t,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='summary_report'

parameter k_en_windon_norm(wind_dist,wind_class,t,n);
parameter k_en_windoff_norm(wind_dist,wind_depth,wind_class,t,n);
parameter k_en_wind_norm_sum(jel_wind,t,n);
parameter wind_mu_marginal(jel_wind,t,n);

k_en_windon_norm(wind_dist,wind_class,t,n) = K_EN_WINDON.l(wind_dist,wind_class,t,n) / K_EN_WINDON.up(wind_dist,wind_class,t,n);
k_en_windoff_norm(wind_dist,wind_depth,wind_class,t,n) = K_EN_WINDOFF.l(wind_dist,wind_depth,wind_class,t,n) / K_EN_WINDOFF.up(wind_dist,wind_depth,wind_class,t,n);
k_en_wind_norm_sum('elwindon',t,n) = sum(wind_class, k_en_windon_norm('near',wind_class,t,n));
k_en_wind_norm_sum('elwindoff',t,n) = sum(wind_class, k_en_windoff_norm('near','shallow',wind_class,t,n));
loop(wind_class,
    wind_mu_marginal(jel_wind,t,n)$(k_en_wind_norm_sum(jel_wind,t,n) gt (ord(wind_class)-1)) = sum(wind_class2$(ord(wind_class2) eq (card(wind_class)-ord(wind_class)+1)), wind_mu(wind_class2));
);

wind_mu_marginal(jel_wind,tfirst,n) = smax(tt$(year(tt) eq 2010),wind_mu_marginal(jel_wind,tt,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Sets
jel_wind
jinv_wind
jreal_wind
wind_class
wind_depth
wind_dist
wind_type

* Parameters
k_en0_windon
k_en_wind_norm_sum
k_en_windoff_norm
k_en_windon_norm
wind_mu
wind_mu_marginal
oem_wind
cap_factor
wind_spill_wcum
yearly_hours
windoff_pot
windon_pot

* Variables
I_EN_WINDOFF
I_EN_WINDON
K_EN_WINDOFF
K_EN_WINDON
MCOST_INV_WINDOFF
Q_EN_WINDOFF
Q_EN_WINDON

$endif

