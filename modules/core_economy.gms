*-------------------------------------------------------------------------------
* Economy
* - Production and Consumption definition
* - Top-level of the production function
* Options:
* --original_ssp=1 : original SSP population and GDP data
*-------------------------------------------------------------------------------

$ifthen %phase%=='sets'

set g 'Goods sector' /
    fg 'Final Good'
/;

set iq 'Economy nodes' /
    y       'Production'
    cc      'Consumption'
    kl      'Aggregate Capital-Labor'
    fen     'Energy services'
    eifen
    en      'Energy'
    el      'Electricity'
    el2
    elffren
    elff
    nel     'Non-electric energy'
    nelog
    ces_elhydro
    ces_elnuclearback
    ces_elintren
    ces_elcoalwbio
    ces_eloil
    ces_elgas
    ces_nelgas
/;

set ccy(*) 'additionnal cost categories' / /;

set ssp 'SSP baseline names' / ssp1,ssp2,ssp3,ssp4,ssp5 /;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

* Parameters from static calibration
parameter alpha(*,n) 'Production function shares of calibration nodes';
parameter q0(*,n)    'Base year values of calibration nodes';
parameter rho(*,t)     'Rho CES coefficients';
parameter delta0(g)  'Final good depreciation';

$ifthen.cg set calibgdx
$gdxin '%calibgdx%'
$loaddc alpha q0 delta0 
$load rho
$gdxin
$endif.cg

parameter ykali(t,n) 'GDP for the dynamic calibration [T$]';
load_from_ssp(ykali,'t,n',%baseline%,baseline)

parameter l(t,n) 'Population [million people]';
load_from_ssp(l,'t,n',%baseline%,baseline)

parameter gdppc_kali(t,n) 'GDP per capita used for calibration [MER]';
gdppc_kali(t,n) = ykali(t,n) / l(t,n) * 1e6;

* Adjust population and GDP data until present to historical values maintaining GDP per capita growth
$ifthen.vd not set original_ssp

$gdxin %datapath%data_validation
parameter ykali_valid(t,n), l_valid(t,n);
$loaddc ykali_valid=ykali_valid_wdi l_valid=l_valid_wdi
parameter i_valid(*,t,n);
$loaddc i_valid=i_valid_wdi
$gdxin

parameter lrate(t,n);
parameter gdppcrate(t,n);

loop((t,tp1)$(pre(t,tp1)),
  lrate(tp1,n) = l(tp1,n) / l(t,n);
  gdppcrate(tp1,n) =  gdppc_kali(tp1,n) / gdppc_kali(t,n);
);

l(t,n)$(year(t) le 2015) = l_valid(t,n);
gdppc_kali(t,n)$(year(t) le 2015) = ykali_valid(t,n) / l_valid(t,n) * 1e6;

loop((t,tp1)$(pre(t,tp1) and (year(tp1) gt 2015)),
  l(tp1,n) = l(t,n) * lrate(tp1,n);
  gdppc_kali(tp1,n) = gdppc_kali(t,n) * gdppcrate(tp1,n);
);

$endif.vd

ykali(t,n) = gdppc_kali(t,n) * l(t,n) / 1e6;

* Conversion factors between PPP and MER
$gdxin %datapath%data_baseline
parameter ppp2mer(t,n) 'ratio to convert PPP to MER';
$loaddc ppp2mer
$gdxin
parameter mer2ppp(t,n) 'ratio to convert MER to PPP';
mer2ppp(t,n) = 1 / ppp2mer(t,n);

* TFP
parameter tfpy(t,n) 'Total Factor Productivity';
parameter tfpn(t,n) 'Total Factor Productivity on energy';

$ifthen.tg set tfpgdx
$gdxin '%tfpgdx%'
$loaddc tfpy tfpn
$gdxin
$endif.tg

parameter m_eqq_y(t,n) 'Marginal value of the production equation';

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

parameter delta(g);
delta(g) = delta0(g);

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

positive variable K(g,t,n) 'Capital for production [T$]';
loadvarbnd(K,'(g,t,n)',1e-5,1e-6,400);
K.fx('fg',tfirst,n) = q0('k',n);

positive variable Q(iq,t,n) 'Upper CES tree nodes [T$]';
loadvarbnd(Q,'(iq,t,n)',1e-5,1e-8,1e5);
Q.l('eifen',t,n) = Q.l('fen',t,n);
* final good consumption lower bounded to 5% of the 2005 GDP to
* povide the solver for a realistic trust interval
* (Relax it if lower consumption levels are needed).
Q.lo('cc',t,n) = 0.01 * ykali(tfirst,n);
Q.l('kl',t,n) = NA; # not determined by the model

positive variable I(g,t,n) 'Investments in goods [T$]';
loadvarbnd(I,'(g,t,n)',1e-5,1e-8,100);

variable COST_Y(ccy,t,n) 'Additionnal costs from modules [T$]';
loadvarbnd(COST_Y,'(ccy,t,n)',0,0,+1e6);

* BAU data
variable BAU_Q(iq,t,n);
execute_load '%baugdx%', BAU_Q=Q;

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eqk_%clt%
eqq_cc_%clt%
eqq_fen_%clt%
eqq_y_%clt%

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

* Production
eqq_y_%clt%(t,n)$(mapn_th('%clt%'))..

    Q('y',t,n) =e= ces('y', 'kl', tfpy(t,n)*cobb('kl', 'k', K('fg',t,n), 'l',l(t,n)), 'fen', Q('fen',t,n))
                   ## Climate feedback on economy
$if set damage_feedback / OMEGA(t,n)
                   ## Net cost of Primary and Secondary Energy Sources
                   - sum(fuel, COST_FUEL(fuel,t,n))
                   ## GHG emissions costs (co2 for nip, emac for abat mac, sink)
                   - sum(cce, COST_EMI(cce,t,n))
                   ## Carbon tax
                   - sum(ghg, ctax(ghg,t,n) * (Q_EMI(ghg,t,n) - Q_EMI.l(ghg,t,n)))
                   ## Additionnal costs on gross product
                   - sum(ccy, COST_Y(ccy,t,n))
;

* Consumption
eqq_cc_%clt%(t,tp1,n)$(mapn_th1_last('%clt%'))..
    Q('cc',t,n) =e= Q('y',t,n)
                    ## Investments in goods g (final good, adaptation)
                    -sum(g, I(g,t,n))
                    ## Investments in r&d
                    -sum(rd, I_RD(rd,t,n)) * rd_crowd_out
                    ## Investments in energy technlogies
                    -sum(jinv, I_EN(jinv,t,n))
                     ## Investments in grid infrastructures
                    - I_EN_GRID(t,n)
                    ## Investments in extraction sector
                    -sum(extract(f), I_OUT(f,t,n))
                    ## O&M for energy technlogies
                    -sum(jreal, oem(jreal,t,n) * K_EN(jreal,t,n))
                    ## O&M for extraction
                    -sum(extract(f), oem_ex(f) * Q_OUT(f,t,n))
                    ## Energy technology penalty costs
                    -sum(jpenalty(j), COST_EN(j,t,n))
;

* Capital accumulation
eqk_%clt%(g,t,tp1,n)$mapn_th1('%clt%')..
    K(g,tp1,n) =e= K(g,t,n)*(1-delta(g))**tlen(t) + tlen(t) * I(g,t,n);

* Energy services
eqq_fen_%clt%(t,n)$(mapn_th('%clt%'))..
    Q('fen',t,n) =e= ces('fen', 'krd_en', K_RD('en',t,n), 'en', tfpn(t,n) * Q('en',t,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='fix_variables'

tfixvar(K,'(g,t,n)')
tfix1var(I,'(g,t,n)')

* Q follows tfixvar apart from Q('cc') which follows tfix1var
loadfix(Q,'(iq,t,n)',variable)
Q.fx(iq,t,n)$((not sameas(iq,'cc')) and tfix(t)) = FIXQ.l(iq,t,n);
loop((t,tfix(tp1))$pre(t,tp1), Q.fx('cc',t,n) = FIXQ.l('cc',t,n));

tfixpar(m_eqq_y,'(t,n)')

*-------------------------------------------------------------------------------
$elseif %phase%=='summary report'

Parameters
  interest_rate(t,n) 'Interest rate (instantaneous short-term rates)'
  interest_rate30yrs(t,n) 'Interest rate average over 30 years for long-term calculations'
;

interest_rate(t,n)= q0('y',n) * (
    alpha('kl',n) * (tfpy(t,n) * (K.l('fg',t,n)/q0('k',n))**alpha('k',n)*(l(t,n)/q0('l',n))**alpha('l',n))**rho('y',t)+
    alpha('fen',n) * (Q.l('fen',t,n)/q0('fen',n))**rho('y',t))**(1/rho('y',t)-1)*
    alpha('kl',n) * (tfpy(t,n) * (K.l('fg',t,n)/q0('k',n))**alpha('k',n)*(l(t,n)/q0('l',n))**alpha('l',n))**(rho('y',t)-1)*
    tfpy(t,n) * alpha('k',n) * (K.l('fg',t,n)/q0('k',n)) **(alpha('k',n)-1)*(l(t,n)/q0('l',n)) ** alpha('l',n) *
    1 / q0('k', n)
$if set solve_damage  / OMEGA.l(t,n)
    - (1 - (1 - delta('fg')) ** tlen(t)) / tlen(t);

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Sets
g
iq

* Parameters
alpha
delta
delta0
l
mer2ppp
m_eqq_y
ppp2mer
q0
rho
tfpn
tfpy
ykali
gdppc_kali

* Variables
I
K
Q
BAU_Q
COST_Y

$endif
