*-------------------------------------------------------------------------------
* Traditional Biofuels
* - Requires the precedence of mod_landuse
*-------------------------------------------------------------------------------

$ifthen %phase%=='sets'

set fuel / trbiofuel 'Traditional biofuel' /;
set s(fuel) / trbiofuel /;

set j 'Energy Technology Sectors' /neltrbiofuel/;

set jreal(j) 'Actual Energy Technology Sectors' /neltrbiofuel/;
set jnel(jreal) 'Non-electrical Actual Energy Technology Sectors' /neltrbiofuel/;
set jfed(jreal) 'Actual Energy Technology Sectors fed by PES' /neltrbiofuel/;
set jnel_ren(jreal) 'Renewable power generation technologies' /neltrbiofuel/;

set map_j(j,jj) 'Relationships between Energy Technology Sectors' /
    nelbio.neltrbiofuel
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_mod_trbiofuel'

* Maximum traditionnal biofuel production
parameter trbiofuel_max(n) 'Max traditionnal Biofuel production';
$loaddc trbiofuel_max

$gdxin


*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

MCOST_FUEL.fx('trbiofuel',t,n)$(not tfix(t)) = FPRICE.l('trbiofuel',t) + p_mkup('trbiofuel',t,n);

* Maximum tradional biofuel consumption
* Initial bound
Q_FUEL.up('trbiofuel',t,n) = sum(nn,trbiofuel_max(nn));

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

* If more world demand than world production potential, adjust bounds
loop(t$(not tfix(t) and year(t)<=2100),
if( sum(n, Q_FUEL.l('trbiofuel',t,n)) > sum(n,trbiofuel_max(n)) ,

else

Q_FUEL.up('trbiofuel',t,n) = sum(nn,trbiofuel_max(nn));

);
);

$endif
