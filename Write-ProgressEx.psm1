# mazzy@mazzy.ru, 2017-10-10
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
            return $pInfo.Clone()
        }

        if ( $Force ) {
            return @{Id = $id}
        }

        $null
    }
}

function Write-ProgressExMessage {
    <#
    .SYNOPSIS
    Write a message to output.

    .PARAMETER pInfo
    The progress info returned by Get-ProgressEx

    .PARAMETER Message
    The message

    .NOTES
    This function is not exported
    #>
    [cmdletbinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$pInfo,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
        [string]$Message
    )

    process {
        if ( $pInfo.ShowMessages -and $Message ) {
            # message may use all variable values in all scope
            $Message = Invoke-Expression $Message -ErrorAction SilentlyContinue

            if ( $Message ) {
                Write-Host $Message
            }
        }
    }
}

function Write-ProgressExStd {
    <#
    .SYNOPSIS
    Show standard Progress bar by $id or $pInfo

    .PARAMETER pInfo
    The progress info returned by Get-ProgressEx

    .NOTES
    This function is not exported
    #>
    [cmdletbinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$pInfo
    )

    process {
        if ( -not $pInfo.NoShowProgressBar -and $pInfo ) {
            # Invoke standard write-progress cmdlet
            $pArgs = @{}
            $pInfo.Keys | Where-Object { $_ -in $StdParmNames } | ForEach-Object { $pArgs[$_] = $pInfo[$_] }

            if ( $pInfo.Total ) {
                $pArgs.Activity = ($pArgs.Activity, ($pInfo.Current, $pInfo.Total -join '/') -join ': ')
            }
            elseif ($pInfo.Current) {
                $pArgs.Activity = ($pArgs.Activity, $pInfo.Current -join ': ')
            }

            # Activity is mandatory parameter for standard Write-Progress
            if ( -not $pArgs.Activity ) {
                $pArgs.Activity = '.'
            }

            Write-Progress @pArgs
        }
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
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$pInfo
    )

    process {
        function Complete-ProgressAndChilren($Ids, $CompleteNow) {
            while ($Ids -ne $null) {
                # Complete
                $Ids | Where-Object { $CompleteNow -and ($_ -in $ProgressEx.Keys) } | ForEach-Object {

                    $ProgressEx[$_].Completed = $true

                    Write-ProgressExMessage $ProgressEx[$_] $ProgressEx[$_].MessageOnEnd
                    Write-ProgressExStd $ProgressEx[$_]

                    $ProgressEx[$_].Stopwatch = $null
                    $ProgressEx.Remove($_)
                }

                # Find children. $tmp used to avoid undefined behavior with $Ids inside and outside the pipe. Let me know if $tmp is not needed.
                $tmp = $ProgressEx.Keys | Where-Object { $ProgressEx[$_].ParentId -in $Ids }
                $Ids = $tmp

                # Complete children anyway
                $CompleteNow = $true
            }
        }

        if ( $pInfo ) {

            # events & messages
            if ( -not $ProgressEx[$pInfo.Id].Stopwatch ) {
                if( -not $pInfo.Stopwatch ) {
                    $pInfo.stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                }
                Write-ProgressExMessage $pInfo $pInfo.MessageOnBegin
            }
            elseif ( $pInfo.Activity -ne $ProgressEx[$pInfo.Id].Activity ) {
                Write-ProgressExMessage $pInfo $pInfo.MessageOnNewActivity
            }
            elseif ( $pInfo.Status -ne $ProgressEx[$pInfo.Id].Status ) {
                Write-ProgressExMessage $pInfo $pInfo.MessageOnNewStatus
            }

            $ProgressEx[$pInfo.Id] = $pInfo

            if ( -not $pInfo.Completed ) {
                Write-ProgressExStd $pInfo
            }

            Complete-ProgressAndChilren $pInfo.id -CompleteNow $pInfo.Completed

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

        $total, # total iterations. [int] or [object[]]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$current, # current iteration number. It may be greather then $total.

        [switch]$increment,
        [System.Diagnostics.Stopwatch]$stopwatch,

        # The Сmdlet does not call a standard write-progress cmdlet. Thus the progress bar does not show.
        [switch]$NoProgressBar,

        # The cmdlet output no messages
        [switch]$ShowMessages,

        # Message templates
        [string]$MessageOnBegin = '"[$(Get-Date )] $($pInfo.Id):$($pInfo.Activity):$($pInfo.Status): start."',
        [string]$MessageOnNewActivity = '"[$(Get-Date )] $($pInfo.Id):$($pInfo.Activity):$($pInfo.Status):"',
        [string]$MessageOnNewStatus = '"[$(Get-Date )] $($pInfo.Id):$($pInfo.Activity):$($pInfo.Status):"',
        [string]$MessageOnEnd = '"[$(Get-Date )] $($pInfo.Id):$($pInfo.Activity):$($pInfo.Status): done. Iterations=$($pInfo.Current), Elapsed=$($pInfo.stopwatch.Elapsed)"'
    )

    process {
        $pInfo = Get-ProgressEx $id -Force

        if ( $ParentId ) {
            $pInfo.ParentId = $ParentId
        }

        if ( $total ) {
            if ( $total -is [object[]] ) {
                $pInfo.Total = $total.Count
            }
            else {
                $pInfo.Total = $total
            }

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
        }

        if ( $Current ) {
            $pInfo.Current = $Current
        }

        if ( $Increment -or $inputObject ) {
            # next
            $pInfo.Current = $pInfo.Current + 1
        }

        $isCalcPossible = ($pInfo.Total -gt 0) -and ($pInfo.Current -gt 0) -and ($pInfo.Current -le $pInfo.Total)

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
            $pInfo.SecondsRemaining = [Math]::Max(0, 1 + $pInfo.stopwatch.Elapsed.TotalSeconds * [Math]::Max(0, $pInfo.Total - $pInfo.Current) / $pInfo.Current)
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

        if ( $SourceId ) {
            $pInfo.SourceId = $SourceId
        }

        if ( $ShowMessages ) {
            $pInfo.ShowMessages = $ShowMessages
        }

        if ( $NoProgressBar ) {
            $pInfo.NoProgressBar = $NoProgressBar
        }

        if ( $Activity ) {
            $pInfo.Activity = $Activity
        }

        if ( $Completed -or -not $PSBoundParameters.Count  ) {
            $pInfo.Completed = $true
        }

        $pInfo.MessageOnBegin = $MessageOnBegin
        $pInfo.MessageOnNewActivity = $MessageOnNewActivity
        $pInfo.MessageOnNewStatus = $MessageOnNewStatus
        $pInfo.MessageOnEnd = $MessageOnEnd

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
