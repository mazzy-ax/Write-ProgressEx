# mazzy@mazzy.ru, 06.08.2017
# https://github.com/mazzy-ax/write-progressEx

Import-Module -Force ".\write-ProgressEx.psm1"

$level1 = 1..20
$level2 = 1..50
$level3 = 1..50
$global = 1..50


write-ProgressEx "parm nodes" -Total $nodes.Count
$nodes | Where-Object {$true} | ForEach-Object {
    write-ProgressEx "parm names" -Total $names.Count -id 1
    $names | Where-Object {$true} | ForEach-Object {
        #start-sleep 1
        write-ProgressEx -id 1 -increment -status "inner"
    }
    write-ProgressEx -Status "outer" -increment
}
write-ProgressEx -complete
