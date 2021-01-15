*-------------------------------------------------------------------------------
* Gas Resources
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Define default resource availability levels for baseline
$if %baseline%=='ssp1' $setglobal fossil_gas L
$if %baseline%=='ssp2' $setglobal fossil_gas M
$if %baseline%=='ssp3' $setglobal fossil_gas H
$if %baseline%=='ssp4' $setglobal fossil_gas M
$if %baseline%=='ssp5' $setglobal fossil_gas H
$if %baseline%=='ssp5' $setglobal nogastrade
$if %baseline%=='ssp3' $setglobal nogastrade

$elseif %phase%=='sets'

set extract(f) / gas/;

set conf /
'fossil_gas'.'%fossil_gas%'
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_mod_gas'

parameter trade_poly_gas(polydeg,*,n);
$loaddc trade_poly_gas

parameter trade_scale_gas(*);
$loaddc trade_scale_gas

parameter cgas(*,*) 'Gas price function coefficients';
$loaddc cgas

$gdxin

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

* No emissions associated with extraction
Q_EMI_OUT.fx('gas',t,n) = 0;

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

FPRICE.l('gas',t)$(not tfix(t)) = max(valuein(2005,FPRICE.l('gas',tt)), poly((wcum('gas',t) - cexs('gas','cum0')), cgas(polydeg,'%fossil_gas%')));

* Calculate cumulative production (by means of polynomial functions)
cum_prodpp('gas',t,n) = max(0, trade_scale_gas('%fossil_gas%') *
                               poly(FPRICE.l('gas',t)/(twh2ej/1000), trade_poly_gas(polydeg,'%fossil_gas%',N))
                           );

* Ensure cumulative production in 2005 = 0
cum_prodpp('gas',t,n)$(tfirst(t))= 0;


* This is to avoid negative production (cumulative production declining)
loop((t,tp1)$(pre(t,tp1)),
  cum_prodpp('gas',tp1,n)=max(cum_prodpp('gas',t,n)+1e-5*tlen(t), cum_prodpp('gas',tp1,n) )
);

** Calculate annual production
loop((t,tp1)$(pre(t,tp1)),
  prodpp('gas',t,n) = (cum_prodpp('gas',tp1,n) - cum_prodpp('gas',t,n))/tlen(t)
);

prodpp('gas',t,n)$(year(t) > 2100) = sum(nn,Q_FUEL.l('gas',t,nn)) * valuein(2100, (prodpp('gas',tt,n)/sum(nn,prodpp('gas',tt,nn))));

$ifthen.ssp set nogastrade
Q_OUT.fx('gas',t,n)$(not tfix(t)) = 0;
FPRICE.l('gas',t)$(not tfix(t)) = cexs('gas','scl') * (cexs('gas','a') + cexs('gas','c') * (wcum('gas',t) /
                                                                                   (cexs('gas','fast') * cexs('gas','res0') )
                                                                                 )**cexs('gas','exp')
                                          ) + cexs('gas','extra');
$else.ssp
Q_OUT.fx('gas',t,n)$(not tfix(t)) = prodpp('gas',t,n);
$endif.ssp

MCOST_FUEL.fx('gas',t,n)$(not tfix(t)) = FPRICE.l('gas',t) + p_mkup('gas',t,n);

$elseif %phase%=='gdx_items'

trade_poly_gas
trade_scale_gas

$endif
