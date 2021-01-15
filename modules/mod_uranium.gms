*-------------------------------------------------------------------------------       
* Uranium Resources
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

parameter
    resgr(f,t) 'Growth rate of ultimately recoverable resources amount'
    res(f,t)   'Ultimately Recoverable Resources [TWh]'
;
resgr('uranium',t) = 0.006 + 0.024 / (1 + exp(-(year(t) - 2075) / 20)); 
res('uranium',tfirst) = cexs('uranium','res0');
loop((tnofirst(t),tm1)$pre(tm1,t),
    res('uranium',t) = res('uranium',tm1)*(1+resgr('uranium',tm1))**tlen(tm1);
);

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

FPRICE.l('uranium',t)$(not tfix(t)) = cexs('uranium','scl') *
                        (cexs('uranium','a') +
                         cexs('uranium','c') *
                         (wcum('uranium',t) / 
                            (cexs('uranium','fast') * res('uranium',t))
                         )**2
                        ) + cexs('uranium','extra');

MCOST_FUEL.fx('uranium',t,n)$(not tfix(t)) = FPRICE.l('uranium',t) + p_mkup('uranium',t,n);

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'

resgr
res

$endif
