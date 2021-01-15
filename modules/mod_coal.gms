*-------------------------------------------------------------------------------
* Coal Resources
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Define default resource availability levels for baseline
$if %baseline%=='ssp1' $setglobal fossil_coal L
$if %baseline%=='ssp2' $setglobal fossil_coal M
$if %baseline%=='ssp3' $setglobal fossil_coal H
$if %baseline%=='ssp4' $setglobal fossil_coal M
$if %baseline%=='ssp5' $setglobal fossil_coal H
$if %baseline%=='ssp5' $setglobal nocoaltrade
$if %baseline%=='ssp3' $setglobal nocoaltrade

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

set extract(f) / coal/;

set conf /
'fossil_coal'.'%fossil_coal%'
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_mod_coal'

parameter trade_poly_coal(polydeg,*,n);
$loaddc trade_poly_coal

parameter trade_scale_coal(*);
$loaddc trade_scale_coal

parameter localpll(t,n) 'Coal/Wbio pollution O&M extra costs [T$/TWh]';
$loaddc localpll

parameter ccoal(*,*) 'Coal price function coefficients';
$loaddc ccoal

$gdxin

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

* Raise coal demand for SSP3&5, otherwise too low
$if %baseline%=='ssp5' cexs('coal','resgr0') = cexs('coal','resgr0') * 4; cexs('coal','exp') = cexs('coal','exp') * 0.4;
$if %baseline%=='ssp3' cexs('coal','resgr0') = cexs('coal','resgr0') * 6; cexs('coal','exp') = cexs('coal','exp') * 0.15;

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

* No emissions associated with extraction
Q_EMI_OUT.fx('coal',t,n) = 0;

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

FPRICE.l('coal',t)$(not tfix(t)) = max(valuein(2005,FPRICE.l('coal',tt)), poly((wcum('coal',t) - cexs('coal','cum0')), ccoal(polydeg,'%fossil_coal%')));

* Calculate cumulative production (by means of polynomial functions)
cum_prodpp('coal',t,n) = max(0, trade_scale_coal('%fossil_coal%') *
                                poly(FPRICE.l('coal',t)/(twh2ej/1000), trade_poly_coal(polydeg,'%fossil_coal%',N))
                            );

* Ensure cumulative production in 2005 = 0
cum_prodpp('coal',t,n)$(tfirst(t))= 0;


* This is to avoid negative production (cumulative production declining)
loop((t,tp1)$(pre(t,tp1)),
  cum_prodpp('coal',tp1,n)=max(cum_prodpp('coal',t,n)+1e-5*tlen(t), cum_prodpp('coal',tp1,n) )
);

** Calculate annual production
loop((t,tp1)$(pre(t,tp1)),
  prodpp('coal',t,n) = (cum_prodpp('coal',tp1,n) - cum_prodpp('coal',t,n))/tlen(t)
);

prodpp('coal',t,n)$(year(t) > 2100) = sum(nn,Q_FUEL.l('coal',t,nn)) * valuein(2100, (prodpp('coal',tt,n)/sum(nn,prodpp('coal',tt,nn))));

$ifthen.ssp set nocoaltrade
Q_OUT.fx('coal',t,n)$(not tfix(t)) = 0;
FPRICE.l('coal',t)$(not tfix(t)) = cexs('coal','scl') * 
                                      (cexs('coal','a') + 
                                       cexs('coal','c') * 
                                       (wcum('coal',t) / (cexs('coal','fast') * cexs('coal','res0')))**cexs('coal','exp')
                                      ) + cexs('coal','extra');
$else.ssp
Q_OUT.fx('coal',t,n)$(not tfix(t)) = prodpp('coal',t,n);
$endif.ssp

MCOST_FUEL.fx('coal',t,n)$(not tfix(t)) = FPRICE.l('coal',t) + p_mkup('coal',t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

trade_poly_coal
trade_scale_coal

$endif
