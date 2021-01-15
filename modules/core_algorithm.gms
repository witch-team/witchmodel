*-------------------------------------------------------------------------------
* Algorithm
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Required conf variables
$if not set baseline $abort 'ERROR: baseline is not defined'
$if not set policy   $abort 'ERROR: policy is not defined'
$if not set startgdx $abort 'ERROR: startgdx is not defined'

* Convergence algorithm
$setglobal algo 'admm' # ADMM algorithm
*$setglobal algo 'taton' # Tatonnement algorithm

* Stopping convergence criteria if all coalitions are {optimal|feasible}
$setglobal converged_if_all optimal

* Toggle GDX generation at each Nash iteration [for debugging purpose]
*$setglobal outgdx_iter

* Maximum number of nash-loop iterations
$setglobal max_iter 999

* Minimum number of nash-loop iterations
$setglobal min_iter 1
* Seconds to wait between solution checks in the nash
$setglobal sleep_factor 0.1
* Max seconds to wait for solutions in the nash loop
$setglobal max_soltime 1e7
* Max solver iterations
$setglobal max_soliter 1e8

* Solve statement parameters
$setglobal pb_type nlp
$setglobal pb_obj UTILITY
$if %algo%=='admm' $setglobal pb_obj OBJADMM

* ADMM algorithm parameters
* Initial value for rho in the oil market
$setglobal admm_rho_oil 3e-9
* Initial value for rho in the carbon markets
$setglobal admm_rho_nip 2e0

* Nosolve = one Nash-loop iteration, zero solver iterations, zero reruns, in-memory
$ifthen.ns set nosolve
$setglobal max_iter 1
$setglobal max_soliter 0
$setglobal rerun 0
$setglobal solvergrid memory
$endif.ns

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

set ierr 'Entries used for checking convergence' / inv, pes, oil, nip, co2, wgt /;

set siter 'Iteration index' / i1*i%max_iter% /;
alias(siter, ssiter, sssiter);

scalar timer      'Timer used to keep track of elapsed solve time';
scalar stop_run   'Flag to signal final convergence or error in the run loop';
scalar stop_nash  'Flag to signal final convergence or error in the Nash loop';
scalar count_run  'Counter for runs';

set conf 'model configuration'/
'baseline'.'%baseline%'
'policy'.'%policy%'
'datapath'.'%datapath%'
'regions'.'%n%'
'n'.'%n%'
'startgdx'.'%startgdx%'
'baugdx'.'%baugdx%'
'tfpgdx'.'%tfpgdx%'
'calibgdx'.'%calibgdx%'
'nameout'.'%nameout%'
'outgdx'.'%outgdx%'
$if set startboost 'startboost'.'enabled'
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

* Convergence tolerance
parameter errtol(ierr) 'Error tolerances for convergence';
errtol('oil')   = 0.005;
errtol('wgt')   = 1.00;
errtol('inv')   = 0.5;
errtol('pes')   = 0.1;
loop(c_mkt, errtol(ierr)$map_ierr_e(ierr, c_mkt) = 0.01);
errtol('co2')   = 0.05;

* ADMM parameters in the objective function
parameter 
    rho_admm(*,t) 'ADMM penalty coefficient'
    u_admm(*,t) 'ADMM dual variable scaled'
    x_admm(*,t,n) 'Regional trade imbalance'
    xavg_admm(*,t) 'Average global trade imbalance'
;

* Relax tolerance for SSP5
$ifthen.x %baseline%=='ssp5'
errtol('inv') = 3.00;
errtol('oil') = 0.08;
errtol('pes') = 0.5;
loop(c_mkt, errtol(ierr)$map_ierr_e(ierr, c_mkt) = 0.02);
$endif.x

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

rho_admm('oil',t) = %admm_rho_oil%;
rho_admm('nip',t) = %admm_rho_nip%;

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

$if %algo%=='admm' variable OBJADMM 'Objective function with ADMM';

*-------------------------------------------------------------------------------
$elseif %phase%=='policy'

$if set startboost execute_loadpoint '%startgdx%.gdx';

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

$if %algo%=='admm' eqobj_%clt%

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

$ifthen.admm %algo%=='admm'
* Add the component of the (maximized) objective function as required by the ADMM algorithm
eqobj_%clt%..
    OBJADMM =e= UTILITY -
        sum(t, rho_admm('oil',t) / 2 *
            sum(n$(mapn('%clt%') and trading_t('oil',t,n)),
                power(
                    (Q_FUEL('oil',t,n) - Q_OUT('oil',t,n)) -
                    x_admm('oil',t,n) +
                    xavg_admm('oil',t) +
                    u_admm('oil', t)
                ,2)
            )) -
        sum((c_mkt,t), rho_admm(c_mkt,t) / 2 *
            sum(n$(mapn('%clt%') and trading_t(c_mkt,t,n)),
                power(
                    Q_EMI(c_mkt,t,n) -
                    x_admm(c_mkt,t,n) +
                    xavg_admm(c_mkt,t) +
                    u_admm(c_mkt,t)
                ,2)
            ))
    ;
$endif.admm

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Sets
ierr
siter
conf

* Parameters
errtol
stop_nash
stop_run

$endif
