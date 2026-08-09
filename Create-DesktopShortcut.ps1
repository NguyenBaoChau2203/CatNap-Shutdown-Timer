param(
    [string] $ShortcutPath = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'CatNap Shutdown Timer.lnk')
)

$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$targetPath = Join-Path $projectRoot 'Start-CatNapShutdownTimer.bat'
$iconPath = Join-Path $projectRoot 'assets\CatNapShutdownTimer-Cat.ico'

if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
    throw "Launcher not found: $targetPath"
}

if (-not (Test-Path -LiteralPath $iconPath -PathType Leaf)) {
    throw "Icon not found: $iconPath"
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($ShortcutPath)
$shortcut.TargetPath = $targetPath
$shortcut.WorkingDirectory = $projectRoot
$shortcut.IconLocation = "$iconPath,0"
$shortcut.Description = 'CatNap Shutdown Timer'
$shortcut.Save()

Write-Host "Desktop shortcut created: $ShortcutPath"
