*-------------------------------------------------------------------------------       
* macros.gms
* 
* Define macros to simplify complex and repetitive expressions
*-------------------------------------------------------------------------------                

* Build a polynomial expression
$if not defined polydeg set polydeg 'Set of polynomial degrees' / deg0*deg11 /;
$macro poly(x,coeff) sum(polydeg$(coeff), (coeff)*(x)**(ord(polydeg)-1))

* Sum expression, defined with the set 'ss', over the subset 'sd'
$macro cast(expression,ss,sd) sum(&ss$(sameas(&ss,&sd)), &expression)

* Return true (>0), if the set 'small' belongs to the set 'big'
$macro xiny(small,big) sum(&big$sameas(&big,&small),1)

*-------------------------------------------------------------------------------
* Specific macros

* Sum child in the CES tree, in post_tables.gms
$macro sumjchild(x,jset,anode) sum(j$map_j(&anode,j), cast(&x,&jset,j))

* store model results, in solve_macros.gms
$macro savereport(reg) solrep('&reg','objval')=witch_&reg.objval;\
                       solrep('&reg','solvestat')=witch_&reg.solvestat;\
                       solrep('&reg','modelstat')=witch_&reg.modelstat;\
                       solrep('&reg','iterusd')=witch_&reg.iterusd;\
                       solrep('&reg','resusd')=witch_&reg.resusd;\
                       solrep('&reg','numvar')=witch_&reg.numvar;\
                       solrep('&reg','numequ')=witch_&reg.numequ;\
                       solrep('&reg','numnz')=witch_&reg.numnz;\
                       solrep('&reg','numvarproj')=witch_&reg.numvarproj;\
                       solrep('&reg','numinfes')=witch_&reg.numinfes;\
                       solrep('&reg','numnopt')=witch_&reg.numnopt;\
                       solrep('&reg','domusd')=witch_&reg.domusd;

* Select numiter iterations
$macro last_iter(numiter) ((ord(ssiter) le ord(siter)) and (ord(ssiter) ge (ord(siter) - (&numiter - 1))))

*-------------------------------------------------------------------------------
* Load variables from startgdx

* Read and set the variable level from the start GDX,
* if the level is not found in the gdx, default is used
$macro loadvar(var,setdep,default) \
prevexecerrors = execerror; last_load_went_wrong=0; \
execute_load '%startgdx%', &var; \
if(execerror gt prevexecerrors, \
  &var.l&&setdep = &default; \
  execerror = prevexecerrors; \
  last_load_went_wrong=1)

* Load variable level and specify bounds
*   if the level is not found in the gdx, default is set as level
$macro loadvarbnd(var,setdep,default,bndlo,bndup) \
loadvar(var,setdep,default); \
&var.lo&&setdep = &bndlo; \
&var.up&&setdep = &bndup; \
&var.l&&setdep$(&var.l&&setdep<&bndlo) = &bndlo; \
&var.l&&setdep$(&var.l&&setdep>&bndup) = &bndup;

$macro loadvarbndcond(var,setdep,cond,default,bndlo,bndup) \
loadvar(var,'&&setdep$(&&cond)',default); \
&var.lo&&setdep$(&&cond) = &bndlo; \
&var.up&&setdep$(&&cond) = &bndup; \
&var.l&&setdep$((&&cond) and (&var.l&&setdep<&bndlo)) = &bndlo; \
&var.l&&setdep$((&&cond) and (&var.l&&setdep>&bndup)) = &bndup;

* Load from the same parameter but with first ssp index. Name starts with ssp_
$macro load_from_ssp(par,idx,ssp,suxfile) \
parameter ssp_&par(*,&&idx); \
execute_loaddc '%datapath%data_&suxfile' ssp_&par; \
&par(&&idx) = ssp_&par('&ssp',&&idx);

* Tracking error parameters
parameter prevexecerrors, last_load_went_wrong;

*-------------------------------------------------------------------------------
* log some message
file output;
$macro putlog(msg) \
  put output; \
  put_utility 'log' / &msg; \
  putclose output;

*-------------------------------------------------------------------------------
* Load parameters from startgdx

$ifthen.st not set startgdx2
$macro loadpar(par,setdep,default) \
prevexecerrors = execerror; last_load_went_wrong=0; \
execute_load '%startgdx%', &par; \
if(execerror gt prevexecerrors, &par&&setdep = &default; execerror = prevexecerrors; last_load_went_wrong=1)
$else.st
$macro loadpar(par,setdep,default) \
prevexecerrors = execerror; last_load_went_wrong=0; \
execute_load '%startgdx%', &par; \
if(execerror gt prevexecerrors, \
    execerror = prevexecerrors; \
    execute_load '%startgdx2%', &par; \
    if(execerror gt prevexecerrors, \
    &par&&setdep = &default; execerror = prevexecerrors; last_load_went_wrong=1))
$endif.st

*-------------------------------------------------------------------------------
* coalition
$macro mapn(clt) map_clt_n(&clt,n) 
$macro mapnn(clt) map_clt_n(&clt,nn) 
* time horizon
$macro mapn_th(clt) (map_clt_n(&clt,n) and (not tfix(t)) and (year(t) le yeoh))
$macro mapn_th1(clt) (map_clt_n(&clt,n) and (not tfix(tp1)) and pre(t,tp1) and (year(t) lt yeoh))
$macro mapn_th2(clt) (map_clt_n(&clt,n) and (not tfix(tp2)) and pre(t,tp1) and pre(tp1,tp2) and (year(t) lt yeoh))
$macro mapn_th1_last(clt) (map_clt_n(&clt,n) and \
      (((not tfix(tp1)) and pre(t,tp1) and (year(t) lt yeoh)) or (year(t) eq yeoh and sameas(t,tp1))))
$macro time_th1_last (((not tfix(tp1)) and pre(t,tp1) and (year(t) lt yeoh)) or (year(t) eq yeoh and sameas(t,tp1)))
* cooperation
$macro cooprd (sum(clt$(map_clt_n(clt,n) and rd_cooperation(rd,clt)),1) eq 1)
$macro nocooprd (sum(clt$(map_clt_n(clt,n) and rd_cooperation(rd,clt)),1) ne 1)

*-------------------------------------------------------------------------------
* Depreciation Rate [TW/TW/yr]

* Let
* A := integral over time of linear 1% depreciation until end of life (than full depreciation)
*      = lifetime - 0.01/2 lifetime**2
* B := integral over time of exponential depreciation
*      = int((1-delta_en)^x, dx) = - 1/log(1-delta_en)
* We find delta_en such that A = B

$macro depreciation_rate(tech) 1 - exp( 1 / ( - lifetime(&tech,n) + (0.01/2) * lifetime(&tech,n)**2) )

*-------------------------------------------------------------------------------
* Production functions

$macro cobb(out,fac1id,fac1exp,fac2id,fac2exp) \
    q0(&out,n)*( \
        (&fac1exp/q0(&fac1id,n))**(alpha(&fac1id,n))* \
        (&fac2exp/q0(&fac2id,n))**(alpha(&fac2id,n)) \
    )

$macro ces(out,fac1id,fac1exp,fac2id,fac2exp) \
    q0(&out,n)*( \
        alpha(&fac1id,n)*(&fac1exp/q0(&fac1id,n))**rho(&out,t)+ \
        alpha(&fac2id,n)*(&fac2exp/q0(&fac2id,n))**rho(&out,t) \
    )**(1/rho(&out,t))

$macro ces3(out,fac1id,fac1exp,fac2id,fac2exp,fac3id,fac3exp) \
    q0(&out,n)*( \
        alpha(&fac1id,n)*(&fac1exp/q0(&fac1id,n))**rho(&out,t)+ \
        alpha(&fac2id,n)*(&fac2exp/q0(&fac2id,n))**rho(&out,t)+ \
        alpha(&fac3id,n)*(&fac3exp/q0(&fac3id,n))**rho(&out,t) \
    )**(1/rho(&out,t))

$macro lin(out,fac1id,fac1exp,fac2id,fac2exp) \
    q0(&out,n)*( \
        alpha(&fac1id,n)*(&fac1exp/q0(&fac1id,n))+ \
        alpha(&fac2id,n)*(&fac2exp/q0(&fac2id,n)) \
    )

$macro lin3(out,fac1id,fac1exp,fac2id,fac2exp,fac3id,fac3exp) \
    q0(&out,n)*( \
        alpha(&fac1id,n)*(&fac1exp/q0(&fac1id,n))+ \
        alpha(&fac2id,n)*(&fac2exp/q0(&fac2id,n))+ \
        alpha(&fac3id,n)*(&fac3exp/q0(&fac3id,n)) \        
    )

*-------------------------------------------------------------------------------
* Solve model

$macro savereport_with_loadhandle(clt) \
  witch_&clt.handle = remh('&clt'); \
  execute_loadhandle witch_&clt; \
  savereport(&clt)

$macro checkforproblems(clt) \
  if((solrep(&clt,'solvestat') ne 1) or (solrep(&clt,'modelstat') ne 2), \
    cproblem(&clt) = yes; \
  else cproblem(&clt) = no;)

*-------------------------------------------------------------------------------
* Frozen variables

$macro freezevar(name,idx) \
&name.fx&&idx = &name.l&&idx;

$macro nullvar(name,idx) \
&name.fx&&idx = 0;
