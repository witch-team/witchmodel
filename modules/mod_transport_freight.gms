*-------------------------------------------------------------------------------
* Road Freight Transport
*-------------------------------------------------------------------------------
$ifthen %phase%=='sets'


set j                       / trad_stfr, hbd_stfr, plg_hbd_stfr, edv_stfr, frt /;
set jreal(j)                / trad_stfr, hbd_stfr, plg_hbd_stfr, edv_stfr /;
set jfed(jreal)             / trad_stfr, hbd_stfr, plg_hbd_stfr /;
set jinv(jreal)             / trad_stfr, hbd_stfr, plg_hbd_stfr, edv_stfr /;
set jfixed_mcost_inv(jreal) / trad_stfr /;

set jfrt(jreal) 'Road Freight Vehicle technologies'
                            / trad_stfr, hbd_stfr, plg_hbd_stfr, edv_stfr /;
set jfedfrt(jfed) 'Road Freight Vehicle technologies with fuel feeding'
                            / trad_stfr, hbd_stfr, plg_hbd_stfr /;
set jfrt_invfix(jfrt)       / trad_stfr /;
set jfrt_inv(jinv)          / trad_stfr, hbd_stfr, plg_hbd_stfr, edv_stfr /;

set map_j(j,jj) 'Relationships between Energy Technology Sectors' /
    en.frt
    frt.(trad_stfr, hbd_stfr, plg_hbd_stfr)
/;

set jmcost_inv(jreal)       / trad_stfr, hbd_stfr, plg_hbd_stfr, edv_stfr /;

set transp_freight_qact(fuel,jfed) 'mapping of activities for transport sectors' /

    oil.trad_stfr
    oil.hbd_stfr
    oil.plg_hbd_stfr

    trbiofuel.trad_stfr
    trbiofuel.hbd_stfr
    trbiofuel.plg_hbd_stfr

    advbiofuel.trad_stfr
    advbiofuel.hbd_stfr
    advbiofuel.plg_hbd_stfr

/;

set el_out /
edvfr
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_mod_transport_freight'

parameter stfr_total(t,n) 'Total number of freight vehicles [million]';
parameter km_demand_stfr(t,n) 'Freight vehicle kilometre demand [million km]';
parameter service_demand_stfr(t,n) 'Total demand for freight travel [million tkm]';
parameter km_demand_pv_stfr(t,n) 'Freight kilometre demand per vehicle [km/vehicle]';
parameter load_factor_stfr(t,n)  'Freight vehicle load factor - N. of tons per vehicle [tons/vehicle]';
parameter fuel_cons_stfr(jfrt,t,n) 'Yearly fuel consumption per freight vehicle [TWh/million vehicles], i.e. [MWh/vehicle]';
parameter elec_plg_stfr(t,n) 'Yearly electricity consumption per plg_hybrid freight vehicle [TWh/million vehicles], i.e. [MWh/vehicle]';

parameter disutility_costs_stfr(*,t,n) 'Additional costs to investment cost of freight [US$2005/vehicle]';
$loaddc disutility_costs_stfr

parameter stfr_total_2005(n) 'Total number of freight vehicles in 2005 [million]';
$loaddc stfr_total_2005

parameter stfr_factor(*) 'Multiplicative factor of road freight ownership growth [-]' /
ssp1  0.8
ssp2  1
ssp3  1.2
ssp4  1.2
ssp5  1
/;

parameter km_demand_pv_stfr_2005(n) 'Freight kilometre demand per vehicle in 2005 [km/vehicle]';
$loaddc km_demand_pv_stfr_2005

parameter load_factor_stfr_2005(n)  'Freight vehicle load factor - N. of tons per vehicle in 2005 [tons/vehicle]';
$loaddc load_factor_stfr_2005

parameter inv_cost_frt(jfrt) 'Cost of purchase for traditional freight vehicles [US$2005/vehicle]';
$loaddc inv_cost_frt

parameter oem_frt(n) 'Freight vehicle O&M costs [$/million vehicles]';
$loaddc oem_frt

parameter fuel_cons_stfr_2005(jfrt,n) '2005 fuel consumption per freight vehicle [TWh/million vehicles)], i.e. [MWh/vehicle]';
$loaddc fuel_cons_stfr_2005

parameter fueleff_rate_stfr(t,n) 'Fuel efficiency improvement rate for freight vehicles';
fueleff_rate_stfr(t,n) = -0.22;
* Strong Fuel Efficiency Improvement (FEI) requires value of -0.22. See Bosetti and Longden (2012) for details.

parameter elec_plghbd_stfr_2005(n)  '2005 electricity consumption per plg_hybrid freight vehicle [TWh/million vehicles], i.e. [MWh/vehicle]';
$loaddc elec_plghbd_stfr_2005

parameter size_battery_freight(jfrt,n) 'Battery size of freight vehicles [kWh/vehicle]';
$loaddc size_battery_freight
size_battery_freight('edv_stfr',n) = 310 ;
size_battery_freight('plg_hbd_stfr',n) = 110 ;

parameter  growth_func_stfr(jfrt) /
trad_stfr        0
hbd_stfr         1
plg_hbd_stfr     1
edv_stfr         1
/;

$gdxin

scalar smooth_strfr / 1.124 /; # numerical factor (1.124) has been derived by fitting the hybrid vehicle projections reported in IEA (2010).

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

stfr_total(tfirst,n) = stfr_total_2005(n);

loop((t,tm1)$(tnofirst(t) and pre(tm1,t)),
  stfr_total(t,n) = stfr_total(tm1,n)*(1+stfr_factor('%tra_baseline%')*((gdppc(t,n)/gdppc(tm1,n))-1));
);

km_demand_pv_stfr(t,n) = km_demand_pv_stfr_2005(n);
load_factor_stfr(t,n) = load_factor_stfr_2005(n);
km_demand_stfr(t,n) = stfr_total(t,n) * km_demand_pv_stfr(t,n);
service_demand_stfr(t,n) = km_demand_stfr(t,n) * load_factor_stfr(t,n);

fuel_cons_stfr(jfrt,tfirst,n) = fuel_cons_stfr_2005(jfrt,n);
fuel_cons_stfr(jfrt,t,n)$(year(t) ge 2010) = fuel_cons_stfr_2005(jfrt,n)*(max((((year(t)-2000)/5)-1),1.4)**fueleff_rate_stfr(t,n));
elec_plg_stfr(t,n) = elec_plghbd_stfr_2005(n)*(((year(t)-2000)/5)**fueleff_rate_stfr(t,n));

oem(jfrt,t,n) = oem_frt(n)/1e12;

lifetime(jfrt,n) = 22; # lifetime of 22 years
delta_en(jfrt,t,n) = depreciation_rate(jfrt);

csi('oil',jfedfrt,t,n) = 1;
csi('trbiofuel',jfedfrt,t,n) = 1;
csi('advbiofuel',jfedfrt,t,n) = 1;

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

K_EN.lo(jfrt,t,n) = 1e-5;
K_EN.up(jfrt,t,n) = stfr_total(t,n);
K_EN.fx('trad_stfr',tfirst,n) = stfr_total(tfirst,n);
K_EN.fx(jfrt,t,n)$((not sameas (jfrt,'trad_stfr')) and (year(t) le 2010)) = 1e-4;

* Disable neltrbiofuel when transport is activated
Q_IN.fx('trbiofuel','neltrbiofuel',t,n) = 1e-12;

MCOST_INV.fx(jfrt_invfix,t,n) = inv_cost_frt(jfrt_invfix)/(reg_discount_veh(n)*1e6);
MCOST_INV.lo(jfrt,t,n)$(not sameas (jfrt,'trad_stfr')) = 1e-5;
MCOST_INV.up(jfrt,t,n)$(not sameas (jfrt,'trad_stfr')) = (inv_cost_frt('trad_stfr')+5*size_battery_freight(jfrt,n)*battery_cost(tfirst)+disutility_costs_stfr(jfrt,t,n))/1e6;
MCOST_INV.l(jfrt,t,n)$(not sameas (jfrt,'trad_stfr')) = (inv_cost_frt('trad_stfr')+size_battery_freight(jfrt,n)*battery_cost(tfirst))/1e6;

MCOST_INV.fx('hbd_stfr',t,n)$(year(t) lt rd_time('battery','start')) = (inv_cost_frt('trad_stfr')+(size_battery_freight('hbd_stfr',n)*battery_cost(t)*1.7)+disutility_costs_stfr('hbd_stfr',t,n))/(reg_discount_veh(n)*1e6);
MCOST_INV.fx('plg_hbd_stfr',t,n)$(year(t) lt rd_time('battery','start')) = (inv_cost_frt('trad_stfr')+(size_battery_freight('plg_hbd_stfr',n)*battery_cost(t)*1.7)+disutility_costs_stfr('plg_hbd_stfr',t,n))/1e6;
MCOST_INV.fx('edv_stfr',t,n)$(year(t) lt rd_time('battery','start')) = (inv_cost_frt('trad_stfr')*0.8+size_battery_freight('edv_stfr',n)*battery_cost(t)*1.7+disutility_costs_stfr('edv_stfr',t,n))/1e6;

*-------------------------------------------------------------------------------
$elseif %phase%=='policy'

Q_IN.fx('trbiofuel','trad_stfr',tfirst,n) = 1e-4;
Q_IN.fx('advbiofuel','trad_stfr',tfirst,n) = 1e-4;

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eqnb_frtveh_%clt%
eqq_en_frtveh_%clt%
eqq_el_frtedv_%clt%
eqmcost_inv_hbd_stfr_%clt%
eqmcost_inv_plghbd_stfr_%clt%
eqmcost_inv_edv_stfr_%clt%

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

*-  Number of freight vehicles
eqnb_frtveh_%clt%(t,n)$(mapn_th('%clt%') and tnofirst(t))..
                sum(jfrt,K_EN(jfrt,t,n)) =e= stfr_total(t,n);

*-  Yearly fuel consumption of freight vehicles
eqq_en_frtveh_%clt%(jfrt,t,n)$(mapn_th('%clt%'))..
                Q_EN(jfrt,t,n) =e= fuel_cons_stfr(jfrt,t,n) * K_EN(jfrt,t,n);

*-  Electricity consumed by grid-connected electric freight vehicles (plg_hbd_stfr and edv_stfr)
eqq_el_frtedv_%clt%(t,n)$(mapn_th('%clt%'))..
                fuel_cons_stfr('edv_stfr',t,n) * K_EN('edv_stfr',t,n) + elec_plg_stfr(t,n) * K_EN('plg_hbd_stfr',t,n) =e= sum(ices_el,QEL_OUT('edvfr',ices_el,t,n));

*-  Investment cost for hbd_stfr vehicle
eqmcost_inv_hbd_stfr_%clt%(t,n)$(mapn_th('%clt%') and (year(t) ge rd_time('battery','start')))..
                MCOST_INV('hbd_stfr',t,n) =e= (inv_cost_frt('trad_stfr') + (size_battery_freight('hbd_stfr',n) * MCOST_INV('battery',t,n) * 1.2) + disutility_costs_stfr('hbd_stfr',t,n)) / (reg_discount_veh(n) * 1e6);

*-  Investment cost for plug-in hbd_stfr vehicle
eqmcost_inv_plghbd_stfr_%clt%(t,n)$(mapn_th('%clt%') and (year(t) ge rd_time('battery','start')))..
                MCOST_INV('plg_hbd_stfr',t,n) =e= (inv_cost_frt('trad_stfr') + (size_battery_freight('plg_hbd_stfr',n) * MCOST_INV('battery',t,n) * 2.23 ) + disutility_costs_stfr('plg_hbd_stfr',t,n)) * 1e-6;

*-  Investment cost for electric drive vehicle
eqmcost_inv_edv_stfr_%clt%(t,n)$(mapn_th('%clt%') and (year(t) ge rd_time('battery','start')))..
                MCOST_INV('edv_stfr',t,n) =e= (inv_cost_frt('trad_stfr') *0.95 + size_battery_freight('edv_stfr',n) * MCOST_INV('battery',t,n) * 1.7 + disutility_costs_stfr('edv_stfr',t,n)) * 1e-6;

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Sets
jfrt
jfrt_inv

* Parameters
disutility_costs_stfr
elec_plg_stfr
elec_plghbd_stfr_2005
fuel_cons_stfr
fuel_cons_stfr_2005
fueleff_rate_stfr
growth_func_stfr
inv_cost_frt
km_demand_pv_stfr
km_demand_stfr
load_factor_stfr
oem_frt
service_demand_stfr
size_battery_freight
stfr_total

$endif




