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

function Test-ShutdownScheduleReplacement {
    param(
        [Parameter(Mandatory = $true)] [int] $AbortExitCode
    )

    return ($AbortExitCode -eq 0 -or $AbortExitCode -eq 1116)
}

function Test-ShutdownScheduleAccepted {
    param(
        [Parameter(Mandatory = $true)] [int] $ExitCode
    )

    return ($ExitCode -eq 0)
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

Export-ModuleMember -Function ConvertTo-ShutdownSeconds, New-ShutdownArguments, Start-ShutdownCommand, Test-ShutdownScheduleReplacement, Test-ShutdownScheduleAccepted
