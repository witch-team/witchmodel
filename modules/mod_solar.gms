*-------------------------------------------------------------------------------
* Solar Powerplants (PV and CSP) to the electrical system
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
$ifthen %phase%=='conf'

* Number of solar classes: full (26) or reduced (5)
$setglobal solar_classes full

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

* introduce solar energy, pv and csp in the sets

set j                      / elsolar, elpv, elcsp /;
set jreal(j)               / elpv, elcsp /;
set jel(jreal)             / elpv, elcsp /;
set jinv(jreal)            / elpv, elcsp /;

set jel_own_mu(jel)        / elpv, elcsp /;
set jinv_own_k(jinv)       / elpv, elcsp /;

set jel_ren(jel)           / elpv, elcsp /;
set jreal_to_scale(jreal)  / elpv, elcsp /;
set j_to_scale(j)          / elpv, elcsp /;
set jinv_to_scale(jinv)    / elpv, elcsp /;

set map_j(j,jj) 'Relationships between Energy Technology Sectors'       /
el.elsolar
elsolar.(elpv,elcsp)
/;

set jmcost_inv(jreal)      / elpv, elcsp /;

set iq                     / ces_elpv,ces_elcsp/;
set ices_el(iq)            / ces_elpv,ces_elcsp/;
set map_ices_el(ices_el,j) /ces_elpv.elpv,ces_elcsp.elcsp /;


set jel_solar(jel)          / elpv, elcsp /;
set jreal_solar(jreal)      / elpv, elcsp /;
set jinv_solar(jinv)        / elpv, elcsp /;

set solar_dist          / near, far /;
set solar_class_all             / c1*c26 /;
$if %solar_classes%==full    set solar_class / solcf1*solcf26 /;
$if %solar_classes%==reduced set solar_class / solcr1*solcr5 /;

set jintren(j) / elpv, elcsp /;

set jel_firm(jel) 'Firm, non intermittent technologies' / elcsp /;

set map_solar_class_all(solar_class, solar_class_all) /
$ifthen.solclass %solar_classes%==reduced
    solcr1.(c1)
    solcr2.(c2*c9)
    solcr3.(c10*c17)
    solcr4.(c18*c25)
    solcr5.(c26)    
$elseif.solclass %solar_classes%==full
$offeolcom
    #solar_class:#solar_class_all
$oneolcom
$endif.solclass
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_mod_solar'

parameter pv_pot_all(n,solar_dist,solar_class_all) 'Solar PV total potential [TW]';
$loaddc pv_pot_all=pv_pot

parameter csp_pot_all(n,solar_dist,solar_class_all) 'Solar CSP total potential [TW]';
$loaddc csp_pot_all=csp_pot

parameter solar_mu_all(solar_class_all,jel_solar) 'Full load hours binned by solar_class [h/yr]';
$loaddc solar_mu_all=solar_mu

parameter pv_pot(n,solar_dist,solar_class) 'Solar PV total potential [TW]';
pv_pot(n,solar_dist,solar_class) = sum(solar_class_all$map_solar_class_all(solar_class, solar_class_all), pv_pot_all(n,solar_dist,solar_class_all));
    
parameter csp_pot(n,solar_dist,solar_class) 'Solar CSP total potential [TW]';
csp_pot(n,solar_dist,solar_class) = sum(solar_class_all$map_solar_class_all(solar_class, solar_class_all), csp_pot_all(n,solar_dist,solar_class_all));

parameter solar_mu(solar_class,jel_solar) 'Full load hours binned by solar_class [h/yr]';
solar_mu(solar_class,jel_solar) = sum(solar_class_all$map_solar_class_all(solar_class, solar_class_all), solar_mu_all(solar_class_all, jel_solar))/
    sum(solar_class_all$map_solar_class_all(solar_class, solar_class_all), 1);

parameter inst_area(n,solar_dist) 'Available area for both PV and CSP installation (competition area) (n,solar_dist) [km^2]';
$loaddc inst_area

parameter inst_density(n,jel_solar) 'Installation density [MW/km^2]';
$loaddc inst_density

parameter k_en0_pv_all(solar_class_all,t,n) 'PV installed/baseline capacity (in all solar classes) [TW]';
$loaddc k_en0_pv_all=k_en0_pv
parameter k_en0_pv(solar_class,t,n) 'PV installed/baseline capacity (in the aggregated solar classes) [TW]';
k_en0_pv(solar_class,t,n) = sum(solar_class_all$map_solar_class_all(solar_class, solar_class_all), k_en0_pv_all(solar_class_all, t,n));

parameter k_en0_csp_all(solar_class_all,t,n) 'CSP installed/baseline capacity (in all solar classes) [TW]';
$loaddc k_en0_csp_all=k_en0_csp
parameter k_en0_csp(solar_class,t,n) 'CSP installed/baseline capacity (in the aggregated solar classes) [TW]';
k_en0_csp(solar_class,t,n) = sum(solar_class_all$map_solar_class_all(solar_class, solar_class_all), k_en0_csp_all(solar_class_all, t,n));

parameter oem_pv(*,n) 'PV oem cost';
$loaddc oem_pv

parameter oem_csp(n) 'CSP oem cost';
$loaddc oem_csp

$gdxin

$gdxin '%datapath%data_validation.gdx'
parameter mcost_inv_valid_solar(jreal,t,n);
$loaddc mcost_inv_valid_solar=mcost_inv_valid_irena
$gdxin
* for 2005 compute linear extrapolation backwards from 2010
mcost_inv_valid_solar(jreal,t,n)$(year(t) eq 2005) = 2 * valuein(2010,mcost_inv_valid_solar(jreal,tt,n)) - valuein(2015,mcost_inv_valid_solar(jreal,tt,n));

* Learning data

* Floor costs
floor_cost('elpv') = 0.25;
floor_cost('elcsp') = 1.25;

* learning rates (updated from IRENA Power Generation Costs in 2019 report, LCOE based) 
* 10% for offshore wind, 23% for onshore wind, 23% for CSP and 36% for solar PV.
* Learning by doing coefficients, converted from learning rates
rd_coef('elpv','lbd') = log2(1 - 0.36);
rd_coef('elcsp','lbd') = log2(1 - 0.23);

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

delta_en(jreal_solar,t,n) = delta_en0(jreal_solar,n);
delta_lcost(jreal_solar,t,n) = delta_en0(jreal_solar,n);

mcost_inv0('elpv',n) = valuein(2005,mcost_inv_valid_solar('elpv',tt,n));
k_en0('elpv',n) = sum(solar_class, k_en0_pv(solar_class,tfirst,n));
oem('elpv',t,n) = oem_pv('mid',n);

mcost_inv0('elcsp',n) = valuein(2005,mcost_inv_valid_solar('elcsp',tt,n));
k_en0('elcsp',n) = sum(solar_class, k_en0_csp(solar_class,tfirst,n));
oem('elcsp',t,n) = oem_csp(n);

mu('elpv',tfirst,n)$(k_en0('elpv',n) gt eps) = sum(solar_class, solar_mu(solar_class,'elpv')*max(1e-8,k_en0_pv(solar_class,tfirst,n)))/k_en0('elpv',n);
mu('elcsp',tfirst,n)$(k_en0('elcsp',n) gt eps) = sum(solar_class, solar_mu(solar_class,'elcsp')*max(1e-8,k_en0_csp(solar_class,tfirst,n)))/k_en0('elcsp',n);

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

variable I_EN_PV(solar_dist,solar_class,t,n);
loadvarbnd(I_EN_PV,'(solar_dist,solar_class,t,n)',1e-8,1e-8,1e8);
I_EN_PV.lo(solar_dist,solar_class,t,n) = 1e-8;
I_EN_PV.up(solar_dist,solar_class,t,n) = max(1e-8,pv_pot(n,solar_dist,solar_class) * mcost_inv0('elpv',n));
I_EN_PV.l(solar_dist,solar_class,t,n) = 1e-8;

variable I_EN_CSP(solar_dist,solar_class,t,n);
loadvarbnd(I_EN_CSP,'(solar_dist,solar_class,t,n)',1e-8,1e-8,1e8);
I_EN_CSP.lo(solar_dist,solar_class,t,n) = 1e-8;
I_EN_CSP.up(solar_dist,solar_class,t,n) = max(1e-8,csp_pot(n,solar_dist,solar_class) * mcost_inv0('elcsp',n));

variable K_EN_PV(solar_dist,solar_class,t,n);
loadvarbnd(K_EN_PV,'(solar_dist,solar_class,t,n)',1e-6,1e-6,1e6);
K_EN_PV.fx('near',solar_class,t,n)$(year(t) le 2015) = max(1e-6,k_en0_pv(solar_class,t,n));
K_EN_PV.fx('far',solar_class,t,n)$(year(t) le 2015) = 1e-6;
K_EN_PV.lo(solar_dist,solar_class,t,n)$(year(t) gt 2015) = valuein(2015, K_EN_PV.l(solar_dist,solar_class,tt,n));
K_EN_PV.up(solar_dist,solar_class,t,n)$(year(t) gt 2015) = max(K_EN_PV.lo(solar_dist,solar_class,t,n),pv_pot(n,solar_dist,solar_class));

variable K_EN_CSP(solar_dist,solar_class,t,n);
loadvarbnd(K_EN_CSP,'(solar_dist,solar_class,t,n)',1e-6,1e-6,1e6);
K_EN_CSP.fx('near',solar_class,t,n)$(year(t) le 2015) = max(1e-6,k_en0_csp(solar_class,t,n));
K_EN_CSP.fx('far',solar_class,t,n)$(year(t) le 2015) = 1e-6;
K_EN_CSP.lo(solar_dist,solar_class,t,n)$(year(t) gt 2015) = valuein(2015, K_EN_CSP.l(solar_dist,solar_class,tt,n));
K_EN_CSP.up(solar_dist,solar_class,t,n)$(year(t) gt 2015) = max(K_EN_CSP.lo(solar_dist,solar_class,t,n),csp_pot(n,solar_dist,solar_class));

K_EN.fx('elpv',tfirst(t),n) = sum((solar_dist,solar_class),K_EN_PV.l(solar_dist,solar_class,t,n));
K_EN.fx('elcsp',tfirst(t),n) = sum((solar_dist,solar_class),K_EN_CSP.l(solar_dist,solar_class,t,n));

K_EN.lo(jel_solar,t,n)$((K_EN.lo(jel_solar,t,n) lt K_EN.up(jel_solar,t,n)) and (year(t) ge 2020)) = valuein(2020, k_en_valid_tot(jel_solar,t,n));

variable Q_EN_PV(solar_dist,solar_class,t,n);
loadvarbnd(Q_EN_PV,'(solar_dist,solar_class,t,n)',1,1e-8,1e8);
Q_EN_PV.up(solar_dist,solar_class,t,n) = max(1e-8,pv_pot(n,solar_dist,solar_class)*solar_mu(solar_class,'elpv'));

variable Q_EN_CSP(solar_dist,solar_class,t,n);
loadvarbnd(Q_EN_CSP,'(solar_dist,solar_class,t,n)',1,1e-8,1e8);
Q_EN_CSP.up(solar_dist,solar_class,t,n) = max(1e-8,csp_pot(n,solar_dist,solar_class)* solar_mu(solar_class,'elcsp'));

* Link core variables upper bounds to module specific upper bounds
Q_EN.up('elpv',t,n) = sum((solar_dist,solar_class),(Q_EN_PV.up(solar_dist,solar_class,t,n)));
Q_EN.up('elcsp',t,n) = sum((solar_dist,solar_class),(Q_EN_CSP.up(solar_dist,solar_class,t,n)));
K_EN.up('elpv',t,n) = sum((solar_dist,solar_class),K_EN_PV.up(solar_dist,solar_class,t,n));
K_EN.up('elcsp',t,n) = sum((solar_dist,solar_class),K_EN_CSP.up(solar_dist,solar_class,t,n));
I_EN.up('elpv',t,n) = sum((solar_dist,solar_class),I_EN_PV.up(solar_dist,solar_class,t,n));
I_EN.up('elcsp',t,n) = sum((solar_dist,solar_class),I_EN_CSP.up(solar_dist,solar_class,t,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eqq_en_mu_pv_%clt%
eqq_en_mu_csp_%clt%
eqk_en_pv_%clt%
eqk_en_csp_%clt%
eqq_en_pv_sum_%clt%
eqq_en_csp_sum_%clt%
eqk_en_pv_sum_%clt%
eqk_en_csp_sum_%clt%
eqi_en_pv_sum_%clt%
eqi_en_csp_sum_%clt%
eqk_en_solar_comp_%clt%

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'


* Capacity limits in the pv electrical sector
eqq_en_mu_pv_%clt%(solar_dist,solar_class,t,n)$(mapn_th('%clt%') and pv_pot(n,solar_dist,solar_class))..
                Q_EN_PV(solar_dist,solar_class,t,n) =l= solar_mu(solar_class,'elpv')*K_EN_PV(solar_dist,solar_class,t,n);

* Capacity limits in the csp electrical sector
eqq_en_mu_csp_%clt%(solar_dist,solar_class,t,n)$(mapn_th('%clt%') and csp_pot(n,solar_dist,solar_class))..
                Q_EN_CSP(solar_dist,solar_class,t,n) =l= solar_mu(solar_class,'elcsp')*K_EN_CSP(solar_dist,solar_class,t,n);

* PV electrical generation plants (new)
eqk_en_pv_%clt%(solar_dist,solar_class,t,tp1,n)$(mapn_th1('%clt%') and pv_pot(n,solar_dist,solar_class))..
                K_EN_PV(solar_dist,solar_class,tp1,n) =e= K_EN_PV(solar_dist,solar_class,t,n)*(1-delta_en('elpv',t,n))**tlen(t)
                                                                        +tlen(t)*I_EN_PV(solar_dist,solar_class,t,n)/MCOST_INV('elpv',t,n);

* CSP electrical generation plants (new)
eqk_en_csp_%clt%(solar_dist,solar_class,t,tp1,n)$(mapn_th1('%clt%') and csp_pot(n,solar_dist,solar_class))..
                K_EN_CSP(solar_dist,solar_class,tp1,n) =e= K_EN_CSP(solar_dist,solar_class,t,n)*(1-delta_en('elcsp',t,n))**tlen(t)
                                                                        +tlen(t)*I_EN_CSP(solar_dist,solar_class,t,n)/MCOST_INV('elcsp',t,n);

* Total PV energy production
eqq_en_pv_sum_%clt%(t,n)$(mapn_th('%clt%'))..
                Q_EN('elpv',t,n) =e= sum((solar_dist,solar_class),Q_EN_PV(solar_dist,solar_class,t,n));

* Total CSP energy production
eqq_en_csp_sum_%clt%(t,n)$(mapn_th('%clt%'))..
                Q_EN('elcsp',t,n) =e= sum((solar_dist,solar_class),Q_EN_CSP(solar_dist,solar_class,t,n));

* Total PV capacity
eqk_en_pv_sum_%clt%(t,n)$(mapn_th('%clt%') and tnofirst(t))..
                K_EN('elpv',t,n) =e= sum((solar_dist,solar_class),K_EN_PV(solar_dist,solar_class,t,n));

* Total CSP capacity
eqk_en_csp_sum_%clt%(t,n)$(mapn_th('%clt%') and tnofirst(t))..
                K_EN('elcsp',t,n) =e= sum((solar_dist,solar_class),K_EN_CSP(solar_dist,solar_class,t,n));

* Total PV investment
eqi_en_pv_sum_%clt%(t,tp1,n)$mapn_th1_last('%clt%')..
                I_EN('elpv',t,n) =e= sum((solar_dist,solar_class),I_EN_PV(solar_dist,solar_class,t,n));

* Total CSP investment
eqi_en_csp_sum_%clt%(t,tp1,n)$mapn_th1_last('%clt%')..
                I_EN('elcsp',t,n) =e= sum((solar_dist,solar_class),I_EN_CSP(solar_dist,solar_class,t,n));

* Capacity constraint in the competition area (e.g. neweuro is excluded for computational reasons, but the constraint is practically irrelevant)
eqk_en_solar_comp_%clt%(t,n,solar_dist)$(map_clt_n('%clt%',n) and (not tfix(t)) and (inst_area(n,solar_dist) gt 1))..
                 sum(solar_class,K_EN_PV(solar_dist,solar_class,t,n)*1e6/inst_density(n,'elpv') +
                                 K_EN_CSP(solar_dist,solar_class,t,n)*1e6/inst_density(n,'elcsp')) =l= inst_area(n,solar_dist);



*-------------------------------------------------------------------------------
$elseif %phase%=='fix_variables'

tfix1var(I_EN_PV,'(solar_dist,solar_class,t,n)')
tfix1var(I_EN_CSP,'(solar_dist,solar_class,t,n)')
tfixvar(K_EN_PV,'(solar_dist,solar_class,t,n)')
tfixvar(K_EN_CSP,'(solar_dist,solar_class,t,n)')
tfixvar(Q_EN_PV,'(solar_dist,solar_class,t,n)')
tfixvar(Q_EN_CSP,'(solar_dist,solar_class,t,n)')

*-------------------------------------------------------------------------------
$elseif %phase%=='before_nashloop'

wcum(jreal_solar,tfirst) = sum(n,K_EN.l(jreal_solar,tfirst,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

* World cumulative capacities of solar plants
loop((tnofirst(t),tm1)$pre(tm1,t),
  wcum(jinv_solar,t) = wcum(jinv_solar,tm1) + tlen(t) * sum(n, I_EN.l(jinv_solar,tm1,n) / MCOST_INV.l(jinv_solar,tm1,n));
);

* Investment costs of solar plants
MCOST_INV.fx(jreal_solar,t,n)$(not tfix(t) and year(t) le 2020) = mcost_inv_valid_solar(jreal_solar,t,n);
MCOST_INV.fx(jreal_solar,t,n)$(not tfix(t) and year(t) gt 2020) = max(floor_cost(jreal_solar),
                                                  valuein(2020,mcost_inv_valid_solar(jreal_solar,tt,n)) *
                                                  (wcum(jreal_solar,t) / valuein(2020,wcum(jreal_solar,tt)))**rd_coef(jreal_solar,'lbd'));

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Sets
jel_solar
jinv_solar
jreal_solar
solar_dist
solar_class

* Parameters
pv_pot
csp_pot
solar_mu
inst_area
inst_density
k_en0_pv
k_en0_csp
oem_pv
oem_csp

* Variables
I_EN_PV
I_EN_CSP
K_EN_PV
K_EN_CSP
Q_EN_PV
Q_EN_CSP

$endif

