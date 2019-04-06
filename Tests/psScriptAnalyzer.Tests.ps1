#Requires -module Pester

$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Describe "PSScriptAnalyzer Rules for $moduleName" -Tag Meta, BestPractice, BP {
    $analysis = Invoke-ScriptAnalyzer -Path $projectRoot -Recurse

    $analysis | ForEach-Object {
        $_ | Out-Default
    }

    It "Should be 0 diagnostic messages" {
        $analysis.count | Should -Be 0
    }
}