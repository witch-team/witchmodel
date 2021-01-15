*-------------------------------------------------------------------------------
* Coal for non-electric sectors
* - Coke Plants
* - Industrial and Commercial combined-heat-and-power (CHP)
* - Others
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Baseline nelcoal yearly growth rate [%]
$setglobal nelcoal_basegr (-1)
$if %baseline%==ssp3 $setglobal nelcoal_basegr 1
$if %baseline%==ssp5 $setglobal nelcoal_basegr 1
*$if %baseline%==ssp1 $setglobal nelcoal_basegr (-1.2)

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

set j / nelcoalccs, nelcoaltr, nelcoalabat /;
set jreal(j) / nelcoalccs, nelcoaltr, nelcoalabat /;
set jnel(jreal) / nelcoalccs, nelcoaltr, nelcoalabat /;
set jfed(jreal) / nelcoalccs, nelcoaltr /;

set jinv(jreal) / nelcoalccs /;
set jccs(jfed) / nelcoalccs /;

set jpenalty(j) /nelcoalabat/;

set map_j(j,jj) /
        nelcoal.(nelcoalccs, nelcoaltr, nelcoalabat)
        /;
 
*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

parameter nelcoal_baseline(t,n) 'Exogenous non-electric coal';
nelcoal_baseline(t,n) = 1; # dummy value before calibration

scalar nelcoal_growthrate 'Yearly Growth Rate in baseline (%)';

$gdxin '%datapath%data_mod_nelcoal'
parameter nelcoal_cmac (n,*);
$loaddc nelcoal_cmac 
$gdxin

parameter nelcoal_max_abat(t,n);
nelcoal_max_abat(t,n)$(year(t) le 2010) = nelcoal_cmac(n,'abat_max_2010');
nelcoal_max_abat(t,n) = min(0.9, nelcoal_cmac(n,'abat_max_2010') * (1 + 0.01)**(year(t) - 2010));

parameter nelcoal_share_ccs(t);

*-------------------------------------------------------------------------------
$elseif %phase%=='include_dynamic_calibration_data'

execute_load '%tfpgdx%', nelcoal_baseline;

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

csi('coal','nelcoal',t,n) = 0;

csi('coal','nelcoaltr',t,n) = 1;
csi('coal','nelcoalccs',t,n) = 1;

mcost_inv0('nelcoalccs',n) = 25 * c2co2 * 1e-6;

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

delta_en('nelcoalccs',t,n) = 1;

nelcoal_share_ccs(tfirst) = 0;
nelcoal_share_ccs(t)$(year(t) ge 2010) = min(1,(year(t) - 2010) / (2100 - 2010)); 

Q_EN.lo('nelcoaltr',t,n) = 1e-12;
Q_EN.up('nelcoaltr',t,n) = nelcoal_baseline(t,n);

Q_EN.lo('nelcoalccs',t,n) = 1e-12;
Q_EN.up('nelcoalccs',t,n) = max(1e-12, nelcoal_baseline(t,n) * nelcoal_share_ccs(t));
K_EN.fx('nelcoalccs',t,n)$(year(t) eq 2005) = 1e-12;

Q_EN.lo('nelcoalabat',t,n) = 0.0;
Q_EN.up('nelcoalabat',t,n) = nelcoal_baseline(t,n) * nelcoal_max_abat(t,n);

Q_IN.lo('coal','nelcoalccs',t,n) = 1e-12;
Q_IN.up('coal','nelcoalccs',t,n) = max(1e-12,nelcoal_baseline(t,n) * nelcoal_share_ccs(t) / csi('coal','nelcoalccs',t,n));

Q_IN.lo('coal','nelcoaltr',t,n) = 1e-12;
Q_IN.up('coal','nelcoaltr',t,n) = nelcoal_baseline(t,n) / csi('coal','nelcoaltr',t,n);

Q_IN.fx('coal','nelcoal',t,n) = 0.0;
Q_EN.fx('nelcoal',t,n) = nelcoal_baseline(t,n);
K_EN.fx('nelcoal',t,n) = 0;

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eqcost_en_nelcoal_%clt%
eqq_ncoalabat_monotone_%clt%
eqq_en_nelcoalccs_max_%clt%

$elseif %phase%=='eqs'

eqcost_en_nelcoal_%clt%(t,n)$(mapn_th('%clt%'))..
         COST_EN('nelcoalabat',t,n) =e= 10e-3 * nelcoal_baseline(t,n) * emi_st('coal') *
                                        nelcoal_max_abat(t,n) *
                                        (nelcoal_cmac(n,'a') *
                                          Q_EN('nelcoalabat',t,n) /
                                            (nelcoal_max_abat(t,n) * nelcoal_baseline(t,n)) +
                                          nelcoal_cmac(n,'b') / nelcoal_cmac(n,'c') *
                                            (exp(nelcoal_cmac(n,'c') *
                                              (Q_EN('nelcoalabat',t,n)/
                                                (nelcoal_max_abat(t,n) *
                                                    nelcoal_baseline(t,n))
                                                ) - 1 )
                                            )
                                        );

eqq_ncoalabat_monotone_%clt%(t,tp1,n)$(mapn_th1('%clt%'))..
        Q_EN('nelcoalabat',tp1,n) =g= Q_EN('nelcoalabat',t,n);

* ensure Q_EN is lower than K_EN for CCS as not in jel
eqq_en_nelcoalccs_max_%clt%(t,n)$(mapn_th('%clt%'))..
        Q_EN('nelcoalccs',t,n) =l= K_EN('nelcoalccs',t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='dynamic_calibration'

* Calibration of nelcoal
nelcoal_baseline(t,n)$(year(t) eq 2005) = q0('nelcoal',n);
nelcoal_baseline(t,n)$(year(t) le 2015 and year(t) gt 2005) = max((q_fuel_valid_weo('coal',t,n) - sum(jfed$map_j('elpc',jfed), Q_IN.l('coal',jfed,t,n))),
                                                                  0.001 * tpes(t,n)) / 
                                                                  csi('coal','nelcoaltr',t,n);
nelcoal_baseline(t,n)$(year(t) gt 2015) = valuein(2015,nelcoal_baseline(tt,n)) / 
                                          csi('coal','nelcoaltr',t,n) * 
                                          (1 + %nelcoal_basegr% / 100)**(year(t) - 2010);

* Update bounds
Q_EN.up('nelcoaltr',t,n)$(not tfix(t)) = nelcoal_baseline(t,n);
Q_EN.up('nelcoalccs',t,n)$(not tfix(t) and (not tfirst(t))) = max(1e-12,nelcoal_baseline(t,n) * nelcoal_share_ccs(t));
Q_EN.up('nelcoalabat',t,n)$(not tfix(t)) = nelcoal_baseline(t,n)*nelcoal_cmac(n,'abat_max_2010') ;
Q_IN.up('coal','nelcoalccs',t,n)$(not tfix(t)) = max(1e-12,nelcoal_baseline(t,n) * nelcoal_share_ccs(t) / csi('coal','nelcoalccs',t,n));
Q_IN.up('coal','nelcoaltr',t,n)$(not tfix(t)) = nelcoal_baseline(t,n) / csi('coal','nelcoaltr',t,n);
Q_EN.fx('nelcoal',t,n)$(not tfix(t)) = nelcoal_baseline(t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='tfpgdx_items'

nelcoal_baseline

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Parameters
nelcoal_cmac
nelcoal_share_ccs
nelcoal_max_abat

$endif
