# mazzy@mazzy.ru, 2017-08-06
# https://github.com/mazzy-ax/write-progressEx

Import-Module -Force "..\write-ProgressEx.psm1"

$nodes = 1..20
$names = 1..50

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
