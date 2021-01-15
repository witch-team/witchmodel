*-------------------------------------------------------------------------------
* Advanced biofuel
* - Require the precedence of mod_landuse
*-------------------------------------------------------------------------------

$ifthen %phase%=='sets'

set fuel / advbiofuel 'Advanced biofuel' /;
set s(fuel) / advbiofuel /;

set j 'Energy Technology Sectors' /nelback/;

set jreal(j) 'Actual Energy Technology Sectors' /nelback/;
set jnel(jreal) 'Non-electrical Actual Energy Technology Sectors' /nelback/;
set jfed(jreal) 'Actual Energy Technology Sectors fed by PES' /nelback/;
set jnel_ren(jreal) 'Renewable power generation technologies' /nelback/;

set map_j(j,jj) 'Relationships between Energy Technology Sectors' /
    neloilback.nelback
/;

* Knowledge
set rd(j) 'R & D' / nelback/;
set jrd(jreal) / nelback/;
set jrd_lbd(jrd) /nelback/;

leadrd('nelback',n)$(oecd(n)) = yes;
jmcost_inv('nelback')         = yes;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

mcost_inv0('nelback',n) = 0.00035;

* Initial advanced biofuel production
scalar q_en0_back / 1e-6 /;

scalar alp_nelback / 0.75 /;

* nelback R&D
rd_delta('nelback') = 0.05;
krd0('nelback',n)   = 0.000478096153846154;
rd_coef('nelback','a')    = 1;
rd_coef('nelback','b')    = 0.85;
rd_coef('nelback','c')    = 0;
rd_coef('nelback','lbr')  = -0.2;
rd_coef('nelback','lbd')  = -0.15;
rd_coef('nelback','wcum0') = 277.777;
rd_time('nelback','gap') = 10; # years
rd_time('nelback','start') = 2020;

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

Q_FUEL.lo('advbiofuel',t,n)$(not tfix(t)) = q_en0_back; 
Q_FUEL.fx('advbiofuel',t,n)$((not tfix(t)) and (year(t) le 2010)) = q_en0_back; 

Q_IN.lo('advbiofuel','nelback',t,n)$(not tfix(t)) = q_en0_back;
Q_IN.fx('advbiofuel','nelback',t,n)$((not tfix(t)) and (year(t) le 2010)) = q_en0_back;

MCOST_INV.fx('nelback',t,n)$((not tfix(t)) and (year(t) lt rd_time('nelback','start'))) = mcost_inv0('nelback',n);
MCOST_FUEL.fx('advbiofuel',t,n)$((not tfix(t)) and (year(t) lt rd_time('nelback','start'))) = mcost_inv0('nelback',n);
MCOST_FUEL.scale('advbiofuel',t,n) = 1e-3;

* No investments in backstop RD for the first 2 periods
loop((t,tp1)$pre(t,tp1),
I_RD.fx('nelback',t,n)$((not tfix(tp1)) and (year(t) le 2010)) = 1e-10;
);

* RnD leader also in China, same regions as for battery!
leadrd('nelback',n)$battery_leadrd(n) = yes;

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eqq_en_lim_advbiofuel_%clt%
eqmcost_fuel_advbiofuel_%clt%
    
*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

* Limitations for nel backstops
eqq_en_lim_advbiofuel_%clt%(t,tp1,n)$(mapn_th1('%clt%'))..
             Q_FUEL('advbiofuel',tp1,n) - Q_FUEL('advbiofuel',t,n) =l=
             alp_nelback * (1-(Q_FUEL('advbiofuel',tp1,n)/Q_FUEL.up('advbiofuel',tp1,n))) * Q_FUEL('advbiofuel',tp1,n);

* Peculiarity of advbiofuel
eqmcost_fuel_advbiofuel_%clt%(t,n)$(mapn_th('%clt%'))..
                MCOST_FUEL('advbiofuel',t,n) =e= MCOST_INV('nelback',t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

loop((t,tp1)$pre(t,tp1),
  wcum('nelback',tp1) = wcum('nelback',t) + tlen(t) * sum(n, Q_FUEL.l('advbiofuel',t,n));
);

Q_FUEL.up('advbiofuel',t,n)$(not tfix(t)) = Q_FUEL.up('wbio',t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Parameters
alp_nelback
q_en0_back

$endif
