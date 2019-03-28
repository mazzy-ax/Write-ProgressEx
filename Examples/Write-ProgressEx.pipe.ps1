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

$nodes | Write-ProgressEx "pipe nodes" -Total $nodes.Count -Status "outer" -ShowMessages -ShowConsoleTitle -ShowElapsed | ForEach-Object {
    $names | Write-ProgressEx "pipe names" -Total $names.Count -id 1 -Status "inner" | ForEach-Object {
        #...
        Start-Sleep -Milliseconds $delayMS
    }
}
