#Requires -module Write-ProgressEx

# To install the module from https://www.powershellgallery.com/packages/Write-ProgressEx run the powershell command:
# PS> Install-Module Write-ProgressEx
#
# see https://github.com/mazzy-ax/Write-ProgressEx for details

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
