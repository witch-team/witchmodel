*-------------------------------------------------------------------------------
* Oil Extraction
* Options:
* - Oil Extraction sector with reduced oil grades ($setglobal mod_oilextr_simplified)
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Define default resource availability levels for baseline
$if %baseline%=='ssp1' $setglobal fossil_oil L
$if %baseline%=='ssp2' $setglobal fossil_oil M
$if %baseline%=='ssp3' $setglobal fossil_oil M
$if %baseline%=='ssp4' $setglobal fossil_oil L
$if %baseline%=='ssp5' $setglobal fossil_oil M

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

set f_mkt /'oil'/;

set extract(f) / oil/;

set oilg /g1*g8/;
alias(oilg,oilgg);

set map_oilgrade(oilg,oilgg);
map_oilgrade(oilg,oilgg) = no;
map_oilgrade(oilg,oilgg) = yes$(ord(oilg) eq ord(oilgg));

set valid_oilg(oilg);
valid_oilg(oilg)=yes;

$ifthen.f set mod_oilextr_simplified 
map_oilgrade(oilg,oilgg)=no;
map_oilgrade('g1','g1')=yes;
map_oilgrade('g2','g2')=yes;
map_oilgrade('g2','g3')=yes;
map_oilgrade('g3','g4')=yes;
map_oilgrade('g3','g5')=yes;
map_oilgrade('g4','g6')=yes;
map_oilgrade('g4','g7')=yes;
map_oilgrade('g4','g8')=yes;
valid_oilg(oilg)$(ord(oilg) ge 5)=no;
$endif.f

set conf /
'fossil_oil'.'%fossil_oil%'
$if set mod_oilextr_simplified 'mod_oilextr_simplified'.'enabled'
/;

set sys 'emission adjustement inventory' /
        extract
/;

$macro sum_oilg(expr) (sum(oilgg$map_oilgrade(oilg,oilgg), &expr))

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_mod_oil.gdx'

parameter oil_capacity(oilg,n);
$loaddc oil_capacity

parameter oil_emi_st_grade(oilg);
$loaddc oil_emi_st_grade=oil_emi_st 

parameter oil_cost_grade(oilg,n);
$loaddc oil_cost_grade=oil_cost

parameter oil_cum_grade(oilg);
$loaddc oil_cum_grade=oil_cum

parameter oem_ex(f);
$loaddc oem_ex

parameter oil_esp_capacity(oilg,*,n);
$loaddc oil_esp_capacity

parameter oil_reserve(oilg,*,n);
$loaddc oil_reserve

$gdxin

$gdxin '%datapath%data_validation.gdx'

parameter q_out_valid_weo(*,t,n);
$loaddc q_out_valid_weo

$gdxin

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

* Set correct grade level
parameter oil_cost(oilg,n);
oil_cost(oilg,n)$(valid_oilg(oilg)) = sum_oilg(oil_cost_grade(oilgg,n) * oil_esp_capacity(oilgg,'%fossil_oil%',n)) / 
                                      sum_oilg(oil_esp_capacity(oilgg,'%fossil_oil%',n));

parameter oil_cum(oilg,n);
oil_cum(oilg,n)$(valid_oilg(oilg)) = sum_oilg(oil_cum_grade(oilgg) * oil_esp_capacity(oilgg,'%fossil_oil%',n)) / 
                                     sum_oilg(oil_esp_capacity(oilgg,'%fossil_oil%',n));

parameter oil_emi_st(oilg,n);
oil_emi_st(oilg,n) = emi_st('oil') * sum_oilg(oil_emi_st_grade(oilgg) * oil_reserve(oilgg,'%fossil_oil%',n)) / 
                                     sum_oilg(oil_reserve(oilgg,'%fossil_oil%',n));

* Calibrate oil_capacity to q_out_valid_weo in 2005
oil_capacity(oilg,n) = oil_capacity(oilg,n) * valuein(2005,q_out_valid_weo('oil',tt,n)) / 
                        sum(oilgg, oil_capacity(oilgg,n));

parameter delta_oilg / 0.1 /;

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

variable Q_EMI_OUT(f,t,n) 'Emissions from PES extraction [GTonC]';
loadvarbnd(Q_EMI_OUT,'(f,t,n)',0,-inf,+inf);

positive variable OILCAP(t,n,oilg)  'Extraction capacity for each grade [TWh]';
loadvarbnd(OILCAP,'(t,n,oilg)',1e-5,1e-6,+inf);
OILCAP.fx(t,n,oilg)$(year(t) eq 2005) = sum_oilg(oil_capacity(oilgg,n));
OILCAP.fx(t,n,oilg)$(not valid_oilg(oilg)) = 0;

positive variable OILPROD(t,n,oilg) 'Oil extraction for each grade [TWh]';
loadvarbnd(OILPROD,'(t,n,oilg)',1e-5,1e-7,+inf);
OILPROD.fx(t,n,oilg)$(not valid_oilg(oilg))=0;

positive variable I_OIL(t,n,oilg) 'Investment for oil sector capital for each grade [T$]';
loadvarbnd(I_OIL,'(t,n,oilg)',1e-5,1e-6,+inf);
I_OIL.fx(t,n,oilg)$(not valid_oilg(oilg))=0;

positive variable COST_OIL(t,n,oilg) 'Cost of additional oil extraction capacity for each grade [T$/TWh]';
loadvarbnd(COST_OIL,'(t,n,oilg)',1e-5,1e-6,1e-2);
COST_OIL.fx(t,n,oilg)$(not valid_oilg(oilg))=0;

positive variable CUM_OIL(t,n,oilg) 'Total production of oil for each grade [TWh]';
loadvarbnd(CUM_OIL,'(t,n,oilg)',1e-2,1e-3,+inf);
CUM_OIL.up(t,n,oilg)$(year(t) gt 2005) = sum_oilg(oil_reserve(oilgg,'%fossil_oil%',n));
CUM_OIL.fx(t,n,oilg)$(year(t) eq 2005) = 1e-3;
CUM_OIL.fx(t,n,oilg)$(not valid_oilg(oilg)) = 0;

positive variable ADDOILCAP(t,n,oilg) 'Additional oil capacity for each grade [TWh]';
loadvarbnd(ADDOILCAP,'(t,n,oilg)',1e-5,1e-6,+inf);
ADDOILCAP.fx(t,n,oilg)$(not valid_oilg(oilg))=0;

positive variable I_OUT(f,t,n) 'Investments in extraction sector [T$]';
loadvar(I_OUT,'(f,t,n)',1e-5);
I_OUT.lo(f,t,n)$extract(f) = 1e-12;
I_OUT.up(f,t,n)$extract(f) = +inf;

positive variable Q_OUT(f,t,n) 'Extracted primary energy supplies [TWh]';
loadvarbnd(Q_OUT,'(f,t,n)',1e-5,0,+inf);

* Base year 2005
OILPROD.fx(t,n,oilg)$(year(t) eq 2005) = sum_oilg(oil_capacity(oilg,n));

* Manual calibration until 2015
Q_OUT.fx('oil',t,n)$(year(t) ge 2010 and year(t) le 2015) = q_out_valid_weo('oil',t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

eqoilcap_%clt%
eqoilprod_%clt%
eqq_out_oil_%clt%
eqcum_oil_%clt%
eqcost_oil_%clt%
eqi_oil_%clt%
eqi_out_oil_%clt%
eqq_emi_out_oil_%clt%

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

* Capacity
eqoilcap_%clt%(t,tp1,n,oilg)$(mapn_th1('%clt%') and valid_oilg(oilg))..
    OILCAP(tp1,n,oilg) =e= OILCAP(t,n,oilg) * (1-delta_oilg)**tlen(t) + tlen(t) * ADDOILCAP(t,n,oilg);

* Production
eqoilprod_%clt%(t,tp1,n,oilg)$(mapn_th1('%clt%') and valid_oilg(oilg))..
    OILPROD(tp1,n,oilg) =l= OILCAP(tp1,n,oilg);

eqq_out_oil_%clt%(t,n)$(mapn_th('%clt%'))..
    Q_OUT('oil',t,n) =e= sum(oilg$valid_oilg(oilg), OILPROD(t,n,oilg));

* Cumulative production
eqcum_oil_%clt%(t,tp1,n,oilg)$(mapn_th1('%clt%') and valid_oilg(oilg))..
    CUM_OIL(tp1,n,oilg) =e= CUM_OIL(t,n,oilg) + tlen(t) * OILPROD(t,n,oilg);

* Cost
eqcost_oil_%clt%(t,tp1,n,oilg)$(mapn_th1_last('%clt%') and valid_oilg(oilg))..
    COST_OIL(t,n,oilg) =e= oil_cost(oilg,n) * (0.9 + 0.1 * tlen(t) * (ADDOILCAP(t,n,oilg) / sum_oilg(oil_esp_capacity(oilgg,'%fossil_oil%',n)))**3) +
                           oil_cost(oilg,n) * 0.1 * (tlen(t) * ADDOILCAP(t,n,oilg) / sum_oilg(oil_esp_capacity(oilgg,'%fossil_oil%',n)))**(1/3) +
                           oil_cum(oilg,n) * ((tlen(t) * OILPROD(t,n,oilg) + CUM_OIL(t,n,oilg)) / (sum_oilg(oil_reserve(oilgg,'%fossil_oil%',n))))**3;

* Investments
eqi_oil_%clt%(t,tp1,n,oilg)$(mapn_th1_last('%clt%') and valid_oilg(oilg))..
    I_OIL(t,n,oilg) =e= ADDOILCAP(t,n,oilg) * COST_OIL(t,n,oilg);

* Total investment
eqi_out_oil_%clt%(t,tp1,n)$(mapn_th1_last('%clt%')).. 
    I_OUT('oil',t,n) =e= sum(oilg$valid_oilg(oilg), I_OIL(t,n,oilg));

* Emissions
eqq_emi_out_oil_%clt%(t,n)$(mapn_th('%clt%'))..
    Q_EMI_OUT('oil',t,n) =e= sum(oilg$valid_oilg(oilg), (oil_emi_st(oilg,n) + emi_sys('extract',t,n)) * OILPROD(t,n,oilg));

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

MCOST_FUEL.fx('oil',t,n)$(not tfix(t)) = max(sum(tfirst, FPRICE.l('oil',tfirst))*0.1, FPRICE.l('oil',t) + p_mkup('oil',t,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='fix_variables'

tfixvar(CUM_OIL,'(t,n,oilg)')    
tfixvar(OILCAP,'(t,n,oilg)')
tfixvar(OILPROD,'(t,n,oilg)')    
tfixvar(Q_EMI_OUT,'(f,t,n)')
tfixvar(Q_OUT,'(f,t,n)')

tfix1var(ADDOILCAP,'(t,n,oilg)')
tfix1var(COST_OIL,'(t,n,oilg)')
tfix1var(I_OIL,'(t,n,oilg)')
tfix1var(I_OUT,'(f,t,n)')

*-------------------------------------------------------------------------------
$elseif %phase%=='dynamic_calibration'


emi_sys('extract',t,n)$(year(t) le 2015) = (q_emi_valid('co2_out',t,n) - sum(oilg$valid_oilg(oilg), (oil_emi_st(oilg,n)) * OILPROD.l(t,n,oilg)))/(sum(oilg, OILPROD.l(t,n,oilg))*card(oilg));
emi_sys('extract',t,n)$(year(t) gt 2015) = valuein(2015, emi_sys('extract',tt,n));

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

* Sets
map_oilgrade
oilg
valid_oilg

* Parameters
delta_oilg
oil_emi_st
oil_esp_capacity
oem_ex
oil_capacity
oil_cost
oil_cost_grade
oil_cum
oil_cum_grade
oil_emi_st_grade
oil_reserve

* Variables
ADDOILCAP
COST_OIL
CUM_OIL
I_OIL
I_OUT
OILCAP
OILPROD
Q_EMI_OUT
Q_OUT

$endif
