# mazzy@mazzy.ru, 2017-10-14
# https://github.com/mazzy-ax/write-progressEx

$me = Split-Path -Leaf $PSCommandPath
$path = Split-Path -Parent $PSCommandPath
$module = Join-Path (Split-Path -Parent $path) "Write-ProgressEx.psd1"
Import-Module -Force $module

$nodes = 1..20
$names = 1..50

$nodes | Where-Object {$true} | write-ProgressEx "pipe nodes" -Total $nodes.Count -Status "outer" -ShowMessages | ForEach-Object {
    $names | Where-Object {$true} | write-ProgressEx "pipe names" -Total $names.Count -id 1 -Status "inner" | ForEach-Object {
        #...
    }
}
