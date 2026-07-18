@echo off
rem zm8 mod launcher - starts BOIII, then installs the lobby-cap lua into
rem %LOCALAPPDATA%\boiii (the client wipes foreign files there at startup,
rem so it has to be re-copied after every launch - this bat automates that).
rem The gameplay script (boiii\custom_scripts) survives on its own.
rem
rem This file must sit in your Black Ops III game folder, next to boiii.exe.

cd /d "%~dp0"

if not exist "%~dp0boiii.exe" (
    echo ERROR: boiii.exe not found next to this file.
    echo Put launch-zm8.bat in your Black Ops III folder ^(same folder as boiii.exe^).
    pause
    exit /b 1
)

set SRC=%~dp0boiii\data\ui_scripts\zm_8player\__init__.lua
set DST=%LOCALAPPDATA%\boiii\data\ui_scripts\zm_8player

start "" /d "%~dp0" "%~dp0boiii.exe"

echo Waiting for BOIII to start and finish its data-folder cleanup...
rem copy a few times over ~90s so we land after the cleanup no matter how slow startup is
for /l %%i in (1,1,3) do (
    timeout /t 30 /nobreak >nul
    if not exist "%DST%" mkdir "%DST%" >nul 2>&1
    copy /y "%SRC%" "%DST%\__init__.lua" >nul
)

echo zm8 lobby lua installed for this session. You can close this window.
