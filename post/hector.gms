* Requires
** $SET: resdir, nameout 
** SETS: t,n,e,m
** VARS: W_EMI, Q_EMI, AQ_WEMI

$set phase conf
$batinclude "modules/ext_hector.gms"
$set phase sets
$batinclude "modules/ext_hector.gms"
$set phase include_data
$batinclude "modules/ext_hector.gms"
$set phase vars
$batinclude "modules/ext_hector.gms"
$set phase after_solve
$batinclude "modules/ext_hector.gms"
