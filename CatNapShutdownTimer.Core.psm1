Set-StrictMode -Version Latest

$script:MaximumShutdownSeconds = 604800

function ConvertTo-ShutdownSeconds {
    param(
        [Parameter(Mandatory = $true)] [decimal] $Amount,
        [Parameter(Mandatory = $true)] [ValidateSet('Minutes', 'Hours')] [string] $Unit
    )

    if ($Amount -le 0) {
        throw 'Thời gian phải lớn hơn 0.'
    }

    if ($Amount -ne [Math]::Truncate($Amount)) {
        throw 'Thời gian phải là số nguyên.'
    }

    $factor = if ($Unit -eq 'Hours') { 3600 } else { 60 }
    if ($Amount -gt ([decimal]$script:MaximumShutdownSeconds / $factor)) {
        throw 'Thời gian tối đa là 7 ngày.'
    }

    return [Int64]($Amount * $factor)
}

function New-ShutdownArguments {
    param(
        [Parameter(Mandatory = $true)] [Int64] $Seconds
    )

    if ($Seconds -lt 1 -or $Seconds -gt $script:MaximumShutdownSeconds) {
        throw 'Số giây hẹn giờ không hợp lệ.'
    }

    return ('/s /f /t {0} /d p:0:0 /c "Hen gio tat may"' -f $Seconds)
}

function Get-ShutdownFlowTransition {
    param(
        [Parameter(Mandatory = $true)] [ValidateSet('Schedule', 'Abort')] [string] $CompletedAction,
        [Parameter(Mandatory = $true)] [int] $ExitCode,
        [Parameter(Mandatory = $true)] [bool] $IsReplacement,
        [Parameter(Mandatory = $true)] [Int64] $RequestedSeconds
    )

    if ($CompletedAction -eq 'Abort' -and $IsReplacement) {
        if ($ExitCode -eq 0 -or $ExitCode -eq 1116) {
            return [PSCustomObject]@{
                Decision = 'Schedule'
                Seconds  = $RequestedSeconds
                IsBusy   = $true
                Outcome  = 'InProgress'
            }
        }
        return [PSCustomObject]@{
            Decision = 'Fail'
            Seconds  = 0
            IsBusy   = $false
            Outcome  = 'Failed'
        }
    }

    if ($CompletedAction -eq 'Schedule') {
        if ($ExitCode -eq 0) {
            return [PSCustomObject]@{
                Decision = 'Complete'
                Seconds  = 0
                IsBusy   = $false
                Outcome  = 'Succeeded'
            }
        }
        return [PSCustomObject]@{
            Decision = 'Fail'
            Seconds  = 0
            IsBusy   = $false
            Outcome  = 'Failed'
        }
    }

    if ($ExitCode -eq 0) {
        $outcome = 'Succeeded'
    }
    elseif ($ExitCode -eq 1116) {
        $outcome = 'Finished'
    }
    else {
        $outcome = 'Failed'
    }

    return [PSCustomObject]@{
        Decision = 'Complete'
        Seconds  = 0
        IsBusy   = $false
        Outcome  = $outcome
    }
}

function Invoke-ShutdownFlowTransition {
    param(
        [Parameter(Mandatory = $true)] [ValidateSet('Schedule', 'Abort')] [string] $CompletedAction,
        [Parameter(Mandatory = $true)] [int] $ExitCode,
        [Parameter(Mandatory = $true)] [bool] $IsReplacement,
        [Parameter(Mandatory = $true)] [Int64] $RequestedSeconds,
        [Parameter(Mandatory = $true)] [scriptblock] $SetBusy,
        [Parameter(Mandatory = $true)] [scriptblock] $StartSchedule,
        [Parameter(Mandatory = $true)] [scriptblock] $Complete
    )

    $transition = Get-ShutdownFlowTransition `
        -CompletedAction $CompletedAction `
        -ExitCode $ExitCode `
        -IsReplacement $IsReplacement `
        -RequestedSeconds $RequestedSeconds

    [void](& $SetBusy $transition.IsBusy)
    if ($transition.Decision -eq 'Schedule') {
        [void](& $StartSchedule $transition.Seconds)
    }
    else {
        [void](& $Complete $transition)
    }

    return $transition
}

function Get-ShutdownExecutablePath {
    $systemDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)
    $shutdownPath = Join-Path -Path $systemDirectory -ChildPath 'shutdown.exe'

    if (-not (Test-Path -LiteralPath $shutdownPath -PathType Leaf)) {
        throw 'Không tìm thấy shutdown.exe trong thư mục hệ thống Windows.'
    }

    return $shutdownPath
}

function Start-ShutdownCommand {
    param(
        [Parameter(Mandatory = $true)] [ValidateSet('Schedule', 'Abort')] [string] $Action,
        [Int64] $Seconds = 0
    )

    $arguments = if ($Action -eq 'Schedule') {
        New-ShutdownArguments -Seconds $Seconds
    }
    else {
        '/a'
    }

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = Get-ShutdownExecutablePath
    $startInfo.Arguments = $arguments
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo

    try {
        if (-not $process.Start()) {
            throw 'Không thể khởi chạy shutdown.exe.'
        }
        return $process
    }
    catch {
        $process.Dispose()
        throw
    }
}

Export-ModuleMember -Function ConvertTo-ShutdownSeconds, New-ShutdownArguments, Start-ShutdownCommand, Get-ShutdownFlowTransition, Invoke-ShutdownFlowTransition
