# mazzy@mazzy.ru, 2017-10-21
# https://github.com/mazzy-ax/write-progressEx

#requires -version 3.0

$me = $PSCommandPath | Split-Path -Leaf
$path = $PSCommandPath | Split-Path -Parent
$module = $path | Split-Path -Parent | Join-Path -ChildPath "Write-ProgressEx.psd1"
Import-Module -Force $module


$nodes = 1..20
$names = 1..50

$nodes | Where-Object {$true} | write-ProgressEx "pipe nodes" -Total $nodes.Count -Status "outer" -ShowMessages | ForEach-Object {
    $names | Where-Object {$true} | write-ProgressEx "pipe names" -Total $names.Count -id 1 -Status "inner" | ForEach-Object {
        #...
    }
}
