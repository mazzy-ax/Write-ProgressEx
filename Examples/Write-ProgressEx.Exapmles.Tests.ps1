# mazzy@mazzy.ru, 2017-10-14
# https://github.com/mazzy-ax/Write-progressEx

$me = Split-Path -Leaf $PSCommandPath
$path = Split-Path -Parent $PSCommandPath

Describe "Write-ProgressEx Exapmles" -Tag "build", "exapmle" {

    Get-ChildItem (Join-Path $path Write-ProgressEx.*.ps1) -Exclude $me | ForEach-Object {
        Write-Verbose $_.Name
        It $_.Name {
            { . $_ | Out-Null } | Should not throw
        }
    }

}
