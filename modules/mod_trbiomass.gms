*-------------------------------------------------------------------------------
* Traditional Biomass
*  - driven by GDP (default) or exogenous ($setglobal mod_trbiomass_exo)
*  - require post_process to be launch before
*-------------------------------------------------------------------------------

$ifthen %phase%=='sets'

set fuel / trbiomass /;
set f(fuel) / trbiomass /;

set j /neltrbiomass/;
set jreal /neltrbiomass/;
set jnel(jreal) /neltrbiomass/;
set jfed(jreal) /neltrbiomass/;

set map_j(j,jj) / nelbio.neltrbiomass /;

$macro trbio_ratio(t) \
min(1,trbio_ctr('beta',n)*log(mer2ppp(&t,n)*1e6*Q.l('y',&t,n)/l(&t,n))+trbio_ctr('alpha',n))

set conf /
$if set mod_trbiomass_exo 'mod_trbiomass_exo'.'enabled'
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_mod_trbiomass'

parameter neltrbiomass0(t,n) 'Exogenous traditional biomass';
$loaddc neltrbiomass0

parameter trbio_countries(n) 'countries where traditional biomass is still used';
$loaddc trbio_countries

$gdxin

parameter scale_trbiomass(n)  'scaling factor for traditional biomass';

parameter trbio_ctr(*,n);
trbio_ctr('alpha',n) =  -0.7221;
trbio_ctr('beta',n)  =   0.1677;

parameter trbio_gdp_fun(t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

* Guarantee consistency with static calibration
neltrbiomass0(tfirst,n)$(q0('neltrbiomass',n) gt 1e-2) = q0('neltrbiomass',n);

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

$ifthen.trbgdp set mod_trbiomass_exo
Q_IN.fx('trbiomass','neltrbiomass',t,n) = neltrbiomass0(t,n);
Q_FUEL.fx('trbiomass',t,n)               = neltrbiomass0(t,n);
Q_EN.fx('neltrbiomass',t,n)             = neltrbiomass0(t,n);
$endif.trbgdp

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

MCOST_FUEL.fx('trbiomass',t,n)$(not tfix(t)) = FPRICE.l('trbiomass',t) + p_mkup('trbiomass',t,n);

$ifthen.trbgdp not set mod_trbiomass_exo

trbio_ctr('phi',n)$trbio_countries(n)  = sum(tfirst,(neltrbiomass0(tfirst,n)/tpes(tfirst,n))/trbio_ratio(tfirst));
trbio_gdp_fun(t,n) = trbio_ctr('phi',n)*(1-trbio_ratio(t));
scale_trbiomass(n)$trbio_countries(n)  = q0('neltrbiomass',n) / ((tpes(tfirst,n) - q0('neltrbiomass',n))*trbio_gdp_fun(tfirst,n)/(1-trbio_gdp_fun(tfirst,n)));

Q_FUEL.fx('trbiomass',t,n)$((not tfix(t)) and tfirst(t)) = q0('neltrbiomass',n);
Q_FUEL.fx('trbiomass',t,n)$((not tfix(t)) and (tnofirst(t) and trbio_countries(n))) = scale_trbiomass(n) * (tpes(t,n)-Q_FUEL.l('trbiomass',t,n))*trbio_gdp_fun(t,n)/(1-trbio_gdp_fun(t,n));
Q_IN.fx('trbiomass','neltrbiomass',t,n)$(not tfix(t)) = Q_FUEL.l('trbiomass',t,n);
Q_EN.fx('neltrbiomass',t,n)$(not tfix(t))             = Q_FUEL.l('trbiomass',t,n);

* Safeguard against bad behavior, usually when a startgdx has wrong values.
loop((t,n)$(Q_FUEL.lo('trbiomass',t,n)<0),
	Q_IN.fx('trbiomass','neltrbiomass',t,n)$(not tfix(t)) = neltrbiomass0(t,n);
	Q_FUEL.fx('trbiomass',t,n)$(not tfix(t))              = neltrbiomass0(t,n);
	Q_EN.fx('neltrbiomass',t,n)$(not tfix(t))             = neltrbiomass0(t,n);
);

$endif.trbgdp

$elseif %phase%=='gdx_items'

* Parameters
trbio_ctr
trbio_gdp_fun
neltrbiomass0
scale_trbiomass

$endif
