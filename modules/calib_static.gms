*-------------------------------------------------------------------------------
* Calibration of CES parameters in base year
*
* Usage: --static_calibration=1
*
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

*$setglobal use_capital
$setglobal error_tolerance_q0    0.1
$setglobal error_tolerance_alpha 0.5

$setglobal caliboutgdx %datapath%data_calib.gdx

* Macros
$macro weighted_jel_fed_k(arg) (sum((jfed,jel,jel2)$(sameas(jfed,jel) and map_jnode_jel(jnode,jel2) and map_jel_jelparam(jel2,jel)), (&arg)*k_en0(jel2,n))/sum((jel,jel2)$(map_jnode_jel(jnode,jel2) and map_jel_jelparam(jel2,jel)), k_en0(jel2,n)))
$macro weighted_jel_notfed_k(arg) (sum((jel,jel2)$(map_jnode_jel(jnode,jel2) and map_jel_jelparam(jel2,jel)), (&arg)*k_en0(jel2,n))/sum((jel,jel2)$(map_jnode_jel(jnode,jel2) and map_jel_jelparam(jel2,jel)), k_en0(jel2,n)))

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

* Production functions nodes
* node -> inode
set inode 'Nodes used in static calibration' /
    y       'Production'
    k       'Capital'
    l       'Labor'
    kl      'Aggregate Capital-Labor'
    fen     'Final energy services'
    krd_en  'Energy R&D capital'
    en      'Energy'
    nel     'Non-electric energy'
    el      'Electricity'
    elhydro 'Electricy from hydroplants'
    el2
    elffren
    elnuclearback
    elintren
    elwind  'Electricity from windmill'
    elpv    'Electricity from photovoltaics'
    elcsp   'Electricity from concentrated solar power'
    elff
    elcoalwbio
    eloil   'Electricity from oil plant'
    elgas   'Electricity from gas plant'
    nelcoal 'Coal (for non-electric use)'
    nelog
    neloil  'Oil (for non-electric use)'
    nelgas  'Gas (for non-electric use)'
    neltrbiofuel 'Traditionnal biofuel'
    neltrbiomass 'Traditionnal biomass'
/;
alias(inode,inode2,inode3);

* Nodes using a ces equation
set ces_node(inode) /
    y
    fen
    en
    el2
    elff
    nelog
    elffren
    elintren
/;

* Nodes using a cobb-douglas equation
set cobb_node(inode) /
    kl
/;

* Nodes using a linear equation
set lin_node(inode) /
    el, nel
/;

* Map inode to its children in the production nest tree
set map_tree_nodes(inode,inode2) /
    y.(fen, kl)
    kl.(k,l)
    fen.(en,krd_en)
    en.(el,nel)
    el.(el2,elhydro)
    el2.(elffren, elnuclearback)
    elffren.(elff, elintren)
    elintren.(elwind,elpv,elcsp)
    elff.(elcoalwbio, eloil, elgas)
    nel.(nelcoal, neltrbiomass, nelog)
    nelog.(neloil, nelgas, neltrbiofuel)
/;

* inode w/ corresponding jel(s)
set jnode(inode) / elintren, elwind, elpv, elcsp, elnuclearback, elhydro,
                   elcoalwbio, eloil, elgas, nelcoal, neltrbiomass, nelog,
                   neloil, nelgas, neltrbiofuel /;

* jnode electric
set jelnode(jnode) / elwind, elpv, elcsp, elnuclearback, elhydro,
                     elcoalwbio, eloil, elgas /;

* jnode non-electric
set jnelnode(jnode) / nelcoal, neltrbiomass, neloil, nelgas, neltrbiofuel /;

* jnode w/ corresponding fuel(s)
set jfednode(jnode) / elnuclearback, elcoalwbio, eloil, elgas, nelcoal,
                      neltrbiomass, neloil, nelgas, neltrbiofuel /;

* Map jnode to corresponding jel(s)
set map_jnode_jel(jnode,jel) /
    elintren.(elwindon,elwindoff,elpv,elcsp)
    elwind.(elwindon,elwindoff)
    elpv.elpv
    elcsp.elcsp
    elnuclearback.(elnuclear_new,elnuclear_old)
    elhydro.(elhydro_new,elhydro_old)
    elcoalwbio.(elpc_new,elpc_old,elpc_late,elpb_new,elpb_old,elcigcc, elpc_ccs, elpc_oxy, elbigcc)
    eloil.(eloil_new,eloil_old)
    elgas.(elgastr_new,elgastr_old,elgasccs)
    /;

* Map jnode to fuel used by jnode
set map_jnode_fuel(jnode,fuel) /
    elnuclearback.uranium
    (elcoalwbio,nelcoal).coal
    (eloil,neloil).oil
    (elgas,nelgas).gas
    neltrbiomass.trbiomass
    neltrbiofuel.trbiofuel
/;

* Map jfednode to its jel old corresponding entry
set map_jfednode_jel_old(jnode,jel) /
    elnuclearback.elnuclear_old
    elcoalwbio.elpc_old
    eloil.eloil_old
    elgas.elgastr_old
    /;

* Map jel to the jel index to be used in weighted_jel_k
set map_jel_jelparam(jel,jel2) /
elpc_new.elpc_new
elpc_old.elpc_new
elpc_late.elpc_late
elpb_new.elpb_new
elpb_old.elpb_new
elcigcc.elcigcc
elpc_ccs.elpc_ccs
elpc_oxy.elpc_oxy
elbigcc.elbigcc
eloil_new.eloil_new
eloil_old.eloil_new
elgastr_new.elgastr_new
elgastr_old.elgastr_new
elgasccs.elgasccs
elhydro_new.elhydro_new
elhydro_old.elhydro_new
elnuclear_new.elnuclear_new
elnuclear_old.elnuclear_new
elpv.elpv
elcsp.elcsp
elwindon.elwindon
elwindoff.elwindoff
/;

set jtrans / trad_cars, trad_stfr /;

set ierr / p0, q0, alpha /;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

parameter p0(inode,n);
p0(inode,n) = na;

$gdxin '%datapath%data_calib_static.gdx'

parameter q_cali00(inode,n) 'Base year calibration values for production function nodes';
$loaddc q_cali00

parameter mcost_inv00(jel,n) 'Cost of investment T$/TW';
$load mcost_inv00

mcost_inv0(jel,n) = mcost_inv00(jel,n);

parameter oem00(jel,n) 'Cost of operation and mantainance T$/TW';
$loaddc oem00

oem0(jel,n) = oem00(jel,n);

parameter mu00(jel,n) 'Capacity factor of maximum production [TWh/TW]';
$load mu00

mu0(jel,n) = mu00(jel,n);

parameter k_en00(jel,n) 'Initial capacity [TW]';
$loaddc k_en00

parameter csi00(fuel,jfed,n) 'Sectoral efficiency ratio [TWh/TWh]';
$loaddc csi00

csi0(fuel,jfed,n) = csi00(fuel,jfed,n);

parameter wprice00(fuel) 'Price of fuels $/Wh';
$loaddc wprice00

parameter p_mkup00(fuel,n);
$loaddc p_mkup00

p_mkup0(fuel,n) = p_mkup00(fuel,n);

parameter fcost(fuel,n);
fcost(fuel,n) = wprice00(fuel) + p_mkup00(fuel,n);

parameter q_extraction0(f,n);
$loaddc q_extraction0

parameter p0_feedback_2015(j,n);
$loaddc p0_feedback_2015

parameter q0_feedback_2015(j,n);
$loaddc q0_feedback_2015

parameter q_transport0(jtrans,n);
$load q_transport0

$if set ces_trans q_transport0(jtrans,n) = 0;

parameter calirho(inode);
$loaddc calirho

rho(inode,t) = calirho(inode);

$ifthen.uc set use_capital
* Capital calibration based on K0
set capitals /k/;
parameter capital_zero(capitals, n);
$loaddc capital_zero

$endif.uc

$ifthen.cg not set calibgdx
$loaddc q0 = q0_start
$else.cg
$gdxin %calibgdx%
$loaddc q0
$endif.cg

$gdxin

$gdxin '%datapath%data_validation.gdx'
parameter k_en_valid_old(*,t,n);
parameter k_en_valid_old_iaea(*,t,n); # for nuclear
parameter k_en_valid_tot(*,t,n);
parameter k_en_valid_irena(*,t,n);
parameter q_en_valid_sta(*,t,n);
parameter q_en_valid_irena(*,t,n);
parameter q_in_valid_sta(*,t,n);
parameter q_fuel_valid_sta(*,t,n);
$loaddc k_en_valid_old=k_en_valid_platts_old
$loaddc k_en_valid_old_iaea=k_en_valid_iaea
$loaddc k_en_valid_tot=k_en_valid_platts_tot
$loaddc k_en_valid_irena=k_en_valid_irena
$loaddc q_en_valid_sta=q_en_valid_weo
$loaddc q_en_valid_irena=q_en_valid_irena
$loaddc q_in_valid_sta=q_in_valid_weo
$loaddc q_fuel_valid_sta=q_fuel_valid_weo
$gdxin

* Override Nuclear with IAEA statistics for capacities
k_en_valid_old('elnuclear',t,n)$(year(t) le 2015) = k_en_valid_old_iaea('elnuclear',t,n);
k_en_valid_tot('elnuclear',t,n) = k_en_valid_old_iaea('elnuclear',t,n);
k_en_valid_tot(jel_wind,t,n) = k_en_valid_irena(jel_wind,t,n);
k_en_valid_tot(jel_solar,t,n) = k_en_valid_irena(jel_solar,t,n);

k_en_valid_old(jcalib,tfirst,n)$(k_en_valid_old(jcalib,tfirst,n) eq 0) = 1e-8;
q_en_valid_sta(jcalib,tfirst,n)$(q_en_valid_sta(jcalib,tfirst,n) eq 0) = 1e-8;

k_en_valid_old(jcalib,t,n)$(k_en_valid_old(jcalib,t,n) eq 0) = 1e-8;

k_en00('elpc_old',n) = valuein(2005, k_en_valid_old('elpc',tt,n));
k_en00('eloil_old',n) = valuein(2005, k_en_valid_old('eloil',tt,n));
k_en00('elgastr_old',n) = valuein(2005, k_en_valid_old('elgastr',tt,n));
k_en00('elhydro_old',n) = valuein(2005, k_en_valid_old('elhydro',tt,n));
k_en00('elnuclear_old',n) = valuein(2005, k_en_valid_old('elnuclear',tt,n));
k_en00('elwindon',n) = valuein(2005, k_en_valid_irena('elwindon',tt,n));
k_en00('elwindoff',n) = valuein(2005, k_en_valid_irena('elwindoff',tt,n));
k_en00('elpv',n) = valuein(2005, k_en_valid_irena('elpv',tt,n));
k_en00('elcsp',n) = valuein(2005, k_en_valid_irena('elcsp',tt,n));

k_en0(jel,n) = k_en00(jel,n);
k_en0(jel,n)$(k_en00(jel,n) eq 0) = 1e-8;

csi0('coal','elpc_old',n) = csi0('coal','elpc_new',n);
csi0('coal','elpc_old',n)$valuein(2005, q_in_valid_sta('elpc', tt, n)) = valuein(2005, q_en_valid_sta('elpc', tt, n)) / valuein(2005, q_in_valid_sta('elpc', tt, n));

csi0('gas','elgastr_old',n) = csi0('gas','elgastr_new',n);
csi0('gas','elgastr_old',n)$valuein(2005, q_in_valid_sta('elgastr', tt, n)) = valuein(2005, q_en_valid_sta('elgastr', tt, n)) / valuein(2005, q_in_valid_sta('elgastr', tt, n));

csi0('oil','eloil_old',n) = csi0('wbio','elpb_new',n);
csi0('oil','eloil_old',n)$valuein(2005, q_in_valid_sta('eloil', tt, n)) = valuein(2005, q_en_valid_sta('eloil', tt, n)) / valuein(2005, q_in_valid_sta('eloil', tt, n));

csi0('wbio','elpb_old',n) = csi0('wbio','elpb_new',n);
csi0('wbio','elpb_old',n)$valuein(2005, q_in_valid_sta('elpb', tt, n)) = valuein(2005, q_en_valid_sta('elpb', tt, n)) / valuein(2005, q_in_valid_sta('elpb', tt, n));

q_cali00('l',n) = l(tfirst, n);
q_cali00('y',n) = ykali(tfirst, n);

q_en_valid_sta(jcalib,t,n)$(q_en_valid_sta(jcalib,t,n) eq 0) = 1e-8;
q_cali00('elhydro',n) = valuein(2005, q_en_valid_sta('elhydro', tt, n));
q_cali00('elwind',n) = valuein(2005, q_en_valid_sta('elwind', tt, n));
q_cali00('elpv',n) = valuein(2005, q_en_valid_sta('elpv', tt, n));
q_cali00('elcsp',n) = 1e-6;
q_cali00('elgas',n) = valuein(2005, q_en_valid_sta('elgastr', tt, n));
q_cali00('eloil',n) = valuein(2005, q_en_valid_sta('eloil', tt, n));
q_cali00('elnuclearback',n) = valuein(2005, q_en_valid_sta('elnuclear', tt, n));
q_cali00('elcoalwbio',n) = valuein(2005, q_en_valid_sta('elpb', tt, n)) + valuein(2005, q_en_valid_sta('elpc', tt, n));
q_cali00('nelcoal',n) = valuein(2005, q_fuel_valid_sta('coal', tt, n)) - valuein(2005, q_en_valid_sta('elpc', tt, n)) / csi0('coal','elpc_old',n); # assume csi0 nelcoal is 1
q_cali00('nelgas',n)$csi0('gas','elgastr_old',n) = (valuein(2005, q_fuel_valid_sta('gas', tt, n)) - valuein(2005, q_en_valid_sta('elgastr', tt, n)) / csi0('gas','elgastr_old',n)) * csi0('gas','nelgas',n);
q_cali00('neloil',n)$csi0('oil','eloil_old',n) = (valuein(2005, q_fuel_valid_sta('oil', tt, n)) - valuein(2005, q_en_valid_sta('eloil', tt, n)) / csi0('oil','eloil_old',n)) * csi0('oil','neloil',n);
q_cali00('neltrbiofuel',n) = valuein(2005, q_en_valid_sta('trbiofuel', tt, n));

q_cali00('neltrbiofuel',n) = 0; map_tree_nodes('nelog','neltrbiofuel') = no;
q_cali00('neltrbiofuel',n) = 0; map_tree_nodes('nelog','neltrbiofuel') = no;

parameter r0(n) 'Interest rate';
r0(n)$(oecd(n)) = 0.05;
r0(n)$(not oecd(n)) = 0.07;

* Final good depreciation
delta0(g) = 0.1;

parameter feedback_price_2015(j,n);
parameter feedback_interest_rate(t,n);
parameter feedback_mu_wind(wind_class);
parameter feedback_wprice(*,t);
parameter feedback_mu_solar(solar_class,jel_solar);
parameters
    feedback_value(j,t,n)
    feedback_price_multiplier(n)
    total_feedback_value(t,n);

loop((jel,jcalib)$(xiny(jel,jold) and xiny(jel,jreal) and map_calib(jcalib,jel)),
    mu0(jel,n) = min(round((q_en_valid_sta(jcalib,tfirst,n)/k_en0(jel,n))),8760);
);

* Compute depreciation rate using lifetime [TW/TW/yr]
delta_en0(jel, n) = depreciation_rate(jel);

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

variable R(n);
$ifthen.uc set use_capital
R.lo(n) = 1e-12;
R.up(n) = 1e5;
R.l(n) = r0(n)
$else.uc
R.fx(n) = r0(n)
$endif.uc

* In general, for each tree inode we have...
** a reference quantity
variable VARQ0(inode,n);
VARQ0.lo(inode,n) = 1e-8;
VARQ0.up(inode,n) = 1e5;
VARQ0.l(inode,n) = q0(inode,n);

VARQ0.fx(inode,n)$(q_cali00(inode,n) gt 0) = q_cali00(inode,n);
$if set transport_feedback VARQ0.fx('neltrbiofuel',n) = 0;

** a reference price
variable VARP0(inode,n) 'Price, for jnode USD2005/Wh';
VARP0.lo(inode,n) = 1e-8;
VARP0.l(inode,n) = 1e-3;
VARP0.up(inode,n) = 1e3;

* All the bundle inodes are assumed to have a reference price = 1
* VARQ0 will then represent the value of the sector in T$
VARP0.fx(inode,n)$(sum(inode2$map_tree_nodes(inode,inode2),1)) = 1;

VARP0.fx(jnode,n)$jnelnode(jnode) = sum(fuel$map_jnode_fuel(jnode,fuel),fcost(fuel,n)); #fuel

* Calculate intermittent renewables prices in 2015
parameter feedback_price(j,t,n);
parameter feedback_interest_rate(t,n);
parameter feedback_mu_wind(wind_class);
parameter feedback_wprice(*,t);
parameter feedback_mu_solar(solar_class,jel_solar);
variable FEEDBACK_MCOST_INV(jreal,t,n);
variable FEEDBACK_Q_EN_WINDON(wind_dist,wind_class,t,n);
variable FEEDBACK_Q_EN_PV(solar_dist,solar_class,t,n);
variable FEEDBACK_Q_EN_CSP(solar_dist,solar_class,t,n);
variable FEEDBACK_Q_EN(j,t,n);
variable FEEDBACK_Q_OUT(f,t,n);
variable FEEDBACK_Q_FUEL(fuel,t,n);
variable FEEDBACK_MCOST_FUEL(fuel,t,n);
parameters feedback_value(j,t,n),
           feedback_price_multiplier(n),
           total_feedback_value(t,n);

parameters old_p0(inode,n), old_q0(inode,n), old_alpha(inode,n);
old_p0(inode,n) = na;
old_q0(inode,n) = na;
old_alpha(inode,n) = na;

** an alpha
variable VARALPHA(inode,n);
VARALPHA.lo(inode,n) = 1e-8;
VARALPHA.up(inode,n) = 1;
VARALPHA.up(inode,n)$(sum(inode2$(map_tree_nodes(inode2,inode) and lin_node(inode2)),1)) = 1e3;
$ifthen.sg set calib_startgdx
parameter alpha_gdx(inode, n);
parameter q0_gdx(inode, n);
execute_load '%calib_startgdx%.gdx',
    alpha_gdx=alpha,
    q0_gdx=q0
;
VARALPHA.l(inode,n) = alpha_gdx(inode,n));
VARQ0.l(inode,n)$(VARQ0.lo(inode,n) lt VARQ0.up(inode,n)) = q0_gdx(inode,n);
$else.sg
VARALPHA.l(inode,n) = 0.5;
$endif.sg

*-------------------------------------------------------------------------------
* Equations
*-------------------------------------------------------------------------------

Equations
    eq_euler
    eq_value_shares
    eq_price_of_capital
    eq_price_of_capital_rnd
    eq_price_of_electricity_not_fed
    eq_price_of_electricity_fed
$if set use_capital eq_interest_rate
;

* Euler's homogeneous function theorem (degree 1)
eq_euler(n,inode)$(sum(inode2$map_tree_nodes(inode,inode2),1))..
    VARQ0(inode,n) =e= sum(inode2$map_tree_nodes(inode,inode2), VARQ0(inode2,n) * VARP0(inode2,n));

* Production functions value shares
eq_value_shares(n,inode2,inode)$(map_tree_nodes(inode2,inode))..
    VARALPHA(inode,n) =e= VARP0(inode,n) * VARQ0(inode,n) / VARQ0(inode2,n);

eq_price_of_capital(n)..
    VARP0('k',n) =e= R(n)+(1-(1-delta0('fg'))**tlen(tfirst))/tlen(tfirst);

eq_price_of_capital_rnd(n)..
    VARP0('krd_en',n) =e= rd_crowd_out * (R(n) + (1 - (1 - rd_delta('en'))**tlen(tfirst)) / tlen(tfirst));

eq_price_of_electricity_not_fed(jnode,n)$(jelnode(jnode) and (not jfednode(jnode)) and (VARP0.lo(jnode,n) lt VARP0.up(jnode,n)))..
    VARP0(jnode,n) =e= weighted_jel_notfed_k(((R(n)+(1-(1-delta_en0(jel,n))**tlen(tfirst))/tlen(tfirst))*mcost_inv0(jel,n)+oem0(jel,n))/mu0(jel,n)); #capital+o&m

eq_price_of_electricity_fed(jnode,n)$(jelnode(jnode) and jfednode(jnode) and (VARP0.lo(jnode,n) lt VARP0.up(jnode,n)))..
    VARP0(jnode,n) =e= weighted_jel_fed_k(((R(n)+(1-(1-delta_en0(jel,n))**tlen(tfirst))/tlen(tfirst))*mcost_inv0(jel,n)+oem0(jel,n))/mu0(jel,n) + sum(fuel$(csi00(fuel,jfed,n) and map_jnode_fuel(jnode,fuel)), fcost(fuel,n)/csi00(fuel,jfed,n)));  #capital+o&m+fuel

$ifthen.uc set use_capital
* Define interest rate as variable
eq_interest_rate(n)..
R(n) =e= VARQ0('y',n) *
    VARALPHA('kl',n) *
    VARALPHA('k',n) *
    1 / capital_zero('k',n) -
    (1 - (1 - delta0('fg'))**tlen(tfirst)) / tlen(tfirst);
$endif.uc

model witch_static_cali /
    eq_euler
    eq_value_shares
    eq_price_of_capital
    eq_price_of_capital_rnd
    eq_price_of_electricity_not_fed
    eq_price_of_electricity_fed
$if set use_capital eq_interest_rate
      /;
witch_static_cali.solvelink=5;

*-------------------------------------------------------------------------------
$elseif %phase%=='policy'

errtol('q0') = %error_tolerance_q0%;
errtol('p0') = %error_tolerance_q0%;
errtol('alpha') = %error_tolerance_alpha%;

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

* Update VARQ0 and VARP0 with feedbacks

** neloil
VARQ0.fx('neloil',n) = q_cali00('neloil',n) -
                       valuein(2005,Q_IN.l('oil','trad_cars',tt,n)) - 
                       valuein(2005,Q_IN.l('oil','trad_stfr',tt,n))
;

VARQ0.fx('neloil',n)$(VARQ0.l('neloil',n) lt 0) = 0.5 * q_cali00('neloil',n);

** y
VARQ0.fx('y',n) = q_cali00('y',n)
        + sum(fuel, MCOST_FUEL.l(fuel,tfirst,n) * Q_FUEL.l(fuel,tfirst,n))
        - sum(extract(f), FPRICE.l(f,tfirst) * Q_OUT.l(f,tfirst,n))
;

** wage
VARP0.fx('l',n) = 0.7*VARQ0.l('y',n)/VARQ0.l('l',n); #wage(n), eq35;

** renewables
feedback_price('elpv',t,n)$(year(t) eq 2015) = ((R.l(n) + (1 - (1 - delta_en0('elpv',n))**tlen(tfirst)) / tlen(tfirst)) *
                                valuein(2015,MCOST_INV.l('elpv',tt,n)) + oem0('elpv',n)) / 
                                (sum(solar_class, solar_mu(solar_class, 'elpv') * 
                                sum(solar_dist, valuein(2015, Q_EN_PV.l(solar_dist, solar_class, tt, n)))) / 
                                valuein(2015, Q_EN.l('elpv',tt,n)));
feedback_price('elcsp',t,n)$(year(t) eq 2015) = ((R.l(n) + (1 - (1 - delta_en0('elcsp',n))**tlen(tfirst)) / tlen(tfirst)) *
                                 valuein(2015,MCOST_INV.l('elcsp',tt,n)) + oem0('elcsp',n)) /
                                 (sum(solar_class, solar_mu(solar_class, 'elcsp') * 
                                 sum(solar_dist, valuein(2015,Q_EN_CSP.l(solar_dist, solar_class, tt, n)))) / 
                                 valuein(2015,Q_EN.l('elcsp',tt,n)));
feedback_price('elwind',t,n)$(year(t) eq 2015) = ((R.l(n) + (1 - (1 - delta_en0('elwindon',n))**tlen(tfirst)) / tlen(tfirst)) * 
                                  valuein(2015,MCOST_INV.l('elwindon',tt,n)) + oem0('elwindon',n)) /
                                  (sum(wind_class, wind_mu(wind_class) * 
                                  sum(wind_dist, valuein(2015,Q_EN_WINDON.l(wind_dist,wind_class,tt,n)))) / 
                                  valuein(2015,Q_EN.l('elwindon',tt,n)));

* values in 2005 and 2015
loop((inode,j)$(jintren(j) and sameas(inode,j)),
    feedback_value(j,tfirst,n) = VARP0.l(inode,n)*VARQ0.l(inode,n);
    feedback_value(j,t,n)$(year(t) eq 2015) = feedback_price(j,t,n)*Q_EN.l(j,t,n);
);
total_feedback_value(t,n) = sum(jintren, feedback_value(jintren,t,n));
* Calculate adjusted reference quantities
loop((t,inode,j)$(jintren(j) and sameas(inode,j) and (year(t) eq 2015)),
    VARQ0.fx(inode,n) =
        Q_EN.l(j,t,n) *
        1/sum(jintren(jj), Q_EN.l(jj,t,n))*
        sum((inode2,jj)$(jintren(jj) and sameas(inode2,jj)), q_cali00(inode2,n));
* Calculate adjusted reference prices
feedback_price_multiplier(n) =
    total_feedback_value(tfirst,n)*
    1/sum((inode2,jj)$(jintren(jj) and sameas(inode2,jj)), feedback_price(jj,t,n)*VARQ0.l(inode2,n));
    VARP0.fx(inode,n) =
        feedback_price(j,t,n)*
        feedback_price_multiplier(n);
);
loop((inode,j)$(jintren(j) and sameas(inode,j)),
    VARP0.fx(inode,n) = p0_feedback_2015(j,n);
    VARQ0.fx(inode,n) = q0_feedback_2015(j,n);
);

$ifthen.dr not set nosolve
solve witch_static_cali using cns;
abort$((witch_static_cali.solvestat ne 1) or ((witch_static_cali.modelstat ne %modelStat.solvedUnique%) and (witch_static_cali.modelstat ne %modelStat.solved%))) 'Model not optimal';
$endif.dr


alpha(inode,n) = VARALPHA.l(inode,n);
q0(inode,n) = VARQ0.l(inode,n);
q0('kl',n) = 1;
p0(inode,n) = VARP0.l(inode,n);

* Update already initializated variables and parameters dependent on new q0
K.fx(g,tfirst,n) = q0('k',n);

* Update errors
if(ord(siter)>1,
    allerr(run,siter,'p0') = 1e2*smax((inode,n)$(old_p0(inode,n)), abs(VARP0.l(inode,n)/old_p0(inode,n)-1));
    allerr(run,siter,'q0') = 1e2*smax((inode,n)$(old_q0(inode,n)), abs(VARQ0.l(inode,n)/old_q0(inode,n)-1));
    allerr(run,siter,'alpha') = 10*smax((inode,n)$(old_alpha(inode,n)), abs(VARALPHA.l(inode,n)/old_alpha(inode,n)-1));
);

old_p0(inode,n) = VARP0.l(inode,n);
old_q0(inode,n) = VARQ0.l(inode,n);
old_alpha(inode,n) = VARALPHA.l(inode,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='finalize'

execute_unload '%caliboutgdx%', alpha, q0, rho, p0, delta0, mcost_inv0,
    p_mkup0, oem0, mu0, csi0, k_en0, delta_en0, rd_delta, rd_crowd_out,
    k_en_valid_old, k_en_valid_tot;

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

inode

$endif
