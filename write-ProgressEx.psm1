# mazzy@mazzy.ru, 06.08.2017
# https://github.com/mazzy-ax/Write-ProgressEx

$StdParmNames = (Get-Command Write-Progress).Parameters.GetEnumerator() | Select-Object -ExpandProperty Key

function Mount-ProgressExInfo {
    [cmdletbinding()]
    param(
        [switch]$Force
    )

    begin {
        if ( $Force -or $Global:ProgressExInfo -isnot [hashtable] ) {
            $Global:ProgressExInfo = @{}
        }
    }
}

function Get-ProgressExInfo {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Id = 0,

        [switch]$ForceNew
    )

    begin {
        Mount-ProgressExInfo
    }

    process {
        $pInfo = $Global:ProgressExInfo[$Id]

        if ( $pInfo -is [hashtable] ) {
            return $pInfo
        }

        if ( $ForceNew ) {
            return @{Id = $id}
        }

        $null
    }
}

function Set-ProgressExInfo {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [hashtable]$Info
    )

    begin {
        Mount-ProgressExInfo
    }

    process {
        function Write-ProgressStd($pInfo) {
            # Invoke standard write-progress cmdlet
            $pArgs = @{}
            $pInfo.GetEnumerator() | Where-Object { $_.name -in $StdParmNames } | ForEach-Object { $pArgs.Add( $_.name, $_.value ) }

            if ( $pInfo.Total ) {
                $pArgs.Activity = ($pArgs.Activity, ($pInfo.Current, $pInfo.Total -join '/') -join ': ')
            }

            # Activity is mandatory parameter for standard Write-Progress
            if ( -not $pArgs.Activity ) {
                $pArgs.Activity = '.'
            }

            Write-Progress @pArgs
        }

        function Complete-Progress($Id) {
            $Global:ProgressExInfo[$Id].Completed = $true
            $Global:ProgressExInfo[$Id].Stopwatch = $null
            $Global:ProgressExInfo.Remove($Id)
        }

        function Complete-ChilrenProgress($Ids) {
            while ($Ids -ne $null) {
                $Ids = $Global:ProgressExInfo.GetEnumerator() `
                    | Where-Object { $_.Value -and ($_.Value.ParentId -ne $null) -and ($_.Value.ParentId -in $Ids) } `
                    | Select-Object -ExpandProperty Key

                $Ids | ForEach-Object {
                    Write-Progress -Completed -Activity '.' -id $_
                    Complete-Progress($_)
                }
            }
        }

        if ( $Info.id -ne $null ) {
            $Global:ProgressExInfo[$Info.Id] = $Info

            Write-ProgressStd $Info

            if ( $Info.Completed ) {
                Complete-Progress($Info.Id)
            }

            # A set-action with a progress is a cause to complete all children
            Complete-ChilrenProgress $Info.id
        }
    }
}

<#
.SYNOPSIS
    Powershell Extended Write-Progress cmdlet.

.EXAMPLE
    Write-ProgressEx -Total $nodes.Count
    $nodes | Where-Object ...... | ForEach-Object {
        Write-ProgressEx -Total $names.Count -id 1
        $names | Where-Object ...... | ForEach-Object {
            ......
            Write-ProgressEx -id 1 -increment
        }
        Write-ProgressEx -increment
    }
    write-posProgress -complete
.EXAMPLE
    Write-ProgressEx -Total $nodes.Count
    $nodes | Where-Object ...... | Write-ProgressEx | ForEach-Object {
        Write-ProgressEx -Total $names.Count -id 1
        $names | Where-Object ...... | Write-ProgressEx -id 1 | ForEach-Object {
            ......
        }
    }
    Write-ProgressEx -complete
.EXAMPLE
    Ideal: is it possible?

    $nodes | Where-Object ...... | Write-ProgressEx | ForEach-Object {
        $names | Where-Object ...... | Write-ProgressEx -id 1 | ForEach-Object {
            ......
        }
    }
    write-posProgress -complete
.NOTE
    Commands 'Write-ProgressEx.ps1' and 'Write-ProgressEx -Complete' are equivalents.
.NOTE
    Cmdlet is not safe with multi-thread.
#>
function Write-ProgressEx {
    [cmdletbinding()]
    param(
        # Extended parameters
        [Parameter(ValueFromPipeline = $true)]
        [object]$inputObject,

        [ValidateRange(-1, [int]::MaxValue)]
        [int]$total,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$current,
        [switch]$increment,

        # Standard parameters for standard Powershell write-progress
        [Parameter(Position = 0)]
        [string]$Activity,
        [Parameter(Position = 1)]
        [string]$Status,
        [Parameter(Position = 2)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Id = 0,
        [int]$PercentComplete,
        [int]$SecondsRemaining,
        [string]$CurrentOperation,
        [int]$ParentId,
        [int]$SourceId,
        [switch]$Completed
    )

    begin {
        Mount-ProgressExInfo
    }

    process {
        $pInfo = Get-ProgressExInfo $id -ForceNew

        if ( $ParentId ) {
            $pInfo.ParentId = $ParentId
        }

        if ( $SourceId ) {
            $pInfo.SourceId = $SourceId
        }

        if ( $total ) {
            $pInfo.PercentComplete = 0
            $pInfo.Current = 0
            $pInfo.Total = $total

            if ( -not $pInfo.ParentId ) {
                $ParentInfo = ($Global:ProgressExInfo.GetEnumerator() | Where-Object { $_.Key -lt $id } | Select-Object -ExpandProperty Key | Measure-Object -Maximum).Maximum
                if ( $ParentInfo -ne $null ) {
                    $pInfo.ParentId = $ParentInfo
                }
            }

            if ( $pInfo.Total -gt 0 ) {
                $pInfo.SecondsRemaining = 0
                $pInfo.stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            }
        }

        if ( $Current ) {
            $pInfo.Current = [Math]::Max(-1, [Math]::Min($Current, $pInfo.Total))
            $pInfo.stopwatch = $null
        }

        if ( $Increment -or $inputObject ) {
            # next
            $pInfo.Current = [Math]::Min([Math]::Max(0, $pInfo.Current + 1), $pInfo.Total)
        }

        $isCalcPossible = ($pInfo.Total -gt 0) -and ($pInfo.Current -gt 0)

        if ( $PercentComplete ) {
            $pInfo.PercentComplete = $PercentComplete
        }
        elseif ( $isCalcPossible ) {
            $pInfo.PercentComplete = [Math]::Min( [Math]::Max(0, [int]($pInfo.Current / $pInfo.Total * 100)), 100)
        }

        if ( $SecondsRemaining ) {
            $pInfo.SecondsRemaining = $SecondsRemaining
        }
        elseif ( $pInfo.stopwatch -and $isCalcPossible ) {
            $stopwatch = [System.Diagnostics.Stopwatch]$pInfo.stopwatch
            $pInfo.SecondsRemaining = [Math]::Max(0, 1 + $stopwatch.Elapsed.TotalSeconds * ($pInfo.Total - $pInfo.Current) / $pInfo.Current)
        }

        if ( $Status ) {
            $pInfo.Status = $Status
        }

        if ( $CurrentOperation ) {
            $pInfo.CurrentOperation = $CurrentOperation
        }

        if ( $Activity ) {
            $pInfo.Activity = $Activity
        }

        if ( -not $PSBoundParameters.Count -or $Completed ) {
            $pInfo.Completed = $true
        }

        # Store to global and call standard Write-Progress to display progress
        Set-ProgressExInfo $pInfo

        # PassThru
        if ( $inputObject ) {
            $inputObject
        }
    }

    # end {
    #     # Cleanup
    #     $Global:ProgressExInfo.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object {
    #         $Global:ProgressExInfo.Remove($_.Key)
    #     }
    # }
}


Export-ModuleMember -function Write-ProgressEx, Get-ProgressExInfo, Set-ProgressExInfo