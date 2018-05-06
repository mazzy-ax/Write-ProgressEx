#Requires -module Write-ProgressEx

# To install the module from https://www.powershellgallery.com/packages/Write-ProgressEx run the powershell command:
# PS> Install-Module Write-ProgressEx
#
# see https://github.com/mazzy-ax/Write-ProgressEx for details

$nodes = 1..20
$names = 1..50

write-ProgressEx "parm nodes" -Total $nodes.Count -ShowMessagesOnCompleted
$nodes | ForEach-Object {
    write-ProgressEx "parm names" -Total $names.Count -id 1
    $names | ForEach-Object {
        #...
        write-ProgressEx -id 1 -increment -Status "inner"
    }
    write-ProgressEx -Status "outer" -increment
}
write-ProgressEx -complete
