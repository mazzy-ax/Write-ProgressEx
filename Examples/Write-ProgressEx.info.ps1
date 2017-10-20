# mazzy@mazzy.ru, 2017-10-21
# https://github.com/mazzy-ax/write-progressEx

#requires -version 3.0

$module = "Write-ProgressEx.psd1"
$PSCommandPath | Split-Path -Parent | Split-Path -Parent | Join-Path -ChildPath $module | Import-Module -Force


$range = 1..1000

write-ProgressEx 'wait, please' -Total $range.Count
$range | write-ProgressEx | ForEach-Object {
    $pInfo = Get-ProgressEx

    if ( $pInfo.SecondsRemaining -lt 5 ) {
        $pInfo.Activity = 'just a few seconds'

        # The splatting to Write-ProgressEx is a common pattern to use progress info. It's recalculate parameters and refresh progress on the console.
        Write-ProgressEx @pInfo
    }

    # ...

    if ( $pInfo.PercentComplete -gt 50 ) {
        $pInfo.Status = 'hard work in progress'

        # A rare pattern to use progress info. It isn't recalulate. It refresh progress on the console only.
        Set-ProgressEx $pInfo
    }
}
write-ProgressEx
