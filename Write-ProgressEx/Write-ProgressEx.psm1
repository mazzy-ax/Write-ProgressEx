# mazzy@mazzy.ru, 2019-04-06
# https://github.com/mazzy-ax/Write-ProgressEx

#region Module variables

$ProgressEx = @{ }

$ProgressExDefault = @{
    MessageOnFirstIteration = { param([hashtable]$pInfo) Write-Warning "[$(Get-Date)] Id=$($pInfo.Id):$($pInfo.Activity):$($pInfo.Status): start." }
    MessageOnNewActivity    = { param([hashtable]$pInfo) Write-Warning "[$(Get-Date)] Id=$($pInfo.Id):$($pInfo.Activity):$($pInfo.Status):" }
    MessageOnNewStatus      = { param([hashtable]$pInfo) Write-Warning "[$(Get-Date)] Id=$($pInfo.Id):$($pInfo.Activity):$($pInfo.Status):" }
    MessageOnCompleted      = { param([hashtable]$pInfo) Write-Warning "[$(Get-Date)] Id=$($pInfo.Id):$($pInfo.Activity):$($pInfo.Status): done. Iterations=$($pInfo.Current), Elapsed=$($pInfo.Elapsed))" }
    UpdateIntervalMin       = [timespan]::FromMilliseconds(200)
    UpdateIntervalMax       = [timespan]::FromSeconds(1)
    UpdateUntervalThreshold = [timespan]::FromMinutes(1)
}

$StdParmNames = (Get-Command Write-Progress).Parameters.Keys

#endregion

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
    Write-ProgressEx 'wait, please' -Total $range.Count
    $range | Write-ProgressEx | ForEach-Object {
        $pInfo = Get-ProgressEx

        if ( $pInfo.SecondsRemaining -lt 5 ) {
            $pInfo['Activity'] = 'just a few seconds'
            Write-ProgressEx @pInfo  # <-------
        }
    }
    The splatting to Write-ProgressEx is a common pattern to use progress info:
    It's recalculate parameters and refresh progress on the console.

    #>
    [cmdletbinding(DefaultParameterSetName='Id')]
    [OutputType([hashtable])]
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Id')]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Id,

        [Parameter(ValueFromPipeline = $true, Position = 0, ParameterSetName = 'ProgressInfo')]
        [hashtable]$pInfo,

        [switch]$Force
    )

    process {
        if( $pInfo ) {
            $Id = $pInfo.Id
        }

        $pInfo = $ProgressEx[$Id]

        if ( $pInfo -is [hashtable] ) {
            $pInfo.Clone()
        }
        elseif ( $Force ) {
            @{
                Id    = $id
                Reset = $true
            }
        }
        else {
            $null
        }
    }
}

function Set-ProgressEx {
    <#
    .SYNOPSIS
    Set parameters for the progress with Id and dispaly this values to the console.

    .DESCRIPTION
    The cmdlet performs a technical work based on user parameters in the pInfo:

    * save parameters to global structure
    * display this parameters to console via standard Write-Progress
    * show event messages
    * decorate activity with iteration info
    * complete progress if Completed parameter is $true
    * complete all children progresses always
    * and so on

    .EXAMPLE
    $range = 1..1000
    Write-ProgressEx 'wait, please' -Total $range.Count
    $range | Write-ProgressEx | ForEach-Object {
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
    [cmdletbinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$pInfo,

        [switch]$Completed
    )

    process {
        if ( -not $pInfo ) {
            $pInfo = Get-ProgressEx -Force
        }

        if ( $Completed ) {
            $pInfo.Completed = $true
        }

        #region message
        if ( $pInfo.ShowMessagesOnFirstIteration -and $pInfo.Reset ) {
            $Message = if ( $pInfo.MessageOnFirstIteration ) {
                $pInfo.MessageOnFirstIteration
            }
            else {
                $ProgressExDefault.MessageOnFirstIteration
            }
        }
        elseif ( $pInfo.ShowMessagesOnNewActivity -and $pInfo.Activity -ne $ProgressEx[$pInfo.Id].Activity ) {
            $Message = if ( $pInfo.MessageOnNewActivity ) {
                $pInfo.MessageOnNewActivity
            }
            else {
                $ProgressExDefault.MessageOnNewActivity
            }
        }
        elseif ( $pInfo.ShowMessagesOnNewStatus -and $pInfo.Status -ne $ProgressEx[$pInfo.Id].Status ) {
            $Message = if ( $pInfo.MessageOnNewStatus ) {
                $pInfo.MessageOnNewStatus
            }
            else {
                $ProgressExDefault.MessageOnNewStatus
            }
        }
        elseif ( $pInfo.ShowMessagesOnCompleted -and $pInfo.Completed ) {
            $Message = if ( $pInfo.MessageOnCompleted ) {
                $pInfo.MessageOnCompleted
            }
            else {
                $ProgressExDefault.MessageOnCompleted
            }
        }

        # message may use all variable values in all scope
        foreach ($m in $Message) {
            Invoke-Command -ScriptBlock $m -ArgumentList $pInfo -ErrorAction SilentlyContinue
        }
        #endregion message

        $shouldShowProgressBar = $pInfo.Reset -or $pInfo.Completed -or $(
            switch ( $pInfo.ShowProgressBar ) {
                'Force' { $True }
                'None' { $False }
                Default {
                    try {
                        $updateInterval = if ( $pinfo.UpdateInterval -is [timespan] ) {
                            $pinfo.UpdateInterval
                        }
                        elseif ( $pinfo.Remaining -is [timespan] ) {
                            if ( $pinfo.Remaining -le $ProgressExDefault.UpdateIntervalTreshold ) {
                                $ProgressExDefault.UpdateIntervalMin
                            }
                            else {
                                $ProgressExDefault.UpdateIntervalMax
                            }
                        }
                        else {
                            0
                        }

                        $updateInterval -and $updateInterval -le (New-TimeSpan -Start $pInfo.UpdateDateTime -End $pInfo.ProgressDateTime)
                    }
                    catch {
                        $True
                    }
                }
            }
        )

        # Invoke standard write-progress cmdlet
        if ( $shouldShowProgressBar ) {
            $pArgs = @{ }
            $pInfo.Keys | Where-Object { $StdParmNames -contains $_ } | ForEach-Object {
                $pArgs[$_] = $pInfo[$_]
            }

            # Decorate activity
            if ( $pInfo.Total ) {
                $pArgs.Activity = '{0}/{1}: {2}' -f $pInfo.Current, $pInfo.Total, $pArgs.Activity
            }
            elseif ( $pInfo.Current ) {
                $pArgs.Activity = '{0}: {1}' -f $pInfo.Current, $pArgs.Activity
            }

            if ( $pInfo.ShowElapsed -and $pInfo.Elapsed -as [TimeSpan] ) {
                $ElapsedSeconds = [TimeSpan]::FromSeconds([int]($pInfo.Elapsed.Ticks / [TimeSpan]::TicksPerSecond))
                if ( $ElapsedSeconds.TotalSeconds ) {
                    $pArgs.Activity = '{0}: {1} elapsed ({2:N} ips).' -f $pArgs.Activity, $ElapsedSeconds, ($pInfo.Current / $ElapsedSeconds.TotalSeconds)
                }
                else {
                    $pArgs.Activity = '{0}: {1} elapsed.' -f $pArgs.Activity, $ElapsedSeconds
                }
            }

            if ( $pInfo.showConsoleTitle ) {
                $host.ui.RawUI.WindowTitle = if ( $pInfo.Completed ) { "" } else { $pArgs.Activity }
            }

            # Activity is mandatory parameter for standard Write-Progress
            if ( -not $pArgs.Activity ) {
                $pArgs.Activity = '.'
            }

            Write-Progress @pArgs

            $pInfo.UpdateDateTime = $pInfo.ProgressDateTime
        }

        if ( $pInfo.Completed ) {
            $ProgressEx.Remove($pInfo.Id)
        }
        else {
            $pInfo.Reset = $false
            $ProgressEx[$pInfo.Id] = $pInfo
        }

        # Recursive complete own children
        $child = $ProgressEx.Values | Where-Object { $pInfo.Id -eq $_.ParentId -and $pInfo.Id -ne $_.Id }
        $child | Get-ProgressEx | Set-ProgressEx -Completed
    }
}

function Write-ProgressEx {
    <#
    .SYNOPSIS
    Powershell Extended Write-Progress cmdlet.

    .DESCRIPTION
    The cmdlet Write-ProgressEx contains a 'business-logic':

    * PercentComplete, SecondsRemaining calculation and other calculations,
    * increment and autoincrement for a Current,
    * autoname an activity string
    * smart parentId search,
    * and so on

    This cmdlet calls Set-ProgressEx to perform technical work and to call a standard Write-Progress.

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

    .NOTES
    Commands 'Write-ProgressEx.ps1' and 'Write-ProgressEx -Complete' are equivalents.
    The cmdlet complete all children progresses.

    .NOTES
    A developer can use a parameter splatting.
    See Get-ProgressEx example.

    .NOTES
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
        [int]$ParentId = -1,
        [int]$SourceId,
        [switch]$Completed,

        # Extended parameters
        [Parameter(ValueFromPipeline = $true)]
        [object]$InputObject,

        [ValidateRange(0, [int]::MaxValue)]
        [int]$Total,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Current, # current iteration number. It may be greather then $total.

        [switch]$Reset,
        [switch]$Increment,

        [DateTime]$ProgressDateTime,
        [Alias('Started')]
        [DateTime]$StartDateTime,

        [TimeSpan]$Elapsed,
        [TimeSpan]$Remaining,

        [Alias('Updated')]
        [DateTime]$UpdateDateTime,
        [TimeSpan]$UpdateInterval,

        [switch]$ShowConsoleTitle,
        [switch]$ShowElapsed,

        [ValidateSet('Auto', 'Force', 'None')]
        [string]$ShowProgressBar,

        # Message templates
        [scriptblock[]]$MessageOnFirstIteration,
        [scriptblock[]]$MessageOnNewActivity,
        [scriptblock[]]$MessageOnNewStatus,
        [scriptblock[]]$MessageOnCompleted,

        # The cmdlet output no messages
        [switch]$ShowMessages,
        [switch]$ShowMessagesOnFirstIteration = $ShowMessages -or $MessageOnFirstIteration,
        [switch]$ShowMessagesOnNewActivity = $ShowMessages -or $MessageOnNewActivity,
        [switch]$ShowMessagesOnNewStatus = $ShowMessages -or $MessageOnNewStatus,
        [switch]$ShowMessagesOnCompleted = $ShowMessages -or $MessageOnCompleted
    )

    process {
        $isPipe = ($null -ne $inputObject) -and ($MyInvocation.PipelineLength -gt 1)

        if ( $isPipe -or $PSBoundParameters.Count ) {
            $pInfo = Get-ProgressEx $id -Force

            $PSBoundParameters.Keys | ForEach-Object {
                $pInfo[$_] = $PSBoundParameters[$_]
            }

            if ( -not $ProgressDateTime ) {
                $pInfo.ProgressDateTime = Get-Date
            }

            if ( $pInfo.Reset -and -not $StartDateTime ) {
                $pInfo.StartDateTime = $pInfo.ProgressDateTime
            }

            if ( $pInfo.Reset -and $pInfo.Id -gt 0 -and $PSBoundParameters.Keys -notcontains 'ParentId' ) {
                # auto parentId
                $parentIdFounded = $ProgressEx.Keys | Where-Object { $pInfo.Id -gt $_ } | Sort-Object -Descending | Select-Object -First 1
                if( $null -ne $parentIdFounded ) {
                    $pInfo.ParentId = $parentIdFounded
                }
            }

            if ( $pInfo.Reset -and -not $Current ) {
                $pInfo.Current = 0
            }

            $pInfo.Increment = $Increment -or $isPipe
            if ( $pInfo.Increment ) {
                $pInfo.Current += 1
            }

            if ( $Elapsed ) {
                $pInfo.Elapsed = $Elapsed
            }
            elseif ( $pInfo.StartDateTime ) {
                $pInfo.Elapsed = New-TimeSpan -End $pInfo.ProgressDateTime -Start $pInfo.StartDateTime
            }
            else {
                $pInfo.Remove('Elapsed')
            }

            if ( $PercentComplete ) {
                $pInfo.PercentComplete = $PercentComplete
            }
            elseif ( $pInfo.Total -and $pInfo.Current ) {
                $pInfo.PercentComplete = [Math]::Min([Math]::Max(0, [int]($pInfo.Current / $pInfo.Total * 100)), 100)
            }
            else {
                $pInfo.Remove('PercentComplete')
            }

            if ( $Remaining ) {
                $pInfo.Remaining = $Remaining
            }
            elseif ( $pInfo.Total -and $pInfo.Current -and $pInfo.Elapsed -as [TimeSpan] ) {
                $pInfo.Remaining = [TimeSpan]::FromTicks($pInfo.Elapsed.Ticks / $pInfo.Current * ($pInfo.Total - $pInfo.Current))
            }
            else {
                $pInfo.Remove('Remaining')
            }

            if ( $SecondsRemaining ) {
                $pInfo.SecondsRemaining = $SecondsRemaining
            }
            elseif ( $pInfo.Remaining -as [TimeSpan] ) {
                $pInfo.SecondsRemaining = [Math]::Max(0, $pInfo.Remaining.TotalSeconds)
            }
            else {
                $pInfo.Remove('SecondsRemaining')
            }

            # autoname it. The caller function name used as activity
            if ( -not $pInfo.Activity ) {
                $ActivityFound = (Get-PSCallStack).InvocationInfo.MyCommand.Name | Where-Object { $_ } | Select-Object -Skip 1 -First 1
                if( $ActivityFound ) {
                    $pInfo.Activity = $ActivityFound
                }
            }

            Set-ProgressEx $pInfo
        }
        else {
            # Complete all if it is No parameters and Not pipe.
            $ProgressEx.Clone().Values | Set-ProgressEx -Completed
        }

        # PassThru
        if ( $isPipe ) {
            $inputObject
        }
    }

    end {
        if ( $MyInvocation.PipelineLength -gt 1 ) {
            # Autocomplete itself and own children
            Get-ProgressEx -Id $id -Force | Set-ProgressEx -Completed
        }
    }
}
