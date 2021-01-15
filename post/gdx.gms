*-------------------------------------------------------------------------------
* Write output GDX
*-------------------------------------------------------------------------------

execute_unload '%resdir%%outgdx%.gdx'

* item list
$if exist 'algo/algoitemlist.txt' $include 'algo/algoitemlist.txt'

* equations
$batinclude 'post/gdx_eql' %coalitions%

* declared items
$batinclude modules 'gdx_items'
$batinclude modules 'tfpgdx_items'

;

$ifthen.c set dynamic_calibration

$ifi %write_tfp_file%=='datapath' execute_unload '%datapath%data_tfp_%tfpscen%.gdx'
$ifi %write_tfp_file%=='resdir'   execute_unload '%resdir%data_tfp_%nameout%.gdx'

* declared items
$batinclude modules 'tfpgdx_items'

;

$endif.c