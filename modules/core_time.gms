*-------------------------------------------------------------------------------
* Time
* - Temporal structure
* - Fixed time periods
* - States of the world
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Default fixgdx
$ifthen.nofx not set fixgdx
$if %baseline%=='ssp1' $setglobal fixgdx '%datapath%results_ssp2_calib'
$if %baseline%=='ssp3' $setglobal fixgdx '%datapath%results_ssp2_calib'
$if %baseline%=='ssp4' $setglobal fixgdx '%datapath%results_ssp2_calib'
$if %baseline%=='ssp5' $setglobal fixgdx '%datapath%results_ssp2_calib'
$if %baseline%=='ssp2' $if not %policy%=='bau' $setglobal fixgdx '%datapath%results_ssp2_calib'
$if set fixgdx $if not set tfix $setglobal tfix 3
$endif.nofx

* Value in a specific year (use tt instead of t, not working in equations)
$macro valuein(takeyear, expr) (smax(tt$(year(tt) eq &takeyear), &expr))

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

* Time period node
sets
    t           'Time period nodes'
    tnofirst(t) 'All nodes except the first time period node'
    tlast(t)    'Last time period nodes'
    tnolast(t)  'All nodes except the last time period nodes'
;
singleton set tfirst(t)   'First time period node';
alias(t,tt,ttt,tp1,ttp1,tp2,tm1,tm2);
set pre(t,tp1)   'Precedence set, t is the predecessor of tp1';
set preds(t,tt)   'Predecessors set, tt are all predecessors of t';

parameter tperiod(t) 'time period';
parameter year(t) 'reference year for period t';
parameter begyear(t) 'beginning year for period t';
parameter tlen(t) 'Length of time period [years]';

* Time horizon for optimization
scalar yeoh 'year end of time horizon';

$include %datapath%/time.inc

* tfirst and tlast over time
tfirst(t) = yes$(tperiod(t) eq smin(tt,tperiod(tt)));
tlast(t) = yes$(tperiod(t) eq smax(tt,tperiod(tt)));

tnofirst(t) = yes$(not tfirst(t));
tnolast(t)  = yes$(not tlast(t));

* End of time horizon for optimization
$ifthen.y set yeoh
yeoh = %yeoh%;
$else.y
yeoh = smax(t, year(t));
$endif.y

* Fixed period nodes
set tfix(t)    'fixed period nodes';
tfix(t) = no;

* Create and load fix variable
$macro loadfix(name,idx,type) \
&type FIX&name&&idx; \
execute_load '%fixgdx%.gdx',FIX&name=&name;

* Fix variable in tfix
$macro tfixvar(name,idx) \
loadfix(name,idx,variable) \
&name.fx&&idx$tfix(t) = FIX&name.l&&idx; \
&name.l&&idx$tfix(t) = FIX&name.l&&idx;

* Fix Variable in tfix+1
$macro tfix1var(name,idx) \
loadfix(name,idx,variable) \
loop((t,tfix(tp1))$pre(t,tp1), \
&name.fx&&idx = FIX&name.l&&idx; \
&name.l&&idx = FIX&name.l&&idx; \
);

* load parameter in tfix
$macro tfixpar(name,idx) \
loadfix(name,idx,parameter) \
&name&&idx$tfix(t) = FIX&name&&idx;

set conf /
$if set fixgdx 'fixgdx'.'%fixgdx%'
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$if set fixgdx $if not set tfix $abort 'fixgdx requires tfix'
$if set fixgdx tfix(t) = yes$(tperiod(t) le %tfix%);

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

variable PROB(t) 'Probability of all states of the world';

PROB.fx(t) = 1;

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

t
tfix
tlen
tfirst
tlast
tperiod
year
yeoh
pre

$endif
