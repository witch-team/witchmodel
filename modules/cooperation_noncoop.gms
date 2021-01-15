*-------------------------------------------------------------------------------
* Non-Cooperative Setup
* 
* Each region is defined as an individual coalition. 
*
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Each region is a coalition
$include %datapath%noncoop.conf
$if set only_solve $setglobal coalitions %only_solve%

* Each coalition cooperates on climate within itself 
$setglobal cooperate_on_climate 'YES'

$setglobal parallel true

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

$include %datapath%noncoop.inc

set conf /
'cooperation'.'%cooperation%'
'cooperate_on_climate'.'%cooperate_on_climate%'
/;

$elseif %phase%=='gdx_items'

* Sets
clt
map_clt_n

$endif
