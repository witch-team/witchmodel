*-------------------------------------------------------------------------------
* Retrive Marginal Values for the convergence algorithm
*-------------------------------------------------------------------------------
$batinclude 'algo/get_marginal' eq_mkt_clearing_oil '(t,clt)' coalitional %coalitions%
$batinclude 'algo/get_marginal' eqq_cc '(t,tp1,n)'            regional %coalitions%
$batinclude 'algo/get_marginal' eqq_emi_lim '(t,n)'           regional %coalitions%
$batinclude 'algo/get_marginal' eqq_emi_tree '(t,n,e)'        regional %coalitions%
$batinclude 'algo/get_marginal' eqq_y '(t,n)'                 regional %coalitions%