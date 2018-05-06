$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Describe "PSScriptAnalyzer Rules for $moduleName" -Tag Meta, BestPractice, BP {
    $analysis = Invoke-ScriptAnalyzer -Path $projectRoot -Recurse
    $scriptAnalyzerRules = Get-ScriptAnalyzerRule
    forEach ($rule in $scriptAnalyzerRules) {
        It "Should pass $rule" {
            If (($analysis) -and ($analysis.RuleName -contains $rule)) {
                $analysis | Where-Object RuleName -EQ $rule -OutVariable failures | Out-Default
                $failures.Count | Should Be 0
            }
        }
    }
}