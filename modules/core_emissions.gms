*-------------------------------------------------------------------------------
* Carbon Emissions
* - Total CO2 emissions and CO2 Fossil fuel and Industry
* - CO2 emission costs
* - GHG permit market
*-------------------------------------------------------------------------------

$ifthen %phase%=='sets'

set e 'Emissions-related entities' /
    co2
    co2ffi # Fossil-fuel and Industry CO2
    nip    # net import of permits
    kghg   # Kyoto greenhouse gases
/;
alias(e,ee);
set map_e(e,ee) 'Relationships between Sectoral Emissions' /
    co2.co2ffi
/;

set ghg(e) 'Green-House Gases' /
    co2
/;

set e_cap(e);

set cce(e) 'Emissions-related entities that cost' /
    co2
/;

set emac(e) 'Emissions with marginal abatment curves' / /;

set sink(e) 'Emission sink for sequestration';

set sys 'emission adjustement inventory' /
    co2ffi
    co2_elheat
/;

set c_mkt(e) 'Market of permits' / nip /;    # if multiple permit markets, be sure to assign them to countries via trading_t

set map_ierr_e(ierr, c_mkt);
map_ierr_e('nip', 'nip') = YES;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_core_emissions'
parameter emi_st(fuel) 'Stoichiometric coefficient for fuels [GTonC/TWh]';
$loaddc emi_st
$gdxin

parameter emi_sys(sys,t,n) 'emi_st adjustments to historical emissions, by sectors';
emi_sys(sys,t,n) = 1; # Default value before calibration


$gdxin %datapath%data_validation
parameter q_emi_valid(*,t,n);
$loaddc q_emi_valid=q_emi_valid_ceds
$gdxin

scalar c2co2;
c2co2 = 44 / 12;

parameter emi_cap(t,n) 'Emissions permits cap [GtCe]';

parameter m_eqq_emi_lim(t,n) 'Marginal value of emission permits cap equation';
parameter m_eqq_emi_tree(t,n,e) 'Marginal value of the emission accounting tree equation';

parameter carbonprice(t,n) 'Carbon price (either the price of permits, the carbon tax, or na) [T$/GtCeq]';
carbonprice(t,n) = 0;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_dynamic_calibration_data'

execute_load '%tfpgdx%', emi_sys;

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

variable Q_EMI(e,t,n) 'Emissions-related quantities [GtCe]';
loadvarbnd(Q_EMI,'(e,t,n)',1,-inf,+inf);
Q_EMI.lo('co2',t,n) = -20;
Q_EMI.lo('co2ffi',t,n) = -20;
Q_EMI.up('co2ffi',t,n) = 100;
Q_EMI.lo(c_mkt,t,n) = -15;
Q_EMI.up(c_mkt,t,n) = 15;

variable COST_EMI(e,t,n) 'Emissions-related costs [T$]';
loadvarbnd(COST_EMI,'(cce,t,n)',0,-inf,+inf);

* BAU data
variable BAU_Q_EMI(e,t,n) 'Baseline emission [GtCe]';
execute_load '%baugdx%', BAU_Q_EMI=Q_EMI;

* Carbon prices
Positive variable CPRICE(c_mkt,t) 'Carbon price of permits [T$/GtCeq]';
loadvarbnd(CPRICE,'(c_mkt,t)',0,0,+Inf);

* Emission Abatment
variable Q_EMI_ABAT(e,t,n) 'GHG emission abatement [GtCe]';
loadvarbnd(Q_EMI_ABAT,'(emac,t,n)',1e-3,0,15);
Q_EMI_ABAT.fx(emac,t,n)$(year(t) le 2015) = 0;
Q_EMI_ABAT.fx(e,t,n)$(not emac(e)) = 0;

parameter emi_bio_harv(t) 'Emissions from harvest and collection of biomass';

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eqq_emi_lim_%clt%
eqq_emi_tree_%clt%
eqq_emi_co2ffi_%clt%

eqcost_emi_co2_%clt%

eq_mkt_clearing_nip_%clt%

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

* GHG emission cap
eqq_emi_lim_%clt%(t,n)$(mapn_th('%clt%') and t_cap(t,n))..
    sum(e_cap(e), Q_EMI(e,t,n)) =l= emi_cap(t,n) +
                                 sum(c_mkt$trading_t(c_mkt,t,n), Q_EMI(c_mkt,t,n));

* Compute total and sectoral emissions
eqq_emi_tree_%clt%(t,n,e)$(mapn_th('%clt%') and (sum(ee$map_e(e,ee),1)))..
    Q_EMI(e,t,n) =e= sum(ee$map_e(e,ee),Q_EMI(ee,t,n));

* Industrial CO2 emissions
eqq_emi_co2ffi_%clt%(t,n)$(mapn_th('%clt%'))..
    Q_EMI('co2ffi',t,n) =e= # Fossil fuel emissions
                            sum(f$emi_st(f), emi_st(f) * emi_sys('co2ffi',t,n) * Q_FUEL(f,t,n)) +
                            # Emissions from biomass
                            sum(jfed$csi('wbio',jfed,t,n), emi_bio_harv(t) * ccs_emi_capt('wbio') * emi_sys('co2ffi',t,n) * Q_IN('wbio',jfed,t,n)) +
                            # Emissions from fuel extraction
                            sum(extract(f), Q_EMI_OUT(f,t,n)) -
                            # Captured emissions
                            sum(sink, Q_EMI(sink,t,n));

* CO2 emission costs
eqcost_emi_co2_%clt%(t,n)$(mapn_th('%clt%'))..
    COST_EMI('co2',t,n) =e= sum(c_mkt$trading_t(c_mkt,t,n), CPRICE.l(c_mkt,t)*Q_EMI(c_mkt,t,n));

* Emission permit market clearing for internal market
eq_mkt_clearing_nip_%clt%(c_mkt,t,'%clt%')$(internal(c_mkt))..
    sum(n$(mapn('%clt%') and trading_t(c_mkt,t,n)), Q_EMI(c_mkt,t,n)) =e= 0;

*-------------------------------------------------------------------------------
$elseif %phase%=='before_nashloop'

Q_EMI.up(c_mkt,t,n)$((not tfix(t)) and (trading_t(c_mkt,t,n))) = 15;
Q_EMI.lo(c_mkt,t,n)$((not tfix(t)) and (trading_t(c_mkt,t,n))) = -15;
Q_EMI.fx(c_mkt,t,n)$((not tfix(t)) and (not trading_t(c_mkt,t,n))) = 0;

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

loop(c_mkt,
carbonprice(t,n)$trading_t(c_mkt,t,n) = CPRICE.l(c_mkt,t);
);
carbonprice(t,n)$(ctax('co2',t,n)) = ctax('co2',t,n);

* Accounting for electrification in the transport sector
* Reference for default carbon efficiency rate: Fajardy and Daggash (2017)
emi_bio_harv(t) = 0.25 * (1 - 
                   sum((n,ices_el), QEL_OUT.l('edv',ices_el,t,n) + QEL_OUT.l('edvfr',ices_el,t,n)) /
                   (sum((f,n,jfed)$(csi(f,jfed,t,n) and (jveh(jfed) or jfrt(jfed))),
                      Q_IN.l(f,jfed,t,n)) + 
                      sum((n,ices_el), QEL_OUT.l('edv',ices_el,t,n) + 
                                       QEL_OUT.l('edvfr',ices_el,t,n))
                    ))**2;

*-------------------------------------------------------------------------------
$elseif %phase%=='dynamic_calibration'

* Calibration of CO2 FFI for supply
emi_sys('co2ffi',t,n)$(year(t) le 2015) = (q_emi_valid('co2ffi',t,n) - 
                                  sum(extract(f), Q_EMI_OUT.l(f,t,n)) * emi_sys('extract',t,n) + 
                                  sum(sink, Q_EMI.l(sink,t,n))
                                 ) / 
                                 sum(fuel, emi_st(fuel) * Q_FUEL.l(fuel,t,n));
emi_sys('co2ffi',t,n)$(year(t) gt 2015) = valuein(2015, emi_sys('co2ffi',tt,n));

emi_sys('co2_elheat',t,n)$(year(t) le 2015) = q_emi_valid('co2_elheat',t,n) /
                                 sum((fuel,jfed)$(jel(jfed) and csi(fuel,jfed,t,n)), 
                                     Q_IN.l(fuel,jfed,t,n) * (emi_st(fuel) - (ccs_emi_capt(fuel) * ccs_capture_eff(jfed))$jccs(jfed))
                                 );
emi_sys('co2_elheat',t,n)$(year(t) gt 2015) = valuein(2015, emi_sys('co2_elheat',tt,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='fix_variables'

tfixvar(COST_EMI,'(e,t,n)')
tfixvar(Q_EMI,'(e,t,n)')
tfixvar(CPRICE,'(c_mkt,t)')

tfixpar(carbonprice,'(t,n)')   
tfixpar(m_eqq_emi_lim,'(t,n)') 
tfixpar(m_eqq_emi_tree,'(t,n,e)') 

*-------------------------------------------------------------------------------
$elseif %phase%=='tfpgdx_items'

emi_sys

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Sets
cce
e
ghg
sink
c_mkt
map_e

* Parameters
c2co2
carbonprice
emi_bio_harv
emi_cap
emi_st

* Variables
BAU_Q_EMI
COST_EMI
CPRICE
Q_EMI

* Summary parameters
m_eqq_emi_lim
m_eqq_emi_tree

$endif
