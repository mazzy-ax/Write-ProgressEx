# mazzy@mazzy.ru, 2017-10-10
# https://github.com/mazzy-ax/write-progressEx

Import-Module -Force "..\Write-ProgressEx.psd1"

$nodes = 1..20
$names = 1..50

write-ProgressEx "parm nodes" -Total $nodes -ShowMessages
$nodes | Where-Object {$true} | ForEach-Object {
    write-ProgressEx "parm names" -Total $names -id 1
    $names | Where-Object {$true} | ForEach-Object {
        #...
        write-ProgressEx -id 1 -increment -Status "inner"
    }
    write-ProgressEx -Status "outer" -increment
}
write-ProgressEx -complete
