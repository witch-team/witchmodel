*-------------------------------------------------------------------------------
* Geographic dimension and mapping with countries
*-------------------------------------------------------------------------------

$ifthen %phase%=='conf'

$include %datapath%regions.conf
$if not %n%==%nmapping% $abort "regional mapping n='%n%' not matching data mapping '%nmapping%'"

$elseif %phase%=='sets'

set n 'Regions' /
$include %datapath%n.inc
/;

$include %datapath%regions.inc

alias (n,nn);

set non_oecd(n) 'non OECD regions';
non_oecd(n) = YES$(not oecd(n));

$elseif %phase%=='gdx_items'

* Sets
n
oecd
non_oecd

$endif
