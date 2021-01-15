*------------------------------------------------------------------------------- 
* GHG module      
* - CH4 FFI + CH4 waste + CH4 open fires
* - N2O FFI + N2O waste + N2O open fires
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Define the oghg baseline data source
$setglobal ghgbaseline ssp2
$if %baseline%=='ssp1' $setglobal ghgbaseline %baseline%
$if %baseline%=='ssp3' $setglobal ghgbaseline %baseline%
$if %baseline%=='ssp4' $setglobal ghgbaseline ssp1
$if %baseline%=='ssp5' $setglobal ghgbaseline ssp3

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

set e /ch4, n2o,          # Total
       ch4_ffi, n2o_ffi,  # Fossil fuel and Industry processes and Extraction
       ch4_wst, n2o_wst,  # Waste
       ch4_ofr, n2o_ofr   # Open Fires
      /;

set map_e(e,ee) 'Relationships between Sectoral Emissions' /
    ch4.(ch4_ffi,ch4_wst)
    n2o.(n2o_ffi,n2o_wst)
    kghg.(co2,ch4,n2o)
/;

set ghg(e) 'Green-House Gases' /
     ch4, n2o
/;

set enrg(e) 'emissions from the energy sector' /
   ch4_ffi
   n2o_ffi
/;

set waste(e) 'waste emissions' /
    ch4_wst, n2o_wst
/;

set efire(e) 'Open fires emissions' /
    ch4_ofr, n2o_ofr
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_validation'
parameter q_emi_valid_ghg;
parameter q_emi_valid_ghg_primap;
$loaddc q_emi_valid_ghg=q_emi_valid_ceds q_emi_valid_ghg_primap=q_emi_valid_primap
$gdxin
q_emi_valid_ghg('n2o_wst',t,n) = q_emi_valid_ghg_primap('n2o_wst',t,n);
q_emi_valid_ghg('n2o_ffi',t,n) = q_emi_valid_ghg_primap('n2o_ffi',t,n);

$gdxin '%datapath%data_mod_ghg'

parameter emi_ghg_hist(e,t,n) 'Historical emissions EDGAR v4.2 (2005,2010) [GtCe]';
$loaddc emi_ghg_hist

parameter ghg_baseline(e,t,n);

* Waste emissions baseline
parameter waste_emi_alpha(waste,n) 'region-dependen alpha coefficient to project waste emissions';
parameter waste_emi_beta(waste) 'beta coefficient to project waste emissions';
waste_emi_beta('ch4_wst') = 0.1022529;
waste_emi_beta('n2o_wst') = 0.08610055;
* compute alpha to match 2010 regional emissions
waste_emi_alpha(waste,n) = log(smax(tt$(tperiod(tt) eq 3), q_emi_valid_ghg(waste,tt,n)) / 
                               smax(tt$(tperiod(tt) eq 3), l(tt,n))) - 
                           waste_emi_beta(waste) * log(smax(tt$(tperiod(tt) eq 3), ykali(tt,n)) / 
                                                       smax(tt$(tperiod(tt) eq 3), l(tt,n)));
ghg_baseline(waste,t,n)$(year(t) le 2015) = q_emi_valid_ghg(waste,t,n);
ghg_baseline(waste,t,n)$(year(t)>2015) = l(t,n) * exp( waste_emi_alpha(waste,n) +
                                                    waste_emi_beta(waste) * log(ykali(t,n)/l(t,n))
                                                  );

* FFI emission factors
parameter emi_fac(e,j) 'Technology specific emission factors [Tg/PJ]';
$loaddc emi_fac

parameters emi_ffac0(e,f,n), emi_ffac(e,f,t,n) 'Fuel-region specific emission factors [Tg/PJ]';
$loaddc emi_ffac0

scalar emi_ch4_tp 'annual rate of decreasing emission leakage [%]' /1/;

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

emi_ffac('ch4_ffi',f,t,n) = emi_ffac0('ch4_ffi',f,n);
emi_ffac('ch4_ffi',f,t,n)$(year(t)>2005) = emi_ffac0('ch4_ffi',f,n) * power(1 - (emi_ch4_tp/100),year(t)-2005);

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

Q_EMI.lo(waste,t,n) = 0;
Q_EMI.lo(enrg,t,n) = 0;

* Historical data emission PRIMAP [GtCe/year]
Q_EMI.fx(waste,t,n)$(year(t) le 2015) = q_emi_valid_ghg(waste,t,n);
Q_EMI.fx(enrg,t,n)$(year(t) le 2015)  = q_emi_valid_ghg(enrg,t,n);
* Historical data emission EDGAR v4.2 [GtCe/year]
Q_EMI.fx(efire,t,n)$(year(t) le 2010) = emi_ghg_hist(efire,t,n);
Q_EMI.fx(efire,t,n)$(year(t) > 2010) = smax(tt$(tperiod(tt) eq 2),emi_ghg_hist(efire,tt,n));

* Ensure baseline emissions are equal to exogenous assumptions
BAU_Q_EMI.fx(waste,t,n) = ghg_baseline(waste,t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eqq_emi_waste_%clt%
eqq_emi_n2o_ffi_%clt%
eqq_emi_ch4_ffi_%clt%

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

* CH4, N2O waste emissions
eqq_emi_waste_%clt%(waste,t,n)$(mapn_th('%clt%') and (year(t)>2015))..
                Q_EMI(waste,t,n) =e= ghg_baseline(waste,t,n) - Q_EMI_ABAT(waste,t,n);

* n2o FFI
eqq_emi_n2o_ffi_%clt%(t,n)$(mapn_th('%clt%') and (year(t)>2015))..
  Q_EMI('n2o_ffi',t,n) =e= ( emi_fac('n2o_ffi','elpc') * sumjchild(Q_IN('coal',jfed,t,n),jfed,'elpc') +
                        emi_fac('n2o_ffi','elpb') * sumjchild(Q_IN('wbio',jfed,t,n),jfed,'elpb') +
                        emi_fac('n2o_ffi','elcigcc') * Q_IN('coal','elcigcc',t,n) +
                        emi_fac('n2o_ffi','elpc_ccs') * Q_IN('coal','elpc_ccs',t,n) +
                        emi_fac('n2o_ffi','elpc_oxy') * Q_IN('coal','elpc_oxy',t,n) +
                        emi_fac('n2o_ffi','elbigcc') * Q_IN('wbio','elbigcc',t,n) +
                        emi_fac('n2o_ffi','eloil') * sum(jfed$(csi('oil',jfed,t,n) and xiny(jfed,jel)), Q_IN('oil',jfed,t,n)) +
                        emi_fac('n2o_ffi','elgas') * sum(jfed$(csi('gas',jfed,t,n) and xiny(jfed,jel)), Q_IN('gas',jfed,t,n)) +
                        emi_fac('n2o_ffi','nelgas') * Q_IN('gas','nelgas',t,n) +
                        emi_fac('n2o_ffi','nelcoal') * Q_IN('coal','nelcoaltr',t,n) +
                        emi_fac('n2o_ffi','neloil') * Q_IN('oil','neloil',t,n) +
                        emi_fac('n2o_ffi','trad_cars') * sum(transp_qact('oil',jfed),Q_IN('oil',jfed,t,n)) +
                        emi_fac('n2o_ffi','hybrid') * sum(transp_qact(fuel,jfed)$(sameas(fuel,'trbiofuel') or sameas(fuel,'advbiofuel')),Q_IN(fuel,jfed,t,n)) +
                        emi_fac('n2o_ffi','neltrbiofuel') * Q_IN('trbiofuel','neltrbiofuel',t,n) +
                        emi_fac('n2o_ffi','neltrbiomass') * Q_IN('trbiomass','neltrbiomass',t,n)
                      ) * smax(tt$(year(tt) eq 2015), q_emi_valid_ghg('n2o_ffi',tt,n) /
                      (emi_fac('n2o_ffi','elpc') * sumjchild(Q_IN.l('coal',jfed,tt,n),jfed,'elpc') +
                        emi_fac('n2o_ffi','elpb') * sumjchild(Q_IN.l('wbio',jfed,tt,n),jfed,'elpb') +
                        emi_fac('n2o_ffi','elcigcc') * Q_IN.l('coal','elcigcc',tt,n) +
                        emi_fac('n2o_ffi','elpc_ccs') * Q_IN.l('coal','elpc_ccs',tt,n) +
                        emi_fac('n2o_ffi','elpc_oxy') * Q_IN.l('coal','elpc_oxy',tt,n) +
                        emi_fac('n2o_ffi','elbigcc') * Q_IN.l('wbio','elbigcc',tt,n) +
                        emi_fac('n2o_ffi','eloil') * sum(jfed$(csi('oil',jfed,tt,n) and xiny(jfed,jel)), Q_IN.l('oil',jfed,tt,n)) +
                        emi_fac('n2o_ffi','elgas') * sum(jfed$(csi('gas',jfed,tt,n) and xiny(jfed,jel)), Q_IN.l('gas',jfed,tt,n)) +
                        emi_fac('n2o_ffi','nelgas') * Q_IN.l('gas','nelgas',tt,n) +
                        emi_fac('n2o_ffi','nelcoal') * Q_IN.l('coal','nelcoaltr',tt,n) +
                        emi_fac('n2o_ffi','neloil') * Q_IN.l('oil','neloil',tt,n) +
                        emi_fac('n2o_ffi','trad_cars') * sum(transp_qact('oil',jfed),Q_IN.l('oil',jfed,tt,n)) +
                        emi_fac('n2o_ffi','hybrid') * sum(transp_qact(fuel,jfed)$(sameas(fuel,'trbiofuel') or sameas(fuel,'advbiofuel')),Q_IN.l(fuel,jfed,tt,n)) +
                        emi_fac('n2o_ffi','neltrbiofuel') * Q_IN.l('trbiofuel','neltrbiofuel',tt,n) +
                        emi_fac('n2o_ffi','neltrbiomass') * Q_IN.l('trbiomass','neltrbiomass',tt,n))) - Q_EMI_ABAT('n2o_ffi',t,n);

* ch4 FFI
eqq_emi_ch4_ffi_%clt%(t,n)$(mapn_th('%clt%') and (year(t)>2015))..
  Q_EMI('ch4_ffi',t,n) =e= div0(( emi_ffac('ch4_ffi','oil',t,n) * Q_FUEL('oil',t,n) +
$if set nogastrade           emi_ffac('ch4_ffi','gas',t,n) * Q_FUEL('gas',t,n) +
$if set nocoaltrade           emi_ffac('ch4_ffi','coal',t,n) * Q_FUEL('coal',t,n) 
$if not set nogastrade       emi_ffac('ch4_ffi','gas',t,n) * Q_OUT('gas',t,n) +
$if not set nocoaltrade       emi_ffac('ch4_ffi','coal',t,n) * Q_OUT('coal',t,n) 
                            ) * smax(tt$(year(tt) eq 2015), q_emi_valid_ghg('ch4_ffi',tt,n)) ,
                           smax(tt$(year(tt) eq 2015), 
                             emi_ffac('ch4_ffi','oil',tt,n) * Q_FUEL.l('oil',tt,n) +
$if set nogastrade           emi_ffac('ch4_ffi','gas',tt,n) * Q_FUEL.l('gas',tt,n) +
$if set nocoaltrade          emi_ffac('ch4_ffi','coal',tt,n) * Q_FUEL.l('coal',tt,n) 
$if not set nogastrade       emi_ffac('ch4_ffi','gas',tt,n) * Q_OUT.l('gas',tt,n) +
$if not set nocoaltrade      emi_ffac('ch4_ffi','coal',tt,n) * Q_OUT.l('coal',tt,n) 
                            ))  - Q_EMI_ABAT('ch4_ffi',t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

waste_emi_alpha
waste_emi_beta
emi_fac
emi_ffac

$endif
