$ErrorActionPreference = 'Stop'

$script:TestCount = 0

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)] $Expected,
        [Parameter(Mandatory = $true)] $Actual,
        [Parameter(Mandatory = $true)] [string] $Name
    )

    $script:TestCount++
    if ($Expected -ne $Actual) {
        throw "FAIL: $Name. Expected [$Expected], got [$Actual]."
    }
    Write-Host "PASS: $Name"
}

function Assert-Throws {
    param(
        [Parameter(Mandatory = $true)] [scriptblock] $Action,
        [Parameter(Mandatory = $true)] [string] $Name
    )

    $script:TestCount++
    try {
        & $Action
    }
    catch {
        Write-Host "PASS: $Name"
        return
    }
    throw "FAIL: $Name. Expected an exception."
}

$projectRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $projectRoot 'CatNapShutdownTimer.Core.psm1') -Force

Assert-Equal 900 (ConvertTo-ShutdownSeconds -Amount 15 -Unit Minutes) '15 minutes becomes 900 seconds'
Assert-Equal 7200 (ConvertTo-ShutdownSeconds -Amount 2 -Unit Hours) '2 hours becomes 7200 seconds'
Assert-Equal 604800 (ConvertTo-ShutdownSeconds -Amount 168 -Unit Hours) 'Seven days is accepted'
Assert-Throws { ConvertTo-ShutdownSeconds -Amount 0 -Unit Minutes } 'Zero is rejected'
Assert-Throws { ConvertTo-ShutdownSeconds -Amount 1.5 -Unit Hours } 'Fractional input is rejected'
Assert-Throws { ConvertTo-ShutdownSeconds -Amount 169 -Unit Hours } 'More than seven days is rejected'
Assert-Equal '/s /f /t 900 /d p:0:0 /c "Hen gio tat may"' (New-ShutdownArguments -Seconds 900) 'Arguments only contain the validated delay'
Assert-Throws { New-ShutdownArguments -Seconds 0 } 'Zero seconds is rejected for a schedule'

Assert-Equal $true (Test-ShutdownScheduleReplacement -AbortExitCode 0) 'Abort exit code 0 allows creating a new schedule'
Assert-Equal $true (Test-ShutdownScheduleReplacement -AbortExitCode 1116) 'Abort exit code 1116 (no pending schedule) allows creating a new schedule'
Assert-Equal $false (Test-ShutdownScheduleReplacement -AbortExitCode 5) 'Other abort exit codes block creating a new schedule'
Assert-Equal $false (Test-ShutdownScheduleReplacement -AbortExitCode 87) 'Access-denied abort exit code blocks creating a new schedule'

Assert-Equal $true (Test-ShutdownScheduleAccepted -ExitCode 0) 'Schedule exit code 0 means the new schedule was created'
Assert-Equal $false (Test-ShutdownScheduleAccepted -ExitCode 5) 'A non-zero schedule exit code means creation failed'

Write-Host "PASS: $script:TestCount assertions completed."
