#Requires -module Write-ProgressEx

# To install the module from https://www.powershellgallery.com/packages/Write-ProgressEx run the powershell command:
# PS> Install-Module Write-ProgressEx
#
# see https://github.com/mazzy-ax/Write-ProgressEx for details

$nodes = 1..20
$names = 1..50

$nodes | write-ProgressEx "pipe nodes" -Total $nodes.Count -Status "outer" -ShowMessages | ForEach-Object {
    $names | write-ProgressEx "pipe names" -Total $names.Count -id 1 -Status "inner" | ForEach-Object {
        #...
    }
}
