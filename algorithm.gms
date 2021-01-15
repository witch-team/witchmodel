*-------------------------------------------------------------------------------
* algorithm.gms
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
* Initialization [sets, parameters and default values]
*-------------------------------------------------------------------------------

$batinclude 'algo/solve' init

$batinclude 'algo/conv' init

$batinclude 'algo/report' init

*-------------------------------------------------------------------------------
* Generation of the model's equations
*-------------------------------------------------------------------------------

$batinclude 'algo/model' %coalitions%

$batinclude 'algo/forsameclt' %coalitions%

*-------------------------------------------------------------------------------
* Main loop
*-------------------------------------------------------------------------------

stop_run = 0;
count_run = 1;
loop(to_run(run)$(stop_run eq 0),

$batinclude 'algo/report' txtrun

$batinclude 'modules' before_nashloop

*-------------------------------------------------------------------------------
* Nash loop
*-------------------------------------------------------------------------------

stop_nash = 0;
loop(siter$((stop_nash eq 0) or (ord(siter) le %min_iter%)),

$batinclude 'modules' before_solve

$if set dynamic_calibration $batinclude 'modules' dynamic_calibration

$batinclude 'algo/conv' before_solve
    
$batinclude 'algo/solve' %coalitions%

$include 'algo/compute_marginal'

$batinclude 'algo/conv' internal_markets

$batinclude 'algo/conv' negishi_weights

$batinclude 'algo/conv' check_convergence

$batinclude 'algo/conv' external_markets

$batinclude 'algo/conv' update_price

$batinclude 'modules' after_solve

$batinclude 'algo/report' txtnash

$batinclude 'algo/report' gdxtemp

* Stop if all converged
if( (sum(ierr, 1$(allerr(run,siter,ierr) le errtol(ierr))) eq (card(ierr))) and all_%converged_if_all%(run,siter),
  stop_nash = 1;
);

* End of nash loop
);

loop(siter$(ord(siter) eq card(siter)),
$batinclude 'modules' before_solve
$if set dynamic_calibration $batinclude 'modules' dynamic_calibration
$batinclude 'modules' after_solve
);

loop(siter$((stop_nash eq 0) and (ord(siter) eq card(siter))),
$batinclude 'algo/report' txtmaxiter
);

if(stop_nash eq 1,
$batinclude 'algo/report' txtconverged
);

$batinclude 'modules' after_nashloop

$batinclude 'algo/report' gdxrun

* End of run loop
count_run = count_run + 1;
);

$batinclude 'algo/report' txtfooter
