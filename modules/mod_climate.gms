*-------------------------------------------------------------------------------
* Climate
*
* Represents the climate
* - based on the DICE model equations
* - Radiative forcing for non CO2 ghgs
* - parameters calibrated to reproduce MAGICC6.4 default response
*
*  Options:
* - Climate is post-processed (default) or solved by the solver ($setglobal solve_climate)
* - $setglobal cooperate_on_climate {'YES','NO'}
* - 'YES'(default): Countries within a coalition act in cooperation
*   'NO': Countries within a coalition act individually
*
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Check requirements
$if set solve_climate $ifi not '%cooperate_on_climate%'=='YES' $ifi not '%cooperate_on_climate%'=='NO' $abort 'ERROR: solve_climate requires "cooperate_on_climate" to be defined as "YES" or "NO".'

$elseif %phase%=='sets'

set oghg(e) 'Other GHGs' /
c2f6 
c6f14 
cf4     
ch4
hfc125 
hfc134a 
hfc143a
hfc227ea
hfc23 
hfc245fa 
hfc32 
hfc43-10
n2o
sf6
/;

set m /
        atm 'Atmosphere'
        upp 'Upper box'
        low 'Deep oceans'
      /;

alias (m,mm);

set map_e_bunk(e,ee) 'map regional and international emissions' / /;

set conf /
$if set solve_climate 'solve_climate'.'enabled'
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_mod_climate'

parameter emi_gwp(ghg)  'Global warming potential over a time horizon of 100 years (2007 IPCC AR4) [GTonCO2eq/GTon]';
$loaddc emi_gwp

parameter tempc(*) 'Temperature update coefficients';
$loaddc tempc

parameter rfc(e,*) 'Radiative forcing update coefficients';
$loaddc rfc

parameter temp0(m) 'Initial temperature [deg C above preindustrial levels]';
$loaddc temp0

parameter wcum_emi0(e,m) 'Initial world GHG emissions [GTon]';
$loaddc wcum_emi0

parameter wcum_emi_eq(e) 'GHG stocks not subject to decay [GTon]';
$loaddc wcum_emi_eq

parameter emi_preind(e) 'Stocks of non-CO2 gases in pre-industrial [GTon]';
$loaddc emi_preind

parameter cmphi(m,mm) 'Carbon Cycle transfert matrix';
$loaddc cmphi

parameter cmdec1(e) 'Yearly retention factor for non-co2 gases';
$loaddc cmdec1

parameter cmdec2(e) 'One period retention factor for non-co2 ghg';
$loaddc cmdec2

* Calibrate on average runs with WITCH given MAGICC outputs
parameter rfaerosols(t) 'Radiative forcing from others (aerosols indirect and direct effects, ozone)';
$loaddc rfaerosols

$gdxin

parameter wemi(e,t)     'World GHG emissions';
parameter wemi2qemi(e)  'Conversion factor W_EMI [GtC for CO2, Gt for others] into Q_EMI [GtonCeq]';

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

wemi2qemi(ghg)   = emi_gwp(ghg) / c2co2;
wemi2qemi('co2') = 1;

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

positive variable TEMP(m,t,n) 'Temperature [deg C above preindustrial levels]';
loadvarbnd(TEMP,'(m,t,n)',1,0,+inf);
TEMP.fx(m,tfirst,n) = temp0(m);

variable TRF(t,n) 'Total radiative forcing [W/m2]';
loadvarbnd(TRF,'(t,n)',0,-inf,+inf);

variable RF(e,t,n) 'Radiative forcing [W/m2]';
loadvarbnd(RF,'(e,t,n)',0,-inf,+inf);

variable W_EMI(e,t,n) 'World emissions during 5-year period [GTon/yr]';
loadvarbnd(W_EMI,'(e,t,n)',0,-inf,+inf);
W_EMI.lo('co2',t,n) = -20;

positive variable WCUM_EMI(e,m,t,n) 'Global stock of GHG [GTon]';
loadvarbnd(WCUM_EMI,'(e,m,t,n)',wcum_emi0(e,m),0,+inf);
WCUM_EMI.fx(ghg(e),m,tfirst,n)$wcum_emi0(e,m) = wcum_emi0(e,m);

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

$ifthen.f set solve_climate
eqw_emi_%clt%
eqwcum_emi_co2_%clt%
eqwcum_emi_oghg_%clt%
eqtemp_atm_%clt%
eqtemp_low_%clt%
eqrf_tot_%clt%
eqrf_co2_%clt%
eqrf_oghg_exp_%clt%
$endif.f

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

$ifthen.f set solve_climate

$iftheni.coop %cooperate_on_climate%=='YES'

* World GHG emissions (in GTon!)
eqw_emi_%clt%(ghg,t,n)$(mapn_th('%clt%'))..
                W_EMI(ghg,t,n) - wemi(ghg,t) =e= sum(nn$map_clt_n('%clt%',nn), Q_EMI(ghg,t,nn) - Q_EMI.l(ghg,t,nn)) / wemi2qemi(ghg);

$else.coop

* World GHG emissions (in GTon!)
eqw_emi_%clt%(ghg,t,n)$(mapn_th('%clt%'))..
                W_EMI(ghg,t,n) - wemi(ghg,t) =e= (Q_EMI(ghg,t,n) - Q_EMI.l(ghg,t,n)) / wemi2qemi(ghg);

$endif.coop

* Accumulation of Carbon in the atmosphere / upper box / deep oceans
eqwcum_emi_co2_%clt%(m,t,tp1,n)$(mapn_th1('%clt%'))..
                WCUM_EMI('co2',m,tp1,n) =e= sum(mm, cmphi(mm,m) * WCUM_EMI('co2',mm,t,n))
                                            + ( tlen(t) * W_EMI('co2',t,n) )$(sameas(m,'atm'));

* Accumulation of OGHG in the atmosphere
eqwcum_emi_oghg_%clt%(oghg,t,tp1,n)$(mapn_th1('%clt%'))..
                WCUM_EMI(oghg,'atm',tp1,n) =e=
                        WCUM_EMI(oghg,'atm',t,n)*cmdec1(oghg)**tlen(t)
                        +cmdec2(oghg)*(W_EMI(oghg,t,n)+W_EMI(oghg,tp1,n))/2
                        +(1-cmdec1(oghg)**tlen(t))*wcum_emi_eq(oghg);

* Total radiative forcing
eqrf_tot_%clt%(t,n)$(mapn_th('%clt%'))..
                TRF(t,n) =e= sum(ghg, RF(ghg,t,n)) + rfaerosols(t)
$iftheni.coop %cooperate_on_climate%=='YES'
$if set mod_srm + geoeng_forcing*(wsrm(t) + sum(nn$map_clt_n('%clt%',nn), (SRM(t,nn) - SRM.l(t,nn))));
$else.coop
$if set mod_srm + geoeng_forcing*(wsrm(t) + (SRM(t,n) - SRM.l(t,n)))
$endif.coop
;

* CO2 radiative forcing
eqrf_co2_%clt%(t,n)$(mapn_th('%clt%'))..
                RF('co2',t,n) =e= rfc('co2','alpha') * 
                                  (log(WCUM_EMI('co2','atm',t,n)) - log(rfc('co2','beta')));

* CH4, N2O, SLF and LLF radiative forcing
eqrf_oghg_exp_%clt%(oghg,t,n)$(mapn_th('%clt%'))..
                RF(oghg,t,n) =e= rfc(oghg,'inter') * rfc(oghg,'fac') * 
                                    ((rfc(oghg,'stm') * WCUM_EMI(oghg,'atm',t,n))**rfc(oghg,'ex') - 
                                     (rfc(oghg,'stm') * emi_preind(oghg))**rfc(oghg,'ex'));

* Global temperature increase from pre-industrial levels
eqtemp_atm_%clt%(t,tp1,n)$(mapn_th1('%clt%'))..
                TEMP('atm',tp1,n) =e= TEMP('atm',t,n) +
                                      tempc('sigma1') * 
                                        (TRF(t,n) - 
                                         tempc('lambda') * TEMP('atm',t,n) -
                                         tempc('sigma2') * (TEMP('atm',t,n) - TEMP('low',t,n)));

eqtemp_low_%clt%(t,tp1,n)$(mapn_th1('%clt%'))..
                TEMP('low',tp1,n) =e= TEMP('low',t,n) + tempc('heat_ocean') * (TEMP('atm',t,n) - TEMP('low',t,n));


$endif.f

*-------------------------------------------------------------------------------
$elseif %phase%=='fix_variables'

tfixvar(TEMP,'(m,t,n)')
tfixvar(TRF,'(t,n)')
tfixvar(RF,'(e,t,n)')
tfixvar(W_EMI,'(ghg,t,n)')
tfixvar(WCUM_EMI,'(e,m,t,n)')

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

wemi(ghg(e),t) = sum(n, Q_EMI.l(e,t,n)) / wemi2qemi(e) + sum((n,ee)$(map_e_bunk(e,ee)), W_EMI.l(ee,t,n)) / card(n);

*-------------------------------------------------------------------------------
$elseif %phase%=='after_solve'

wemi(ghg(e),t) = sum(n, Q_EMI.l(e,t,n)) / wemi2qemi(e) + sum((n,ee)$(map_e_bunk(e,ee)), W_EMI.l(ee,t,n)) / card(n);

$ifthen.f not set solve_climate

W_EMI.l(ghg,t,n)$(not tfix(t)) = wemi(ghg,t);

loop((t,tp1)$(pre(t,tp1)),

WCUM_EMI.l('co2',m,tp1,n)$(not tfix(tp1)) = sum(mm, cmphi(mm,m) * WCUM_EMI.l('co2',mm,t,n)) +
                            ( tlen(t) * wemi('co2',t) )$( sameas(m,'atm') );

WCUM_EMI.l(oghg,'atm',tp1,n)$(not tfix(tp1)) = WCUM_EMI.l(oghg,'atm',t,n)*cmdec1(oghg)**tlen(t)
                                 +cmdec2(oghg)*(wemi(oghg,t) +wemi(oghg,tp1))/2
                                 +(1-cmdec1(oghg)**tlen(t))*wcum_emi_eq(oghg);
);


RF.l('co2',t,n)$(not tfix(t)) = rfc('co2','alpha')*(log(WCUM_EMI.l('co2','atm',t,n))- log(rfc('co2','beta')));

RF.l(oghg,t,n)$(not tfix(t)) = rfc(oghg,'inter')*rfc(oghg,'fac')*((rfc(oghg,'stm')*WCUM_EMI.l(oghg,'atm',t,n))**rfc(oghg,'ex')
                                        -(rfc(oghg,'stm')*emi_preind(oghg))**rfc(oghg,'ex'));

TRF.l(t,n)$(not tfix(t)) = sum(ghg,RF.l(ghg,t,n)) + rfaerosols(t)
$if set mod_srm +geoeng_forcing*W_SRM.l(t,n)
                ;

loop((t,tp1)$pre(t,tp1),
TEMP.l('atm',tp1,n)$(not tfix(tp1)) = TEMP.l('atm',t,n) + 
                                           tempc('sigma1') * 
                                            (TRF.l(t,n) - 
                                             tempc('lambda') * TEMP.l('atm',t,n) -
                                             tempc('sigma2') * (TEMP.l('atm',t,n) - TEMP.l('low',t,n)));

TEMP.l('low',tp1,n)$(not tfix(tp1)) = TEMP.l('low',t,n) + tempc('heat_ocean') * (TEMP.l('atm',t,n) - TEMP.l('low',t,n));
);

$endif.f

$elseif %phase%=='gdx_items'

* Sets
m
oghg

* Parameters
cmdec1
cmdec2
cmphi
emi_gwp
emi_preind
rfaerosols
rfc
temp0
tempc
wcum_emi0
wcum_emi_eq
wemi
wemi2qemi

* Variables
RF
TEMP
TRF
W_EMI
WCUM_EMI

$endif
