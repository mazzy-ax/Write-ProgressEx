# mazzy@mazzy.ru, 2018-05-13
# https://github.com/mazzy-ax/Write-ProgressEx

#region Module variables

$ProgressEx = @{}

$ProgressExDefault = @{
    MessageOnFirstIteration = {param([hashtable]$pInfo) Write-Warning "[$(Get-Date)] Id=$($pInfo.Id):$($pInfo.Activity):$($pInfo.Status): start."}
    MessageOnNewActivity    = {param([hashtable]$pInfo) Write-Warning "[$(Get-Date)] Id=$($pInfo.Id):$($pInfo.Activity):$($pInfo.Status):"}
    MessageOnNewStatus      = {param([hashtable]$pInfo) Write-Warning "[$(Get-Date)] Id=$($pInfo.Id):$($pInfo.Activity):$($pInfo.Status):"}
    MessageOnCompleted      = {param([hashtable]$pInfo) Write-Warning "[$(Get-Date)] Id=$($pInfo.Id):$($pInfo.Activity):$($pInfo.Status): done. Iterations=$($pInfo.Current), Elapsed=$($pInfo.Elapsed))"}
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
            $pInfo.Clone()
        }
        elseif ( $Force ) {
            @{
                Id             = $id
                Reset          = $true
                UpdateInterval = [TimeSpan]::FromMilliseconds(100)
            }
        }
        else {
            $null
        }
    }
}

function nz ($a, $b) {
    if ($a) { $a } else { $b }
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

        [scriptblock[]]$Message,
        [switch]$ShowMessagesOnFirstIteration,
        [switch]$ShowMessagesOnNewActivity,
        [switch]$ShowMessagesOnNewStatus,
        [switch]$ShowMessagesOnCompleted
    )

    process {
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
        $Message | Where-Object { $_ } | ForEach-Object {
            Invoke-Command -ScriptBlock $_ -ArgumentList $pInfo -ErrorAction SilentlyContinue
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

        Write-ProgressExMessage $pInfo `
            -ShowMessagesOnFirstIteration:($pInfo.Reset) `
            -ShowMessagesOnNewActivity:($pInfo.Activity -ne $ProgressEx[$pInfo.Id].Activity) `
            -ShowMessagesOnNewStatus:($pInfo.Status -ne $ProgressEx[$pInfo.Id].Status) `
            -ShowMessagesOnCompleted:($pInfo.Completed)

        $shouldShowProgressBar = switch ( $pInfo.ShowProgressBar ) {
            'None' { $false }
            'Force' { $true }
            Default {
                try {
                    $pInfo.Completed -or
                    $pInfo.UpdateInterval -le (New-TimeSpan -End $pInfo.ProgressDateTime -Start $pInfo.UpdateDateTime)
                }
                catch {
                    $true
                }
            }
        }

        # Invoke standard write-progress cmdlet
        if ( $shouldShowProgressBar ) {
            $pArgs = @{}
            $pInfo.Keys | Where-Object { $StdParmNames -contains $_ } | ForEach-Object {
                $pArgs[$_] = $pInfo[$_]
            }

            # Decorate activity
            if ( $pInfo.Total ) {
                $pArgs.Activity = $pArgs.Activity, ($pInfo.Current, $pInfo.Total -join '/') -join ': '
            }
            elseif ( $pInfo.Current ) {
                $pArgs.Activity = $pArgs.Activity, $pInfo.Current -join ': '
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
        $childrenIds = $ProgressEx.values | Where-Object { $_.ParentId -eq $pInfo.Id } | ForEach-Object { $_.Id }
        $childrenIds | Get-ProgressEx | Set-ProgressEx -Completed
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

        [switch]$Reset,
        [switch]$Increment,

        [DateTime]$ProgressDateTime,
        [DateTime]$StartDateTime,
        [TimeSpan]$Elapsed,

        [DateTime]$UpdateDateTime,
        [TimeSpan]$UpdateInterval,

        [ValidateSet('Auto', 'Force', 'None')] # Different first letters make typing fast
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
        $isPipe = $inputObject -and ($MyInvocation.PipelineLength -gt 1)

        if ( $isPipe -or $PSBoundParameters.Count ) {
            $pInfo = Get-ProgressEx $id -Force

            $PSBoundParameters.Keys | ForEach-Object {
                $pInfo[$_] = $PSBoundParameters[$_]
            }

            if ( -not $ProgressDateTime ) {
                $pInfo.ProgressDateTime = Get-Date
            }

            # auto parentId
            if ( $pInfo.Reset -and $pInfo.Keys -notcontains 'ParentId' ) {
                $ParentProbe = $ProgressEx.Keys | Where-Object { $_ -lt $pInfo.id } | Measure-Object -Maximum
                if ( $null -ne $ParentProbe.Maximum ) {
                    $pInfo.ParentId = $ParentProbe.Maximum
                }
            }

            if ( $pInfo.Reset -and -not $Current ) {
                $pInfo.Current = 0
            }

            if ( $pInfo.Reset -and -not $StartDateTime ) {
                $pInfo.StartDateTime = $pInfo.ProgressDateTime
            }

            if ( -not $Elapsed -and $pInfo.StartDateTime ) {
                $pInfo.Elapsed = New-TimeSpan -End $pInfo.ProgressDateTime -Start $pInfo.StartDateTime
            }

            $pInfo.Increment = $Increment -or $isPipe
            if ( $pInfo.Increment ) {
                $pInfo.Current += 1
            }

            if ( $pInfo.Total -and $pInfo.Current ) {
                if ( -not $PercentComplete ) {
                    [int]$pInfo.PercentComplete = [Math]::Min([Math]::Max(0, $pInfo.Current / $pInfo.Total * 100), 100)
                }

                if ( -not $SecondsRemaining -and $pInfo.Elapsed ) {
                    [int]$pInfo.SecondsRemaining = [Math]::Max(0, $pInfo.Elapsed.TotalSeconds * ($pInfo.Total - $pInfo.Current) / $pInfo.Current)
                }
            }

            # autoname it. The caller function name used as activity
            if ( -not $pInfo.Activity ) {
                $pInfo.Activity = (Get-PSCallStack)[1].InvocationInfo.MyCommand.Name
            }

            Set-ProgressEx $pInfo
        }
        else {
            # Complete all if it is No parameters and Not pipe.
            $ProgressEx.Clone().values | Set-ProgressEx -Completed
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
