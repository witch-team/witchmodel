*-------------------------------------------------------------------------------
* Welfare
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Default option: utilitarian, gamma=0
* [if utilitarian not set, negishi weigths are used]
$setglobal utilitarian
$setglobal gamma 0
$setglobal eta 0.66
$setglobal srtp 1

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

set negishi_coop(clt,n);
negishi_coop(clt,n)=no;

$setglobal welfare_order 'tn'

*-------------------------------------------------------------------------------
$elseif  %phase%=='include_data'

scalar eta 'inverse of the intertemporal elasticity of substitution';
eta = %eta%; #exponent of power utility function (set 1.01 if logarithm)

parameter gamma 'Degree of relative inequality aversion (between regions)' /%gamma%/;

parameter utility_cebge_global;
parameter utility_cebge_regional(n);
parameter utility_cebge_pc_global;
parameter utility_cebge_pc_regional(n);

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

parameter srtp(t) 'Social rate of time preference [% per year]';
srtp(t) = %srtp%;

parameter stpf(t) 'Social time preference factor';
stpf(tfirst) = 1;
loop(tnolast(t),
  stpf(tt)$pre(t,tt) = stpf(t) / (1 + srtp(t) / 100)**tlen(t);
);

*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

variable UTILITY 'Social welfare';

*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

equtility_%clt%

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'

* Objective function - Welfare to be maximized
equtility_%clt%..
    UTILITY =e=

* Negishi SWF
$ifthen.neg not set utilitarian
                sum((t,tp1,n)$(mapn_th1_last('%clt%')),
                   w_negishi(t,n) * PROB(t) * stpf(t) * l(t,n) * 
                   ((Q('CC',t,n) / l(t,n))**(1 - eta) - 1) / (1 - eta)
                )
$endif.neg

* Welfare functions based on CEBGE
$ifthen.neg set utilitarian
$ifthen.tnnt %welfare_order%=='tn'
                (sum((t,tp1)$time_th1_last, 
                    PROB(t) * stpf(t) / sum(tt$(year(tt) le yeoh), PROB(tt) * stpf(tt)) * 
                    ((sum(n$mapn('%clt%'), 
                      (l(t,n) / sum(nn$mapnn('%clt%'), l(t,nn))) *
                      (Q('CC',t,n) / l(t,n))**(1 - gamma))
                     )**(1 / (1 - gamma))
                    )**(1 - eta) ) +
                sum((t,tp1)$(tfix(tp1) and pre(t,tp1)), 
                    PROB(t) * stpf(t) / sum(tt$(year(tt) le yeoh), PROB(tt) * stpf(tt)) * 
                    ((sum(n$mapn('%clt%'), 
                      (l(t,n) / sum(nn$mapnn('%clt%'), l(t,nn))) *
                      (Q.l('CC',t,n) / l(t,n))**(1 - gamma))
                     )**(1 / (1 - gamma))
                    )**(1 - eta) )
                )**(1/(1 - eta)) * 1e6
$elseif.tnnt %welfare_order%=='nt'
                (sum(n$mapn('%clt%'), 
                    (sum((t,tp1)$(year(t) le yeoh), l(t,n)) / 
                     sum((t,tp1)$(year(t) le yeoh), sum(nn$mapnn('%clt%'), l(t,nn)))) * 
                  ((sum((t,tp1)$time_th1_last, 
                        ((PROB(t) * stpf(t)) / sum(tt$(year(tt) le yeoh), PROB(tt) * stpf(tt)) * 
                        ((Q('CC',t,n) / l(t,n))**(1 - eta)))) +
                    sum((t,tp1)$(tfix(tp1) and pre(t,tp1)), 
                        ((PROB(t) * stpf(t)) / sum(tt$(year(tt) le yeoh), PROB(tt) * stpf(tt)) * 
                        ((Q.l('CC',t,n) / l(t,n))**(1 - eta))))
                   )**((1 - gamma) / (1 - eta))
                  )))**(1 / (1 - gamma)) * 1e6;
$endif.tnnt
$endif.neg


;

$elseif %phase%=='after_solve'

* CEBGE global for tn welfare function and gamma
utility_cebge_global =
  (sum(t$(year(t) le yeoh), PROB.l(t) * stpf(t) / 
           (sum(tt$(year(tt) le yeoh), PROB.l(tt) * stpf(tt))) * 
           (sum(n, l(t,n) / sum(nn, l(t,nn)) *
           (Q.l('CC',t,n) / l(t,n))**(1 - gamma)))**(1 / (1 - gamma))**(1 - eta)
        ))**(1 / (1 - eta)) /
  ((sum(t$(year(t) le yeoh), sum(n, l(t,n)) * PROB.l(t) * stpf(t) * (1 + 0.00)**((1 - eta) * (year(t) - 2005))) /
   (sum(t$(year(t) le yeoh), sum(n, l(t,n)) * PROB.l(t) * stpf(t))))**(1 / (1 - eta))
  ) * 1e6;

* Utility per region (based on Utilitarian CEBGE_g0 welfare function, eta throughout all three dimensions)
utility_cebge_regional(n) =
  (sum(t$(year(t) le yeoh), PROB.l(t) * stpf(t) * l(t,n) * ((Q.l('CC',t,n) / l(t,n))**(1 - eta))) /
          (sum(tt$(year(tt) le yeoh), l(tt,n) * PROB.l(tt) * stpf(tt)))
  )**(1 / (1 - eta)) * 1e6;

* Policy costs based on CEBGE
utility_cebge_pc_global = utility_cebge_global /
  ((sum(t$(year(t) le yeoh), PROB.l(t) * stpf(t) / 
           (sum(tt$(year(tt) le yeoh),PROB.l(tt) * stpf(tt))) * 
           (sum(n, l(t,n) / sum(nn, l(t,nn)) *
           (BAU_Q.l('CC',t,n) / l(t,n))**(1 - gamma)))**(1 / (1 - gamma))**(1 - eta)) 
  )**(1 / (1 - eta)) /
  ((sum(t$(year(t) le yeoh), sum(n,l(t,n)) * PROB.l(t) * stpf(t) * (1 + 0.00)**((1 - eta) * (year(t) - 2005))) /
    (sum(t$(year(t) le yeoh), sum(n, l(t,n)) * PROB.l(t) * stpf(t))))**(1 / (1 - eta))
  ) * 1e6) - 1;

utility_cebge_pc_regional(n) = utility_cebge_regional(n) /
  (( sum(t$(year(t) le yeoh),PROB.l(t)*stpf(t)*l(t,n)*((BAU_Q.l('CC',t,n)/l(t,n))**(1-eta))) /
    (sum(tt$(year(tt) le yeoh), l(tt,n)*PROB.l(tt)*stpf(tt))) )**(1/(1-eta)) * 1e6
  ) - 1;

$elseif %phase%=='gdx_items'

* Sets
negishi_coop

* Parameters
eta
gamma
srtp
stpf
utility_cebge_global
utility_cebge_pc_global
utility_cebge_pc_regional
utility_cebge_regional
w_negishi

* Variables
UTILITY
PROB

$endif
