*-------------------------------------------------------------------------------
* Technology development scenarios
*-------------------------------------------------------------------------------

$ifthen %phase%=='sets'

acronym low, medium, high, high_oecd, high_non_oecd;

parameter tech_scen(*);

scalar tech_cost_var / 0.01 /;

table ccs_inv_var(jlccs,*) 'multiplier of investment cost for ccs'
          low      high
elcigcc   0.43     1.51
elbigcc   0.44     1.52
elgasccs  0.51     1.50
elpc_ccs  0.46     1.51
elpc_oxy  0.35     1.55
;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

* Default SSP is SSP2 (Middle of the road)
tech_scen('CCS') = medium;
tech_scen('nuclear') = medium;
tech_scen('renewables') = medium;

* SSPs variants

* SSP1 (Sustainability)
$ifthen.l %baseline% == 'ssp1'

tech_scen('CCS') = low;
tech_scen('nuclear') = low;
tech_scen('renewables') = high;

* SSP3 (Regional Rivalry)
$elseif.l %baseline% == 'ssp3'

tech_scen('nuclear') = high_oecd;
tech_scen('renewables') = low;

* SSP4 (Inequality)
$elseif.l %baseline% == 'ssp4'

tech_scen('CCS') = high_non_oecd;
tech_scen('nuclear') = high_non_oecd;
tech_scen('renewables') = high;

* SSP5 (Fossil Fuel Development)
$elseif.l %baseline% == 'ssp5'

tech_scen('CCS') = high;

$endif.l

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

if(tech_scen('renewables') = low,

rd_coef(jreal_wind,'lbd') = 2/3 * rd_coef(jreal_wind,'lbd');
rd_coef(jreal_solar,'lbd') = 2/3 * rd_coef(jreal_solar,'lbd');

floor_cost(jel_wind) = 3/2 * floor_cost(jel_wind);
floor_cost(jel_solar) = 3/2 * floor_cost(jel_solar);
flex_coeff(jel_wind) = 3/2 * flex_coeff(jel_wind);
flex_coeff(jel_solar) = 3/2 * flex_coeff(jel_solar);

);

if(tech_scen('renewables') = high,

rd_coef(jreal_wind,'lbd') = 3/2 * rd_coef(jreal_wind,'lbd');
rd_coef(jreal_solar,'lbd') = 3/2 * rd_coef(jreal_solar,'lbd');

floor_cost(jel_wind) = 1 * floor_cost(jel_wind);
floor_cost(jel_solar) = 1 * floor_cost(jel_solar);
flex_coeff(jel_wind) = 1/2 * flex_coeff(jel_wind);
flex_coeff(jel_solar) = 1/2 * flex_coeff(jel_solar);

);

if(tech_scen('nuclear') = low, 
cwaste_reg('rho',n) = 2.2;
);

if(tech_scen('nuclear') = high_oecd,
cwaste_reg('rho',oecd) = 1.6;
);

if(tech_scen('nuclear') = high_non_oecd,
cwaste_reg('rho',non_oecd) = 1.6;
);

if(tech_scen('CCS') = low,
mcost_inv0(jlccs,n) = mcost_inv0(jlccs,n) * ccs_inv_var(jlccs,'high');
ccs_stor_cost(ccs_stor,n) = ccs_stor_cost_estim(ccs_stor,'high');
);

if(tech_scen('CCS') = high,
mcost_inv0(jlccs,n) = mcost_inv0(jlccs,n)*ccs_inv_var(jlccs,'low');
ccs_stor_cost(ccs_stor,n)=ccs_stor_cost_estim(ccs_stor,'low');
);

if(tech_scen('CCS') = high_non_oecd,
mcost_inv0(jlccs,non_oecd) = mcost_inv0(jlccs,non_oecd)*ccs_inv_var(jlccs,'low');
ccs_stor_cost(ccs_stor,non_oecd)=ccs_stor_cost_estim(ccs_stor,'low');
);

$elseif %phase%=='before_nashloop'

if(tech_scen('nuclear')= low,
MCOST_INV.fx('elnuclear_new',t,n)$((not tfix(t)) and (year(t) ge 2015)) = mcost_inv0('elnuclear_new',n)*(1+tech_cost_var)**(tlen(t)*(tperiod(t)-2));
);

if(tech_scen('nuclear')= high_oecd,
MCOST_INV.fx('elnuclear_new',t,oecd)$((not tfix(t)) and (year(t) ge 2015)) = mcost_inv0('elnuclear_new',oecd)*(1-tech_cost_var)**(tlen(t)*(tperiod(t)-2));
);

if(tech_scen('nuclear')= high_non_oecd,
MCOST_INV.fx('elnuclear_new',t,non_oecd)$((not tfix(t)) and (year(t) ge 2015)) = mcost_inv0('elnuclear_new',non_oecd)*(1-tech_cost_var)**(tlen(t)*(tperiod(t)-2));
);

* Additional SSP specificities
* For SSP5, disable nelback
$if %baseline%=='ssp5' I_RD.fx('nelback',t,n)$(not tfix(t)) = I_RD.lo('nelback',t,n);

* For SSP5, disable Energy RnD
$if %baseline%=='ssp5' I_RD.fx('en',t,n)$(not tfix(t)) = EPS;

$elseif %phase%=='gdx_items'

* Parameters
tech_scen
tech_cost_var

$endif
