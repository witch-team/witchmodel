*-------------------------------------------------------------------------------
* Default Climate Policy Implementation
*
* Options:
*    --policy={bau (default),ctax}
*        Implement a climate policy setting
*  [ --scen= ]
*        Policy variant.
*        For ctax, it can be {ramsey,spa,XXX}, defining the growh rate of tax:
*          * XXX for a fixed percentage/yr (e.g. 5) growth
*          * 'ramsey' (default) for world average Ramsey consumption discount rate
*  [ --ctax_year=2020 ]
*        Starting year of the carbon tax
*  [ --ctax_initial=30 ]
*        Initial level of tax [USD2005/tCO2eq] (if %policy%==ctax)
*
*-------------------------------------------------------------------------------
$ifthen %phase%=='conf'

* Carbon tax default options
$ifthen.cx '%policy%'=='ctax'
** Starting year of the carbon tax
$setglobal ctax_year 2020
** Initial level of tax [USD2005/tCO2eq]
$setglobal ctax_initial 30
** Growh rate of tax, in percentage/yr (e.g. 5) or equal to
** 'ramsey' for world average Ramsey consumption discount rate
$setglobal scen ramsey
$endif.cx

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

* Runs
set run /r1/;
set to_run(run);

* Trading
set trading_t(*,t,n) 'Periods for the international markets per regions';
trading_t(c_mkt,t,n) = no;
trading_t(f_mkt,t,n) = no;

set internal(*) 'Internal markets [within coalition]';
internal(c_mkt) = no;
internal(f_mkt) = no;

set internal_clt(*,clt) 'Mapping between coalition and internal market';
internal_clt(c_mkt,clt) = no;
internal_clt(f_mkt,clt) = no;

set t_cap(t,n) 'Cap on emissions time periods and regions';
t_cap(t,n) = no;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

parameter ctax(ghg,t,n) 'Carbon tax [T$/GTonC]';

*-------------------------------------------------------------------------------
$elseif %phase%=='policy'

* Initialization

* Trading all time periods
trading_t(c_mkt,t,n) = yes;
trading_t(f_mkt,t,n) = yes;

* No carbon tax
ctax(ghg,t,n) = 0;

* Default emission cap
e_cap(ghg) = yes;
emi_cap(t,n) = 500;

$ifthen.pol %policy%=="bau"

to_run('r1') = yes;
trading_t(c_mkt,t,n) = no;

$elseif.pol %policy%=="ctax"

trading_t(c_mkt,t,n) = no;
to_run('r1') = yes;

ctax(ghg,t,n)$(year(t) eq %ctax_year%) = (%ctax_initial%) * c2co2 * 1e-3;
ctax(ghg,t,n)$(year(t) gt %ctax_year%) = valuein(%ctax_year%,ctax(ghg,tt,n)) * 
$iftheni.cg '%scen%'=='ramsey'
( 
  (((sum(nn, Q.l('cc',t,nn))/sum(nn, l(t,nn))) / (sum(nn, valuein(%ctax_year%,Q.l('cc',tt,nn))) / sum(nn, valuein(%ctax_year%,l(tt,nn)))))**(eta)) * 
  ((stpf(t)/valuein(%ctax_year%,stpf(tt)))**(-1))
)
$else.cg
((1+(%scen%)/100)**(year(t)-%ctax_year%))
$endif.cg
;

emi_cap(t,n) = 100; # very high number

$endif.pol

*-------------------------------------------------------------------------------
$elseif %phase%=='before_nashloop'

internal_clt(c_mkt,clt)$(internal(c_mkt) and (sum((t,n)$(map_clt_n(clt,n) and trading_t(c_mkt,t,n)),1) ge 1)) = yes;
internal_clt(f_mkt,clt)$(internal(f_mkt) and (sum((t,n)$(map_clt_n(clt,n) and trading_t(f_mkt,t,n)),1) ge 1)) = yes;

trading_t(c_mkt,t,n) = yes$(trading_t(c_mkt,t,n) and (not tfix(t)));

* By default no trading -> no cap, if t_cap was not set
if(card(t_cap) eq 0,
  t_cap(t,n) = yes$(sum(c_mkt$trading_t(c_mkt,t,n),1));
);

$elseif %phase%=='gdx_items'

run
to_run

internal
internal_clt
trading_t
t_cap

ctax

$endif
