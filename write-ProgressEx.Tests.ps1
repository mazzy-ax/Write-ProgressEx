# mazzy@mazzy.ru, 21.07.2017
# https://github.com/mazzy-ax/write-progressEx

Import-Module -Force ".\write-ProgressEx.psm1"

Describe "poshProgress" {
    $outerLevel = 1..3
    $innerLevel = 1..2

    BeforeEach {
        $global:ProgressExInfo = $null
    }

    Context "work" {
        It "work" {
            { write-ProgressEx } | Should not throw
        }

        It "double trouble work" {
            { write-ProgressEx; write-ProgressEx } | Should not throw
        }
    }

    context "sample" {
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
                $outerLevel | write-ProgressEx -increment | ForEach-Object {
                    write-ProgressEx "names" -Total $names.Count -id 1
                    $innerLevel | write-ProgressEx -id 1 -increment | ForEach-Object {
                        #start-sleep 1
                    }
                }
                write-ProgressEx -complete
            } | Should not throw
        }
    }


    context "basic functional" {
        It "store into global variable ProgressExInfo" {
            write-ProgressEx -Total $outerLevel.Count
            $Global:ProgressExInfo.Count | Should be 1
            ($Global:ProgressExInfo | Where-Object { $_.Std.ID -eq 0 }).Total | Should be $outerLevel.Count
        }

        It "write-ProgressEx without parameters complete all progresses" {
            write-ProgressEx "outerLevel" -Total $outerLevel.Count
            write-ProgressEx "innerLevel" -Total $innerLevel.Count -id 1

            $Global:ProgressExInfo.Count | Should be 2
            ($Global:ProgressExInfo | Where-Object { $_.Std.ID -eq 0 }).Total | Should be $outerLevel.Count
            ($Global:ProgressExInfo | Where-Object { $_.Std.ID -eq 1 }).Total | Should be $innerLevel.Count

            write-ProgressEx
            $Global:ProgressExInfo.Count | Should be 0
        }

        It "After the total updated every write-ProgressEx increment counter" {
            write-ProgressEx -Total $outerLevel.Count
            ($Global:ProgressExInfo | Where-Object { $_.Std.ID -eq 0 }).current | Should be 0

            write-ProgressEx -increment
            ($Global:ProgressExInfo | Where-Object { $_.Std.ID -eq 0 }).current | Should be 1
        }

        It "Every write-ProgressEx with 'previous' id complete inner progress" {
            write-ProgressEx -Total $outerLevel.Count
            write-ProgressEx -Total $innerLevel.Count -id 1
            ($Global:ProgressExInfo | Where-Object { $_.Std.ID -eq 0 }).current | Should be 0
            ($Global:ProgressExInfo | Where-Object { $_.Std.ID -eq 1 }).current | Should be 0

            write-ProgressEx -id 1 -increment
            ($Global:ProgressExInfo | Where-Object { $_.Std.ID -eq 0 }).current | Should be 0
            ($Global:ProgressExInfo | Where-Object { $_.Std.ID -eq 1 }).current | Should be 1

            write-ProgressEx -id 0 -increment
            ($Global:ProgressExInfo | Where-Object { $_.Std.ID -eq 0 }).current | Should be 1
            $Global:ProgressExInfo.Count | Should be 1

            write-ProgressEx
            $Global:ProgressExInfo.Count | Should be 0
        }
    }
}