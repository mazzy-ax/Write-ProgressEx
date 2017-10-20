# mazzy@mazzy.ru, 2017-10-21
# https://github.com/mazzy-ax/write-progressEx

#requires -version 3.0

$me = $PSCommandPath | Split-Path -Leaf
$path = $PSCommandPath | Split-Path -Parent
$module = $path | Split-Path -Parent | Join-Path -ChildPath "Write-ProgressEx.psd1"
Import-Module -Force $module


$nodes = 1..20
$names = 1..50

write-ProgressEx "parm nodes" -Total $nodes.Count -ShowMessagesOnCompleted
$nodes | Where-Object {$true} | ForEach-Object {
    write-ProgressEx "parm names" -Total $names.Count -id 1
    $names | Where-Object {$true} | ForEach-Object {
        #...
        write-ProgressEx -id 1 -increment -Status "inner"
    }
    write-ProgressEx -Status "outer" -increment
}
write-ProgressEx -complete
