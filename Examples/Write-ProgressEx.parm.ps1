# mazzy@mazzy.ru, 2017-10-14
# https://github.com/mazzy-ax/write-progressEx

$me = Split-Path -Leaf $PSCommandPath
$path = Split-Path -Parent $PSCommandPath
$module = Join-Path (Split-Path -Parent $path) "Write-ProgressEx.psd1"
Import-Module -Force $module

$nodes = 1..20
$names = 1..50

write-ProgressEx "parm nodes" -Total $nodes.Count -ShowMessagesOnEnd
$nodes | Where-Object {$true} | ForEach-Object {
    write-ProgressEx "parm names" -Total $names.Count -id 1
    $names | Where-Object {$true} | ForEach-Object {
        #...
        write-ProgressEx -id 1 -increment -Status "inner"
    }
    write-ProgressEx -Status "outer" -increment
}
write-ProgressEx -complete
