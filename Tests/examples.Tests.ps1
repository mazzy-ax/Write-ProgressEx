$projectRoot = Resolve-Path $PSScriptRoot\..
$moduleRoot = Split-Path (Resolve-Path $projectRoot\*\*.psd1)
$moduleName = Split-Path $moduleRoot -Leaf

Import-Module $moduleRoot -Force

Describe "Module $moduleName examples Tests" -Tag Build, Examples {

    Get-ChildItem $projectRoot\Examples\*.ps1 -Recurse | ForEach-Object {
        It "ok for $_" {
            & $_ 3>&1 4>&1 | Out-Null
            $? | Should Be $true
        }
    }

}