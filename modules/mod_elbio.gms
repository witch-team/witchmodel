*-------------------------------------------------------------------------------
* Bioenergy power plant
*-------------------------------------------------------------------------------

$ifthen %phase%=='sets'

set fuel / wbio 'solid biomass for biomass plant' /;

set j 'Energy Technology Sectors' /
    elpb
    elpb_new
    elpb_old
    elbigcc
/;

set jreal(j) 'Actual Energy Technology Sectors' /
    elpb_new
    elpb_old
    elbigcc
/;

set jel(jreal) 'Electrical Actual Energy Technology Sectors' /
    elpb_new
    elpb_old
    elbigcc
/;

set jel_bio(jel) 'Biomass power plants' /
    elpb_new
    elpb_old
    elbigcc
/;

set jfed(jreal) 'Actual Energy Technology Sectors fed by PES' /
    elpb_new
    elpb_old
    elbigcc
/;

set jinv(jreal) 'Electrical Actual Energy Technology Sectors with investments' /
    elpb_new
    elbigcc
/;

set jold(jel) 'Old Electrical Actual Energy Technology Sectors' /
    elpb_old
/;

set jel_ren(jel) 'Renewable power generation technologies' /
    elpb_new
    elpb_old
    elbigcc
/;

set map_j(j,jj) 'Relationships between Energy Technology Sectors' /
    elp.elpb
    elpb.(elpb_new, elpb_old)
    eligcc.elbigcc
/;

set jel_firm(jel) 'Firm, non intermittent technologies' /
    elpb_new, elpb_old, elbigcc
/;

set jel_stdgrid(jel) 'Technologies requiring standard grid infrastructure (i.e. no W&S)' /
    elpb_new, elpb_old, elbigcc
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_mod_elbio'
parameter elpb_capacity(n,t) 'Pulverized biomass 2010/2015 capacity [TW]';
$loaddc elpb_capacity
$gdxin

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

* Lower bound for consumption of woody biomass for 'elpb_new', 'elpb_old', 'elbigcc'
Q_IN.lo('wbio',jfed,t,n)$csi('wbio',jfed,t,n) = 1e-8;

* Fix 'elpb_old' to its maximum production
Q_EN.fx('elpb_old',t,n)$(K_EN.l('elpb_old',t,n) gt 1e-5) = mu('elpb_old',t,n) * K_EN.l('elpb_old',t,n);

* Fix historical capacity in 2010-2015
K_EN.fx('elpb_new',t,n)$((not tfix(t)) and elpb_capacity(n,t)) = max(elpb_capacity(n,t) - K_EN.l('elpb_old',t,n), 1e-6);

$elseif %phase%=='gdx_items'

* Parameters
elpb_capacity

$endif
