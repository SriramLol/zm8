@echo off
rem ============================================================
rem  zm8 launcher  -  Black Ops III 8-player zombies mod
rem ============================================================
rem Launches the BUNDLED boiii.exe (v1.1.7) with -noupdate.
rem
rem Why -noupdate matters:
rem  * The client's auto-updater would otherwise replace boiii.exe with the
rem    "latest" build (currently 1.1.10), which breaks this mod. -noupdate
rem    pins you to the bundled v1.1.7.
rem  * It also disables the client's startup purge of %LOCALAPPDATA%\boiii,
rem    so the mod files installed under boiii\ are left alone.
rem
rem ALWAYS start the game with this bat. If you launch boiii.exe directly or
rem through the EZZ launcher WITHOUT -noupdate, it will update to the latest
rem build and the mod will stop working.
rem
rem This file must sit in your Black Ops III folder, next to boiii.exe.

cd /d "%~dp0"

if not exist "%~dp0boiii.exe" (
    echo ERROR: boiii.exe not found next to this file.
    echo Put EVERYTHING from the zip into your Black Ops III folder
    echo ^(the folder that runs boiii.exe^), then run this bat again.
    pause
    exit /b 1
)

rem Close any leftover BO3 processes so the launcher doesn't report
rem "game already running" (a stuck boiii.exe/BlackOps3.exe holds that lock).
taskkill /f /im boiii.exe >nul 2>&1
taskkill /f /im BlackOps3.exe >nul 2>&1
timeout /t 2 /nobreak >nul

rem The lobby lua ships at boiii\ui_scripts\zm_8player\ (loaded directly, never
rem purged with -noupdate). Also mirror it into the appdata path as a backup.
set SRC=%~dp0boiii\data\ui_scripts\zm_8player\__init__.lua
set DST=%LOCALAPPDATA%\boiii\data\ui_scripts\zm_8player
if exist "%SRC%" (
    if not exist "%DST%" mkdir "%DST%" >nul 2>&1
    copy /y "%SRC%" "%DST%\__init__.lua" >nul
)

echo Launching zm8  (BOIII v1.1.7, auto-update disabled)...
start "" /d "%~dp0" "%~dp0boiii.exe" -noupdate
