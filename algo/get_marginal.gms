*-------------------------------------------------------------------------------
* Extract the marginal value from equation
* Usage: 
* $batinclude get_marginal eq_name set_dep (regional|coalitional) coalitions_list
*-------------------------------------------------------------------------------

$setlocal eqname %1
$setlocal setdep %2
$setlocal mtype %3 
$label start_loop
$if "a%4"=="a" $goto end_loop
$ifthen.x %eqname%=="eqq_cc"
$ifthen.s "%mtype%"=="regional"
m_%eqname%%setdep%$(mapn_th1_last('%4')) = %eqname%_%4.m%setdep%;
$elseif.s "%mtype%"=="coalitional"
m_%eqname%%setdep%$(sameas(clt,'%4') and (((not tfix(tp1)) and pre(t,tp1)) or (year(t) eq yeoh and sameas(t,tp1)))) = %eqname%_%4.m%setdep%;
$else.s
$abort "Please specify whether you want the marginal of a REGIONAL or a COALITIONAL equation!"
$endif.s
$else.x
$ifthen.s "%mtype%"=="regional"
m_%eqname%%setdep%$(mapn_th('%4')) = %eqname%_%4.m%setdep%;
$elseif.s "%mtype%"=="coalitional"
m_%eqname%%setdep%$(sameas(clt,'%4') and (not tfix(t)) and (year(t) le yeoh)) = %eqname%_%4.m%setdep%;
$else.s
$abort "Please specify whether you want the marginal of a REGIONAL or a COALITIONAL equation!"
$endif.s
$endif.x
$label good_eq_type
$shift
$goto start_loop
$label end_loop