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
        [int]$Id = 0,
        [int]$PercentComplete,
        [int]$SecondsRemaining,
        [string]$CurrentOperation,
        [int]$ParentId,
        [int]$SourceId,
        [switch]$Completed
    )
    process {
        if ( -not $PSBoundParameters.Count ) {
            $Completed = $true
        }

        if ( -not $Global:ProgressExInfo ) {
            $Global:ProgressExInfo = @()
        }

        $id = [Math]::Min( [Math]::Max(0, $id), $Global:ProgressExInfo.Count)

        while ($id -lt $Global:ProgressExInfo.Count - 1 ) {
            Write-ProgressEx -Complete -id ($Global:ProgressExInfo.Count - 1)
        }

        if ( $id -eq $Global:ProgressExInfo.Count ) {
            $Global:ProgressExInfo += @{std = @{Id = $id}}
        }

        $pInfo = $Global:ProgressExInfo[$id]

        if ( $Activity ) {
            $pInfo.std.Activity = $Activity
        }

        if ( $Status ) {
            $pInfo.std.Status = $Status
        }

        if ( $CurrentOperation ) {
            $pInfo.std.CurrentOperation = $CurrentOperation
        }

        if ( $ParentId ) {
            $pInfo.std.ParentId = $ParentId
        }

        if ( $SourceId ) {
            $pInfo.std.SourceId = $SourceId
        }

        if ( $total ) {
            $pInfo.Current = 0
            $pInfo.std.PercentComplete = 0
            $pInfo.Total = $total
            if ( -not $Completed -and ($pInfo.Total -gt 0) ) {
                $pInfo.std.Activity = ($pInfo.std.Activity, $pInfo.Total -join ': ')
                $pInfo.stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $pInfo.std.SecondsRemaining = 0
            }
        }

        if ( $current ) {
            $pInfo.Current = [Math]::Min($current, $pInfo.Total)
        }

        if ( $increment -and -not $Completed `
                -and ($pInfo.Total -gt 0) `
                -and ($pInfo.Current -ne -1) ) {
            $pInfo.Current = [Math]::Min($pInfo.Current + 1, $pInfo.Total)
            $pInfo.std.PercentComplete = [Math]::Min( [Math]::Max(0, [int]($pInfo.Current / $pInfo.Total * 100)), 100)
            if ( $pInfo.stopwatch ) {
                [System.Diagnostics.Stopwatch]$stopwatch = $pInfo.stopwatch
                $pInfo.std.SecondsRemaining = [Math]::Max(0, 1 + $stopwatch.Elapsed.TotalSeconds * ($pInfo.Total - $pInfo.Current) / $pInfo.Current)
            }
        }

        if ( $PercentComplete ) {
            $pInfo.std.PercentComplete = $PercentComplete
        }

        if ( $SecondsRemaining ) {
            $pInfo.std.SecondsRemaining = $SecondsRemaining
        }

        if ( $Completed ) {
            $pInfo.std.Completed = $Completed
        }

        # Activity is mandatory parameter for Write-Progress
        if (-not $pInfo.std.Activity) {
            $pInfo.std.Activity = '.'
        }

        $Args = $pInfo.std
        Write-Progress @Args

        # Housecleaning
        if ( $pInfo.std.Completed ) {
            $pInfo.stopwatch = $null
            $Global:ProgressExInfo = @() + ($Global:ProgressExInfo | Select-Object -First ($Global:ProgressExInfo.Count - 1)) # not safe with multithreading
        }
        else {
            $Global:ProgressExInfo[$id] = $pInfo
        }

        # PassThru
        if ( $inputObject ) {
            $inputObject
        }
    }
}