# mazzy@mazzy.ru, 2017-08-25
# https://github.com/mazzy-ax/write-progressEx

Import-Module -Force "..\Write-ProgressEx.psm1"

$nodes = 1..20
$names = 1..50

write-ProgressEx "pipe nodes" -Total $nodes.Count
$nodes | Where-Object {$true} | write-ProgressEx -Status "outer" | ForEach-Object {
    write-ProgressEx "pipe names" -Total $names.Count -id 1
    $names | Where-Object {$true} | write-ProgressEx -id 1 -status "inner" | ForEach-Object {
        #...
    }
}
