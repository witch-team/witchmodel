*-------------------------------------------------------------------------------
* Long-run Damages from Climate Change
* - Economic impacts
* - Adaptation
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Define adaptation efficacy
$setglobal adap_efficiency ssp2
$if %baseline%=='ssp1' $setglobal adap_efficiency ssp1_ssp5
$if %baseline%=='ssp3' $setglobal adap_efficiency ssp3
$if %baseline%=='ssp5' $setglobal adap_efficiency ssp1_ssp5

* Check requirements
$if set damage_feedback $if not set solve_climate $abort 'ERROR: solve_climate is required by damage_feedback.'
$if set solve_climate $if not set adaptation $abort 'ERROR: solve_climate requires "adaptation" to be defined as "YES" or "NO".'

$if set damage_feedback $if not %n%=='witch13' $abort damage function is compatible only with witch13

* Define damage cost function
$setglobal damcost 'climcost'

$elseif %phase%=='sets'

set
    iq  'Nodes representing economic values (which have a Q)' /ada, cap, act, gcap/
    g   'Goods sector' /prada,rada,scap/
;

set conf /
'mod_damage'.'enabled'
$if set damage_feedback 'damage_feedback'.'enabled'
$if set adaptation 'adaptation'.'%adaptation%'
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'


$gdxin '%datapath%data_mod_damage'

parameter k_h0(n);
$loaddc k_h0

parameter k_edu0(n);
$loaddc k_edu0

parameter owa(*,n);
$loaddc owa

parameter ces_ada(*,n);
$loaddc ces_ada

parameter comega_neg(*,n,polydeg);
$loaddc comega_neg

parameter comega_pos(*,n,polydeg);
$loaddc comega_pos

$gdxin


* Adaptation efficiency

$if not set adap_efficiency $setglobal adap_efficiency 'ssp2'

$ifthen.ae %adap_efficiency%=='ssp2'
ces_ada('eff',n)      = 1;

$elseif.ae %adap_efficiency%=='ssp1_ssp5'
ces_ada('eff',n)      = 1.25;

$elseif.ae %adap_efficiency%=='ssp3'
ces_ada('eff',n)      = 0.75;

$endif.ae


*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

delta('prada') = 0.1;
delta('rada') = 1;
delta('scap') = 0.03;

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

variable OMEGA(t,n) 'economic impact from climate change [% of GDP]';
loadvarbnd(OMEGA,'(t,n)',0,-inf,+inf);

K.fx('prada',tfirst,n) = 1e-5;
K.fx('rada',tfirst,n)  = 1e-5;
K.fx('scap',tfirst,n)  = 1e-5;

* OMEGA fixed in first period
OMEGA.fx(t,n)$tfirst(t) = 1
$if set damage_feedback  + (comega_pos('%damcost%',n,'deg1')*0.859 + comega_pos('%damcost%',n,'deg2')*0.859**comega_pos('%damcost%',n,'deg3')+comega_pos('%damcost%',n,'deg4'))
$if set damage_feedback  + (comega_neg('%damcost%',n,'deg1')*0.859 + comega_neg('%damcost%',n,'deg2')*0.859**comega_neg('%damcost%',n,'deg3')+comega_neg('%damcost%',n,'deg4'))
;
*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

$ifthen.f set damage_feedback
eqomega_%clt%

$iftheni.ada %adaptation%=='YES'
eqq_ada_%clt%
eqq_act_%clt%
eqq_cap_%clt%
eqq_gcap_%clt%
$endif.ada

$endif.f

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

$ifthen.f set damage_feedback

**damage function
eqomega_%clt%(tp1,t,n)$(mapn_th1('%clt%'))..
                OMEGA(tp1,n) =e= 1 + (comega_pos('%damcost%',n,'deg1')*TEMP('atm',tp1,n) +
                                        comega_pos('%damcost%',n,'deg2')*TEMP('atm',tp1,n)**comega_pos('%damcost%',n,'deg3') +
                                        comega_pos('%damcost%',n,'deg4'))
                                 + (comega_neg('%damcost%',n,'deg1')*TEMP('atm',tp1,n) +
                                        comega_neg('%damcost%',n,'deg2')*TEMP('atm',tp1,n)**comega_neg('%damcost%',n,'deg3') +
                                        comega_neg('%damcost%',n,'deg4'))
$ifi %adaptation%=='YES'       / ( 1 + Q('ADA',tp1,n)**ces_ada('exp',n) )
;

$iftheni.ada %adaptation%=='YES'
eqq_ada_%clt%(t,n)$(mapn_th('%clt%'))..   
            Q('ADA',t,n)  =e= ces_ada('tfpada',n)*(owa("act",n)*Q('ACT',t,n)**ces_ada('ada',n)+ owa("cap",n)*Q('CAP',t,n)**ces_ada('ada',n))**(1/ces_ada('ada',n));

eqq_act_%clt%(t,n)$(mapn_th('%clt%'))..   
            Q('ACT',t,n)  =e= ces_ada('eff',n) *owa('actc',n)*(owa("rada",n)*I('RADA',t,n)**ces_ada('act',n)+ owa("prada",n)*K('PRADA',t,n)**ces_ada('act',n))**(1/ces_ada('act',n));

eqq_cap_%clt%(t,n)$(mapn_th('%clt%'))..   
            Q('CAP',t,n)  =e= (owa("gcap",n)*Q('GCAP',t,n)**ces_ada('cap',n)+ owa("scap",n)*K('SCAP',t,n)**ces_ada('cap',n))**(1/ces_ada('cap',n));

eqq_gcap_%clt%(t,n)$(mapn_th('%clt%'))..  
            Q('GCAP',t,n) =e= ((k_h0(n)+k_edu0(n))/2)*tfpy(t,n);
$endif.ada

$endif.f

*-------------------------------------------------------------------------------
$elseif %phase%=='fix_variables'

$if set damage_feedback tfixvar(OMEGA,'(t,n)')

*-------------------------------------------------------------------------------
$elseif %phase%=='after_nashloop'

$if not set damage_feedback OMEGA.l(t,n)$(not tfix(t)) = 1;

$elseif %phase%=='summary_report'

parameter resdam(t,n) 'Residual damage [T$]';
resdam(t, n) = Q.l('y', t, n) * (OMEGA.l(t, n) - 1);

parameter grossdam(t,n) 'Gross damage [T$]';
grossdam(t,n) = Q.l('y', t, n) * ((comega_neg('%damcost%',n, 'deg1') + comega_pos('%damcost%',n, 'deg1')) * TEMP.l('atm', t, n) +
                                (comega_neg('%damcost%',n, 'deg2') + comega_pos('%damcost%',n, 'deg2')) * TEMP.l('atm', t, n) ** comega_neg('%damcost%',n,'deg3') +
                                (comega_neg('%damcost%',n, 'deg4') + comega_pos('%damcost%',n, 'deg4'))
                               );

parameter dam_rep(t,n,*) 'Damages in terms of OMEGA approx %GDP loss' ;
$ifthen.d set damage_feedback
dam_rep(t,n,'standard_gross') = (comega_pos('%damcost%',n,'deg1')*TEMP.l('atm',t,n) + comega_pos('%damcost%',n,'deg2')*TEMP.l('atm',t,n)**comega_pos('%damcost%',n,'deg3')+comega_pos('%damcost%',n,'deg4'))  +(comega_neg('%damcost%',n,'deg1')*TEMP.l('atm',t,n) + comega_neg('%damcost%',n,'deg2')*TEMP.l('atm',t,n)**comega_neg('%damcost%',n,'deg3')+comega_neg('%damcost%',n,'deg4'));
$if %adaptation%=='YES'   dam_rep(t,n,'standard_adapted') = (comega_neg('%damcost%',n,'deg1')*TEMP.l('atm',t,n) + comega_neg('%damcost%',n,'deg2')*TEMP.l('atm',t,n)**comega_neg('%damcost%',n,'deg3')+comega_neg('%damcost%',n,'deg4')) *(Q.l('ADA',t,n)**ces_ada('exp',n) / ( 1 + Q.l('ADA',t,n)**ces_ada('exp',n) ))
$endif.d

$elseif %phase%=='gdx_items'

* Parameters
ces_ada
comega_neg
comega_pos
k_edu0
k_h0
owa

* Variables
OMEGA

* Report parameters
resdam
grossdam
dam_rep

$endif
