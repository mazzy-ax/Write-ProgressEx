# mazzy@mazzy.ru, 2017-10-10
# https://github.com/mazzy-ax/write-progressEx

Import-Module -Force "..\Write-ProgressEx.psd1"

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
