$ErrorActionPreference = 'Stop'

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)] $Expected,
        [Parameter(Mandatory = $true)] $Actual,
        [Parameter(Mandatory = $true)] [string] $Name
    )

    if ($Expected -ne $Actual) {
        throw "FAIL: $Name. Expected [$Expected], got [$Actual]."
    }
    Write-Host "PASS: $Name"
}

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

$projectRoot = Split-Path -Parent $PSScriptRoot
$creatorPath = Join-Path $projectRoot 'Create-DesktopShortcut.ps1'
$testDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("CatNapShortcutTest-{0}" -f [Guid]::NewGuid())
$shortcutPath = Join-Path $testDirectory 'CatNap Shutdown Timer.lnk'

New-Item -ItemType Directory -Path $testDirectory | Out-Null

try {
    Assert-True (Test-Path -LiteralPath $creatorPath -PathType Leaf) 'The shortcut creator is available'

    & $creatorPath -ShortcutPath $shortcutPath

    Assert-True (Test-Path -LiteralPath $shortcutPath -PathType Leaf) 'The shortcut is created at the requested path'

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)

    Assert-Equal (Join-Path $projectRoot 'Start-CatNapShutdownTimer.bat') $shortcut.TargetPath 'The shortcut launches the BAT file'
    Assert-Equal $projectRoot $shortcut.WorkingDirectory 'The shortcut starts in the project folder'
    Assert-Equal "$(Join-Path $projectRoot 'assets\CatNapShutdownTimer-Cat.ico'),0" $shortcut.IconLocation 'The shortcut uses the bundled cat icon'
    Assert-Equal 'CatNap Shutdown Timer' $shortcut.Description 'The shortcut has a friendly description'
}
finally {
    if (Test-Path -LiteralPath $shortcutPath) {
        Remove-Item -LiteralPath $shortcutPath -Force
    }
    if (Test-Path -LiteralPath $testDirectory) {
        Remove-Item -LiteralPath $testDirectory -Force
    }
}
