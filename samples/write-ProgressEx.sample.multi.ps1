# mazzy@mazzy.ru, 2017-08-08
# https://github.com/mazzy-ax/write-progressEx

Import-Module -Force "..\write-ProgressEx.psm1"

$level1 = 1..6
$level2 = 1..9
$level3 = 1..15
$global = 1..700


write-ProgressEx "Try to change the height of the console window..." -Total $level1.Count
$level1 | write-ProgressEx | ForEach-Object {

    write-ProgressEx "Level2" -Total $level2.Count -id 2
    $level2 | write-ProgressEx -id 2 | ForEach-Object {

        write-ProgressEx "Level3" -Total $level3.Count -id 3
        $level3 | write-ProgressEx -id 3 -SecondsRemaining -1 -PercentComplete -1 | ForEach-Object {

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
