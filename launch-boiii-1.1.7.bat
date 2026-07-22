@echo off
rem Minimal launcher for the pinned BOIII v1.1.7 client.
rem Keep this file next to boiii-v1.1.7.exe and always use this launcher.

cd /d "%~dp0"

if not exist "%~dp0boiii-v1.1.7.exe" (
    echo ERROR: boiii-v1.1.7.exe was not found next to this launcher.
    echo Extract every file from boiii-v1.1.7-noupdate.zip into your
    echo Black Ops III folder, then run this file again.
    pause
    exit /b 1
)

rem Close stale game processes that can hold the single-instance lock.
taskkill /f /im boiii-v1.1.7.exe >nul 2>&1
taskkill /f /im boiii.exe >nul 2>&1
taskkill /f /im BlackOps3.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo Launching BOIII v1.1.7 ^(automatic updates disabled^)...
start "" /d "%~dp0" "%~dp0boiii-v1.1.7.exe" -noupdate
