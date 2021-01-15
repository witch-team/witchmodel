*-------------------------------------------------------------------------------
* Convergence algorithm
*-------------------------------------------------------------------------------
$set phase %1

*-------------------------------------------------------------------------------
$ifthen.a %phase%=='init'

parameters allerr(run,siter,*) 'error over iteration'
           errtrade(*,t) 'Sum over n of traded quantities';

parameter price_iter(run,siter,*,t)  "Price accross iteration";
parameter delta_price(run,siter,*,t) "Step price";

parameters allrho_admm(run,siter,*,t) 'rho value of the ADMM algorithm over iteration';
parameters allerr_admm(run,siter,*,t) 'error values algorithm over iteration by t';

set mkt(*) 'market collector';
mkt(c_mkt) = yes;
mkt(f_mkt) = yes;

set t_admm(*,t);

set external(*);
external(mkt)=yes;
external(mkt)$(internal(mkt))=no;

trading_t(mkt,t,n)$(tfix(t))=no;

* Period to evaluate the convergence of markets (oil, c_mkt, co2) and negishi weights
set tcheck(t);
tcheck(t) = yes$(year(t) le yeoh and year(t) le 2100);

parameter mbalance(run,siter,*,t)     "Balance of the market"
          trust_region(run,siter,*,t) "Maximal value on the absolute value of step price" ;

* Parameters for the "equilibrium" method
parameter price_eq(run,siter,*,t)     "Price according to the equilibrium algorithm"
          do_price_eq(run,siter,*,t)  "if 1, perform an equilibrium step"
          mprofit(run,siter,*,t,n);

do_price_eq(run,siter,mkt,t)=no;

* Parameters for the bissection method
parameter mbalance_rhs(run,siter,*,t),
          mbalance_lhs(run,siter,*,t),
          price_rhs(run,siter,*,t),
          price_lhs(run,siter,*,t),
          do_bissection(run,siter,*,t);

do_bissection(run,siter,mkt,t) = no;

* COALITION CODE
parameter w_negishi(t,n),
          w_negishi_iter(run,siter,t,n);
w_negishi(t,n)$(sum(clt$(map_clt_n(clt,n) and negishi_coop(clt,n)),1) eq 0) = 1;
w_negishi(t,n)$(sum(clt$(map_clt_n(clt,n) and negishi_coop(clt,n)),1) eq 1) = ((Q.l('CC',t,n)/l(t,n))**(eta))/(sum((nn,clt)$(map_clt_n(clt,n) and map_clt_n(clt,nn)),(Q.l('cc',t,nn)/l(t,nn))**(eta)));
w_negishi_iter(run,siter,t,n)$(ord(siter) eq 1)= w_negishi(t,n);

parameter m_consumption(t,clt);
parameter m_eqq_cc(t,tp1,n),
          m_eq_mkt_clearing(*,t,clt),
          m_eq_mkt_clearing_oil(t,clt),
          m_eq_mkt_clearing_nip(*,t,clt);

* initialization
m_eq_mkt_clearing_oil(t,clt) = 0;
m_eq_mkt_clearing_nip(c_mkt,t,clt) = 0;

* Set default values if starting values are zeros
loop((c_mkt,t)$((not tfix(t)) and (sum(n$trading_t(c_mkt,t,n),1)>0) and (CPRICE.l(c_mkt,t)) eq 0),
  CPRICE.l(c_mkt,t) = 30 * (1 + 0.03)**(year(t) - 2020) * c2co2 * 1e-3; 
);
loop((f_mkt,t)$((not tfix(t)) and (sum(n$trading_t(f_mkt,t,n),1)>0) and (FPRICE.l(f_mkt,t)) eq 0),
  FPRICE.l(f_mkt,t) = 1e-5;
);

* Define default trust_region
trust_region(run,siter, c_mkt, t) = 0.15 * CPRICE.l(c_mkt, t);
trust_region(run,siter, f_mkt, t) = 0.15 * FPRICE.l(f_mkt, t);

*-------------------------------------------------------------------------------
$elseif.a %phase%=='internal_markets'

* delta price is equal to the dual of the market clearing equation
* Oil Market
if(internal('oil'),

$batinclude 'algo/get_marginal' eqq_cc (t,tp1,n) regional %coalitions%
$batinclude 'algo/get_marginal' eq_mkt_clearing_oil (t,clt) coalitional %coalitions%

m_consumption(t,clt) = sum((n,tp1)$mapn_th1_last(clt),m_eqq_cc(t,tp1,n))/sum(n$map_clt_n(clt,n),1);
delta_price(run,siter,'oil',t)$(not tfix(t)) = (sum(clt$internal_clt('oil',clt),m_eq_mkt_clearing_oil(t,clt)/m_consumption(t,clt)))$(smin(clt$internal_clt('oil',clt),m_consumption(t,clt)) gt eps);

);
* Permit Markets
loop(c_mkt$internal(c_mkt),

$batinclude 'algo/get_marginal' eqq_cc (t,tp1,n) regional %coalitions%
$batinclude 'algo/get_marginal' eq_mkt_clearing_nip (c_mkt,t,clt) coalitional %coalitions%

m_consumption(t,clt) = sum((n,tp1)$mapn_th1_last(clt),m_eqq_cc(t,tp1,n))/sum(n$map_clt_n(clt,n),1);
delta_price(run,siter,c_mkt,t)$(not tfix(t)) = (sum(clt$internal_clt(c_mkt,clt),m_eq_mkt_clearing_nip(c_mkt,t,clt)/m_consumption(t,clt)))$(smin(clt$internal_clt(c_mkt,clt),m_consumption(t,clt)) gt eps);

);

*-------------------------------------------------------------------------------
$elseif.a %phase%=='negishi_weights'

loop((t,n),
  if(sum(clt$(map_clt_n(clt,n) and negishi_coop(clt,n)),1) eq 0,
    w_negishi(t,n) = 1;
  else
    w_negishi(t,n) = ((Q.l('CC',t,n)/l(t,n))**(eta)) / sum((nn,clt)$(map_clt_n(clt,n) and map_clt_n(clt,nn)),(Q.l('cc',t,nn)/l(t,nn))**(eta))
  )
);
w_negishi_iter(run,siter+1,t,n) = w_negishi(t,n);

*-------------------------------------------------------------------------------
$elseif.a %phase%=='check_convergence'

* Relative variation in investments
* expressed in terms of [% of current total investment].
allerr(run,siter,'inv') = 100 * sum((t,n)$(tcheck(t)),
                              abs(I.l('fg',t,n)-LAST_I.l('fg',t,n)) +
                              sum(jinv, abs(I_EN.l(jinv,t,n)-LAST_I_EN.l(jinv,t,n))) +
                              sum(rd, abs(I_RD.l(rd,t,n)-LAST_I_RD.l(rd,t,n))) +
                              sum(extract(f), abs(I_OUT.l(f,t,n)-LAST_I_OUT.l(f,t,n)))
                              ) /
                            sum((t,n)$(tcheck(t)),
                              I.l('fg',t,n) +
                              sum(rd,I_RD.l(rd,t,n)) * rd_crowd_out +
                              sum(jinv, I_EN.l(jinv,t,n)) +
                              sum(extract(f), I_OUT.l(f,t,n))
                              );

* Variation in COST_FUEL
* expressed in terms of [% of total level of consumption].
allerr(run,siter,'pes') = 100 * sum((t,f,n)$(tcheck(t)), abs(COST_FUEL.l(f,t,n)-LAST_COST_FUEL.l(f,t,n))) / sum((t,n)$(tcheck(t)),Q.l('CC',t,n));

* External markets [market between coalitions]
* Variation in cost of oil
* expressed in terms of [% of total level of consumption].
errtrade('oil',tcheck(t)) = sum(n$trading_t('oil',t,n), Q_FUEL.l('oil',t,n) - Q_OUT.l('oil',t,n));
allerr(run,siter,'oil')$(external('oil')) = 100 * sum(tcheck(t)$(sum(n$(trading_t('oil',t,n)),1)>0),
                                                 abs(errtrade('oil',t)) * FPRICE.l('oil',t)
                                                 ) / (sum((tcheck(t),n)$(trading_t('oil',t,n)),Q.l('CC',t,n)) + 1e-5);

* Variation in cost of nip
* expressed in terms of [% of total level of consumption].
errtrade(c_mkt,tcheck(t)) = sum(n$trading_t(c_mkt,t,n), Q_EMI.l(c_mkt,t,n));
allerr(run,siter,c_mkt)$(external(c_mkt)) = 100 * sum(tcheck(t)$(sum(n$(trading_t(c_mkt,t,n)),1)>0),
                                                 abs(errtrade(c_mkt,t)) * CPRICE.l(c_mkt,t)
                                                 ) / (sum((tcheck(t),n)$(trading_t(c_mkt,t,n)),Q.l('CC',t,n)) + 1e-5);

* Internal markets [market within coalition]
* Price variation
* expressed in terms of [% of world price].
allerr(run,siter,c_mkt)$(internal(c_mkt)) = 100 * sum(tcheck(t)$(sum(n$(trading_t(c_mkt,t,n)),1)>0), div0(abs(delta_price(run,siter,c_mkt,t)),CPRICE.l(c_mkt,t)));
allerr(run,siter,f_mkt)$(internal(f_mkt)) = 100 * sum(tcheck(t)$(sum(n$(trading_t(f_mkt,t,n)),1)>0), div0(abs(delta_price(run,siter,f_mkt,t)),FPRICE.l(f_mkt,t)));

* Excess permits of CO2
* expressed in terms of [% of total of allowed emission].
if(sum((c_mkt,t,n)$trading_t(c_mkt,t,n),1),
  allerr(run,siter, 'co2') = 100 * sum((tcheck(t),c_mkt), abs(errtrade(c_mkt,t))) /
                               sum((tcheck(t),n,c_mkt)$trading_t(c_mkt,t,n),emi_cap(t,n))
);

* Relative variation in Negishi weigths
* expressed in terms of [% of last seen value].
allerr(run,siter,'wgt') = 100 * sum((tcheck(t), n)$w_negishi_iter(run,siter+1, t, n), abs(w_negishi_iter(run,siter+1, t, n) - w_negishi_iter(run,siter, t, n)) / w_negishi_iter(run,siter+1, t, n));

*-------------------------------------------------------------------------------
$elseif.a %phase%=='external_markets'

price_iter(run,siter,f_mkt, t) = FPRICE.l(f_mkt, t);
price_iter(run,siter,c_mkt, t) = CPRICE.l(c_mkt, t);

* External markets [market between coalitions]
mprofit(run,siter, 'oil', t,n)$(trading_t('oil', t, n)) = -(Q_FUEL.l('oil',t,n) - Q_OUT.l('oil',t,n)) * FPRICE.l('oil',t);
mprofit(run,siter, c_mkt, t,n)$(trading_t(c_mkt, t, n)) = -Q_EMI.l(c_mkt,t,n) * CPRICE.l(c_mkt,t);

mbalance(run,siter, 'oil', t) = sum(n$trading_t('oil',t,n), Q_FUEL.l('oil',t,n) - Q_OUT.l('oil',t,n));
mbalance(run,siter, c_mkt, t) = sum(n$trading_t(c_mkt,t,n), Q_EMI.l(c_mkt,t,n));

price_eq(run,siter, c_mkt, t)$(external(c_mkt) and all_optimal(run,siter) and (sum(n$trading_t(c_mkt,t,n),1) gt 0) ) = CPRICE.l(c_mkt,t) * sum(n$trading_t(c_mkt,t,n), Q.l('CC',t,n) - mprofit(run,siter,c_mkt,t,n))/sum(n$trading_t(c_mkt,t,n), Q.l('CC',t,n));
price_eq(run,siter, f_mkt, t)$(external(f_mkt) and all_optimal(run,siter) and (sum(n$trading_t(f_mkt,t,n),1) gt 0) ) = FPRICE.l(f_mkt,t) * sum(n$trading_t(f_mkt,t,n), Q.l('CC',t,n) - mprofit(run,siter,f_mkt,t,n))/sum(n$trading_t(f_mkt,t,n), Q.l('CC',t,n));

*-------------------------------------------------------------------------------
$elseif.a %phase%=='update_price'

* Update fuel price
loop(f_mkt,
  if ( (ord(siter) eq 1) and external(f_mkt),
    FPRICE.l(f_mkt,t)$(do_price_eq(run,siter,f_mkt,t) and (not tfix(t))) = FPRICE.l(f_mkt,t) + delta_price(run,siter,f_mkt,t);
    FPRICE.l(f_mkt,t)$((not do_price_eq(run,siter,f_mkt,t)) and (not tfix(t)))= price_iter(run,siter,f_mkt,t)+sign(mbalance(run,siter,f_mkt,t))*0.05*price_iter(run,siter,f_mkt,t);
    trust_region(run,siter,f_mkt,t)$(not tfix(t)) = abs(0.05 * price_iter(run,siter,f_mkt,t));
  else
    FPRICE.l(f_mkt,t)$(not tfix(t)) = price_iter(run,siter,f_mkt,t) + delta_price(run,siter,f_mkt,t);
  );
  FPRICE.l(f_mkt,t)$((sum(n$trading_t(f_mkt,t,n),1) eq 0) and (not tfix(t))) = 0;
  price_iter(run,siter+1,f_mkt,t) = FPRICE.l(f_mkt,t);
);

* Update permit price
loop(c_mkt,
  if ( (ord(siter) eq 1) and external(c_mkt),
    CPRICE.l(c_mkt,t)$(do_price_eq(run,siter,c_mkt,t) and (not tfix(t))) = CPRICE.l(c_mkt,t) + delta_price(run,siter,c_mkt,t);
    CPRICE.l(c_mkt,t)$((not do_price_eq(run,siter,c_mkt,t)) and (not tfix(t)))= price_iter(run,siter,c_mkt,t)+sign(mbalance(run,siter,c_mkt,t))*0.05*price_iter(run,siter,c_mkt,t);
    trust_region(run,siter,c_mkt,t)$(not tfix(t)) = abs(0.05 * price_iter(run,siter,c_mkt,t));
  else
    CPRICE.l(c_mkt,t)$(not tfix(t)) = price_iter(run,siter,c_mkt,t) + delta_price(run,siter,c_mkt,t);
  );
  CPRICE.l(c_mkt,t)$((sum(n$trading_t(c_mkt,t,n),1) eq 0) and (not tfix(t))) = 0;
  price_iter(run,siter+1,c_mkt,t) = CPRICE.l(c_mkt,t);
);

$endif.a

$batinclude algo/conv_%algo% %phase%