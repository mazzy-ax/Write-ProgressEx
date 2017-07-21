# mazzy@mazzy.ru, 21.07.2017
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
            #FIXME check array of hashtable
            $Global:ProgressExInfo = @()
        }

        $id = [Math]::Min( [Math]::Max(0, $id), $Global:ProgressExInfo.Count)

        while ($id -lt $Global:ProgressExInfo.Count - 1 ) {
            Write-ProgressEx -Complete -id ($Global:ProgressExInfo.Count - 1)                       
        }

        if ( $id -eq $Global:ProgressExInfo.Count ) {
            $Global:ProgressExInfo += @{std = @{Id = $id}}
        }

        if ( $Activity ) {
            $Global:ProgressExInfo[$id].std.Activity = $Activity
        }

        if ( $Status ) {
            $Global:ProgressExInfo[$id].std.Status = $Status
        }

        if ( $CurrentOperation ) {
            $Global:ProgressExInfo[$id].std.CurrentOperation = $CurrentOperation
        }

        if ( $ParentId ) {
            $Global:ProgressExInfo[$id].std.ParentId = $ParentId
        }

        if ( $SourceId ) {
            $Global:ProgressExInfo[$id].std.SourceId = $SourceId
        }

        if ( $total ) {
            $Global:ProgressExInfo[$id].Current = 0
            $Global:ProgressExInfo[$id].std.PercentComplete = 0
            $Global:ProgressExInfo[$id].Total = $total
            if ( -not $Completed -and ($Global:ProgressExInfo[$id].Total -gt 0) ) {
                $Global:ProgressExInfo[$id].std.Activity = ($Global:ProgressExInfo[$id].std.Activity, $Global:ProgressExInfo[$id].Total -join ': ')
                $Global:ProgressExInfo[$id].stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $Global:ProgressExInfo[$id].std.SecondsRemaining = 0
            }
        }
        if ( $current ) {
            $Global:ProgressExInfo[$id].Current = [Math]::Min($current, $Global:ProgressExInfo[$id].Total)
        }       
        if ( $increment -and -not $Completed `
                -and ($Global:ProgressExInfo[$id].Total -gt 0) `
                -and ($Global:ProgressExInfo[$id].Current -ne -1) ) {
            $Global:ProgressExInfo[$id].Current = [Math]::Min($Global:ProgressExInfo[$id].Current + 1, $Global:ProgressExInfo[$id].Total)
            $Global:ProgressExInfo[$id].std.PercentComplete = [Math]::Min( [Math]::Max(0, [int]($Global:ProgressExInfo[$id].Current / $Global:ProgressExInfo[$id].Total * 100)), 100)
            if ( $Global:ProgressExInfo[$id].stopwatch ) {
                [System.Diagnostics.Stopwatch]$stopwatch = $Global:ProgressExInfo[$id].stopwatch
                $Global:ProgressExInfo[$id].std.SecondsRemaining = [Math]::Max(0, 1 + $stopwatch.Elapsed.TotalSeconds * ($Global:ProgressExInfo[$id].Total - $Global:ProgressExInfo[$id].Current) / $Global:ProgressExInfo[$id].Current)
            }
        }

        if ( $PercentComplete ) {
            $Global:ProgressExInfo[$id].std.PercentComplete = $PercentComplete
        }
        if ( $SecondsRemaining -or $Completed ) {
            $Global:ProgressExInfo[$id].std.SecondsRemaining = $SecondsRemaining
            $Global:ProgressExInfo[$id].stopwatch = $null
        }

        if (-not $Global:ProgressExInfo[$id].std.Activity) {
            $Global:ProgressExInfo[$id].std.Activity = '.'
        }

        $pInfo = $Global:ProgressExInfo[$id].std
        if ( $Completed ) {
            Write-Progress @pInfo -Completed
            $Global:ProgressExInfo[$id].stopwatch = $null
            $Global:ProgressExInfo = @() + ($Global:ProgressExInfo | Select-Object -First ($Global:ProgressExInfo.Count - 1))
        }
        else {
            Write-Progress @pInfo
        }

        if ( $inputObject ) {
            $inputObject
        }
    }
}