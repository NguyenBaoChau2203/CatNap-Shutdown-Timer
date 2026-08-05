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

Write-Host "PASS: $script:TestCount assertions completed."
