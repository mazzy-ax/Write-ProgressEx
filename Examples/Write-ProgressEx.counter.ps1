#Requires -module Write-ProgressEx

# To install the module from https://www.powershellgallery.com/packages/Write-ProgressEx run the powershell command:
# PS> Install-Module Write-ProgressEx
#
# see https://github.com/mazzy-ax/Write-ProgressEx for details

Get-ChildItem $PSScriptRoot\Write-ProgressEx.*.ps1 |
    write-ProgressEx -id 0 "files in Exapmle directory" -ShowMessagesOnFirstIteration -ShowMessagesOnCompleted -ShowProgress None |
    ForEach-Object {

    # ....

}

