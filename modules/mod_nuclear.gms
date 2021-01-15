*-------------------------------------------------------------------------------
* Nuclear power plants
*-------------------------------------------------------------------------------

$ifthen %phase%=='sets'

set j 'Energy Technology Sectors' /
    elnuclear
    elnuclear_new
    elnuclear_old
/;

set jreal(j) 'Actual Energy Technology Sectors' /
    elnuclear_new
    elnuclear_old
/;

set jel(jreal) 'Electrical Actual Energy Technology Sectors' /
    elnuclear_new
    elnuclear_old
/;

set jel_nuclear(jel) 'Nuclear power plants' /
    elnuclear_new
    elnuclear_old
/;

set jfed(jreal) 'Actual Energy Technology Sectors fed by PES' /
    elnuclear_new
    elnuclear_old
/;

set jinv(jreal) 'Electrical Actual Energy Technology Sectors with investments' /
    elnuclear_new
/;

set jold(jel) 'Old Electrical Actual Energy Technology Sectors' /
    elnuclear_old
/;

set map_j(j,jj) 'Relationships between Energy Technology Sectors' /
    elnuclearback.elnuclear
    elnuclear.(elnuclear_new, elnuclear_old)
/;

set jel_firm 'Firm, non intermittent technologies' /
    elnuclear_new
    elnuclear_old
/;

set jel_stdgrid(jel) 'Technologies requiring standard grid infrastructure (i.e. no W&S)' /
    elnuclear_new
    elnuclear_old
/;

set iwaste / alpha, rho /;



*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_mod_nuclear'

parameter cwaste(iwaste);
$loaddc cwaste

$gdxin

parameter cwaste_reg(iwaste,n);
cwaste_reg(iwaste,n) = cwaste(iwaste);
cwaste_reg('rho',n) = 1.8;

parameter wastemgm(t,n) 'Waste management costs';

scalar twh2tonU / 24.4119 /;

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

K_EN.scale('elnuclear_new',t,n) = 1e-3;
K_EN.scale('elnuclear_old',t,n) = 1e-3;

Q_EN.scale('elnuclear',t,n) = 1e-3;
Q_EN.scale('elnuclear_new',t,n) = 1e-3;
Q_EN.scale('elnuclear_old',t,n) = 1e-3;

I_EN.scale('elnuclear_new',t,n) = 1e-3;

Q_IN.scale('uranium',jfed,t,n)$csi('uranium',jfed,t,n) = 1e-3;
Q_FUEL.scale('uranium',t,n) = 1/twh2tonU;

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

if(sum((tt,n)$tfirst(tt),Q_EN.l('elnuclear',tt,n)) gt 0,
    wastemgm(t,n) =  cwaste_reg('alpha',n) * 
                     ( sum(nn, Q_EN.l('elnuclear',t,nn)) / 
                       sum((tt,nn)$tfirst(tt),Q_EN.l('elnuclear',tt,nn))
                     )**cwaste_reg('rho',n);
);
oem(jreal,t,n)$(map_j('elnuclear',jreal)) = oem0(jreal,n) + wastemgm(t,n);

$elseif %phase%=='gdx_items'

* Parameters
cwaste
cwaste_reg
wastemgm
twh2tonU

$endif
