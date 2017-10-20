# mazzy@mazzy.ru, 2017-10-21
# https://github.com/mazzy-ax/Write-progressEx

$me = $PSCommandPath | Split-Path -Leaf
$path = $PSCommandPath | Split-Path -Parent

Describe "Write-ProgressEx Exapmles" -Tag "build", "exapmle" {

    $path | Join-Path -ChildPath Write-ProgressEx.*.ps1 | Get-ChildItem -Exclude $me | ForEach-Object {
        Write-Verbose $_.Name
        It $_.Name {
            { . $_ | Out-Null } | Should not throw
        }
    }

}
