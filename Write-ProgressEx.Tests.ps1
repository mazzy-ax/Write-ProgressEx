# mazzy@mazzy.ru, 2017-08-25
# https://github.com/mazzy-ax/Write-progressEx

Import-Module -Force ".\Write-ProgressEx.psm1"

Describe "Write-ProgressEx" {
    $outerLevel = 1..3
    $innerLevel = 1..2

    Context "Example" {
        It "work" {
            { Write-ProgressEx } | Should not throw
        }

        It "double trouble work" {
            { Write-ProgressEx; Write-ProgressEx } | Should not throw
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
                Write-ProgressEx -complete
            } | Should not throw
        }

        It "pipes: outer and inner loops" {
            {
                $outerLevel | Write-ProgressEx "outer" -Total $outerLevel.Count | ForEach-Object {
                    $innerLevel | Write-ProgressEx "inner" -Total $innerLevel.Count -id 1 | ForEach-Object {
                        # ...
                    }
                }
            } | Should not throw
        }

        It "progress info: splatting" {
            {
                Write-ProgressEx "outer" -Total $outerLevel.Count
                $outerLevel | Write-ProgressEx | ForEach-Object {
                    $pInfo = Get-ProgressEx
                    $pInfo.status = 'another status'
                    Write-ProgressEx @pInfo
                }
                Write-ProgressEx -complete
            } | Should not throw
        }
    }

    Context "functional" {
        It "store paramters in module variable" {
            Write-ProgressEx -Total $outerLevel.Count
            (Get-ProgressEx).Total | Should be $outerLevel.Count
        }

        It "increment counter after the increment" {
            Write-ProgressEx -Total $outerLevel.Count
            (Get-ProgressEx).current | Should be 0

            Write-ProgressEx -increment
            (Get-ProgressEx).current | Should be 1
        }

        It "autocomplete with pipe" {
            $outerLevel | Write-ProgressEx "outer" -Total $outerLevel.Count | ForEach-Object {
                $innerLevel | Write-ProgressEx "inner" -Total $innerLevel.Count -id 1 | ForEach-Object {
                    # ...
                    (Get-ProgressEx -id 0).Total | Should be $outerLevel.Count
                    (Get-ProgressEx -id 1).Total | Should be $innerLevel.Count
                    break
                }
                (Get-ProgressEx -id 0).Total | Should be $outerLevel.Count
                (Get-ProgressEx -id 1).Total | Should be $null
                break
            }
            (Get-ProgressEx -id 0) | Should be $null
        }

        It "complete children progress when 'previous' id used" {
            Write-ProgressEx -Total $outerLevel.Count
            Write-ProgressEx -Total $innerLevel.Count -id 1
            (Get-ProgressEx -id 0).current | Should be 0
            (Get-ProgressEx -id 1).current | Should be 0

            Write-ProgressEx -id 1 -increment
            (Get-ProgressEx -id 0).current | Should be 0
            (Get-ProgressEx -id 1).current | Should be 1

            Write-ProgressEx -id 0 -increment
            (Get-ProgressEx -id 0).current | Should be 1
            (Get-ProgressEx -id 1) | Should be $null

            Write-ProgressEx
            (Get-ProgressEx -id 0) | Should be $null
        }

        It "without parameters complete all children progresses" {
            Write-ProgressEx "outerLevel" -Total $outerLevel.Count
            Write-ProgressEx "innerLevel" -Total $innerLevel.Count -id 1

            (Get-ProgressEx -id 0).Total | Should be $outerLevel.Count
            (Get-ProgressEx -id 1).Total | Should be $innerLevel.Count

            Write-ProgressEx
            (Get-ProgressEx) | Should be $null
            (Get-ProgressEx -id 1) | Should be $null
        }
    }
}

Describe "Get-ProgressEx" {

    Context "work" {
        It "get" {
            { Get-ProgressEx } | Should not throw
        }

        It "get -force" {
            { Get-ProgressEx -force } | Should not throw
        }
    }

    Context "functional" {
        It "name parameter" {
            $pInfo = Get-ProgressEx -id 1
            $pInfo | Should be $null
        }

        It "name parameter -force" {
            $pInfo = Get-ProgressEx -id 1 -force
            $pInfo.Id | Should be 1
        }

        It "position parameter" {
            $pInfo = Get-ProgressEx 1
            $pInfo | Should be $null
        }

        It "position parameter -force" {
            $pInfo = Get-ProgressEx 1 -force
            $pInfo.Id | Should be 1
        }

        It "pipe parameter" {
            $pInfo = 1 | Get-ProgressEx
            $pInfo | Should be $null
        }

        It "pipe parameter -force" {
            $pInfo = 1 | Get-ProgressEx -force
            $pInfo.Id | Should be 1
        }

        It "pipe array parameter" {
            $pInfo = 1,30,40 | Get-ProgressEx
            $pInfo.Count | Should be 3
            $pInfo[0] | Should be $null
            $pInfo[1] | Should be $null
            $pInfo[2] | Should be $null
        }

        It "pipe array parameter -force" {
            $pInfo = 1,30,40 | Get-ProgressEx -force
            $pInfo.Count | Should be 3
            $pInfo[0].Id | Should be 1
            $pInfo[1].Id | Should be 30
            $pInfo[2].Id | Should be 40
        }
    }
}

Describe "Set-ProgressEx" {

    Context "work" {
        It "work" {
            { Set-ProgressEx } | Should not throw
        }

        It "double trouble work" {
            { Set-ProgressEx; Set-ProgressEx } | Should not throw
        }
    }
}