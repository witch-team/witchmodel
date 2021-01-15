*-------------------------------------------------------------------------------       
* F-gases
* - LLF
* - SLF
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Define the fgases baseline data source
$setglobal fgasesbaseline ssp2
$if %baseline%=='ssp1' $setglobal fgasesbaseline %baseline%
$if %baseline%=='ssp3' $setglobal fgasesbaseline %baseline%
$if %baseline%=='ssp4' $setglobal fgasesbaseline ssp1
$if %baseline%=='ssp5' $setglobal fgasesbaseline ssp3

$elseif %phase%=='sets'

set e /
pfc
c2f6 
c6f14 
cf4
hfc
hfc125 
hfc134a 
hfc143a
hfc227ea
hfc23
hfc245fa
hfc32
hfc43-10
sf6
f-gases
/;

set ghg(e) 'Green-House Gases' /
c2f6 
c6f14 
cf4
hfc125 
hfc134a 
hfc143a
hfc227ea
hfc23 
hfc245fa
hfc32 
hfc43-10 
sf6
/;

set fgases(e) 'Green-House Gases' /
c2f6 
c6f14 
cf4 
hfc125 
hfc134a 
hfc143a
hfc227ea
hfc23 
hfc245fa
hfc32 
hfc43-10 
sf6
/;

set map_e(e,ee) 'Relationships between Sectoral Emissions' /
    kghg.(c2f6,c6f14,cf4,hfc125,hfc134a,hfc143a,hfc227ea,hfc23,hfc245fa,hfc32,hfc43-10,sf6)
    hfc.(hfc143a, hfc227ea, hfc134a, hfc125, hfc43-10, hfc32, hfc23, hfc245fa)
    pfc.(c2f6,c6f14,cf4)
    f-gases.(c2f6,c6f14,cf4,hfc125,hfc134a,hfc143a,hfc227ea,hfc23,hfc245fa,hfc32,hfc43-10,sf6)
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

* Baseline emissions
parameter fgases_baseline(e,t,n) 'Baseline f-gases emissions for MAC [GTonCeq]';
load_from_ssp(fgases_baseline,'e,t,n',%fgasesbaseline%,mod_fgases)

* Extrapolation post-2100
fgases_baseline(e,t,n)$(year(t) gt 2100) = max(0,valuein(2100, fgases_baseline(e,tt,n)) +
                                           (4.516 * exp(-0.2 * (year(t) - 2100)) * 
                                           (1.2214 * exp(0.2 * (year(t) - 2100))-1)-1) *
                                           smax((tt,tm1)$(year(tt) eq 2100 and pre(tm1,tt)), fgases_baseline(e,tt,n) - fgases_baseline(e,tm1,n)) / tlen(t));

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

Q_EMI.fx(fgases,t,n)$(year(t) le 2015) = fgases_baseline(fgases,t,n);
Q_EMI.lo(fgases,t,n)$(year(t) > 2015)  = 0.05 * fgases_baseline(fgases,t,n);

* Ensure baseline emissions are equal to exogenous assumptions
BAU_Q_EMI.fx(fgases,t,n) = fgases_baseline(fgases,t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eqq_emi_fgases_%clt%

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

* F-gases emissions
eqq_emi_fgases_%clt%(fgases,t,n)$(mapn_th('%clt%') and (year(t)>2010))..
                Q_EMI(fgases,t,n) =e= fgases_baseline(fgases,t,n) - Q_EMI_ABAT(fgases,t,n);

$elseif %phase%=='gdx_items'

fgases
fgases_baseline

$endif
