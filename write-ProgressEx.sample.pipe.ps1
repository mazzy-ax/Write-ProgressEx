# mazzy@mazzy.ru, 21.07.2017
# https://github.com/mazzy-ax/write-progressEx

Import-Module -Force ".\write-ProgressEx.psm1"

$nodes = 1..20
$names = 1..50

write-ProgressEx "pipe nodes" -Total $nodes.Count
$nodes | Where-Object {$true} | write-ProgressEx -Status "outer $_" -increment | ForEach-Object {
    write-ProgressEx "pipe names" -Total $names.Count -id 1
    $names | Where-Object {$true} | write-ProgressEx -id 1 -increment -status "inner $_" | ForEach-Object {
        Start-Sleep 0
    }
}
write-ProgressEx -complete