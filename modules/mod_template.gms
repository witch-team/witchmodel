*-------------------------------------------------------------------------------       
* Module Template
* Explain in brief what your module is for and basic usage
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

* Definition of the global variable specific to the module 
$setglobal xxx

*-------------------------------------------------------------------------------
$elseif %phase%=='sets'

* In the phase SETS you should declare all your sets, or add to the existing 
* sets the element that you need.

set j / my_new_element /;
set jreal(j) /my_new_element /;
 

*-------------------------------------------------------------------------------
$elseif %phase%=='include_data'

* In the phase INCLUDE_DATA you should declare and include exogenous parameters. 
* You can also modify the data loaded in data.gms
* Best practice : - create a .gdx containing those and to loading it 
*                 - this is the only phase where we should have numbers...


*-------------------------------------------------------------------------------
$elseif %phase%=='compute_data'

* In the phase COMPUTE_DATA you should declare and compute all the parameters 
* that depend on the data loaded in the previous phase. 


*-------------------------------------------------------------------------------
$elseif %phase%=='vars'

* In the phase VARS, you can declare new variables for your module. 
* Remember that by modifying sets, you already have some variables for free.
* Best practice : - for variables that are fixed for the first time period => 
*									MY_VARIABLE.fx(tfirst,n)=my_variable0(n);
*                 - load a good initial point from a gdx 


*-------------------------------------------------------------------------------
$elseif %phase%=='policy'

* In the phase POLICY, you should specify your policy 
* Best practice : This phase should be used mainly when you write a project file 
*                 and you declare the policy according to your scenarios


*-------------------------------------------------------------------------------
$elseif %phase%=='eql'

* List of equations
* One per line.

*-------------------------------------------------------------------------------
$elseif %phase%=='eqs'


* In the phase EQS, you can include new equations to the model.
* The equations are always included.
* Best practice : - condition your equation to be able to do a run with tfix(t) 

eq_linear(t)$(not tfix(t))..
                X(t)  =e= alpha * Y(t) + Z(t);


*-------------------------------------------------------------------------------
$elseif %phase%=='fix_variables'

* This phase is done after the phase POLICY.
* You should fix all your new variables.
* Remember, quantities are fixed up to the last tfix, while investment only 
* up to tfix-1
* Best practices : 
* - Use the provided macro in policy_fix
* - Your module should be able to do a tfix run

* fix variable MY_VAR(t,n) in tfix
tfixvar(MY_VAR,'(t,n)')

* fix variable MY_VAR_INVEST(t,n) in tfix
tfix1var(MY_VAR_INVEST,'(t,n)')

*-------------------------------------------------------------------------------
$elseif %phase%=='before_nashloop'

* The phase BEFORE_NASHLOOP is ran just before the loop solving an equilibrium

*-------------------------------------------------------------------------------
$elseif %phase%=='before_solve'

* In the phase BEFORE_SOLVE, you can update parameters (fixed
* variables, ...) inside the nash loop and right before solving the
* model. This is typically done for externalities, spillovers, ...
* Best practice: record the variable that you update across iterations.
* Remember that you are inside the nash loop, so you cannot declare
* parameters, ...
* This phase is recalled one last time after the last nash iteration.
    
alpha = log(X.l(t)/Y.l(t));
alpha_iter(siter)=alpha;


*-------------------------------------------------------------------------------
$elseif %phase%=='after_nashloop'
* In the phase AFTER_NASHLOOP, you compute parameters needed for the report,
* once the job is ready.
* Best practice :
*      - you should not declare parameters as this phase might be inside a loop


*-------------------------------------------------------------------------------
$elseif %phase%=='summary_report'

* parameter necessary for database

*-------------------------------------------------------------------------------
$elseif %phase%=='gdx_items'
* List the items to be kept in the final gdx 

* Sets (avoid to include the aliases)
s1
s2

* Parameters
param1
param2

* Variables
V1
V2

$endif
