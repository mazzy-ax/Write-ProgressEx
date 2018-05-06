#Requires -module Write-ProgressEx

# To install the module from https://www.powershellgallery.com/packages/Write-ProgressEx run the powershell command:
# PS> Install-Module Write-ProgressEx
#
# see https://github.com/mazzy-ax/Write-ProgressEx for details

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

$nodes | write-ProgressEx @progressNode | ForEach-Object {
    $names | write-ProgressEx @progressNames | ForEach-Object {
        #...
    }
}
