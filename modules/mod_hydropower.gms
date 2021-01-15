*-------------------------------------------------------------------------------
* Hydro Power
*-------------------------------------------------------------------------------

$ifthen %phase%=='sets'

set j /
    elhydro       'Power plant | Hydro | All'
    elhydro_new   'Power plant | Hydro | New'
    elhydro_old   'Power plant | Hydro | Old'
/;
set jreal(j) / elhydro_new, elhydro_old /;
set jel(jreal) / elhydro_new, elhydro_old /;
set jold(jel) / elhydro_old /;
set jinv(jreal) / elhydro_new /;
set jel_ren(jel) /elhydro_old, elhydro_new/;
set map_j(j,jj) /
    el.elhydro
    elhydro.(elhydro_new, elhydro_old)
/;
set ices_el(iq) /ces_elhydro/;
set map_ices_el(ices_el,j)/
ces_elhydro.elhydro
/;
set jcalib /elhydro/;

set map_calib(jcalib,jreal) /
elhydro.(elhydro_new,elhydro_old)
/;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

$gdxin '%datapath%data_mod_hydropower'
parameter k_en_hydro(n) 'Factor for exogenous investment profiles';
$loaddc k_en_hydro
$gdxin

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

I_EN.fx('elhydro_new',t,n)$(year(t) ge 2015) = k_en0('elhydro_old',n) *
                             k_en_hydro(n) *
                             mcost_inv0('elhydro_new',n) *
                             0.12 * (1-(1-delta_en0('elhydro_new',n))**5) /
                             (1-(1-0.12)**5) *
                             (1-(1-0.12)**(5 * 10)) /
                             (1-(1-delta_en0('elhydro_new',n))**(5 * 10))
;

* Scaling for the solver
K_EN.scale('elhydro_old',t,n) = 1e-3;
K_EN.scale('elhydro_new',t,n) = 1e-3;

Q.scale('ces_elhydro',t,n) = 1e-3;

Q_EN.scale('elhydro',t,n) = 1e-3;
Q_EN.scale('elhydro_new',t,n) = 1e-3;
Q_EN.scale('elhydro_old',t,n) = 1e-3;

$endif
