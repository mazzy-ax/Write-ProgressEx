# mazzy@mazzy.ru, 2017-08-09
# https://github.com/mazzy-ax/write-progressEx

Import-Module -Force "..\write-ProgressEx.psm1"

$level1 = 1..6
$level2 = 1..9
$level3 = 1..11
$global = 1..900


write-ProgressEx "Try to change the height of the console window..." -Total $level1.Count
$level1 | write-ProgressEx | ForEach-Object {

    $level2 | write-ProgressEx "Level2" -id 2 -Total $level2.Count | ForEach-Object {

        $level3 | write-ProgressEx "Level3" -id 3 -Total $level3.Count -SecondsRemaining -1 -PercentComplete -1 | ForEach-Object {

            Write-ProgressEx "Global" -id 50 -total $global.Count -increment -ParentId -1
            #...
        }
    }
}
write-ProgressEx -complete

$pInfo = Get-ProgressEx -Id 50
$pInfo.Current..$pInfo.Total | Write-ProgressEx -id 50 | ForEach-Object {
    #...
}
