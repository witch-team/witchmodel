*-------------------------------------------------------------------------------
* Call modules by order
*-------------------------------------------------------------------------------
$set phase %1
$set clt %2
$set mp 'modules'

* Algorithm
$batinclude '%mp%/core_algorithm'

* Time structure
$batinclude '%mp%/core_time'

* Regions + Coalitions
$batinclude '%mp%/core_regions'
$batinclude '%mp%/cooperation_%cooperation%'

* Core model
$batinclude '%mp%/core_welfare'
$batinclude '%mp%/core_economy'
$batinclude '%mp%/core_energy'
$batinclude '%mp%/core_emissions'
$batinclude '%mp%/core_knowledge'
$batinclude '%mp%/core_policy'

* Modules
$batinclude '%mp%/mod_energy_efficiency'
$batinclude '%mp%/mod_hydropower'
$batinclude '%mp%/mod_systint'
$batinclude '%mp%/mod_nuclear'
$batinclude '%mp%/mod_ghg'
$batinclude '%mp%/mod_fgases'
$batinclude '%mp%/mod_landuse'
$batinclude '%mp%/mod_elbio'
$batinclude '%mp%/mod_trbiofuel'
$batinclude '%mp%/mod_advbiofuel'
$batinclude '%mp%/mod_ccs'

$batinclude '%mp%/mod_nelcoal'
$batinclude '%mp%/mod_wind'
$batinclude '%mp%/mod_solar'
$batinclude '%mp%/pol_techno_ssp'

$batinclude '%mp%/mod_oil'
$batinclude '%mp%/mod_uranium'
$batinclude '%mp%/mod_gas'
$batinclude '%mp%/mod_coal'


$batinclude '%mp%/mod_climate'
$if not set mod_impact $batinclude '%mp%/mod_damage'

$batinclude '%mp%/mod_transport'
$batinclude '%mp%/mod_transport_freight'


* Modules requiring post-processing
$batinclude '%mp%/mod_trbiomass'

* Optional modules

* Policy modules

* Calibration
$if set static_calibration $batinclude '%mp%/calib_static'
$if set dynamic_calibration $batinclude '%mp%/calib_dynamic'
