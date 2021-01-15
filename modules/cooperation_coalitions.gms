*-------------------------------------------------------------------------------
* Coalition Ad-hoc Definitions
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

$if not %n%=="witch13" $abort 'ERROR: cooperation_coalitions require n mapping is witch13'

* all regions; usa, oldeuro, neweuro, kosau, cajaz, te, mena, ssa, sasia, china, easia, laca, india

* gc: Granc coalition
* oecd: OECD
* 4400 {CAJAZ, OLDEURO, NEWEURO, KOSAU}
* 1600 {MENA, INDIA, EASIA}
* 2065 {USA, CHINA, OLDEURO}
* 78 {TE, SSA, MENA, SASIA}
* 180 {SSA, NEWEURO, OLDEURO, LACA}
* 6963 {USA, CAJAZ, OLDEURO, NEWEURO, CHINA, INDIA, KOSAU, TE}


* ID or name of a given coalition
$setglobal coalition_id gc
* Solving full coalition (nstab not set) or for stability tests excluding the member set by nstab
*$setglobal nstab usa

* startgdx file from coalition run for nstab, if full coalition already run
*$if set nstab $setglobal startgdx '%coalition_id%'

* In case of stability tests, create string to replace the c_any within the set of models to create
$setglobal coalitions_subset 'c_any'
$if set nstab $setglobal coalitions_subset 'c_any c_single'

* Set output name
$setglobal nameout '%coalition_id%'
$if set nstab $setglobal nameout '%coalition_id%_%nstab%'
$setglobal outgdx %nameout%

$setglobal parallel true

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

set clt /c_any/;
$if set nstab set clt /c_single/;


* Grand Coalition
$ifthen.coal %coalition_id%=='gc'
$setglobal coalitions %coalitions_subset%
set clt / c_any /;
set map_clt_n(clt,n) / c_any.(usa, oldeuro, neweuro, kosau, cajaz, te, mena, ssa, sasia, china, easia, laca, india) /;
* OECD Coalition
$elseif.coal %coalition_id%=='oecd'
$setglobal coalitions %coalitions_subset% c_te  c_mena c_ssa c_sasia c_china c_easia c_laca c_india
set clt / c_any, c_te,  c_mena, c_ssa, c_sasia, c_china, c_easia, c_laca, c_india /;
set map_clt_n(clt,n) / c_any.(usa, oldeuro, neweuro, kosau, cajaz), c_te.te, c_mena.mena, c_ssa.ssa, c_sasia.sasia, c_china.china, c_easia.easia, c_laca.laca, c_india.india  /;
* NR: 4400 {CAJAZ, OLDEURO, NEWEURO, KOSAU}
$elseif.coal %coalition_id%=='4400'
$setglobal coalitions %coalitions_subset% c_usa c_te  c_mena c_ssa c_sasia c_china c_easia c_laca c_india
set clt / c_any, c_usa, c_te,  c_mena, c_ssa, c_sasia, c_china, c_easia, c_laca, c_india /;
set map_clt_n(clt,n) / c_any.(oldeuro, neweuro, kosau, cajaz), c_usa.usa, c_te.te, c_mena.mena, c_ssa.ssa, c_sasia.sasia, c_china.china, c_easia.easia, c_laca.laca, c_india.india  /;
* NR: 1600 {MENA, INDIA, EASIA}
$elseif.coal %coalition_id%=='1600'
$setglobal coalitions %coalitions_subset% c_neweuro c_kosau c_cajaz c_te  c_oldeuro c_ssa c_sasia c_china c_laca c_usa
set clt / c_any, c_neweuro, c_kosau, c_cajaz, c_te, c_oldeuro, c_ssa, c_sasia, c_china, c_laca, c_usa /;
set map_clt_n(clt,n) / c_any.(mena, india, easia), c_neweuro.neweuro, c_kosau.kosau, c_cajaz.cajaz, c_te.te, c_oldeuro.oldeuro, c_ssa.ssa, c_sasia.sasia, c_china.china, c_laca.laca, c_usa.usa  /;
* NR: 180 {SSA, NEWEURO, OLDEURO, LACA}
$elseif.coal %coalition_id%=='180'
$setglobal coalitions %coalitions_subset% c_usa c_te  c_mena c_cajaz c_sasia c_china c_easia c_kosau c_india
set clt / c_any, c_usa, c_te,  c_mena, c_cajaz, c_sasia, c_china, c_easia, c_kosau, c_india /;
set map_clt_n(clt,n) / c_any.(oldeuro, neweuro, laca, ssa), c_usa.usa, c_te.te, c_mena.mena, c_cajaz.cajaz, c_sasia.sasia, c_china.china, c_easia.easia, c_kosau.kosau, c_india.india  /;
* NR: 6963 {USA, CAJAZ, OLDEURO, NEWEURO, CHINA, INDIA, KOSAU, TE}
$elseif.coal %coalition_id%=='6963'
$setglobal coalitions %coalitions_subset% c_mena c_ssa c_sasia c_easia c_laca
set clt / c_any, c_mena, c_ssa, c_sasia, c_easia, c_laca /;
set map_clt_n(clt,n) / c_any.(usa, oldeuro, neweuro, kosau, cajaz, china, india, te), c_mena.mena, c_ssa.ssa, c_sasia.sasia, c_easia.easia, c_laca.laca  /;
* NR: 78 {TE, SSA, MENA, SASIA}
$elseif.coal %coalition_id%=='78'
$setglobal coalitions %coalitions_subset% c_usa c_oldeuro c_neweuro c_kosau c_cajaz c_china c_easia c_laca c_india
set clt / c_any, c_usa, c_oldeuro, c_neweuro, c_kosau, c_cajaz, c_china, c_easia, c_laca, c_india /;
set map_clt_n(clt,n) / c_any.(te, ssa, mena, sasia), c_usa.usa, c_oldeuro.oldeuro, c_neweuro.neweuro, c_kosau.kosau, c_cajaz.cajaz, c_china.china, c_easia.easia, c_laca.laca, c_india.india  /;
* NR: 2065 {USA, CHINA, OLDEURO}
$elseif.coal %coalition_id%=='2065'
$setglobal coalitions %coalitions_subset% c_neweuro c_kosau c_cajaz c_te  c_mena c_ssa c_sasia c_easia c_laca c_india
set clt / c_any, c_neweuro, c_kosau, c_cajaz, c_te, c_mena, c_ssa, c_sasia, c_easia, c_laca, c_india /;
set map_clt_n(clt,n) / c_any.(oldeuro, usa, china), c_neweuro.neweuro, c_kosau.kosau, c_cajaz.cajaz, c_te.te, c_mena.mena, c_ssa.ssa, c_sasia.sasia, c_easia.easia, c_laca.laca, c_india.india  /;
$endif.coal


* Abort if stabilization region is not set of the coalition c_any
$if set nstab abort$(not map_clt_n('c_any','%nstab%')) 'Stabilization coalition region not in coalition!';

$if set nstab set clt / c_single /;
$if set nstab set map_clt_n(clt,n) / c_single.(%nstab%) /;
$if set nstab map_clt_n('c_any','%nstab%') = no;

*-------------------------------------------------------------------------------
$elseif %phase%=='policy'

negishi_coop(clt,n)=no;
$if not set utilitarian negishi_coop(clt,n)=yes;

rd_cooperation(rd,clt)=no;
$if set cooperate_on_rd rd_cooperation(rd,clt)=yes;

internal('oil')=no;
internal(c_mkt)$(sum((t,n)$trading_t(c_mkt,t,n),1))=yes;

$elseif %phase%=='gdx_items'

* Sets
clt
map_clt_n

$endif

