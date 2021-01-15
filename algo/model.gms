*-------------------------------------------------------------------------------
* Generate the model equations
*-------------------------------------------------------------------------------

$label start_loop
$if "a%1"=="a" $goto end_loop

Equations
$batinclude modules 'eql' %1
;

$batinclude modules 'eqs' %1


model witch_%1 /
$batinclude modules 'eql' %1
/;

witch_%1.optfile=1;   # the option file solvername.opt is to be used
witch_%1.holdfixed=%holdfixed%; # treat fixed values as constant
witch_%1.scaleopt=1;  # Use scaling for better gradients estimation
witch_%1.solvelink=%solvelink%; # Use parallel or sequential solving

$shift
$goto start_loop
$label end_loop