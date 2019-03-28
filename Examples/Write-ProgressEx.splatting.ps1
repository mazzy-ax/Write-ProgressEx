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

$nodes = 1..20
$names = 1..50

# hashtables for constant parameters
$progressNode = @{
    id = 0
    total = $nodes.Count
    activity = 'splatting nodes'
    status = 'outer'
}

$progressNames = @{
    id = 1
    total = $names.count
    activity = 'splatting names'
    status = 'inner'
}

# splatting. see https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting

$nodes | Write-ProgressEx @progressNode | ForEach-Object {
    $names | Write-ProgressEx @progressNames | ForEach-Object {
        #...
        Start-Sleep -Milliseconds $delayMS
    }
}
