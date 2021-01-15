*-------------------------------------------------------------------------------
* ADMM algorithm
*-------------------------------------------------------------------------------
$set phase %1

*-------------------------------------------------------------------------------
$ifthen.a %phase%=='init'

* ADMM residual balancing parameters
** Threshold for ratio between scaled residuals to trigger change in rho
$setglobal admm_mu 5
** Multiplicative factor used to increase or decrease rho
** (use either number or "dynamic")
$setglobal admm_tau 2
** If admm_tau is dynamic, max tau to use
$setglobal admm_tau_max 10
** Order of magnitude between relative primal and dual residuals, oil market
$setglobal admm_csi_exp_oil 0
** Order of magnitude between relative primal and dual residuals, nip market
$setglobal admm_csi_exp_nip 0

parameters
    u_admmiter(siter,*,t) 'ADMM dual variable scaled'
    x_admmiter(siter,*,t,n) 'Regional trade imbalance over iterations'
    xavg_admmiter(siter,*,t) 'Average trade imbalance over iterations'
    z_admm(*,t,n) 'ADMM copy variable of x used for trade clearing'
    z_admmiter(siter,*,t,n) 'ADMM copy variable of x used for trade clearing over iterations'
    r_admm(siter,*) 'ADMM primal residual'
    rrel_admm(siter,*) 'ADMM relative primal residual'    
    s_admm(siter,*) 'ADMM dual residual'
    srel_admm(siter,*) 'ADMM relative dual residual'    
    delta_price_off(t) 'Offset for proposed ADMM price to fit into WITCH price update framework'
    csi_admm(*) 'ADMM scaling coefficient to balance primal and dual residuals'
    admm_tau(siter,*) 'ADMM multiplicative factor used to increase or decrease rho'
;

scalar admm_mu 'ADMM threshold for ratio between scaled residuals to trigger change in rho' / %admm_mu% /;

csi_admm('oil') = 1e%admm_csi_exp_oil%;
csi_admm('nip') = 1e%admm_csi_exp_nip%; # TOCHECK

*-------------------------------------------------------------------------------
$elseif.a %phase%=='before_solve'

t_admm(mkt,t) = yes$(sum(n$trading_t(mkt,t,n),1) gt 0);

if(ord(siter) eq 1,
    z_admm(mkt,t,n)$(t_admm(mkt,t)) = 0;
    u_admm(mkt,t)$(t_admm(mkt,t) and xiny(mkt,f_mkt)) = cast(FPRICE.l(f_mkt,t),f_mkt,mkt)/rho_admm(mkt,t);
    u_admm(mkt,t)$(t_admm(mkt,t) and xiny(mkt,c_mkt)) = cast(CPRICE.l(c_mkt,t),c_mkt,mkt)/rho_admm(mkt,t);
    x_admm(mkt,t,n)$(trading_t(mkt,t,n) and xiny(mkt,f_mkt)) = cast((Q_FUEL.l(f,t,n) - Q_OUT.l(f,t,n)),f,mkt);
    x_admm(mkt,t,n)$(trading_t(mkt,t,n) and xiny(mkt,c_mkt)) = cast((Q_EMI.l(e,t,n)),e,mkt);
    xavg_admm(mkt,t)$(t_admm(mkt,t)) = (sum(n$trading_t(mkt,t,n),x_admm(mkt,t,n)))/(sum(n$trading_t(mkt,t,n),1));
);

*-------------------------------------------------------------------------------
$elseif.a %phase%=='check_convergence'

allerr_admm(run,siter,'oil',t)$(external('oil') and tcheck(t) and (sum(n$(trading_t('oil',t,n)),1)>0)) = 100 *
                                                    abs(errtrade('oil',t)) * FPRICE.l('oil',t) / 
                                                    (sum(n$trading_t('oil',t,n),Q.l('CC',t,n)) + 1e-5);

allerr_admm(run,siter,c_mkt,tcheck(t))$(external('oil') and (sum(n$(trading_t(c_mkt,t,n)),1)>0)) = 100 *
                                                    abs(errtrade(c_mkt,t)) * CPRICE.l(c_mkt,t) / 
                                                    (sum(n$trading_t(c_mkt,t,n),Q.l('CC',t,n)) + 1e-5);

*-------------------------------------------------------------------------------
$elseif.a %phase%=='external_markets'

* Follow http://stanford.edu/~boyd/papers/pdf/admm_distr_stats.pdf (pp.56-60)
loop((mkt)$(external(mkt) and (sum((t,n)$trading_t(mkt,t,n),1) gt 0)),
    x_admmiter(siter,mkt,t,n)$trading_t(mkt,t,n) = x_admm(mkt,t,n);
    x_admm(mkt,t,n)$(trading_t(mkt,t,n) and xiny(mkt,f_mkt)) = cast((Q_FUEL.l(f,t,n) - Q_OUT.l(f,t,n)),f,mkt);
    x_admm(mkt,t,n)$(trading_t(mkt,t,n) and xiny(mkt,c_mkt)) = cast((Q_EMI.l(e,t,n)),e,mkt);
    u_admmiter(siter,mkt,t)$(t_admm(mkt,t)) = u_admm(mkt,t);
    xavg_admmiter(siter,mkt,t)$(t_admm(mkt,t)) = xavg_admm(mkt,t);
    xavg_admm(mkt,t)$(t_admm(mkt,t)) = sum(n$trading_t(mkt,t,n), x_admm(mkt,t,n))/sum(n$trading_t(mkt,t,n), 1);
    u_admm(mkt,t)$(t_admm(mkt,t)) = u_admm(mkt,t) + xavg_admm(mkt,t);
    z_admmiter(siter,mkt,t,n)$trading_t(mkt,t,n) = z_admm(mkt,t,n);
    z_admm(mkt,t,n)$trading_t(mkt,t,n) = u_admmiter(siter,mkt,t) - u_admm(mkt,t) + x_admm(mkt,t,n);
    r_admm(siter,mkt) = sum((t,n)$(trading_t(mkt,t,n) and tcheck(t)), power(u_admm(mkt,t) - u_admmiter(siter,mkt,t), 2));
    rrel_admm(siter,mkt) = div0(
        r_admm(siter,mkt), max(
            sum((t,n)$(trading_t(mkt,t,n) and tcheck(t)), power(x_admm(mkt,t,n), 2)),
            sum((t,n)$(trading_t(mkt,t,n) and tcheck(t)), power(u_admm(mkt,t), 2))
        ));
    s_admm(siter,mkt) = sum((t,n)$(trading_t(mkt,t,n) and tcheck(t)), power(rho_admm(mkt,t)*(z_admm(mkt,t,n) - z_admmiter(siter,mkt,t,n)), 2));
    srel_admm(siter,mkt) = div0(
        sum((t,n)$(trading_t(mkt,t,n) and tcheck(t)), power((z_admm(mkt,t,n) - z_admmiter(siter,mkt,t,n)), 2)),
        sum((t,n)$(trading_t(mkt,t,n) and tcheck(t)), power(u_admm(mkt,t), 2))
        );
    do_price_eq(run,siter,mkt,t) = yes$(t_admm(mkt,t));
    if(ord(siter) eq 1,
        delta_price_off(t)$xiny(mkt,f_mkt) = cast(FPRICE.l(f_mkt,t),f_mkt,mkt);
        delta_price_off(t)$xiny(mkt,c_mkt) = cast(CPRICE.l(c_mkt,t),c_mkt,mkt);
    else
        delta_price_off(t) = price_iter(run,siter,mkt,t);
    );
    delta_price(run,siter,mkt,t)$(t_admm(mkt,t)) = max(u_admm(mkt,t)*rho_admm(mkt,t), sum(tfirst, 0.1*delta_price_off(tfirst))) - delta_price_off(t);
    allrho_admm(run,siter,mkt,t) = rho_admm(mkt,t);
* See https://arxiv.org/pdf/1704.06209.pdf
$ifthen.tdyn %admm_tau%=='dynamic'
    admm_tau(siter,mkt) = sqrt(div0(rrel_admm(siter,mkt),srel_admm(siter,mkt)*csi_admm(mkt)));
    if(admm_tau(siter,mkt) ge 1,
       admm_tau(siter,mkt) = min(admm_tau(siter,mkt), %admm_tau_max%);
    else
       admm_tau(siter,mkt) = 1/max(admm_tau(siter,mkt), 1/%admm_tau_max%);
    );
$else.tdyn
    admm_tau(siter,mkt) = %admm_tau%;
$endif.tdyn
    if(rrel_admm(siter,mkt) gt admm_mu*srel_admm(siter,mkt)*csi_admm(mkt),
        rho_admm(mkt,t) = admm_tau(siter,mkt)*rho_admm(mkt,t);
    elseif srel_admm(siter,mkt)*csi_admm(mkt) gt admm_mu*rrel_admm(siter,mkt),
        rho_admm(mkt,t) = 1/admm_tau(siter,mkt)*rho_admm(mkt,t);
    );
    u_admm(mkt,t)$(t_admm(mkt,t)) = allrho_admm(run,siter,mkt,t)/rho_admm(mkt,t)*u_admm(mkt,t);
    z_admm(mkt,t,n)$trading_t(mkt,t,n) = allrho_admm(run,siter,mkt,t)/rho_admm(mkt,t)*u_admmiter(siter,mkt,t) - u_admm(mkt,t) + x_admm(mkt,t,n);
);

$endif.a