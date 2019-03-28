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

$nodes = 1..10
$names = 1..120

Write-ProgressEx "parm nodes" -Total $nodes.Count -ShowMessagesOnCompleted
$nodes | ForEach-Object {
    Write-ProgressEx "parm names" -Total $names.Count -id 1
    $names | ForEach-Object {
        Write-ProgressEx -id 1 -increment -Status "inner"
        #...
        Start-Sleep -Milliseconds $delayMS
    }
    Write-ProgressEx -Status "outer" -increment
}
Write-ProgressEx -complete
