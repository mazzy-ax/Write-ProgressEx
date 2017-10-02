# mazzy@mazzy.ru, 2017-10-03
# https://github.com/mazzy-ax/Write-ProgressEx

#requires -version 3.0

$ProgressEx = @{}
$StdParmNames = (Get-Command Write-Progress).Parameters.Keys

function Get-ProgressEx {
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

function Set-ProgressEx {
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
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [hashtable]$Info
    )

    process {
        function Write-EndMessage ($Id) {
            $pInfo = Get-ProgressEx $Id
            if ( $pInfo -and $pInfo.Completed -and $pInfo.EndMessage ) {
                $Message = -join $pInfo.EndMessage #TODO How to format apostrophe string?
                Write-Output $Message
            }
        }

        function Write-ProgressStd([hashtable]$pInfo) {
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

        function Complete-ProgressAndChilren($Ids, $CompleteNow) {
            while ($Ids -ne $null) {
                # Complete
                $Ids | Where-Object { $CompleteNow -and ($_ -in $ProgressEx.Keys) } | ForEach-Object {
                    Write-Progress -Completed -Activity '.' -id $_
                    $ProgressEx[$_].Completed = $true
                    $ProgressEx[$_].Stopwatch = $null
                    Write-EndMessage $_
                    $ProgressEx.Remove($_)
                }

                # Find children. $tmp used to avoid undefined behavior with $Ids inside and outside the pipe. Let me know if $tmp is not needed.
                $tmp = $ProgressEx.Keys | Where-Object { $ProgressEx[$_].ParentId -in $Ids }
                $Ids = $tmp

                # Complete children anyway
                $CompleteNow = $true
            }
        }

        if ( $Info.id -ne $null ) {
            $ProgressEx[$Info.Id] = $Info

            if ( -not $Info.Completed ) {
                Write-ProgressStd $Info
            }

            Complete-ProgressAndChilren $Info.id -CompleteNow $Info.Completed
        }
    }
}

function Write-ProgressEx {
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
    [cmdletbinding()]
    param(
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
        [switch]$Completed,

        # Extended parameters
        [Parameter(ValueFromPipeline = $true)]
        [object]$inputObject,

        [ValidateRange(-1, [int]::MaxValue)]
        [int]$total, # total iterations
        [ValidateRange(0, [int]::MaxValue)]
        [int]$current, # current iteration number
        [ValidateRange(0, [int]::MaxValue)]
        [int]$iterations, # number of executed iterations. It may be not equal to $current because of skip some iterations

        [switch]$increment,
        [System.Diagnostics.Stopwatch]$stopwatch,

        [string[]]$BeginMessage,
        [string[]]$EndMessage # = '$($pInfo.Id):$($pInfo.Activity) done. Iterations=$($pInfo.Iterations), Elapsed time=$($pInfo.stopwatch.Elapsed)'
    )

    process {
        $pInfo = Get-ProgressEx $id -Force

        if ( $ParentId ) {
            $pInfo.ParentId = $ParentId
        }

        if ( $SourceId ) {
            $pInfo.SourceId = $SourceId
        }

        if ( $BeginMessage ) {
            $pInfo.BeginMessage = $BeginMessage
        }

        if ( $EndMessage ) {
            $pInfo.EndMessage = $EndMessage
        }

        if ( $total ) {
            $pInfo.Total = $total

            if ( -not $Increment -and -not $inputObject ) {
                $pInfo.PercentComplete = 0
                $pInfo.Current = 0

                if ( $BeginMessage ) {
                    $Message = -join $BeginMessage #TODO How to format apostrophe string?
                    Write-Output $Message
                }
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

        if ( $iterations ) {
            $pInfo.Iterations = $iterations
        }

        if ( $Current ) {
            $pInfo.Current = [Math]::Max(-1, [Math]::Min($Current, $pInfo.Total))
            $pInfo.stopwatch = $null
        }

        if ( $Increment -or $inputObject ) {
            # next
            $pInfo.Iterations += 1
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
            $pInfo.stopwatch = $null
        }
        elseif ( $isCalcPossible -and $pInfo.stopwatch  ) {
            $stopwatch = [System.Diagnostics.Stopwatch]$pInfo.stopwatch
            $pInfo.SecondsRemaining = [Math]::Max(0, 1 + $stopwatch.Elapsed.TotalSeconds * ($pInfo.Total - $pInfo.Current) / $pInfo.Current)
        }

        if ( $stopwatch ) {
            $pInfo.stopwatch = $stopwatch
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

    end {
        if ( $MyInvocation.PipelineLength -gt 1 ) {
            $pInfo = Get-ProgressEx -Id $id -Force
            $pInfo.Completed = $true
            Set-ProgressEx $pInfo
        }
    }
}

Export-ModuleMember `
    -Cmdlet 'Write-ProgressEx', 'Get-ProgressEx', 'Set-ProgressEx' `
    -Function 'Write-ProgressEx', 'Get-ProgressEx', 'Set-ProgressEx'