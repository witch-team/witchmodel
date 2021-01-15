*-------------------------------------------------------------------------------
* Interface with the CONOPT Solver
*-------------------------------------------------------------------------------
$ifthen.si %1=="init"

* Number of iterations to check for slow convergence
$setglobal slow_iter 50
* Max improvement to check for slow convergence
$setglobal slow_criteria 0.0009
* Max number of attempts to retry solving an infeasible region*
$setglobal max_retry 10

* Treat fixed variables as constant
$setglobal holdfixed 1

* Determine if gams links the solver using temporary files (Grid computing environment) or the memory (Threads)
* More details at https://www.gams.com/latest/docs/UG_GamsCall.html#GAMSAOsolvelink
$if not set solvergrid $setglobal solvergrid 'file'
$if %parallel%=='incore' $setglobal solvergrid 'memory'
$ifthen.x %solvergrid%=='memory'
$if %parallel%==false $setglobal solvelink %solveLink.loadLibrary%
$setglobal solvelink %solvelink.AsyncThreads%
$else.x
$if %parallel%==false $setglobal solvelink %solveLink.chainScript% 
$setglobal solvelink %solvelink.AsyncGrid%
$endif.x

* Solver tuning
$if not set solver $setglobal solver conopt

$if not set conopt_tolerance $setglobal conopt_tolerance 12

$ifthen.x %solver%=='conopt'
file opt / '%gams.curdir%%solver%.opt' /;
put opt;
put 'rtredg=1e-%conopt_tolerance%'/;
put 'rtbndt=1e-12'/;
putclose opt;
$endif.x

$ifthen.x %solver%=='conopt4'
file opt / '%gams.curdir%conopt4.opt' /;
put opt;
put 'Tol_Optimality=1e-%conopt_tolerance%'/;
put 'Tol_Bound=1e-12'/;
putclose opt;
$endif.x

*-------------------------------------------------------------------------------
* Initialization
*-------------------------------------------------------------------------------
set retry  'Solve retries after infeasibilities' / 1*%max_retry% /;
set irep   'Solution report entries'
           / status, objval, solvestat, modelstat, iterusd,
             resusd, numvar, numequ, numnz, numvarproj,
             numinfes, numnopt, domusd /;
parameter solrep(clt,irep) 'Solution report data';
parameter remh(clt) 'Remaining solve handles';
set all_optimal(run,siter);
all_optimal(run,siter)  = no;
set all_feasible(run,siter);
all_feasible(run,siter)  = no;
parameters nb_clt_infes(run,siter), nb_clt_noopt(run,siter), nb_tot_infes(run,siter);
set cproblem(clt);
set cproblem2(clt);

scalar rcjob;

variables LAST_I, LAST_I_EN, LAST_I_RD, LAST_I_OUT, LAST_COST_FUEL;

$else.si

*-------------------------------------------------------------------------------
* Save old state
*-------------------------------------------------------------------------------

LAST_I.l('fg',t,n)           = I.l('fg',t,n);
LAST_I_EN.l(jinv,t,n)        = I_EN.l(jinv,t,n);
LAST_I_RD.l(rd,t,n)          = I_RD.l(rd,t,n);
LAST_I_OUT.l(extract(f),t,n) = I_OUT.l(f,t,n);
LAST_COST_FUEL.l(f,t,n)      = COST_FUEL.l(f,t,n);

*-------------------------------------------------------------------------------
* Solver macro
*-------------------------------------------------------------------------------
$if set no_speculation $setglobal pb_type dnlp
$macro launchsolve(clt) \
solve witch_&clt maximizing %pb_obj% using %pb_type%; \
if((witch_&clt.solvelink eq %solvelink.AsyncThreads%) or (witch_&clt.solvelink eq %solvelink.AsyncGrid%), \
  remh('&clt') = witch_&clt.handle; \
else savereport(&clt); \
  checkforproblems('&clt'));

*-------------------------------------------------------------------------------
* Initialization solver parameters
*-------------------------------------------------------------------------------
option nlp      = %solver%;
option dnlp     = %solver%;
option cns      = %solver%;
option iterlim  = %max_soliter%;
option reslim   = %max_soltime%;
option decimals = 8; # default number of decimal to be printed
option sysout   = off; # Do not incorporate solver output into LST
option limcol   = 0;  # number of cases displayed in LST per var
option limrow   = 0;  # number of cases displayed in LST per equ
$if not set verbose option sysout   = off;
$if not set verbose option solprint = off;
timer            = timeelapsed;
solrep(clt,irep) = na;
remh(clt)        = 0;
cproblem(clt)    = no;

*-------------------------------------------------------------------------------
* Check if everything is OK
*-------------------------------------------------------------------------------

abort$(execerror gt 0) 'Please check execution errors!';

*-------------------------------------------------------------------------------
* Launch a solver for each coalition
*-------------------------------------------------------------------------------

$label start_loop
$if "a%1"=="a" $goto end_loop
launchsolve(%1)
$shift
$goto start_loop
$label end_loop

*-------------------------------------------------------------------------------
* Retrieve solution in parallel model
*-------------------------------------------------------------------------------
repeat
    rcjob = readyCollect(remh);
    display$rcjob rcjob;
    abort$(rcjob>1)  'Problem waiting for model';
    loop(clt$handlecollect(remh(clt)),
        solrep(clt,'status') = handlestatus(remh(clt));
        forsameclt(savereport,clt);
        abort$handledelete(remh(clt)) 'ERROR: problem deleting handles' ;
        remh(clt)=0;
        checkforproblems(clt);
    );
until ((card(remh) eq 0) or ((timeelapsed-timer) gt %max_soltime%));

if(card(remh) gt 0,
  display 'TIME OUT: %max_soltime% seconds elapsed and not all solves are complete';
  cproblem(clt)$(remh(clt)) = yes;
);

*-------------------------------------------------------------------------------
* Rerun individual problem in case of infeasibility
*-------------------------------------------------------------------------------

$if not set rerun $setglobal rerun 2

$macro seqsolve(clt) \
  witch_&clt.solvelink = %solveLink.chainScript%; \
  launchsolve(&clt); \
  witch_&clt.solvelink = %solvelink%;

* rerun models solved with errors
if(card(cproblem) gt 0,
  loop(retry$((card(cproblem) gt 0) and (ord(retry) le %rerun%) ),
      cproblem2(clt) = yes$cproblem(clt);
      loop(cproblem2(clt),
          forsameclt(seqsolve,clt);
      );
  );
);

* Store model status
* optimal: optimal (code=1) or locally optimal (code=2)
* feasible: locally optimal (code=2) or feasible solution excluding discrete variables (code=7)
all_optimal(run,siter)   = yes$(sum(clt,solrep(clt,'modelstat')) le sum(clt,2));
all_feasible(run,siter)  = yes$(sum(clt$((solrep(clt,'modelstat') eq %modelStat.locally Optimal%) or (solrep(clt,'modelstat') eq %modelStat.feasibleSolution%)),1) eq card(clt));
nb_clt_infes(run,siter) = sum(clt$(solrep(clt,'modelstat') eq %modelStat.infeasible%  or solrep(clt,'modelstat') eq %modelStat.locallyInfeasible%  or solrep(clt,'modelstat') eq %modelStat.intermediateInfeasible%),1);
nb_clt_noopt(run,siter) = sum(clt$(solrep(clt,'modelstat') eq %modelStat.feasibleSolution%),1);
nb_tot_infes(run,siter) = sum(clt,solrep(clt,'numinfes'));

$endif.si
