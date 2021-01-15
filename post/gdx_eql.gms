*-------------------------------------------------------------------------------
* post_gdx_eql.gms
*
* Get list of equations from all coalitions for outputs
*-------------------------------------------------------------------------------

$label start_loop
$if "a%1"=="a" $goto end_loop

$batinclude modules 'eql' %1

$shift
$goto start_loop
$label end_loop