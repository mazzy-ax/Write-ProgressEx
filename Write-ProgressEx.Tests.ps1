# mazzy@mazzy.ru, 2017-10-10
# https://github.com/mazzy-ax/Write-progressEx

Import-Module -Force ".\Write-ProgressEx.psd1"

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
                Write-ProgressEx "outer" -Total $outerLevel
                $outerLevel | ForEach-Object {
                    Write-ProgressEx "inner" -Total $innerLevel -id 1
                    $innerLevel | ForEach-Object {
                        #start-sleep 1
                        Write-ProgressEx -id 1 -increment
                    }
                    Write-ProgressEx -increment
                }
                Write-ProgressEx -Completed
            } | Should not throw
        }

        It "pipes: outer and inner loops" {
            {
                $outerLevel | Write-ProgressEx "outer" -Total $outerLevel | ForEach-Object {
                    $innerLevel | Write-ProgressEx "inner" -Total $innerLevel -id 1 | ForEach-Object {
                        # ...
                    }
                }
            } | Should not throw
        }

        It "progress info: splatting" {
            $pInfo = Get-ProgressEx -Force
            $pInfo.Activity = 'splating'
            $pInfo.Status = 'another status'
            $pInfo.Total = $outerLevel

            { Write-ProgressEx @pInfo } | Should not throw

            Write-ProgressEx
        }
    }

    Context "functional" {
        AfterEach {
            Write-ProgressEx # complete all
        }

        It "store paramters in module variable" {
            Write-ProgressEx -Total $outerLevel
            (Get-ProgressEx).Total | Should be $outerLevel.Count
        }

        It "increment counter after the increment" {
            Write-ProgressEx -Total $outerLevel
            (Get-ProgressEx).current | Should be 0

            Write-ProgressEx -increment
            (Get-ProgressEx).current | Should be 1
        }

        It "autocomplete with pipe" {
            $outerLevel | Write-ProgressEx "outer" -Total $outerLevel | ForEach-Object {
                $innerLevel | Write-ProgressEx "inner" -Total $innerLevel -id 1 | ForEach-Object {
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
            Write-ProgressEx -Total $outerLevel
            Write-ProgressEx -Total $innerLevel -id 1
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
            Write-ProgressEx "outerLevel" -Total $outerLevel
            Write-ProgressEx "innerLevel" -Total $innerLevel -id 1

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
            $pInfo = 1, 30, 40 | Get-ProgressEx
            $pInfo.Count | Should be 3
            $pInfo[0] | Should be $null
            $pInfo[1] | Should be $null
            $pInfo[2] | Should be $null
        }

        It "pipe array parameter -force" {
            $pInfo = 1, 30, 40 | Get-ProgressEx -force
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

<#
Describe "Write-ProgressExMesage" {

    Context "work" {
        $MessageOnBegin = "Begin"
        Write-ProgressEx -MessageOnBegin $MessageOnBegin

        It "not exported" {
            get-command Write-ProgressExMessage -Module Write-ProgressEx | Should throw
        }

        InModuleScope Write-ProgressEx {
            It "by pInfo" {
                $pInfo = Get-ProgressEx -id 0
                Write-ProgressExMessage -pInfo $pInfo -MessageType OnBegin | Should $MessageOnBegin
            }
        }
    }
}

Describe "Write-ProgressExStd" {

    Context "work" {
        It "not exported" {
            { get-command Write-ProgressExStd -Module Write-ProgressEx } | Should throw
        }

        InModuleScope Write-ProgressEx {
            It "by pInfo" {
                $pInfo = Get-ProgressEx -id 0
                { Write-ProgressExStd -pInfo $pInfo } | Should not throw
            }
        }
    }
}
#>