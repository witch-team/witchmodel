$title WITCH 5.2.0
$if set debug $setglobal verbose
$if not set verbose $offlisting
$offdigit
$offend
$onmulti
$onempty
$eolcom #
$setenv gdxcompress 1
$setenv errmsg 1
$setenv ps 9999
$setenv pw 32767

*-------------------------------------------------------------------------------
* WITCH CONFIGURATION
*-------------------------------------------------------------------------------

* DATA SETUP

* Regional mapping (r5, witch13, witch17, ...)
$setglobal n witch17

* Data path suffix
$setglobal datapathext '%n%'

* Location of the data gdx files
$setglobal datapath 'data_%datapathext%/'
$if not exist '%datapath%n.inc'
$error '%datapath% does not exist or is corrupted' 

* BASELINE SETUP

* Baseline scenario (ssp1, ssp2*, ssp3, ssp4, ssp5)
$setglobal baseline ssp2

* POLICY SETUP

* Default policy is BAU, for other policy see core_policy.gms
$setglobal policy bau

* COOPERATION SETUP

* Cooperation type (noncoop, coop)
*  noncoop: non-cooperative, each region is a coalition
*  coop: fully cooperative, one world coalition
$setglobal cooperation noncoop

* GDX SETUP

* Starting gdx
$setglobal startgdx '%datapath%results_%baseline%_calib'

* Set BAU GDX for losses calculation
$setglobal baugdx '%datapath%results_%baseline%_calib'

* Toggle and set GDX to fix variables
*$setglobal fixgdx %baugdx%

* SOLVING SETUP

* Don't solve the models
*$setglobal nosolve
* Solve only one region
*$setglobal only_solve c_usa

* OUTPUT SETUP

* Set output name
$setglobal nameout '%baseline%_%policy%'
* Make an output gdx with the given name
$setglobal outgdx results_%nameout%

* CALIBRATION

$ifthen.cb set calibration
$setglobal nameout '%baseline%_calib'
$setglobal outgdx '%datapath%results_%baseline%_calib'
$ifthen.s2 %baseline%=='ssp2'
$setglobal static_calibration
$setglobal startgdx '%datapath%data_startvar'
$setglobal tfpgdx '%datapath%data_starttfp'
$setglobal baugdx '%datapath%data_startvar'
$else.s2
$setglobal startgdx '%datapath%results_ssp2_calib'
$setglobal calibgdx '%datapath%data_calib'
$setglobal tfpgdx '%datapath%data_tfp_ssp2'
$setglobal baugdx '%datapath%results_ssp2_calib'
$endif.s2
$setglobal dynamic_calibration
$setglobal policy bau
$else.cb
$setglobal calibgdx '%datapath%data_calib'
$setglobal tfpgdx '%datapath%data_tfp_%baseline%'
$if not exist '%calibgdx%.gdx'
$error 'Please calibrate the model first (--calibration=1)'
$endif.cb

* MODEL SETUP

* Enable climate equations
*$setglobal solve_climate

* Enable feedback
*$setglobal damage_feedback

* Toggle adaptation
*$setglobal adaptation 'YES'



*-------------------------------------------------------------------------------
* DIRECTORY FOR OUTPUT [default = current directory]
*-------------------------------------------------------------------------------

* directory for outputs
$ifthen not set workdir
$setglobal resdir "%gams.curdir%"
$else
$setglobal resdir "%workdir%\"
$if %system.filesys% == UNIX $setglobal resdir "%workdir%/"
$endif

*-------------------------------------------------------------------------------
* GENERATE - SOLVE - REPORT WITCH
*-------------------------------------------------------------------------------

$batinclude modules 'conf'
$include 'macros'
$batinclude modules 'sets'
$batinclude modules 'include_data'
$if not set dynamic_calibration $batinclude modules 'include_dynamic_calibration_data'
$batinclude modules 'compute_data'
$batinclude modules 'vars'
$batinclude modules 'policy'
$ondotl
$if set fixgdx $batinclude modules 'fix_variables'
$offdotl

$include 'algorithm'

$batinclude modules 'finalize'

$batinclude modules 'summary_report'

$include 'post/gdx'

$show
