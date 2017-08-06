# mazzy@mazzy.ru, 06.08.2017
# https://github.com/mazzy-ax/write-progressEx

Import-Module -Force ".\write-ProgressEx.psm1"

Describe "Write-ProgressEx" {
    $outerLevel = 1..3
    $innerLevel = 1..2

    BeforeEach {
        $Global:ProgressExInfo = $null
    }

    Context "work" {
        It "work" {
            { write-ProgressEx } | Should not throw
        }

        It "double trouble work" {
            { write-ProgressEx; write-ProgressEx } | Should not throw
        }

        It "parameters: outer and inner loops" {
            {
                write-ProgressEx "nodes" -Total $nodes.Count
                $outerLevel | ForEach-Object {
                    write-ProgressEx "names" -Total $names.Count -id 1
                    $innerLevel | ForEach-Object {
                        #start-sleep 1
                        write-ProgressEx -id 1 -increment
                    }
                    write-ProgressEx -increment
                }
                write-ProgressEx -complete
            } | Should not throw
        }

        It "pipes: outer and inner loops" {
            {
                write-ProgressEx "nodes" -Total $nodes.Count
                $outerLevel | write-ProgressEx | ForEach-Object {
                    write-ProgressEx "names" -Total $names.Count -id 1
                    $innerLevel | write-ProgressEx -id 1 | ForEach-Object {
                        #start-sleep 1
                    }
                }
                write-ProgressEx -complete
            } | Should not throw
        }
    }


    context "basic functional" {
        It "ProgressExInfo stored" {
            write-ProgressEx -Total $outerLevel.Count
            (Get-ProgressExInfo).Total | Should be $outerLevel.Count
        }

        It "write-ProgressEx without parameters complete all progresses" {
            write-ProgressEx "outerLevel" -Total $outerLevel.Count
            write-ProgressEx "innerLevel" -Total $innerLevel.Count -id 1

            (Get-ProgressExInfo).Total | Should be $outerLevel.Count
            (Get-ProgressExInfo -id 1).Total | Should be $innerLevel.Count

            write-ProgressEx
            $Global:ProgressExInfo.Count | Should be 0
        }

        It "After the total updated every write-ProgressEx increment counter" {
            write-ProgressEx -Total $outerLevel.Count
            (Get-ProgressExInfo).current | Should be 0

            write-ProgressEx -increment
            (Get-ProgressExInfo).current | Should be 1
        }

        It "Every write-ProgressEx with 'previous' id complete inner progress" {
            write-ProgressEx -Total $outerLevel.Count
            write-ProgressEx -Total $innerLevel.Count -id 1
            (Get-ProgressExInfo).current | Should be 0
            (Get-ProgressExInfo -id 1).current | Should be 0

            write-ProgressEx -id 1 -increment
            (Get-ProgressExInfo).current | Should be 0
            (Get-ProgressExInfo -id 1).current | Should be 1

            write-ProgressEx -id 0 -increment
            (Get-ProgressExInfo -id 0).current | Should be 1
            $Global:ProgressExInfo.Count | Should be 1

            write-ProgressEx
            $Global:ProgressExInfo.Count | Should be 0
        }
    }
}

Describe "Get-ProgressExInfo" {

    BeforeEach {
        $Global:ProgressExInfo = $null
    }

    Context "work" {
        It "get" {
            { Get-ProgressExInfo } | Should not throw
        }

        It "get -ForceNew" {
            { Get-ProgressExInfo -ForceNew } | Should not throw
        }

        It "name parameter" {
            $pInfo = Get-ProgressExInfo -id 1
            $pInfo | Should be $null
        }

        It "name parameter -forceNew" {
            $pInfo = Get-ProgressExInfo -id 1 -forceNew
            $pInfo.Id | Should be 1
        }

        It "position parameter" {
            $pInfo = Get-ProgressExInfo 1
            $pInfo | Should be $null
        }

        It "position parameter -forceNew" {
            $pInfo = Get-ProgressExInfo 1 -forceNew
            $pInfo.Id | Should be 1
        }

        It "pipe parameter" {
            $pInfo = 1 | Get-ProgressExInfo
            $pInfo | Should be $null
        }

        It "pipe parameter -forceNew" {
            $pInfo = 1 | Get-ProgressExInfo -forceNew
            $pInfo.Id | Should be 1
        }

        It "pipe array parameter" {
            $pInfoArray = 1,30,40 | Get-ProgressExInfo
            $pInfoArray.Count | Should be 3
            $pInfoArray[0] | Should be $null
            $pInfoArray[1] | Should be $null
            $pInfoArray[2] | Should be $null
        }

        It "pipe array parameter -forceNew" {
            $pInfoArray = 1,30,40 | Get-ProgressExInfo -ForceNew
            $pInfoArray.Count | Should be 3
            $pInfoArray[0].Id | Should be 1
            $pInfoArray[1].Id | Should be 30
            $pInfoArray[2].Id | Should be 40
        }
    }

}

Describe "Set-ProgressExInfo" {

    BeforeEach {
        $Global:ProgressExInfo = $null
    }

    Context "work" {
        It "work" {
            { Set-ProgressExInfo } | Should not throw
        }

        It "double trouble work" {
            { Set-ProgressExInfo; Set-ProgressExInfo } | Should not throw
        }
    }
}