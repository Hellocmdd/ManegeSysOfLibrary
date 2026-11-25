@echo off
rem One-key launcher for the library project (Windows).
rem Keep this file ASCII-only for cmd.exe compatibility.
setlocal
cd /d "%~dp0"

echo == Library one-key launcher ==
echo Starting backend and frontend in separate windows ...

start "Library Backend" cmd /k call "%~dp0src\backend\start.bat"
start "Library Frontend" cmd /k call "%~dp0src\frontend\start.bat"

echo.
echo Both windows opened. Close them or press Ctrl+C in each to stop.
