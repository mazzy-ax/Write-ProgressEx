#Requires -module Write-ProgressEx

# To install the module from https://www.powershellgallery.com/packages/Write-ProgressEx run the powershell command:
# PS> Install-Module Write-ProgressEx
#
# see https://github.com/mazzy-ax/Write-ProgressEx for details

$range = 1..500

$range | write-ProgressEx -Total $range.Count | ForEach-Object {
    # The progress name is equal to the script file name
}

function test-range {
    $range | write-ProgressEx -Total $range.Count | ForEach-Object {
        # The progress name is equal to the function name
    }
}

test-range