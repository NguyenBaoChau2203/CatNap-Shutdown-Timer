$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName UIAutomationClient

function Assert-True {
    param(
        [Parameter(Mandatory = $true)] [bool] $Condition,
        [Parameter(Mandatory = $true)] [string] $Name
    )

    if (-not $Condition) {
        throw "FAIL: $Name"
    }
    Write-Host "PASS: $Name"
}

function Find-ElementByName {
    param(
        [Parameter(Mandatory = $true)] [System.Windows.Automation.AutomationElement] $Parent,
        [Parameter(Mandatory = $true)] [string] $Name
    )

    $condition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::NameProperty,
        $Name
    )
    return $Parent.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $condition)
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $projectRoot 'CatNapShutdownTimer.ps1'
$process = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', $scriptPath
) -PassThru

try {
    $window = $null
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    $windowCondition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ProcessIdProperty,
        $process.Id
    )

    while (-not $window -and [DateTime]::UtcNow -lt $deadline) {
        $window = [System.Windows.Automation.AutomationElement]::RootElement.FindFirst(
            [System.Windows.Automation.TreeScope]::Children,
            $windowCondition
        )
        if (-not $window) {
            Start-Sleep -Milliseconds 100
        }
    }

    Assert-True ($null -ne $window) 'The application window opens'
    Assert-True ($window.Current.Name -eq 'Hẹn Giờ Tắt Máy - Cat Sleep Timer') 'The application title is correct'

    $numberInput = Find-ElementByName -Parent $window -Name '60'
    $quick15 = Find-ElementByName -Parent $window -Name '15 phút'
    $startButton = Find-ElementByName -Parent $window -Name 'BẮT ĐẦU HẸN GIỜ'
    $cancelButton = Find-ElementByName -Parent $window -Name 'HỦY LỊCH'

    Assert-True ($null -ne $numberInput) 'The default time input is visible'
    Assert-True ($null -ne $quick15) 'The quick 15-minute button is visible'
    Assert-True ($null -ne $startButton) 'The schedule button is visible'
    Assert-True ($null -ne $cancelButton) 'The cancel button is visible'

    [void]$process.CloseMainWindow()
    Assert-True ($process.WaitForExit(5000)) 'The application closes cleanly while idle'
}
finally {
    if (-not $process.HasExited) {
        [void]$process.CloseMainWindow()
        [void]$process.WaitForExit(2000)
    }
    $process.Dispose()
}
