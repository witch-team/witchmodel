*-------------------------------------------------------------------------------
* Research & Development
* Options:
*  - $setglobal rd_myopic_iter: Reset knowledge variables for the first 3 Nash iterations
*  - $setglobal cooperate_on_rd: Regions cooperation within coalitions on R&D
*-------------------------------------------------------------------------------

$ifthen %phase%=='sets'

set rd(j) 'Energy sectors or technologies with R&D' / /;

set jrd(jreal) 'Technologies with R&D' / /;

set jrd_lbd(jrd) 'Technologies with learning-by-doing';

set leadrd(rd,n) 'Regions which are leader in R&D innovation';

set rd_cooperation(rd,clt) 'cooperation in R&D inside coalition';
rd_cooperation(rd,clt) = no; # By default, no R&D cooperation

set rd_tgap(jrd,t,tt) 'reference period for learning cost equations';

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

parameter rd_delta(rd) 'R&D depreciation rate';
rd_delta(rd) = 0.05; 

scalar rd_crowd_out 'R&D crowding out';
rd_crowd_out = 4;

* R&D learning equation coefficients (rd,param)
* a: scale parameter [T$]
* b = 0.18 (for 'en', slightly higher elasticity to the own investments)
* c = 0.38 since Popp (2004, JEEM) has 0.53 for the total effect from knowledge stock minus the own knowledge stock 0.53-0.15=0.38 
* d = 0.15: 1% increase in spillovers increases output of domestic ideas by 0.15%
* wcum0: Initial cumulative capacity
* lbr: learning by researching rate
* lbd: learning by doing rate
parameter rd_coef(*,*) 'R&D learning equation coefficients';
rd_coef(jrd,'krd0_year') = 2005;

* R&D learning timing (rd,param)
* gap: number of year after learning
* start: starting year for endogenous learning
parameter rd_time(jrd,*) 'R&D learning timing';

parameter krd0(rd,n) 'Initial R&D capital';
parameter wkrd0(rd) 'Initial average R&D capital in leader regions';

parameter krd_lead(rd,t) 'Total R&D capital in leader regions';
parameter krd_oth_lead_krd(rd,t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

wcum(rd,tfirst) = rd_coef(rd,'wcum0');

* Map a period to its learning reference period.
* Example: if all periods last 5 years and rd_gap_year is 10 years, then 
* the period to consider is the second predecessor (t-2).
loop(jrd,
rd_tgap(jrd,t,tt) = no;
loop((t,tt)$(not tfix(t) and 
  preds(t,tt) and 
  (year(t) ge rd_time(jrd,'start')) and
  (begyear(t)-rd_time(jrd,'gap') ge begyear(tt)) and 
  (begyear(t)-rd_time(jrd,'gap') lt begyear(tt)+tlen(tt))),
rd_tgap(jrd,t,tt) = yes;
);
);

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

positive variable I_RD(rd,t,n) 'Investments in R&D [T$]';
loadvarbnd(I_RD,'(rd,t,n)',1e-5,1e-10,+inf);
I_RD.scale(rd,t,n) = 1e-3;

positive variable K_RD(rd,t,n) 'Capital in R&D [T$]';
loadvarbnd(K_RD,'(rd,t,n)',1e-5,1e-7,+inf);
K_RD.l(rd,t,n)$(K_RD.l(rd,t,n) eq 0) = K_RD.lo(rd,t,n);
K_RD.fx(rd,tfirst,n) = max(krd0(rd,n),K_RD.lo(rd,tfirst,n));
K_RD.scale(rd,t,n) = 1e-3;

positive variable SPILL(rd,t,n) 'Spill ratio * K_RD(leaders)';
loadvarbnd(SPILL,'(rd,t,n)',1e-5,1e-8,+inf);

krd_lead(rd,t) = sum(n$leadrd(rd,n), K_RD.l(rd,t,n));
krd_oth_lead_krd(rd,t,n)$leadrd(rd,n) = krd_lead(rd,t) - K_RD.l(rd,t,n);

parameter wlspill_k_rd(rd,t,n);
wlspill_k_rd(rd,tfirst,n) = 0;

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eqk_rd_%clt%
eqspill_coop_%clt%
eqspill_lead_%clt%
eqspill_foll_%clt%
eqmcost_inv_back_%clt%
eqmcost_inv_back_lbd_%clt%

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

* Knowledge stock accumulation
eqk_rd_%clt%(rd,t,tp1,n)$(mapn_th1('%clt%'))..
                K_RD(rd,tp1,n) =e= K_RD(rd,t,n)*(1-rd_delta(rd))**tlen(t)
                                      +tlen(t)*rd_coef(rd,'a')*I_RD(rd,t,n)**rd_coef(rd,'b') *
                                      K_RD(rd,t,n)**rd_coef(rd,'c') *
                                      SPILL(rd,t,n)**rd_coef(rd,'d');

* Cooperation : internalize the externalities due the spillovers (but only optimize over the regions inside the coalition)
eqspill_coop_%clt%(rd,t,n)$(mapn_th('%clt%') and rd_cooperation(rd,'%clt%'))..
        SPILL(rd,t,n) =e= K_RD(rd,t,n) / 
                          ( sum(nn$(leadrd(rd,nn) and map_clt_n('%clt%',nn)), K_RD(rd,t,nn)) + 
                            sum(nn$(leadrd(rd,nn) and (not map_clt_n('%clt%',nn))), K_RD.l(rd,t,nn))
                          ) * 
                          (
                            ( sum(nn$(leadrd(rd,nn) and map_clt_n('%clt%',nn)), K_RD(rd,t,nn)) +
                              sum(nn$(leadrd(rd,nn) and (not map_clt_n('%clt%',nn))), K_RD.l(rd,t,nn))
                            ) - K_RD(rd,t,n)
                          );

* No-cooperation : a leader sees is negative effect when he is closed to the frontier
eqspill_lead_%clt%(rd,t,n)$(mapn_th('%clt%') and (not rd_cooperation(rd,'%clt%')) and leadrd(rd,n))..
                SPILL(rd,t,n) =e= K_RD(rd,t,n)/(krd_oth_lead_krd(rd,t,n)+K_RD(rd,t,n)) * krd_oth_lead_krd(rd,t,n);

* No-cooperation : a follower sees is negative effect on the quantity he can grab
eqspill_foll_%clt%(rd,t,n)$(mapn_th('%clt%') and (not rd_cooperation(rd,'%clt%')) and (not leadrd(rd,n)))..
                SPILL(rd,t,n) =e= K_RD(rd,t,n)/krd_lead(rd,t) * (krd_lead(rd,t)-K_RD(rd,t,n));

*- Only LbR (without learning by doing)
eqmcost_inv_back_%clt%(jrd,t,tt,n)$(mapn_th('%clt%') and rd_tgap(jrd,t,tt) and (not jrd_lbd(jrd)))..
                MCOST_INV(jrd,t,n) =e= sum(ttt$(year(ttt) eq rd_coef(jrd,'krd0_year')),MCOST_INV(jrd,ttt,n)) *
                                       (sum(rd$(sameas(rd,jrd)), K_RD(rd,tt,n)/wkrd0(rd)))**rd_coef(jrd,'lbr');

*- LbR together with learning by doing ==> Two-factor learning curve
eqmcost_inv_back_lbd_%clt%(jrd,t,tt,tfirst,n)$(mapn_th('%clt%') and rd_tgap(jrd,t,tt) and jrd_lbd(jrd))..
                MCOST_INV(jrd,t,n) =e= MCOST_INV(jrd,tfirst,n) *
                                       (sum(rd$(sameas(rd,jrd)), K_RD(rd,tt,n)/wkrd0(rd)))**rd_coef(jrd,'lbr') *
                                       (wcum(jrd,t)/wcum(jrd,tfirst))**rd_coef(jrd,'lbd');

*-------------------------------------------------------------------------------
$elseif %phase%=='fix_variables'

tfix1var(I_RD,'(rd,t,n)')
tfixvar(K_RD,'(rd,t,n)')
tfixvar(SPILL,'(rd,t,n)')

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

wkrd0(rd) = sum(n$leadrd(rd,n), krd0(rd,n)) / sum(n$leadrd(rd,n), 1);

$ifthen.cr set rd_myopic_iter
*
* rd_myopic_iter:  - No anticipation of learning-by-doing, i.e. wcum(t) = wcum(tfirst) 
*             - No anticipation of the (positive) externalities from other players, i.e. K_RD.l(t,n)=K_RD(tfirst,n)
*  
if(ord(siter) le 3,

wcum(jrd,t)$(jrd_lbd(jrd) and not tfix(t)) = sum(tfirst,wcum(jrd,tfirst));

K_RD.l(rd,t,n)$((not sameas(rd,'en')) and (tnofirst(t)) and (not tfix(t))) = max(K_RD.lo(rd,t,n), sum(tfirst,K_RD.l(rd,tfirst,n)));

krd_lead(rd,t) = sum(n$leadrd(rd,n), K_RD.l(rd,t,n));
krd_oth_lead_krd(rd,t,n)$leadrd(rd,n) = krd_lead(rd,t) - K_RD.l(rd,t,n);

* Reset quantities and prices of jrd techs
MCOST_INV.l(jrd,t,n)$(not tfix(t)) = mcost_inv0(jrd,n);
Q_EN.l(jrd,t,n)$(not tfix(t)) = Q_EN.lo(jrd,t,n);
* Reset quantities and prices of jrd fuels
loop((jrd,fuel)$sum((t,n),cast(csi(fuel,jfed,t,n),jfed,jrd)),
    # All inputs to technologies fed with fuels linked to a jrd are reset 
    Q_IN.l(fuel,jfed,t,n)$((csi(fuel,jfed,t,n)) and (not tfix(t))) = Q_IN.lo(fuel,jfed,t,n);
    Q_FUEL.l(fuel,t,n)$(not tfix(t)) = Q_FUEL.lo(fuel,t,n);
    # All costs of fuels linked to a jrd are reset 
    MCOST_FUEL.l(fuel,t,n)$(not tfix(t)) = mcost_inv0(jrd,n);
);

SPILL.l(rd,t,n)$((not tfix(t)) and (leadrd(rd,n))) = K_RD.l(rd,t,n)/(krd_oth_lead_krd(rd,t,n)+K_RD.l(rd,t,n))*krd_oth_lead_krd(rd,t,n);
SPILL.l(rd,t,n)$((not tfix(t)) and (not leadrd(rd,n))) = K_RD.l(rd,t,n)/krd_lead(rd,t)*(krd_lead(rd,t)-K_RD.l(rd,t,n));

);
$endif.cr

*- updating externalities
krd_lead(rd,t) = sum(n$leadrd(rd,n), K_RD.l(rd,t,n));
krd_oth_lead_krd(rd,t,n)$leadrd(rd,n) = krd_lead(rd,t) - K_RD.l(rd,t,n);

*-initialisation of the SPILL variable
if(ord(siter) eq 1,
SPILL.l(rd,t,n)$((not tfix(t)) and (leadrd(rd,n))) = K_RD.l(rd,t,n)/(krd_oth_lead_krd(rd,t,n)+K_RD.l(rd,t,n))*krd_oth_lead_krd(rd,t,n);
SPILL.l(rd,t,n)$((not tfix(t)) and (not leadrd(rd,n))) = K_RD.l(rd,t,n) /krd_lead(rd,t)*(krd_lead(rd,t)-K_RD.l(rd,t,n));
);

wlspill_k_rd(rd,t,n) = smax(nn, K_RD.l(rd,t,nn)) - K_RD.l(rd,t,n);

$elseif %phase%=='gdx_items'

* Sets
jrd
jrd_lbd
leadrd
rd
rd_cooperation
rd_tgap

* Parameters
rd_coef
rd_delta
krd0
rd_crowd_out
krd_lead
krd_oth_lead_krd
wkrd0
wlspill_k_rd

* Variables
I_RD
K_RD
SPILL

$endif
