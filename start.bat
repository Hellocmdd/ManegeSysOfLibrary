@echo off
rem One-key launcher for the library project (Windows).
rem Keep this file ASCII-only for cmd.exe compatibility.
setlocal
cd /d "%~dp0"

if not exist ".env" if exist ".env.example" (
    copy /y ".env.example" ".env" >nul
    if errorlevel 1 (
        echo Failed to create .env from .env.example.
        exit /b 1
    )
    echo [hint] created repo root .env from .env.example; fill DB_PASSWORD before connecting
)

echo == Library one-key launcher ==
echo [1/1] starting frontend in current window ...
echo Browser: http://127.0.0.1:5000
echo Java CLI is optional: src\backend\start.bat --cli
echo Press Ctrl+C to stop.

call "%~dp0src\frontend\start.bat"
