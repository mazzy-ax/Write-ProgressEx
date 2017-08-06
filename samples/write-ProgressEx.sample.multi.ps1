# mazzy@mazzy.ru, 2017-08-06
# https://github.com/mazzy-ax/write-progressEx

Import-Module -Force "..\write-ProgressEx.psm1"

$level1 = 1..6
$level2 = 1..30
$global = 1..500


write-ProgressEx "Level1" -Total $level1.Count
$level1 | write-ProgressEx | ForEach-Object {

    write-ProgressEx "Level2" -Total $level2.Count -id 2
    $level2 | write-ProgressEx -id 2 | ForEach-Object {
        Write-ProgressEx "Global" -id 50 -total $global.Count -increment -ParentId -1
        #...
    }

}
write-ProgressEx -complete

$pInfo = Get-ProgressEx -Id 50
$pInfo.Current..$pInfo.Total | Write-ProgressEx -id 50 | ForEach-Object {
    #...
}
