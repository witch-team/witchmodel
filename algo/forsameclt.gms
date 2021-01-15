$macro forsameclt(action,clt) \
$label loop0
$if "a%1"=="a" $goto loop1
  if(sameas(&clt,'%1'), &action(%1)); \
$shift
$goto loop0
$label loop1
;