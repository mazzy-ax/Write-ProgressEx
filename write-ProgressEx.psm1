# mazzy@mazzy.ru, 23.07.2017
# https://github.com/mazzy-ax/Write-ProgressEx

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
    process {
        if ( $Global:ProgressExInfo -isnot [array] ) {
            $Global:ProgressExInfo = @()
        }

        $pInfo = $Global:ProgressExInfo | Where-Object { $_.Std.Id -eq $id } | Select-Object -First 1

        if ( $pInfo -isnot [hashtable] -or $pInfo.Std -isnot [hashtable] ) {
            $pInfo = @{Std = @{Id = $id}}
        }

        if ( $Completed ) {
            $pInfo.Std.Completed = $Completed
        }

        if ( $Activity ) {
            $pInfo.Std.Activity = $Activity
        }

        if ( $total ) {
            $pInfo.Std.PercentComplete = 0
            $pInfo.Current = 0
            $pInfo.Total = $total
            if ( -not $pInfo.Std.Completed -and ($pInfo.Total -gt 0) ) {
                $pInfo.Std.Activity = ($pInfo.Std.Activity, $pInfo.Total -join ': ')
                $pInfo.Std.SecondsRemaining = 0
                $pInfo.stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

                if ( (-not $ParentId) -and (-not $pInfo.Std.ParentId) ) {
                    $ParentInfo = ($Global:ProgressExInfo | Where-Object { $_.Std.Id -lt $id } | Measure-Object -Maximum).Maximum
                    if ( $ParentInfo ) {
                        $pInfo.Std.ParentId = $ParentInfo.Std.Id
                    }
                }
            }
        }

        if ( $Current ) {
            $pInfo.Current = [Math]::Max(-1, [Math]::Min($Current, $pInfo.Total))
            $pInfo.stopwatch = $null
        }

        if ( $Increment -and -not $pInfo.Std.Completed `
                -and ($pInfo.Total -gt 0) `
                -and ($pInfo.Current -ne -1) ) {
            # next
            $pInfo.Current = [Math]::Min($pInfo.Current + 1, $pInfo.Total)

            # calc
            if ( -not $PercentComplete ) {
                $pInfo.Std.PercentComplete = [Math]::Min( [Math]::Max(0, [int]($pInfo.Current / $pInfo.Total * 100)), 100)
            }
            if ( -not $SecondsRemaining -and $pInfo.stopwatch ) {
                [System.Diagnostics.Stopwatch]$stopwatch = $pInfo.stopwatch
                $pInfo.Std.SecondsRemaining = [Math]::Max(0, 1 + $stopwatch.Elapsed.TotalSeconds * ($pInfo.Total - $pInfo.Current) / $pInfo.Current)
            }
        }

        if ( $PercentComplete ) {
            $pInfo.Std.PercentComplete = $PercentComplete
        }

        if ( $SecondsRemaining ) {
            $pInfo.Std.SecondsRemaining = $SecondsRemaining
        }

        if ( $ParentId ) {
            $pInfo.Std.ParentId = $ParentId
        }

        if ( $SourceId ) {
            $pInfo.Std.SourceId = $SourceId
        }

        if ( $Status ) {
            $pInfo.Std.Status = $Status
        }

        if ( $CurrentOperation ) {
            $pInfo.Std.CurrentOperation = $CurrentOperation
        }

        # Activity is mandatory parameter for Write-Progress
        if ( -not $pInfo.Std.Activity ) {
            $pInfo.Std.Activity = '.'
        }

        $pArgs = $pInfo.Std
        Write-Progress @pArgs

        # Store to global
        $Global:ProgressExInfo = (, $pInfo) + ($Global:ProgressExInfo | Where-Object { $_.Std.Id -ne $pInfo.Std.Id })

        # Remove Completed
        if ( -not $PSBoundParameters.Count ) {
            # Complete all progresses
            $ToComplete = @() + ($Global:ProgressExInfo | ForEach-Object { $_.Std.Id })
        }
        else {
            # Complete all children progresses
            $ToComplete = @() + ($Global:ProgressExInfo | Where-Object { $_.Std.Completed } | ForEach-Object { $_.Std.Id })
            $Generation = @($pInfo.Std.id)
            do {
                $Generation = @() + ($Global:ProgressExInfo `
                    | Where-Object { ($_.Std.ParentId -ne $null) -and ($_.Std.ParentId -in $Generation) -and ($_.Std.id -notin $ToComplete) } `
                    | ForEach-Object { $_.Std.Id })
                $ToComplete += $Generation
            } while ($Generation)
        }

        if ( $ToComplete.Count ) {
            $Global:ProgressExInfo = @() + ($Global:ProgressExInfo | ForEach-Object {
                    if ( $_.Std.Id -notin $ToComplete ) {
                        $_
                    }
                    else {
                        $_.stopwatch = $null
                        $_.Std.Completed = $true
                        Write-Progress -Complete -id $_.Std.id -Activity $_.Std.Activity
                    }
                })
        }

        # PassThru
        if ( $inputObject ) {
            $inputObject
        }
    }
}

Export-ModuleMember -function Write-ProgressEx