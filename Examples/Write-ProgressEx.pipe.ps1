# mazzy@mazzy.ru, 2017-10-21
# https://github.com/mazzy-ax/write-progressEx

#requires -version 3.0

$module = "Write-ProgressEx.psd1"
$PSCommandPath | Split-Path -Parent | Split-Path -Parent | Join-Path -ChildPath $module | Import-Module -Force


$nodes = 1..20
$names = 1..50

$nodes | Where-Object {$true} | write-ProgressEx "pipe nodes" -Total $nodes.Count -Status "outer" -ShowMessages | ForEach-Object {
    $names | Where-Object {$true} | write-ProgressEx "pipe names" -Total $names.Count -id 1 -Status "inner" | ForEach-Object {
        #...
    }
}
