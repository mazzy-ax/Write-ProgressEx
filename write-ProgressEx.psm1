# mazzy@mazzy.ru, 2017-08-06
# https://github.com/mazzy-ax/Write-ProgressEx


$ProgressEx = @{}
$StdParmNames = (Get-Command Write-Progress).Parameters.Keys

<#
.SYNOPSIS
    Get or Create hashtable for progress with Id.

.DESCRIPTION
    This cmdlet returns an hashtable related the progress with an Id.
    The hashtable contain activity string, current and total counters, remain seconds, PercentComplete and other progress parameters.

    The cmdlet returns $null if an Id was not used yet.
    It returns new hashtable if $force specified and an Id was not used.

.NOTES
    A developer can modify values and use the hashtable for splatting into Write-ProgressEx.

.EXAMPLE
    $range = 1..1000
    write-ProgressEx 'wait, please' -Total $range.Count
    $range | write-ProgressEx | ForEach-Object {
        $pInfo = Get-ProgressEx

        if ( $pInfo.SecondsRemaining -lt 5 ) {
            $pInfo['Activity'] = 'just a few seconds'
            Write-ProgressEx @pInfo  # <-------
        }
    }
    The splatting to Write-ProgressEx is a common pattern to use progress info:
    It's recalculate parameters and refresh progress on the console.

#>
function Get-ProgressEx {
    [cmdletbinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Id = 0,

        [switch]$Force
    )

    process {
        $pInfo = $ProgressEx[$Id]

        if ( $pInfo -is [hashtable] ) {
            return $pInfo
        }

        if ( $Force ) {
            return @{Id = $id}
        }

        $null
    }
}

<#
.SYNOPSIS
    Set parameters for the progress with Id and dispaly this values to the console.

.DESCRIPTION
    The cmdlet:
    * save parameters
    * display this parameters to console
    * complete progress if Completed parameter is $true
    * complete all children progresses always.

.EXAMPLE
    $range = 1..1000
    write-ProgressEx 'wait, please' -Total $range.Count
    $range | write-ProgressEx | ForEach-Object {
        $pInfo = Get-ProgressEx
        if ( $pInfo.PercentComplete -gt 50 ) {
            $pInfo['Status'] = 'hard work in progress'
            Set-ProgressEx $pInfo  # <-------
        }
    }
    Set-ProgressEx is a rare pattern to use progress info.
    It's no recalulate. It refresh progress on the console only.
    Write-ProgressEx recommended.

#>
function Set-ProgressEx {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [hashtable]$Info
    )

    process {
        function Write-ProgressStd($pInfo) {
            # Invoke standard write-progress cmdlet
            $pArgs = @{}
            $pInfo.Keys | Where-Object { $_ -in $StdParmNames } | ForEach-Object { $pArgs[$_] = $pInfo[$_] }

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
            if ( $ProgressEx.ContainsKey($Id) ) {
                $ProgressEx[$Id].Completed = $true
                $ProgressEx[$Id].Stopwatch = $null
                $ProgressEx.Remove($Id)
            }
        }

        function Complete-ChilrenProgress($Ids) {
            while ($Ids -ne $null) {
                $Ids = $ProgressEx.Keys | Where-Object { $ProgressEx[$_].ParentId -in $Ids }
                $Ids | ForEach-Object {
                    Write-Progress -Completed -Activity '.' -id $_
                    Complete-Progress $_
                }
            }
        }

        if ( $Info.id -ge 0 ) {
            $ProgressEx[$Info.Id] = $Info

            Write-ProgressStd $Info

            if ( $Info.Completed ) {
                Complete-Progress $Info.Id
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
    The cmdlet complete all children progresses.
.NOTE
    A developer can use a parameter splatting.
    See Get-ProgressEx example.
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
        [System.Diagnostics.Stopwatch]$stopwatch,

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
        $pInfo = Get-ProgressEx $id -Force

        if ( $ParentId ) {
            $pInfo.ParentId = $ParentId
        }

        if ( $SourceId ) {
            $pInfo.SourceId = $SourceId
        }

        if ( $stopwatch ) {
            $pInfo.stopwatch = $stopwatch
        }

        if ( $total ) {
            $pInfo.Total = $total

            if ( -not $Increment -and -not $inputObject ) {
                $pInfo.PercentComplete = 0
                $pInfo.Current = 0
            }

            if ( -not $pInfo.ParentId ) {
                $ParentInfo = ($ProgressEx.Keys | Where-Object { $_ -lt $pInfo.id } | Measure-Object -Maximum).Maximum
                if ( $ParentInfo -ne $null ) {
                    $pInfo.ParentId = $ParentInfo
                }
            }

            if ( -not $pInfo.stopwatch -and ($pInfo.Total -gt 0) ) {
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
        elseif ( $isCalcPossible -and $pInfo.stopwatch  ) {
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

        if ( $Completed -or -not $PSBoundParameters.Count  ) {
            $pInfo.Completed = $true
        }

        # Store to global and call standard Write-Progress to display progress
        Set-ProgressEx $pInfo

        # PassThru
        if ( $inputObject ) {
            $inputObject
        }
    }
}

Export-ModuleMember -function Write-ProgressEx, Get-ProgressEx, Set-ProgressEx