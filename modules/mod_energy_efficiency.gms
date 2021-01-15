*-------------------------------------------------------------------------------
* Energy efficiency
*-------------------------------------------------------------------------------

$ifthen %phase%=='sets'

set rd(j) /en/;

* OECD are R&D Leaders in energy efficiency
leadrd('en',n)$(oecd(n)) = yes;

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

rd_delta('en') = 0.05;
rd_coef('en','a') = 0.0419258;
rd_coef('en','b') = 0.18;
rd_coef('en','c') = 0.3840625;
rd_coef('en','d') = 0.15;

*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

krd0('en',n) = q0('krd_en',n);

$endif
