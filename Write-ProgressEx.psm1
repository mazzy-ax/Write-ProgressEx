# mazzy@mazzy.ru, 2017-10-21
# https://github.com/mazzy-ax/Write-ProgressEx

#requires -version 3.0

#region Module Variables

$ProgressEx = @{}

$ProgressExDefault = @{
    MessageOnFirstIteration = {param([hashtable]$pInfo) Write-Warning "[$(Get-Date )] $($pInfo.Id):$($pInfo.Activity):$($pInfo.Status): start."}
    MessageOnNewActivity    = {param([hashtable]$pInfo) Write-Warning "[$(Get-Date )] $($pInfo.Id):$($pInfo.Activity):$($pInfo.Status):"}
    MessageOnNewStatus      = {param([hashtable]$pInfo) Write-Warning "[$(Get-Date )] $($pInfo.Id):$($pInfo.Activity):$($pInfo.Status):"}
    MessageOnCompleted      = {param([hashtable]$pInfo) Write-Warning "[$(Get-Date )] $($pInfo.Id):$($pInfo.Activity):$($pInfo.Status): done. Iterations=$($pInfo.Current), Elapsed=$($pInfo.stopwatch.Elapsed)"}
}

$StdParmNames = (Get-Command Write-Progress).Parameters.Keys

#endregion Module Variables

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
    [cmdletbinding(DefaultParameterSetName = 'Message')]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$pInfo,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Message')]
        [scriptblock]$Message,

        [Parameter(ParameterSetName = 'OnFirstIteration')]
        [switch]$ShowMessagesOnFirstIteration,

        [Parameter(ParameterSetName = 'OnNewActivity')]
        [switch]$ShowMessagesOnNewActivity,

        [Parameter(ParameterSetName = 'OnNewStatus')]
        [switch]$ShowMessagesOnNewStatus,

        [Parameter(ParameterSetName = 'OnCompleted')]
        [switch]$ShowMessagesOnCompleted
    )

    process {
        function nz ($a, $b) {
            if ($a) { $a } else { $b }
        }

        if ( $ShowMessagesOnFirstIteration -and $pInfo.ShowMessagesOnFirstIteration ) {
            $Message = nz $pInfo.MessageOnFirstIteration $ProgressExDefault.MessageOnFirstIteration
        }
        elseif ( $ShowMessagesOnNewActivity -and $pInfo.ShowMessagesOnNewActivity ) {
            $Message = nz $pInfo.MessageOnNewActivity $ProgressExDefault.MessageOnNewActivity
        }
        elseif ( $ShowMessagesOnNewStatus -and $pInfo.ShowMessagesOnNewStatus ) {
            $Message = nz $pInfo.MessageOnNewStatus $ProgressExDefault.MessageOnNewStatus
        }
        elseif ( $ShowMessagesOnCompleted -and $pInfo.ShowMessagesOnCompleted ) {
            $Message = nz $pInfo.MessageOnCompleted $ProgressExDefault.MessageOnCompleted
        }

        # message may use all variable values in all scope
        if ( $Message ) {
            Invoke-Command -ScriptBlock $Message -ArgumentList $pInfo -ErrorAction SilentlyContinue
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

                    Write-ProgressExMessage $ProgressEx[$_] -ShowMessagesOnCompleted
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
            if ( -not $pInfo.Completed ) {
                # events & messages
                if ( -not $ProgressEx[$pInfo.Id].Stopwatch ) {
                    if ( -not $pInfo.Stopwatch ) {
                        $pInfo.stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    }
                    Write-ProgressExMessage $pInfo -ShowMessagesOnFirstIteration
                }
                elseif ( $pInfo.Activity -ne $ProgressEx[$pInfo.Id].Activity ) {
                    Write-ProgressExMessage $pInfo -ShowMessagesOnNewActivity
                }
                elseif ( $pInfo.Status -ne $ProgressEx[$pInfo.Id].Status ) {
                    Write-ProgressExMessage $pInfo -ShowMessagesOnNewStatus
                }

                Write-ProgressExStd $pInfo
            }

            $ProgressEx[$pInfo.Id] = $pInfo
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
            Write-ProgressEx -id 1 -Increment
        }
        Write-ProgressEx -Increment
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
        [object]$InputObject,

        [ValidateRange(0, [int]::MaxValue)]
        [int]$Total,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Current, # current iteration number. It may be greather then $total.

        [switch]$Increment,
        [System.Diagnostics.Stopwatch]$Stopwatch,

        # The Сmdlet does not call a standard write-progress cmdlet. Thus the progress bar does not show.
        [switch]$NoProgressBar,

        # Message templates
        [scriptblock]$MessageOnFirstIteration,
        [scriptblock]$MessageOnNewActivity,
        [scriptblock]$MessageOnNewStatus,
        [scriptblock]$MessageOnCompleted,

        # The cmdlet output no messages
        [switch]$ShowMessages,
        [switch]$ShowMessagesOnFirstIteration = $ShowMessages -or $MessageOnFirstIteration,
        [switch]$ShowMessagesOnNewActivity = $ShowMessages -or $MessageOnNewActivity,
        [switch]$ShowMessagesOnNewStatus = $ShowMessages -or $MessageOnNewStatus,
        [switch]$ShowMessagesOnCompleted = $ShowMessages -or $MessageOnCompleted
    )

    process {
        $pInfo = Get-ProgressEx $id -Force

        if ( $ParentId ) {
            $pInfo.ParentId = $ParentId
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

        if ( $Completed -or -not ($PSBoundParameters.Count -or ($MyInvocation.PipelineLength -gt 1)) ) {
            $pInfo.Completed = $true
        }

        if ( $Activity ) {
            $pInfo.Activity = $Activity
        }

        if ( -not $pInfo.Activity ) {
            $pInfo.Activity = (Get-PSCallStack)[1].InvocationInfo.MyCommand.Name
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

        if ( $NoProgressBar ) {
            $pInfo.NoProgressBar = $NoProgressBar
        }

        if ( $ShowMessagesOnFirstIteration ) {
            $pInfo.ShowMessagesOnFirstIteration = $ShowMessagesOnFirstIteration
        }

        if ( $ShowMessagesOnNewActivity ) {
            $pInfo.ShowMessagesOnNewActivity = $ShowMessagesOnNewActivity
        }

        if ( $ShowMessagesOnNewStatus ) {
            $pInfo.ShowMessagesOnNewStatus = $ShowMessagesOnNewStatus
        }

        if ( $ShowMessagesOnCompleted ) {
            $pInfo.ShowMessagesOnCompleted = $ShowMessagesOnCompleted
        }

        if ( $MessageOnFirstIteration ) {
            $pInfo.MessageOnFirstIteration = $MessageOnFirstIteration
        }

        if ( $MessageOnNewActivity ) {
            $pInfo.MessageOnNewActivity = $MessageOnNewActivity
        }

        if ( $MessageOnNewStatus ) {
            $pInfo.MessageOnNewStatus = $MessageOnNewStatus
        }

        if ( $MessageOnCompleted ) {
            $pInfo.MessageOnCompleted = $MessageOnCompleted
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
