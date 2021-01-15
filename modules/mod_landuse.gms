*-------------------------------------------------------------------------------
* Landuse [simplified version of the land-use model]
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Define the land-use baseline data source
$setglobal lubaseline ssp2
$if %baseline%=='ssp1' $setglobal lubaseline ssp1
$if %baseline%=='ssp3' $setglobal lubaseline ssp3
$if %baseline%=='ssp4' $setglobal lubaseline ssp1
$if %baseline%=='ssp5' $setglobal lubaseline ssp3

$elseif %phase%=='sets'

set fuel / wbio /;
set f(fuel) / wbio /;

set e 'Emissions-related entities' /
    co2lu        # Land use CO2
    ch4_agr      # CH4 from Agriculture
    n2o_agr      # N2O from Agriculture
    redd         # Avoided deforestation emissions
/;

set map_e(e,ee) 'Relationships between Sectoral Emissions' /
    co2.co2lu
    ch4.ch4_agr
    n2o.n2o_agr
/;

set cce(e) 'Emissions-related entities that cost' /
redd
/;

set sys /ch4_agr, n2o_agr, co2lu/;

* Time periods where land-use emissions are priced at same level than energy sector
set t_lu(t);
t_lu(t) = yes;

* Set ot override the default pricing of landuse by no pricing.
set nocluprice(t,n);
nocluprice(t,n) = no;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_landuse'
scalar wbio2_price 'Coefficient of the quadratic function of woody biomass';
parameter wbio2_max(n) 'Maximum woody biomass [TWh]';
$loaddc wbio2_price wbio2_max
parameter ch4_agr_baseline(t,n) 'CH4 Agriculture emission baseline [GtCe]';
parameter n2o_agr_baseline(t,n) 'N2O Agriculture emission baseline [GtCe]';
parameter co2lu_baseline(t,n) 'CO2 Land-use emission baseline [GtCe]';
$loaddc ch4_agr_baseline n2o_agr_baseline co2lu_baseline 
$gdxin

$gdxin '%datapath%data_validation'
parameter q_emi_valid_lu(*,t,n)  'Historical land-use emissions [GtCe]';
parameter q_emi_valid_lu_primap(*,t,n) 'Historical land-use emissions --- PRIMAP [GtCe]';
parameter q_fuel_valid_weo(*,t,n) 'Historical fuel consumption --- WEO [GtCe]';
$loaddc q_emi_valid_lu=q_emi_valid_fao q_emi_valid_lu_primap=q_emi_valid_primap q_fuel_valid_weo
$gdxin

q_emi_valid_lu('n2o_agr',t,n) = q_emi_valid_lu_primap('n2o_agr',t,n);
q_emi_valid_lu('ch4_agr',t,n) = q_emi_valid_lu_primap('ch4_agr',t,n);

parameter cluprice(t,n) 'Price of CO2 landuse [T$/GtCeq]';
cluprice(t,n) = 0;

parameter cluprice_iter(siter,t,n);
cluprice_iter(siter,t,n) = 0;

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

* BIOMASS are fixed for the calibration years
Q_FUEL.fx('wbio',t,n)$(year(t) le 2015) = q_fuel_valid_weo('wbio',t,n);

* lower bound to avoid infinite mcost
Q_FUEL.lo('wbio',t,n) = 1e-8;

* Land-use Emissions
Q_EMI.lo('co2lu',t,n) = -20;
Q_EMI.up('co2lu',t,n) = 50;

COST_EMI.lo('redd',t,n) = 0;

* Simple land-use model in case of no soft-link with a land-use model
$ifthen.x not set landuse_model
Q_FUEL.up('wbio',t,n) = wbio2_max(n);
Q_EMI.fx('co2lu',t,n) = co2lu_baseline(t,n) * emi_sys('co2lu',t,n);
Q_EMI.fx('n2o_agr',t,n) = n2o_agr_baseline(t,n) * emi_sys('n2o_agr',t,n);
Q_EMI.fx('ch4_agr',t,n) = ch4_agr_baseline(t,n) * emi_sys('ch4_agr',t,n);
$endif.x

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eq_wbio_%clt%
$if not set landuse_model eqcost_pes_wbio_%clt%

$elseif %phase%=='eqs'

* Quantity of woody biomass. distributed as solid biomass for biomass plant, advanced biofuel and traditional biofuel.
eq_wbio_%clt%(t,n)$(mapn_th('%clt%'))..
    Q_FUEL('wbio',t,n) =e= sum(jfed$csi('wbio',jfed,t,n), Q_IN('wbio',jfed,t,n)) + Q_FUEL('advbiofuel',t,n) + Q_FUEL('trbiofuel',t,n);

$ifthen.x not set landuse_model
* Cost of all woody biomass produced for advanced biofuels and woody biomass
eqcost_pes_wbio_%clt%(t,n)$(mapn_th('%clt%'))..
    COST_FUEL('wbio',t,n) =e= Q_FUEL('wbio',t,n) * Q_FUEL('wbio',t,n) * wbio2_price;
$endif.x

*-------------------------------------------------------------------------------
$elseif %phase%=='policy'

$ifthen.spa setglobal spalu

* LP: Price all land use emissions at the level of carbon prices in the energy sector
$if %spalu%=='LP' t_lu(t) = yes;
* LN: No price (=0) for all land use emissions
$if %spalu%=='LN' t_lu(t) = no;
* LD: No price (=0) for all land use emissions before 2030, then price all landuse according to energy sector's carbon price
$if %spalu%=='LD' t_lu(t)$(year(t) < 2030) = no; 

$endif.spa

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

MCOST_FUEL.fx('wbio',t,n)$(not tfix(t)) = div0(COST_FUEL.l('wbio',t,n),Q_FUEL.l('wbio',t,n));

* Set the price of co2lu emissions according to the applied policy
loop(c_mkt,
cluprice(t_lu,n)$trading_t(c_mkt,t_lu,n) = CPRICE.l(c_mkt,t_lu);
);
cluprice(t_lu,n)$(ctax('co2',t_lu,n)) = ctax('co2',t_lu,n);
cluprice(t_lu,n)$(nocluprice(t_lu,n)) = 0; # force LU non pricing

*-------------------------------------------------------------------------------
$elseif %phase%=='dynamic_calibration'

* Calibration of Land-use emission
emi_sys('ch4_agr',t,n)$(year(t) le 2015) = q_emi_valid_lu('ch4_agr',t,n) / ch4_agr_baseline(t,n);
emi_sys('ch4_agr',t,n)$(year(t) gt 2015) = valuein(2015, emi_sys('ch4_agr',tt,n));

emi_sys('n2o_agr',t,n)$(year(t) le 2015) = q_emi_valid_lu('n2o_agr',t,n) / n2o_agr_baseline(t,n);
emi_sys('n2o_agr',t,n)$(year(t) gt 2015) = valuein(2015, emi_sys('n2o_agr',tt,n));

emi_sys('co2lu',t,n)$(year(t) le 2015) = q_emi_valid_lu('co2lu',t,n) / co2lu_baseline(t,n);
emi_sys('co2lu',t,n)$(year(t) gt 2015) = valuein(2015, emi_sys('co2lu',tt,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Sets
t_lu

* Parameters
cluprice
q_emi_valid_lu

$endif
