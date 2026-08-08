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

$abortOk = Get-ShutdownFlowTransition -CompletedAction Abort -ExitCode 0 -IsReplacement $true -RequestedSeconds 900
Assert-Equal 'Schedule' $abortOk.Decision 'Abort exit 0 in a replacement chains to Schedule'
Assert-Equal 900 $abortOk.Seconds 'The requested seconds are carried into the next schedule'
Assert-Equal $true $abortOk.IsBusy 'The UI stays busy after a successful abort'
Assert-Equal 'InProgress' $abortOk.Outcome 'No success is reported before the schedule completes'

$abortEmpty = Get-ShutdownFlowTransition -CompletedAction Abort -ExitCode 1116 -IsReplacement $true -RequestedSeconds 900
Assert-Equal 'Schedule' $abortEmpty.Decision 'Abort exit 1116 (no pending schedule) still chains to Schedule'
Assert-Equal $true $abortEmpty.IsBusy 'The UI stays busy after abort exit 1116'
Assert-Equal 900 $abortEmpty.Seconds 'Abort exit 1116 also carries the requested seconds'

$abortFail = Get-ShutdownFlowTransition -CompletedAction Abort -ExitCode 5 -IsReplacement $true -RequestedSeconds 900
Assert-Equal 'Fail' $abortFail.Decision 'A failing abort does not chain to Schedule'
Assert-Equal $false $abortFail.IsBusy 'A failing abort ends the busy state'
Assert-Equal 'Failed' $abortFail.Outcome 'A failing abort ends with an error outcome'

$scheduleOk = Get-ShutdownFlowTransition -CompletedAction Schedule -ExitCode 0 -IsReplacement $false -RequestedSeconds 900
Assert-Equal 'Complete' $scheduleOk.Decision 'A successful schedule completes the flow'
Assert-Equal $false $scheduleOk.IsBusy 'A successful schedule unlocks the UI'
Assert-Equal 'Succeeded' $scheduleOk.Outcome 'Success is only reported after the schedule exits 0'

$scheduleFail = Get-ShutdownFlowTransition -CompletedAction Schedule -ExitCode 5 -IsReplacement $false -RequestedSeconds 900
Assert-Equal 'Fail' $scheduleFail.Decision 'A failing schedule ends the flow with failure'
Assert-Equal $false $scheduleFail.IsBusy 'A failing schedule unlocks the UI'
Assert-Equal 'Failed' $scheduleFail.Outcome 'A failing schedule is never reported as success'

foreach ($code in 0, 1116, 87) {
    $standalone = Get-ShutdownFlowTransition -CompletedAction Abort -ExitCode $code -IsReplacement $false -RequestedSeconds 900
    Assert-Equal 'Complete' $standalone.Decision "A standalone cancel (exit $code) completes the flow without chaining to Schedule"
    Assert-Equal $false $standalone.IsBusy 'A standalone cancel ends the busy state'
}

Write-Host "PASS: $script:TestCount assertions completed."
