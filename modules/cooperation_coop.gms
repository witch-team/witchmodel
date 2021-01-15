*-------------------------------------------------------------------------------
* Cooperative Setup
*
* Defines a world coalition, or Grand coalition.
* All regions belongs to one coalition
*
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* The grand coalition name
$setglobal coalitions c_world

* The regions cooperate on climate
$setglobal cooperate_on_climate 'YES'

* Lower solver tolerance
$setglobal conopt_tolerance 4

* fix periods until 2015 to the non-cooperative calibration
$setglobal fixgdx '%datapath%results_%baseline%_calib'
$setglobal tfix 3

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

set clt/ c_world /;

set map_clt_n(clt,n) 'Mapping between all coalitions and regions';
map_clt_n('c_world',n) = YES;

set conf /
'cooperation'.'%cooperation%'
'cooperate_on_climate'.'%cooperate_on_climate%'
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='policy'

negishi_coop('c_world',n)=no;
$if not set utilitarian negishi_coop('c_world',n)=yes;

rd_cooperation(rd,'c_world')=no;
$if set cooperate_on_rd rd_cooperation(rd,'c_world')=yes;

* By default, oil market is solve internally (see equation eq_mkt_clearing_oil)
* But in some cases, it can be faster with external oil market
internal('oil')=yes;

* All carbon market are solved internally
internal(c_mkt)$(sum((t,n)$trading_t(c_mkt,t,n),1))=yes;

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Sets
clt
map_clt_n

$endif
