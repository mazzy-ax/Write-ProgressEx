$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Describe "PSScriptAnalyzer Rules for $moduleName" -Tag Meta, BestPractice, BP {
    $analysis = Invoke-ScriptAnalyzer -Path $projectRoot -Recurse

    It "Should be Ok" {
        $analysis | Should -BeNullOrEmpty
    }

}