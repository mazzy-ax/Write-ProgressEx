#Requires -module Write-ProgressEx

# To install the module from https://www.powershellgallery.com/packages/Write-ProgressEx run the powershell command:
# PS> Install-Module Write-ProgressEx
#
# see https://github.com/mazzy-ax/Write-ProgressEx for details

param(
    [Parameter(HelpMessage='Specifies how long each iteration sleeps in milliseconds. The default value is used when the user runs this script, 0 is used in unit tests.')]
    [int]$delayMS = 30
)

Write-ProgressEx    # reset incomplete runs

$range = 1..500

$range | Write-ProgressEx -Total $range.Count | ForEach-Object {
    # The progress name is equal to the script file name
    #...
    Start-Sleep -Milliseconds $delayMS
}

function test-range {
    $range | Write-ProgressEx -Total $range.Count | ForEach-Object {
        # The progress name is equal to the function name
        #...
        Start-Sleep -Milliseconds $delayMS
    }
}

test-range