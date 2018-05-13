#Requires -module Write-ProgressEx

# To install the module from https://www.powershellgallery.com/packages/Write-ProgressEx run the powershell command:
# PS> Install-Module Write-ProgressEx
#
# see https://github.com/mazzy-ax/Write-ProgressEx for details

$range = 1..1000

Write-Verbose @'
-ShowProgress Force causes to show the progress bar in each iteration. It takes a long time.
Default value for -ShowProgress parameter is Auto. It redraws the progress bar no more than once every 100 milliseconds.
You can use -ShowProgress None to disable the progress bar display.
'@

write-ProgressEx 'wait, please' -Total $range.Count -ShowProgress Force
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
