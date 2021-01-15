*-------------------------------------------------------------------------------
* Tâtonnement algorithm
*-------------------------------------------------------------------------------
$set phase %1

*-------------------------------------------------------------------------------
$ifthen.a %phase%=='init'

* COMPUTATIONAL PARAMETERS FOR EXTERNAL MARKETS
*  cvg_step1: Start to do some "equilibrium" steps when
*             convergence reaches that value (1 over 3 steps).
*                         Recommended value: (0.5-1).
*             To speed up the solution time, you may want to decrease it
*             in order to do more steps with the tatonement algorithm
*  cvg_step2: The algorithm only does "equilibrium" steps when this convergence
*                         has been reached.
*                         If you have problem to obtain a solution => increase it
*             If the equilibrium algorithm takes too much times => decrease it
*             Recommended value: (0.05-0.07), clearly depends on convergence tol
scalar cvg_step1 /0.1/;
scalar cvg_step2 /0.007/;

*-------------------------------------------------------------------------------
$elseif.a %phase%=='external_markets'

loop(mkt$external(mkt),

  # KNOWN BUG: If during the 5 last iterations, all balances have the same sign then mabalance_{rhs,lhs} is not defined
  # (a) Get the market balance equation sides
  mbalance_rhs(run,siter, mkt, t) = smax(ssiter$(last_iter(5) and (mbalance(run,ssiter, mkt, t) lt 0)), mbalance(run,ssiter, mkt, t));
  mbalance_lhs(run,siter, mkt, t) = smin(ssiter$(last_iter(5) and (mbalance(run,ssiter, mkt, t) gt 0)), mbalance(run,ssiter, mkt, t));

  # KNOWN BUG: If during the 5 last iterations, all prices have the same sign then price__{rhs,lhs} is not defined
  # (b) If market is clear, get the price equation sides
  price_rhs(run,siter, mkt, t) = smax(ssiter$(last_iter(5) and (mbalance(run,ssiter, mkt, t) eq mbalance_rhs(run,siter, mkt, t))), price_iter(run,ssiter, mkt,t));
  price_lhs(run,siter, mkt, t) = smin(ssiter$(last_iter(5) and (mbalance(run,ssiter, mkt, t) eq mbalance_lhs(run,siter, mkt, t))), price_iter(run,ssiter, mkt,t));

  # (c) Determine when to do bissection method
  do_bissection(run,siter, mkt, t)$(price_rhs(run,siter, mkt, t) gt price_lhs(run,siter, mkt, t)) = yes;

  loop((t,ssiter)$(do_bissection(run,siter,mkt,t) and last_iter(5) and do_bissection(run,ssiter,mkt,t) and (ord(ssiter) ne ord(siter))),
    do_bissection(run,siter,c_mkt,t)$((price_lhs(run,siter,mkt,t) eq price_lhs(run,ssiter,mkt,t)) and (price_rhs(run,siter,mkt,t) eq price_rhs(run,ssiter,mkt,t))) = no;
  );


  # (d) Bissection method
  delta_price(run,siter,mkt,t)$(do_bissection(run,siter,mkt,t)) = price_lhs(run,siter,mkt,t) - price_iter(run,siter,mkt,t) +
                                                              (price_rhs(run,siter,mkt,t)-price_lhs(run,siter,mkt,t)) *
                                                              mbalance_lhs(run,siter,mkt,t) / (mbalance_lhs(run,siter,mkt,t)-mbalance_rhs(run,siter,mkt,t));

  # (e) Secant method
  delta_price(run,siter,mkt,t)$(not do_bissection(run,siter,mkt,t)) = - mbalance(run,siter,mkt,t) *
                                                               (price_iter(run,siter,mkt,t) - price_iter(run,siter-1,mkt,t)) /
                                                               (mbalance(run,siter,mkt,t) - mbalance(run,siter-1,mkt,t) + 1e-12);

  # (f) Update the trust_region
  trust_region(run,siter,mkt,t)$(sign(mbalance(run,siter,mkt,t)) ne sign(mbalance(run,siter-1,mkt,t))) = max( 0.6 * trust_region(run,siter-1,mkt,t),
                                                                                                  1e-6 * price_iter(run,siter,mkt,t));
  trust_region(run,siter,mkt,t)$(sign(mbalance(run,siter,mkt,t)) eq sign(mbalance(run,siter-1,mkt,t))) = trust_region(run,siter-1, mkt, t);

  # (g) If closer enough to the solution, perform an equilibrium step only every 3 iterations
  do_price_eq(run,siter,c_mkt,t)$((allerr(run,siter,c_mkt) le cvg_step1) and (mod((ord(siter)),3) eq 1)) = yes;

  # (h) If you are very close to the solution, perform an equilbrium step
  do_price_eq(run,siter,mkt,t)$(allerr(run,siter,mkt) le cvg_step2) = yes;

  # (i) prevent the equilibrium step in some cases
  do_price_eq(run,siter,mkt,t)$(not all_optimal(run,siter)) = no;
  do_price_eq(run,siter,mkt,t)$((abs(price_eq(run,siter,mkt,t) - price_iter(run,siter,mkt,t))/(price_eq(run,siter,mkt,t)+1e-12)) ge 0.1) = no;

  # (j) Update the trust region when no equilibrium step and the last 3 iteration mbalance have the same sign
  trust_region(run,siter,mkt,t)$((not do_price_eq(run,siter,mkt,t)) and
                             (abs(sum(ssiter$last_iter(3),sign(mbalance(run,ssiter,mkt,t))))eq sum(ssiter$last_iter(3),1))
                            ) = min(1.2 * trust_region(run,siter-1,mkt,t), 0.1 * price_iter(run,siter,mkt,t));

  # (k) Adjust delta price according the chosen method
  delta_price(run,siter,mkt,t)$(not do_bissection(run,siter,mkt,t)) = sign(mbalance(run,siter,mkt,t)) *
                                                                  min(trust_region(run,siter,mkt,t), abs(delta_price(run,siter,mkt,t)));
  delta_price(run,siter,mkt,t)$(not do_price_eq(run,siter,mkt,t) and (abs(delta_price(run,siter,mkt,t)) le (1e-7 * price_iter(run,siter,mkt,t)))) =
                                                              sign(mbalance(run,siter,mkt,t)) * trust_region(run,siter,mkt,t);
  delta_price(run,siter,mkt,t)$(do_price_eq(run,siter,mkt,t)) = price_eq(run,siter,mkt,t) - price_iter(run,siter,mkt,t);

);

$endif.a