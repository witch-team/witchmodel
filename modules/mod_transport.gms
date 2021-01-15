*-------------------------------------------------------------------------------
* Light-duty Vehicles for Personal Transport
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Define the transport baseline
$setglobal tra_baseline %baseline%

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

set j            / trad_cars, hybrid, plg_hybrid, edv, battery, pt /;
set jreal(j)     / trad_cars, hybrid, plg_hybrid, edv, battery /;
set jfed(jreal)  / trad_cars, hybrid, plg_hybrid /;
set jinv(jreal)  / trad_cars, hybrid, plg_hybrid, edv /;
set rd(j)        / battery /;
set jrd(jreal)   / battery /;

set jveh(jreal)    'Light Duty Vehicle technologies'
                 / trad_cars, hybrid, plg_hybrid, edv /;
set jfedveh(jfed)  'Light Duty Vehicle technologies with fuel feeding'
                 / trad_cars, hybrid, plg_hybrid /;
set jveh_invfix(jveh) / trad_cars /;
set jveh_inv(jinv)    / trad_cars, hybrid, plg_hybrid, edv /;

set oge_ai_set   / c1*c5 /;
set krd_lo_set   / a, b, c /;

set map_j(j,jj) 'Relationships between Energy Technology Sectors' /
    en.pt
    pt.(trad_cars, hybrid, plg_hybrid)
/;

set jmcost_inv(jreal) / trad_cars, hybrid, plg_hybrid, edv, battery /;

set transp_qact(fuel,jfed) 'mapping of activities for transport sectors' /
    oil.trad_cars
    oil.hybrid
    oil.plg_hybrid

    trbiofuel.trad_cars
    trbiofuel.hybrid
    trbiofuel.plg_hybrid

    advbiofuel.trad_cars
    advbiofuel.hybrid
    advbiofuel.plg_hybrid
/;

jrd_lbd('battery') = yes;

set jveh_rd(j);
jveh_rd(j)=yes$(cast(jveh(jreal),jreal,j) and rd(j));

set jveh_fed(jreal);
jveh_fed(jveh)=yes$(jfed(jveh));

set el_out /
edv
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_mod_transport.gdx'

* 1) Vehicles, demand, consumption

parameter gdppc(t,n) 'GDP per capita [US$2005/person]';
parameter ldv_pthc(t,n) 'Specific number of light duty vehicles [vehicles/thousand capita]';
parameter ldv_total(t,n) 'Total number of light duty vehicles [million]';
parameter km_demand_ldv(t,n) 'LDV kilometre demand [million km]';
parameter service_demand_ldv(t,n) 'Total demand for LDV passenger travel [million pkm]';
parameter km_demand_pv_ldv(t,n) 'LDV kilometre demand per vehicle [km/vehicle]';
parameter km_demand_pv_deviation_ldv(t,n) 'Relative LDV kilometre demand wrt 2005';
parameter fuel_cons(jveh,t,n) 'Yearly fuel consumption per vehicle [TWh/million vehicles], i.e. [MWh/vehicle]';
parameter elec_plg(t,n) 'Yearly electricity consumption per plg_hybrid vehicle [TWh/million vehicles], i.e. [MWh/vehicle]';#source: https://theicct.org/publications/charging-cost-US

* Source: https://theicct.org/publications/charging-cost-US
parameter charging_station 'cost of charging stations estimation per vehicle' /580/ ;

parameter disutility_costs_ldv(jveh,t,n) 'Additional costs to investment cost of cars [US$2005/vehicle]';
$loaddc disutility_costs_ldv

parameter max_biofuel_feed_share(t) 'Maximum allowable share of biofuels in engines [-]';
$loaddc max_biofuel_feed_share

parameter ai(oge_ai_set) 'Autonomous Increase';
$loaddc ai

parameter oge(oge_ai_set) 'Ownership Growth Elasticity';
load_from_ssp(oge,'oge_ai_set',%tra_baseline%,mod_transport)

parameter coeff_ldv(t,n) 'Multiplicative parameter to adjust the number of vehicles';
$loaddc coeff_ldv

parameter fueleff_rate(t,n) 'Fuel efficiency improvement rate';
fueleff_rate(t,n) = -0.25;

$ifthen.fr %tra_baseline% == 'ssp1'

fueleff_rate(t,n)$(year(t) ge 2015) = 3/2 * fueleff_rate(t,n);

$elseif.fr %tra_baseline% == 'ssp3'

fueleff_rate(t,n)$(year(t) ge 2015) = 4/5 * fueleff_rate(t,n);

$elseif.fr %tra_baseline% == 'ssp4'

fueleff_rate(t,oecd)$(year(t) ge 2015) = 3/2 * fueleff_rate(t,oecd);
fueleff_rate(t,non_oecd)$(year(t) ge 2015) = 4/5 * fueleff_rate(t,non_oecd);

$elseif.fr %tra_baseline% == 'ssp5'

fueleff_rate(t,n)$(year(t) ge 2015) = 4/5 * fueleff_rate(t,n);

$endif.fr

parameter reg_discount_veh(n) 'Regional discount for vehicle investment cost';
$loaddc reg_discount_veh

parameter ldv_pthc_2005(n) 'Specific number of light duty vehicles in 2005 [vehicles/thousand capita]';
$loaddc ldv_pthc_2005
parameter k_veh_passengercars(n,t) 'Number of passenger cars [thousand]';
$loaddc k_veh_passengercars
parameter k_veh_commercial(n,t) 'Number of commercial vehicles [thousand]';
$loaddc k_veh_commercial

parameter k_veh_2005_2015(jveh,t,n) 'Number of LDVs per category (other than trad_cars) in 2005, 2010 and 2015 [million]';
$loaddc k_veh_2005_2015

parameter inv_cost_veh(jveh) 'Cost of purchase for traditional cars [US$2005/vehicle]';
$loaddc inv_cost_veh

parameter oem_veh(jveh,n) 'Vehicle O&M costs [$/million vehicles]';
$loaddc oem_veh

parameter fuel_cons_2005(jveh,n) 'Initial yearly fuel consumption per vehicle [TWh/million vehicles], i.e. [MWh/vehicle]';
$loaddc fuel_cons_2005

parameter elec_plg_2005(n) 'Yearly electricity consumption per plg_hybrid vehicle in 2005 [TWh/million vehicles], i.e. [MWh/vehicle]';
$loaddc elec_plg_2005

parameter trad_biofuel_lim(t,n) 'Limitation on traditional biofuels [TWh]';
$loaddc trad_biofuel_lim

parameter biofuel_2005_2010(t,n) 'Biofuel consumption in traditional cars in 2005 and 2010 [TWh]';
$loaddc biofuel_2005_2010

parameter biofuel_2013(n) 'Biofuel consumption in traditional cars in 2013 [TWh]';
$loaddc biofuel_2013

parameter travel_intensity_2005(n)  'Travel intensity in 2005 [km/US$2005]';
$loaddc travel_intensity_2005

parameter travel_intensity(t,n) 'Travel intensity [km/US$2005]';
travel_intensity(t,n) = travel_intensity_2005(n);
* An evolution of the travel intensity might be envisioned, but for the moment it is kept constant over the century.

$ifthen.ti_bl %tra_baseline% == 'ssp1'

travel_intensity(t,n)$(year(t) ge 2015) = travel_intensity(t,n) * (1-((((year(t)-2000)/5)-2)*0.01));

$elseif.ti_bl %tra_baseline% == 'ssp3'

travel_intensity(t,n)$(year(t) ge 2015) = travel_intensity(t,n) * (1+((((year(t)-2000)/5)-2)*0.01));

$elseif.ti_bl %tra_baseline% == 'ssp4'

travel_intensity(t,n)$(year(t) ge 2015) = travel_intensity(t,n) * (1+((((year(t)-2000)/5)-2)*0.01));

$endif.ti_bl

parameter load_factor_ldv(t,n)  'LDV load factor - N. of persons per vehicle [persons/vehicle]';
$loaddc load_factor_ldv

* 2) Batteries, R&D

parameter battery_leadrd(n) 'Countries leading in battery R&D';
$loaddc battery_leadrd

leadrd('battery',n) = yes$(battery_leadrd(n));
rd_coef('battery','a')    = 1;
rd_coef('battery','b')    = 0.85;
rd_coef('battery','c')    = 0;
rd_coef('battery','d')    = 0.15;
rd_coef('battery','lbr')  = -0.193;
rd_coef('battery','lbd')  = -0.160;
rd_coef('battery','wcum0') = sum(n, k_veh_2005_2015('hybrid',tfirst,n));
rd_cooperation('battery',clt) = no;
rd_delta('battery') = 0.05;
rd_time('battery','gap') = 10; # years
rd_time('battery','start') = 2020;

$ifthen.lbr %tra_baseline% == 'ssp1'

rd_coef('battery','lbr') = 5/4 * rd_coef('battery','lbr');

$elseif.lbr %tra_baseline% == 'ssp3'

rd_coef('battery','lbr') = 2/3 * rd_coef('battery','lbr');

$elseif.lbr %tra_baseline% == 'ssp4'

rd_coef('battery','lbr') = 5/4 * rd_coef('battery','lbr');

$elseif.lbr %tra_baseline% == 'ssp5'

rd_coef('battery','lbr') = 2/3 * rd_coef('battery','lbr');

$endif.lbr

parameter krd_lo_coeff(krd_lo_set);
$loaddc krd_lo_coeff

parameter size_battery(jveh,n) 'Battery size [kWh/vehicle]';
$loaddc size_battery

parameter battery_cost(t) 'Historical (2005-2015) and then upper bound battery cost [US$2005/kWh]';
$loaddc battery_cost

parameter bat_multip(jveh,n) ;
bat_multip('hybrid',n) = 2.23 ;
bat_multip('plg_hybrid',n) = 1.2 ;

parameter tank_cost(jveh) ;
tank_cost('trad_cars') = 471 ;
tank_cost('hybrid') = 471 ;
tank_cost('plg_hybrid') = 471 ;

parameter size_elmotor(jveh) ;
size_elmotor('edv') = 75 ;
size_elmotor('hybrid') = 20 ;
size_elmotor('plg_hybrid') = 47 ;


parameter size_ice(jveh);
size_ice('trad_cars') = 75 ;
size_ice('hybrid') = 58 ;
size_ice('plg_hybrid') = 58 ;
parameter charger_cost /576/ ;
parameter glider_manufacture_cost /17410/ ; # $
parameter ice_cost /38/ ; # $/kw
* 3) Flags

parameter  growth_func_ldv(jveh) /
trad_cars       0
hybrid          1
plg_hybrid      1
edv             1
/;

parameter  inv_constraint_ldv(jveh_inv) /
trad_cars       0
hybrid          1
plg_hybrid      1
edv             1
/;

$gdxin

scalar smooth_ldv / 1.25 /;

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

krd0('battery',n) = sum(nn,krd0('en',nn))*0.0141*0.076923077;

* 1) Calculation of the number of vehicles

gdppc(t,n) = (ykali(t,n)*1e6)/l(t,n);

ldv_pthc(t,n) = ldv_pthc_2005(n);
* Now replaced by passenger car data per country and population (in vehicles per 1000 capita)
ldv_pthc(t,n)$(year(t) le 2015) = k_veh_passengercars(n,t) / l(t,n);

loop((tm1,t,n)$(pre(tm1,t) and year(t) gt 2015),
    if(gdppc(t,n) le 5000,
        ldv_pthc(t,n) = ldv_pthc(tm1,n)*(1+(gdppc(t,n)/gdppc(tm1,n)-1)*oge('c1'))+ai('c1');
    else
        ldv_pthc(t,n)$(ldv_pthc(tm1,n) le 300) = ldv_pthc(tm1,n)*(1+(gdppc(t,n)/gdppc(tm1,n)-1)*oge('c2'))+ai('c2');
        ldv_pthc(t,n)$(ldv_pthc(tm1,n) gt 300 and ldv_pthc(tm1,n) le 500) = ldv_pthc(tm1,n)*(1+(gdppc(t,n)/gdppc(tm1,n)-1)*oge('c3'))+ai('c3');
        ldv_pthc(t,n)$(ldv_pthc(tm1,n) gt 500 and ldv_pthc(tm1,n) le 600) = ldv_pthc(tm1,n)*(1+(gdppc(t,n)/gdppc(tm1,n)-1)*oge('c4'))+ai('c4');
        ldv_pthc(t,n)$(ldv_pthc(tm1,n) gt 600) = ldv_pthc(tm1,n)*(1+(gdppc(t,n)/gdppc(tm1,n)-1)*oge('c5'))+ai('c5');
    );
);

ldv_pthc(t,n) = ldv_pthc(t,n) * coeff_ldv(t,n);

ldv_total(t,n) = ldv_pthc(t,n)*l(t,n)/1e3;

* 2) Calculation of demand and consumption

km_demand_ldv(t,n) = (travel_intensity(t,n)*(ykali(t,n)*1e12))/1e6;
service_demand_ldv(t,n) = load_factor_ldv(t,n) * km_demand_ldv(t,n);
km_demand_pv_ldv(t,n) = km_demand_ldv(t,n)/ldv_total(t,n);
km_demand_pv_deviation_ldv(t,n) = km_demand_pv_ldv(t,n)/km_demand_pv_ldv(tfirst,n);

fuel_cons(jveh,tfirst,n) = fuel_cons_2005(jveh,n);
fuel_cons(jveh,t,n)$(year(t) ge 2010) = fuel_cons_2005(jveh,n) * km_demand_pv_deviation_ldv(t,n) * (max((tperiod(t)-1),1.4)**fueleff_rate(t,n));
elec_plg(t,n) = elec_plg_2005(n) * km_demand_pv_deviation_ldv(t,n) * (tperiod(t)**fueleff_rate(t,n));
* The expression max((tperiod(t)-1),1.4) is needed to recalibrate the 2010 data.


* 3) Other parameters

oem(jveh,t,n) = oem_veh(jveh,n)/1e12;

lifetime(jveh,n) = 22; # lifetime of 22 years
delta_en(jveh,t,n) = depreciation_rate(jveh);

csi('oil',jfedveh,t,n) = 1;
csi('trbiofuel',jfedveh,t,n) = 1;
csi('advbiofuel',jfedveh,t,n) = 1;

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

variable ELMOTOR_COST(t) '$/kw' ;
ELMOTOR_COST.fx(t) $(year(t) le 2010) = 243 ;
ELMOTOR_COST.fx(t) $(year(t) ge 2010 and year(t) le 2030) = 40 ;
ELMOTOR_COST.fx(t) $(year(t) ge 2030 and year(t) le 2050) = 31 ;
ELMOTOR_COST.fx(t) $(year(t) ge 2050) = 23 ;

* 1) Vehicles

K_EN.lo(jveh,t,n) = 1e-6;
K_EN.up(jveh,t,n) = ldv_total(t,n);
K_EN.fx(jveh,t,n)$((year(t) le 2015) and (not sameas (jveh,'trad_cars'))) = k_veh_2005_2015(jveh,t,n);
K_EN.lo(jveh,t,n)$((year(t) gt 2015) and (not sameas (jveh,'trad_cars'))) = k_veh_2005_2015(jveh,'3',n);
I_EN.lo(jveh_inv,t,n)$((year(t) le 2015) and (not sameas (jveh_inv,'trad_cars'))) = 1e-9;

MCOST_INV.fx(jveh_invfix,t,n) = inv_cost_veh(jveh_invfix)/(reg_discount_veh(n)*1e6);
MCOST_INV.lo(jveh,t,n)$(not sameas(jveh,'trad_cars')) = 1e-5;
MCOST_INV.up(jveh,t,n)$(not sameas(jveh,'trad_cars')) = (inv_cost_veh('trad_cars') + 
                                                         5 * size_battery(jveh,n) * battery_cost(tfirst) +
                                                         disutility_costs_ldv(jveh,t,n)) * 1e-6;

Q_IN.fx('trbiofuel','trad_cars',t,n)$(year(t) le 2010) = biofuel_2005_2010(t,n);
Q_IN.lo('trbiofuel','trad_cars',t,n)$(year(t) gt 2010) = biofuel_2013(n);

* Disable neltrbiofuel when transport is activated
Q_IN.fx('trbiofuel','neltrbiofuel',t,n) = 1e-12;

* 2) Batteries, R&D

K_RD.fx('battery',t,n)$(tfirst(t) and (not tfix(t))) = krd0('battery',n);
K_RD.lo('battery',t,n)$((not tfix(t)) and (year(t) ge 2010)) = krd0('battery',n)*(krd_lo_coeff('a')*exp(krd_lo_coeff('b')*exp(krd_lo_coeff('c')*((year(t)-2000)/5))));
K_EN.fx('battery',t,n) = 0;
Q_EN.fx('battery',t,n) = 0;

MCOST_INV.up('battery',t,n)$(not tfix(t)) = battery_cost(tfirst);
MCOST_INV.fx('battery',t,n)$((not tfix(t)) and (year(t) lt rd_time('battery','start'))) = battery_cost(t);
MCOST_INV.fx('hybrid',t,n)$((not tfix(t)) and (year(t) lt rd_time('battery','start'))) = (glider_manufacture_cost+(size_battery('hybrid',n)*battery_cost(t)*bat_multip('hybrid',n)
 + ELMOTOR_COST.l(t)*size_elmotor('hybrid') + ice_cost*size_ice('hybrid') + tank_cost('hybrid')))/(1e6);
MCOST_INV.fx('plg_hybrid',t,n)$((not tfix(t)) and (year(t) lt rd_time('battery','start'))) = (glider_manufacture_cost + (size_battery('plg_hybrid',n)*battery_cost(t)*bat_multip('plg_hybrid',n)
 + ELMOTOR_COST.l(t)*size_elmotor('plg_hybrid') + ice_cost*size_ice('plg_hybrid') + tank_cost('plg_hybrid') + charger_cost ))/1e6;
MCOST_INV.fx('edv',t,n)$((not tfix(t)) and (year(t) lt rd_time('battery','start'))) = (glider_manufacture_cost + size_battery('edv',n)*battery_cost(t)
 + ELMOTOR_COST.l(t)*size_elmotor('edv') + charger_cost+ charging_station)/1e6;

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eqnb_veh_%clt%
eqq_en_veh_%clt%
eqq_el_edv_%clt%
eqmcost_inv_hybrid_%clt%
eqmcost_inv_plghybrid_%clt%
eqmcost_inv_edv_%clt%

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

*- Number of light duty vehicles
eqnb_veh_%clt%(t,n)$(mapn_th('%clt%'))..
    sum(jveh,K_EN(jveh,t,n)) =e= ldv_total(t,n);

*- Yearly energy demand of vehicles
eqq_en_veh_%clt%(jveh,t,n)$(mapn_th('%clt%'))..
    Q_EN(jveh,t,n) =e= fuel_cons(jveh,t,n) * K_EN(jveh,t,n);

*-  Electricity consumed by grid-connected electric vehicles (plg_hybrid and edv)
eqq_el_edv_%clt%(t,n)$(mapn_th('%clt%'))..
    fuel_cons('edv',t,n) * K_EN('edv',t,n) + elec_plg(t,n) * K_EN('plg_hybrid',t,n) =e= sum(ices_el,QEL_OUT('edv',ices_el,t,n));

*- Investment cost for hybrid vehicles
eqmcost_inv_hybrid_%clt%(t,n)$(mapn_th('%clt%') and (year(t) ge rd_time('battery','start')))..
                MCOST_INV('hybrid',t,n) =e= (glider_manufacture_cost+(size_battery('hybrid',n)*MCOST_INV('battery',t,n)*bat_multip('hybrid',n) + ELMOTOR_COST(t)*size_elmotor('hybrid') + ice_cost*size_ice('hybrid') + tank_cost('hybrid')))/(1e6*reg_discount_veh(n));

*- Investment cost for plug-in hybrid vehicles
eqmcost_inv_plghybrid_%clt%(t,n)$(mapn_th('%clt%') and (year(t) ge rd_time('battery','start')))..
                MCOST_INV('plg_hybrid',t,n) =e= (glider_manufacture_cost + (size_battery('plg_hybrid',n)*MCOST_INV('battery',t,n)*bat_multip('plg_hybrid',n)  + ELMOTOR_COST(t)*size_elmotor('plg_hybrid') + ice_cost*size_ice('plg_hybrid') + tank_cost('plg_hybrid') + charger_cost))/(1e6*reg_discount_veh(n));

*- Investment cost for electric drive vehicles
eqmcost_inv_edv_%clt%(t,n)$(mapn_th('%clt%') and (year(t) ge rd_time('battery','start')))..
                MCOST_INV('edv',t,n) =e= (glider_manufacture_cost + size_battery('edv',n) * MCOST_INV('battery',t,n) + ELMOTOR_COST(t)*size_elmotor('edv') + charger_cost + charging_station)/(1e6*reg_discount_veh(n));

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

loop((t,tp1)$(pre(t,tp1)),
           wcum('battery',tp1) = sum(n,(div0(I_EN.l('hybrid',t,n),MCOST_INV.l('hybrid',t,n)) +
                                        div0(I_EN.l('plg_hybrid',t,n),MCOST_INV.l('plg_hybrid',t,n)) +
                                        div0(I_EN.l('edv',t,n),MCOST_INV.l('edv',t,n)) +
                                        div0(I_EN.l('hbd_stfr',t,n),MCOST_INV.l('hbd_stfr',t,n)) +
                                        div0(I_EN.l('plg_hbd_stfr',t,n),MCOST_INV.l('plg_hbd_stfr',t,n)) + 
                                        div0(I_EN.l('edv_stfr',t,n),MCOST_INV.l('edv_stfr',t,n))) * tlen(t)) + 
                                        wcum('battery',t)
);

$ifthen.cr set rd_myopic_iter

if(ord(siter) le 3,

K_EN.l('plg_hybrid',t,n)$(tnofirst(t) and (not tfix(t))) = 1e-5;
K_EN.l('edv',t,n)$(tnofirst(t) and (not tfix(t))) = 1e-5;
Q_EN.l('plg_hybrid',t,n)$(tnofirst(t) and (not tfix(t))) = 1e-5;
Q_EN.l('edv',t,n)$(tnofirst(t) and (not tfix(t))) = 1e-5;
QEL_OUT.l('edv',ices_el,t,n)$(not tfix(t)) = 1e-7;

);

$endif.cr


*-------------------------------------------------------------------------------
$elseif %phase%=='summary_report'

parameter transp_world_ldv_fleet(jveh,t);
parameter transp_ldv_ice_feeding(fuel,jfedveh,t,n);
parameter transp_world_ldv_ice_feeding(fuel,jfedveh,t);
parameter transp_ldv_biofuel_feed_share(jfedveh,t,n);
parameter co2_transport(t,n);

transp_world_ldv_fleet(jveh,t) = sum(n, K_EN.l(jveh,t,n));
transp_ldv_ice_feeding(fuel,jfedveh,t,n) = Q_IN.l(fuel,jfedveh,t,n);
transp_world_ldv_ice_feeding(fuel,jfedveh,t) = sum(n, Q_IN.l(fuel,jfedveh,t,n));
transp_ldv_biofuel_feed_share(jfedveh,t,n) = (Q_IN.l('trbiofuel',jfedveh,t,n)+Q_IN.l('advbiofuel',jfedveh,t,n))/(Q_IN.l('oil',jfedveh,t,n)+Q_IN.l('trbiofuel',jfedveh,t,n)+Q_IN.l('advbiofuel',jfedveh,t,n));

co2_transport(t,n) = sum((fuel,jfed)$(csi(fuel,jfed,t,n) and (jveh(jfed) or jfrt(jfed))),Q_IN.l(fuel,jfed,t,n)*emi_st(fuel)*emi_sys('co2ffi',t,n));

$elseif %phase%=='gdx_items'

* Sets
jveh
jveh_inv
jveh_invfix

* Parameters
ai
battery_cost
biofuel_2005_2010
biofuel_2013
coeff_ldv
disutility_costs_ldv
elec_plg
elec_plg_2005
fuel_cons
fuel_cons_2005
fueleff_rate
gdppc
growth_func_ldv
inv_constraint_ldv
inv_cost_veh
k_veh_2005_2015
km_demand_ldv
km_demand_pv_deviation_ldv
km_demand_pv_ldv
krd_lo_coeff
ldv_pthc
ldv_total
load_factor_ldv
max_biofuel_feed_share
oem_veh
oge
reg_discount_veh
service_demand_ldv
size_battery
trad_biofuel_lim
transp_ldv_biofuel_feed_share
transp_ldv_ice_feeding
transp_world_ldv_fleet
transp_world_ldv_ice_feeding
travel_intensity
travel_intensity_2005
co2_transport
size_ice
size_elmotor
ice_cost
tank_cost
charger_cost
glider_manufacture_cost

ELMOTOR_COST

$endif
