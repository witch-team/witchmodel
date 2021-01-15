*-------------------------------------------------------------------------------
* Dynamic calibration
* - Calibrate TFP (both energy and capital-labor)
* - Set population to the GDP/population data used
* 
* Options:
* - Time-varying Elasticity of Substitution (default) or Constant ($setglobal ces_fixed)
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* By default, GDP/population/EI data is taken from baseline scenario
$if not set tfpscen $setglobal tfpscen '%baseline%'

$if %baseline%=='ssp1' $setglobal nogastrade
$if %baseline%=='ssp1' $setglobal nocoaltrade

$if not '%baseline%'=='ssp2' $setglobal nocorrallssp2
$setglobal tfp_min 0.05

* By default, creates and overwrites start and data_tfp files
$setglobal tfpoutgdx '%datapath%data_tfp_%tfpscen%.gdx'

* Iteration from which starting to calibrate
$setglobal start_calib_iter 2
$setglobal min_iter 3

$setglobal calibrate_tfpy yes
$setglobal calibrate_tfpn yes

* Error tolerances for convergence (in % of GDP/TPES averaged over time and regions)
$setglobal errtol_tfpy 0.1
$setglobal errtol_tfpn 0.1

* Calibration of TFPN only in SSP2
$if set nocorrallssp2 $setglobal calibrate_tfpn no
$if %tfpscen%=='ssp2' $setglobal calibrate_tfpn yes

$setglobal nodectfpy 2125

* Specific option for SSP5
$ifthen.ssp5 %tfpscen%=="ssp5"
$setglobal errtol_tfpy 0.2
$setglobal fix_tfpn_end 2125
$endif.ssp5

* Time-varying Elasticity of Substitution
* By default (SSP2, elffren elasticity is increasing from 5 to 10 by 2100)
$setglobal ela_endvalue_elffren 10 #was:5
* These values are kept constant:
$setglobal ela_endvalue_elff 2
$setglobal ela_endvalue_el2 2
$setglobal ela_endvalue_elintren 2
$setglobal ela_endvalue_en 2/3
$setglobal ela_startyear 2005
$setglobal ela_endyear 2100
$ifthen.l %baseline% == 'ssp1'
$setglobal ela_endvalue_elffren 100
$elseif.l %baseline% == 'ssp2'
$setglobal ela_endvalue_elffren 10
$elseif.l %baseline% == 'ssp3'
$setglobal ela_endvalue_elffren 5
$elseif.l %baseline% == 'ssp4'
$setglobal ela_endvalue_elffren 100
$elseif.l %baseline% == 'ssp5'
$setglobal ela_endvalue_elffren 5
$endif.l
$if set ces_fixed $setglobal ela_endvalue_elffren 5

$setglobal write_tfp_file 'datapath'

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

$if %calibrate_tfpy% =='yes' set ierr / tfpy /;
$if %calibrate_tfpn% =='yes' set ierr / tfpn /;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

* Explicit load for non-ssp2 calibration
$gdxin '%datapath%data_validation.gdx';
parameter q_en_valid_dyn(*,t,n);
$loaddc q_en_valid_dyn=q_en_valid_weo
parameter q_in_valid_dyn(*,t,n);
$loaddc q_in_valid_dyn=q_in_valid_weo
$gdxin
q_en_valid_dyn(jcalib,t,n)$(q_en_valid_dyn(jcalib,t,n) eq 0)=1e-8;

Parameter ei(t,n), ei_global(t), ei_kali(t,n);

Parameter tpes_iter(siter, t,n), delta_tfpn_iter(siter, t, n);

Parameter tfpn_corr_ssp_param(ssp) 'Factor by wich growth rate of SSP2 tfpn adjusted'/
ssp1    1.015
ssp2    1
ssp3    0.9975
ssp4    1.0075
ssp5    1.012
/;

* Load source for TPES
$gdxin %datapath%data_validation
parameter tpes_valid_weo(t,n);
$loaddc tpes_valid_weo
$gdxin

$ifthen.c %calibrate_tfpy% =='yes'
errtol('tfpy')=%errtol_tfpy%;
$endif.c

$ifthen.c %calibrate_tfpn% =='yes'
errtol('tfpn')=%errtol_tfpn%;
$endif.c


*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

parameter income_el(t,n), income_elkali(t,n), tfpy_iter(siter,t,n),tfpn_iter(siter,t,n);
parameter delta_tfpy(t,n), delta_tfpn(t,n);
parameter dtpes(t,n), dy(t,n), dy_calib(t,n);
parameter tpes_kali(t,n);

* Use TFPN from SSP2 for other SSPs
$ifthen.s2a set nocorrallssp2
Parameter tfpn_ssp2(t,n), tfpy_ssp2(t,n);
$if not set tfpgdxssp2 $setglobal tfpgdxssp2 data_tfp_ssp2
$gdxin '%datapath%%tfpgdxssp2%.gdx'
$loaddc tfpn_ssp2=tfpn tfpy_ssp2=tfpy
$gdxin
tfpn(tfirst,n) = 1;
Loop((t,tp1)$(pre(t,tp1)),
tfpn(tp1,n) = tfpn(t,n) * (1 + ((tfpn_ssp2(tp1,n)/tfpn_ssp2(t,n))-1)) * (tfpn_corr_ssp_param('%tfpscen%')**5);
);
$endif.s2a

* Initial income elasticity: 0.4 (OECD) and in 0.55 (non-OECD). Growth rate such that in 2150, both values decline to 0.2
income_elkali(tfirst,n)$(oecd(n)) = 0.40;
income_elkali(tfirst,n)$(not oecd(n)) = 0.55;
income_elkali(tfirst,'china') = 0.20;
income_elkali(tfirst,'india') = 0.40;
income_elkali(t,n) = income_elkali(tfirst,n) * 
                     exp((year(t) - 2005) / (smax(tt,year(tt)) - 2005) *
                     log(0.20 / income_elkali(tfirst,n)));

* implement time-varying CES elasticities linearly
* Elasticities (rho): elffren: 5 (0.8), elff: 2 (0.5), el2: 2 (0.5) (nuclear with rest), elintren: 2 (0.5), en: 2/3 (-0.5)
* rho = (ela - 1) / ela = 1 - 1/ela 
* ela = 1 / (1 - rho)
* implement linear change in elasticity
rho('elffren',t) =  1 - 1 / ( (1 / (1 - rho('elffren','1')) ) * ((%ela_endyear% - year(t))/(%ela_endyear%-%ela_startyear%)) + %ela_endvalue_elffren% * ((year(t)-%ela_startyear%)/(%ela_endyear%-%ela_startyear%)) );
rho('elff',t) =  1 - 1 / ( (1 / (1 - rho('elff','1')) ) * ((%ela_endyear% - year(t))/(%ela_endyear%-%ela_startyear%)) + %ela_endvalue_elff% * ((year(t)-%ela_startyear%)/(%ela_endyear%-%ela_startyear%)) );
rho('el2',t) =  1 - 1 / ( (1 / (1 - rho('el2','1')) ) * ((%ela_endyear% - year(t))/(%ela_endyear%-%ela_startyear%)) + %ela_endvalue_el2% * ((year(t)-%ela_startyear%)/(%ela_endyear%-%ela_startyear%)) );
rho('elintren',t) =  1 - 1 / ( (1 / (1 - rho('elintren','1')) ) * ((%ela_endyear% - year(t))/(%ela_endyear%-%ela_startyear%)) + %ela_endvalue_elintren% * ((year(t)-%ela_startyear%)/(%ela_endyear%-%ela_startyear%)) );
rho('en',t) =  1 - 1 / ( (1 / (1 - rho('en','1')) ) * ((%ela_endyear% - year(t))/(%ela_endyear%-%ela_startyear%)) + %ela_endvalue_en% * ((year(t)-%ela_startyear%)/(%ela_endyear%-%ela_startyear%)) );
* after %ela_endyear% all constant
rho('elffren',t)$(year(t) gt %ela_endyear%) = valuein(%ela_endyear%, rho('elffren',tt));
rho('elff',t)$(year(t) gt %ela_endyear%) = valuein(%ela_endyear%, rho('elff',tt));
rho('el2',t)$(year(t) gt %ela_endyear%) = valuein(%ela_endyear%, rho('el2',tt)); 
rho('elintren',t)$(year(t) gt %ela_endyear%) = valuein(%ela_endyear%, rho('elintren',tt)); 
rho('en',t)$(year(t) gt %ela_endyear%) = valuein(%ela_endyear%, rho('en',tt)); 

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

if((stop_nash ne 1),

* TFPY Calibration

$ifthen.c %calibrate_tfpy% =='yes'

delta_tfpy(t,n) = (ykali(t,n)/Q.l('y',t,n)-1);
tfpy(t,n)$(ord(siter) eq 1 and tfirst(t)) = 1;
tfpy(t,n)$(ord(siter) gt 1 and tfirst(t)) = (((((Q.l('y',t,n) + sum(fuel, COST_FUEL.l(fuel,t,n)))/q0('y',n))**rho('y',t) -
    alpha('fen',n)*(Q.l('fen',t,n)/q0('fen',n))**rho('y',t))/alpha('kl',n))**(1/rho('y',t)) ) /
    (q0('kl',n)*((K.l('fg',t,n)/q0('k',n))**(alpha('k',n))*(l(t,n)/q0('l',n))**(alpha('l',n)))/q0('kl',n));

tfpy(t,n)$(ord(siter) ge %start_calib_iter% and tperiod(t) gt 1)=tfpy(t,n)*(1+delta_tfpy(t,n));

$if set nocorrallssp2 tfpy(t,n)$tfix(t)=tfpy_ssp2(t,n);

* If over i10, take moving average
tfpy_iter(siter,t,n)=tfpy(t,n);
tfpy(tlast,n) = sum(pre(t, tlast), tfpy(t,n));
tfpy(t,n) = max(tfpy(t,n), %tfp_min%);

allerr(run,siter,'tfpy')=100 * sum((t,n)$(year(t) gt 2010 and year(t) le 2100),abs((Q.l('y',t,n)-ykali(t,n))/ykali(t,n)))/sum((t,n)$(tperiod(t) gt 2 and not tperiod(t) gt 20), 1);

$if set nodectfpy loop((t,tm1)$pre(tm1,t), tfpy(t,n)$(year(t) gt %nodectfpy%) = max(tfpy(tm1,n),tfpy(t,n)));

tfpy_iter(siter,t,n) = tfpy(t,n);

$endif.c

* TFPN Calibration

$ifthen.c %calibrate_tfpn%=='yes'

dtpes(tfirst,n)    = 1.000001;
dy(tfirst,n)       = 1.000001;
dy_calib(tfirst,N) = 1.000001;

* INCOME ELASTICITY
loop((t,tp1)$(pre(t,tp1)),
dtpes(tp1,n)= (tpes(tp1,n) /tpes(t,n)) -1  ;
dy(tp1,n)= (Q.l('y',tp1,n) / Q.l('y',t,n))-1;
dy_calib(tp1,n)= (ykali(tp1,n) / ykali(t,n))  -1;
income_el(tp1,n)= DIV0(dtpes(tp1,n),dy(tp1,n));
);

* Update tpes kali
tpes_kali(tfirst,n)= tpes(tfirst,n);

* Calibrate TPES until 2015 on IEA World Energy Balances from Validation
loop((tm1,t)$((pre(tm1,t)) and (year(t) gt 2005) and (smin(n,tpes_valid_weo(t,n)) ne 0)),
tpes_kali(t,n) = tpes_kali(tm1,n) * (tpes_valid_weo(t,n)/tpes_valid_weo(tm1,n));
);

* Elasticity rule only after 2015
Loop((t,tp1)$(pre(t,tp1) and (ORD(tp1) gt CARD(tpes_valid_weo)/CARD(n))),
tpes_kali(tp1,n)=tpes_kali(t,n)*(1+income_elkali(tp1,n)*dy_calib(tp1,n));
);

ei_kali(t,n) =  (tpes_kali(t,n)  *twh2ej) / (ykali(t,n) * mer2ppp(t,n));  #just as output

* Updating tfpn to obtain calibrated tpes
delta_tfpn(t,n)=((tpes(t,n)/tpes_kali(t,n))-1);
tfpn(tfirst,n)=1;
tfpn(t,n)$(ord(siter) ge %start_calib_iter% and tperiod(t) gt 1)=tfpn(t,n)*(1+delta_tfpn(t,n));
tfpn_iter(siter,t,n)=tfpn(t,n);
tfpn(tlast,n) = sum(pre(t, tlast), tfpn(t,n));
tfpn(t,n) = max(tfpn(t,n), %tfp_min%);
tpes_iter(siter, t,n)=tpes(t,n);
delta_tfpn_iter(siter, t, n)=delta_tfpn(t,n);
allerr(run,siter,'tfpn')=100*sum((t,n)$(tperiod(t) gt 2 and not tperiod(t) gt 20),abs((tpes(t,n)-tpes_kali(t,n))/tpes_kali(t,n)))/sum((t,n)$(tperiod(t) gt 2 and not tperiod(t) gt 20), 1);
$endif.c

$ifthen.ft set fix_tfpn_end
tfpn(t,n)$(year(t) gt %fix_tfpn_end%) =  valuein(%fix_tfpn_end%,tfpn(tt,n));
$endif.ft

);

*-------------------------------------------------------------------------------
$elseif %phase%=='summary_report'

* Energy Intensity
ei(t,n) = tpes(t,n) * twh2ej / (Q.l('y',t,n) * mer2ppp(t,n));
ei_global(t) = sum(n,tpes(t,n)) * twh2ej / sum(n,Q.l('y',t,n) * mer2ppp(t,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='tfpgdx_items'

tfpy
tfpn
ykali

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Parameters
delta_tfpn
delta_tfpy
dtpes
dy
dy_calib
ei
ei_global
ei_kali
income_el
income_elkali
tfpn_corr_ssp_param
tfpn_iter
tfpy_iter
tpes_kali

$endif

