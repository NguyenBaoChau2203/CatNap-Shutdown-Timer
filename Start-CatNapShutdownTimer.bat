@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0CatNapShutdownTimer.ps1"
if errorlevel 1 (
    echo.
    echo Khong the mo chuong trinh.
    echo.
    echo Nguyen nhan co the:
    echo   - PowerShell bi chan boi chinh sach he thong
    echo   - File CatNapShutdownTimer.ps1 hoac CatNapShutdownTimer.Core.psm1 bi thieu/hong
    echo.
    echo Giai phap:
    echo   1. Giai nen day du tat ca file trong goi ZIP
    echo   2. Thu mo lai bang cach nhap dup vao file nay
    echo.
    pause
)
endlocal
