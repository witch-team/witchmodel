*-------------------------------------------------------------------------------
* Report model progress
*-------------------------------------------------------------------------------

$setargs phase

$ifthen %phase% == 'init'

set iterrep / infes, nonopt, itertime, tottime /;
set timeiterrep(iterrep) / itertime, tottime /;

parameter infoiter(iterrep);
parameter allinfoiter(run,siter,iterrep);

file gdxput; # Device used to save variables to a different gdxs

* File used for realtime errors plotting
file errdat / '%resdir%errors_%nameout%.txt' /;
errdat.ap=0;
errdat.lj=1;
errdat.tj=1;

put errdat;
* Time
put 'Start: ',system.date,' 'system.time /;
* To be run
put 'To run: ';
loop(to_run, 
  put to_run.tl:0,' ';
);
put /;
$if set nosolve put "NO SOLVE RUN" /;
* Explanation sol
put 'sol: [Y/N][clt nonopt][clt infes][tot infes]';
put /;
* Horizontal separator
put '====';
put '=====';
loop(ierr,
put '=========';
);
loop(timeiterrep,
put '==========';
);
put /;
* Column headers
put 'iter';
put '  sol';
loop(ierr,
put  ' ' ierr.tl:8;
);
loop(timeiterrep,
put  ' ' timeiterrep.tl:9;
);
put /;
* Convergence tolerances
put '    ';
put '     ';
loop(ierr,
put  '   <' errtol(ierr):5:3;
);
put  '         ';
put /;
putclose errdat;
errdat.ap=1;

$elseif %phase% == 'txtfooter'

put errdat;
* Horizontal separator
put '====';
put '=====';
loop(ierr,
put '=========';
);
loop(timeiterrep,
put '==========';
);
put /;
putclose errdat;

$elseif %phase% == 'txtmaxiter'

put errdat;
* Horizontal separator
put '----';
put '-----';
loop(ierr,
put '---------';
);
loop(timeiterrep,
put '----------';
);
put /;
put '> reach max_iter!';
put /;
putclose errdat;

$elseif %phase% == 'txtconverged'

put errdat;
* Horizontal separator
put '----';
put '-----';
loop(ierr,
put '---------';
);
loop(timeiterrep,
put '----------';
);
put /;
put '> Convergence criteria met!';
put /;
putclose errdat;

$elseif %phase% == 'txtrun'

put errdat;
* Horizontal separator with run text 
put '>' run.tl:3 ;
put ' ----';
loop(ierr,
    put '---------';
);
loop(timeiterrep,
    put '----------';
);
put /;
putclose errdat;

$elseif %phase% == 'txtnash'

* Get information
infoiter('infes')     = sum(clt$((solrep(clt,'modelstat') eq %modelStat.infeasible%) or (solrep(clt,'modelstat') eq %modelStat.locallyInfeasible%) or (solrep(clt,'modelstat') eq %modelStat.intermediateInfeasible%)), 1);
infoiter('nonopt')    = sum(clt$((solrep(clt,'modelstat') eq %modelStat.feasibleSolution%)), 1);
infoiter('itertime')  = (timeelapsed-timer);
infoiter('tottime')   = timeelapsed;
allinfoiter(run,siter,iterrep) = infoiter(iterrep);

put errdat;
errdat.ap=1;

put ord(siter):<4:0
put ' ';
put all_optimal(run,siter):1:0;
if(nb_clt_noopt(run,siter) eq 0,
  put '0';
);
if(nb_clt_noopt(run,siter) ge 1 and nb_clt_noopt(run,siter) le 9,
  put nb_clt_noopt(run,siter):1:0;
);
if(nb_clt_noopt(run,siter) gt 9,
  put 'X';
);
if(nb_clt_infes(run,siter) eq 0,
  put '0';
);
if(nb_clt_infes(run,siter) ge 1 and nb_clt_infes(run,siter) le 9,
  put nb_clt_infes(run,siter):1:0;
);
if(nb_clt_infes(run,siter) gt 9,
  put 'X';
);
if(nb_tot_infes(run,siter) eq 0,
  put '0';
);
if(nb_tot_infes(run,siter) ge 1 and nb_tot_infes(run,siter) lt 9.8e+9,
  put log10(nb_tot_infes(run,siter)):1:0;
);
if(nb_tot_infes(run,siter) ge 9.8e+9,
  put 'X';
);
loop(ierr,
  put allerr(run,siter,ierr):9:3;
);
loop(iterrep$timeiterrep(iterrep),
    put ' ';
    # hours
    if(floor(allinfoiter(run,siter,iterrep)/3600)>0,
      put (floor(allinfoiter(run,siter,iterrep)/3600)):3:0, ':';
    else
      put '  0:';
    );
    # minutes
    if(floor(mod(allinfoiter(run,siter,iterrep),3600)/60)>0,
      if(floor(mod(allinfoiter(run,siter,iterrep),3600)/60)>9,
        put (floor(mod(allinfoiter(run,siter,iterrep),3600)/60)):2:0, ':';
      else
        put '0' (floor(mod(allinfoiter(run,siter,iterrep),3600)/60)):1:0, ':';
    );
    else
      put '00:';
    );
    # seconds
    if(floor(mod(allinfoiter(run,siter,iterrep),60))>9,
        put (floor(mod(allinfoiter(run,siter,iterrep),60))):2:0;
      else
        put '0' (floor(mod(allinfoiter(run,siter,iterrep),60))):1:0;
    );
);
put /;
putclose errdat;

$elseif %phase% == 'gdxtemp'

* write temp gdx
execute_unload '%resdir%all_data_temp_%nameout%.gdx';

* write iter gdx
$ifthen.x set outgdx_iter
put gdxput;
put_utility 'gdxout' / '%resdir%%outgdx%_' run.tl:0 '_' siter.tl:0 '.gdx';
execute_unload;
putclose gdxput;
$endif.x

$endif
