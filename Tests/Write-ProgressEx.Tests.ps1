$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Import-Module $moduleName -Force

Describe "Write-ProgressEx" -Tag "Run", "UnitTest", "UT" {
    $outerLevel = 1..3
    $innerLevel = 1..2

    Context "Work" {
        It "work" {
            { Write-ProgressEx } | Should -Not -Throw
        }

        It "double trouble work" {
            { Write-ProgressEx; Write-ProgressEx } | Should -Not -Throw
        }

        It "parameters: outer and inner loops" {
            {
                Write-ProgressEx "outer" -Total $outerLevel.Count
                $outerLevel | ForEach-Object {
                    Write-ProgressEx "inner" -Total $innerLevel.Count -id 1
                    $innerLevel | ForEach-Object {
                        #start-sleep 1
                        Write-ProgressEx -id 1 -increment
                    }
                    Write-ProgressEx -increment
                }
                Write-ProgressEx -Completed
            } | Should -Not -Throw
        }

        It "pipes: outer and inner loops" {
            {
                $outerLevel | Write-ProgressEx "outer" -Total $outerLevel.Count | ForEach-Object {
                    $innerLevel | Write-ProgressEx "inner" -Total $innerLevel.Count -id 1 | ForEach-Object {
                        # ...
                    }
                }
            } | Should -Not -Throw
        }

        It "progress info: splatting" {
            $pInfo = Get-ProgressEx -Force
            $pInfo.Activity = 'splating'
            $pInfo.Status = 'another status'
            $pInfo.Total = $outerLevel.Count

            { Write-ProgressEx @pInfo } | Should -Not -Throw

            Write-ProgressEx
        }
    }

    Context "Functional" {
        AfterEach {
            Write-ProgressEx # complete all
        }

        It "store paramters in module variable" {
            Write-ProgressEx -Total $outerLevel.Count
            (Get-ProgressEx).Total | Should -Be $outerLevel.Count
        }

        It "increment counter after the increment" {
            Write-ProgressEx -Total $outerLevel.Count
            (Get-ProgressEx).current | Should -Be 0

            Write-ProgressEx -increment
            (Get-ProgressEx).current | Should -Be 1
        }

        It "autocomplete with pipe" {
            $outerLevel | Write-ProgressEx "outer" -Total $outerLevel.Count | ForEach-Object {
                $innerLevel | Write-ProgressEx "inner" -Total $innerLevel.Count -id 1 | ForEach-Object {
                    # ...
                    (Get-ProgressEx -id 0).Total | Should -Be $outerLevel.Count
                    (Get-ProgressEx -id 1).Total | Should -Be $innerLevel.Count
                    break
                }
                (Get-ProgressEx -id 0).Total | Should -Be $outerLevel.Count
                (Get-ProgressEx -id 1).Total | Should -BeNullOrEmpty
                break
            }
            (Get-ProgressEx -id 0) | Should -BeNullOrEmpty
        }

        It "complete children progress when 'previous' id used" {
            Write-ProgressEx -Total $outerLevel.Count
            Write-ProgressEx -Total $innerLevel.Count -id 1
            (Get-ProgressEx -id 0).current | Should -Be 0
            (Get-ProgressEx -id 1).current | Should -Be 0

            Write-ProgressEx -id 1 -increment
            (Get-ProgressEx -id 0).current | Should -Be 0
            (Get-ProgressEx -id 1).current | Should -Be 1

            Write-ProgressEx -id 0 -increment
            (Get-ProgressEx -id 0).current | Should -Be 1
            (Get-ProgressEx -id 1) | Should -BeNullOrEmpty

            Write-ProgressEx
            (Get-ProgressEx -id 0) | Should -BeNullOrEmpty
        }

        It "without parameters complete all children progresses" {
            Write-ProgressEx "outerLevel" -Total $outerLevel.Count
            Write-ProgressEx "innerLevel" -Total $innerLevel.Count -id 1

            (Get-ProgressEx -id 0).Total | Should -Be $outerLevel.Count
            (Get-ProgressEx -id 1).Total | Should -Be $innerLevel.Count

            Write-ProgressEx
            (Get-ProgressEx) | Should -BeNullOrEmpty
            (Get-ProgressEx -id 1) | Should -BeNullOrEmpty
        }
    }
}

Describe "Get-ProgressEx" -Tag "Run", "UnitTest", "UT" {

    Context "work" {
        It "get" {
            { Get-ProgressEx } | Should -Not -Throw
        }

        It "get -force" {
            { Get-ProgressEx -force } | Should -Not -Throw
        }
    }

    Context "functional" {
        It "name parameter" {
            $pInfo = Get-ProgressEx -id 1
            $pInfo | Should -BeNullOrEmpty
        }

        It "name parameter -force" {
            $pInfo = Get-ProgressEx -id 1 -force
            $pInfo.Id | Should -Be 1
        }

        It "position parameter" {
            $pInfo = Get-ProgressEx 1
            $pInfo | Should -BeNullOrEmpty
        }

        It "position parameter -force" {
            $pInfo = Get-ProgressEx 1 -force
            $pInfo.Id | Should -Be 1
        }

        It "pipe parameter" {
            $pInfo = 1 | Get-ProgressEx
            $pInfo | Should -BeNullOrEmpty
        }

        It "pipe parameter -force" {
            $pInfo = 1 | Get-ProgressEx -force
            $pInfo.Id | Should -Be 1
        }

        It "pipe array parameter" {
            $pInfo = 1, 30, 40 | Get-ProgressEx
            $pInfo.Count | Should -Be 3
            $pInfo[0] | Should -BeNullOrEmpty
            $pInfo[1] | Should -BeNullOrEmpty
            $pInfo[2] | Should -BeNullOrEmpty
        }

        It "pipe array parameter -force" {
            $pInfo = 1, 30, 40 | Get-ProgressEx -force
            $pInfo.Count | Should -Be 3
            $pInfo[0].Id | Should -Be 1
            $pInfo[1].Id | Should -Be 30
            $pInfo[2].Id | Should -Be 40
        }
    }
}

Describe "Set-ProgressEx" -Tag "Run", "UnitTest", "UT" {

    Context "work" {
        It "work" {
            { Set-ProgressEx } | Should -Not -Throw
        }

        It "double trouble work" {
            { Set-ProgressEx; Set-ProgressEx } | Should -Not -Throw
        }
    }
}
