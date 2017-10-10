# mazzy@mazzy.ru, 2017-10-10
# https://github.com/mazzy-ax/write-progressEx

Import-Module -Force "..\Write-ProgressEx.psd1"

$nodes = 1..20
$names = 1..50

$nodes | Where-Object {$true} | write-ProgressEx "pipe nodes" -Total $nodes -Status "outer" -ShowMessages | ForEach-Object {
    $names | Where-Object {$true} | write-ProgressEx "pipe names" -Total $names -id 1 -Status "inner" | ForEach-Object {
        #...
    }
}
