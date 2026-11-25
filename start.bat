@echo off
rem One-key launcher for the library project (Windows).
rem Keep this file ASCII-only for cmd.exe compatibility.
rem Usage: start.bat [--content=all|backend|frontend|database]
setlocal
cd /d "%~dp0"

set "CONTENT=frontend"

:parse
if "%~1"=="" goto parsed
if /I "%~1"=="--content=all" goto set_all
if /I "%~1"=="--content=backend" goto set_backend
if /I "%~1"=="--content=frontend" goto set_frontend
if /I "%~1"=="--content=database" goto set_database
if /I "%~1"=="--help" goto usage
if /I "%~1"=="-h" goto usage
echo Unknown argument: %~1
goto usage_error

:set_all
set "CONTENT=all"
shift
goto parse

:set_backend
set "CONTENT=backend"
shift
goto parse

:set_frontend
set "CONTENT=frontend"
shift
goto parse

:set_database
set "CONTENT=database"
shift
goto parse

:parsed
if /I "%CONTENT%"=="all" goto content_all
if /I "%CONTENT%"=="backend" goto content_backend
if /I "%CONTENT%"=="frontend" goto content_frontend
if /I "%CONTENT%"=="database" goto content_database
echo Invalid --content value: %CONTENT%
goto usage_error

:ensure_env
if not exist ".env" if exist ".env.example" (
    copy /y ".env.example" ".env" >nul
    if errorlevel 1 (
        echo Failed to create .env from .env.example.
        exit /b 1
    )
    echo [hint] created repo root .env from .env.example; fill DB_PASSWORD before connecting
)
goto :eof

:start_db
where docker >nul 2>&1
if errorlevel 1 (
    echo Docker not found. Install Docker first, or use --content=frontend.
    exit /b 1
)
echo == Starting Docker MySQL ==
docker compose up -d --wait
if errorlevel 1 exit /b 1
goto :eof

:content_all
call :ensure_env
if errorlevel 1 exit /b 1
call :start_db
if errorlevel 1 exit /b 1
echo == Checking JDBC connection ==
call "%~dp0src\backend\start.bat"
echo Browser: http://127.0.0.1:5000
echo Java CLI is available via: start.bat --content=backend
call "%~dp0src\frontend\start.bat"
exit /b 0

:content_backend
call :ensure_env
if errorlevel 1 exit /b 1
call :start_db
if errorlevel 1 exit /b 1
call "%~dp0src\backend\start.bat" --cli
exit /b 0

:content_frontend
call :ensure_env
if errorlevel 1 exit /b 1
echo Browser: http://127.0.0.1:5000
call "%~dp0src\frontend\start.bat"
exit /b 0

:content_database
call :ensure_env
if errorlevel 1 exit /b 1
call :start_db
if errorlevel 1 exit /b 1
echo Database is up. Run start.bat --content=frontend to start the web app.
exit /b 0

:usage
echo Usage: start.bat [--content=all^|backend^|frontend^|database]
echo   all       start database, check JDBC, then run frontend in foreground
echo   backend   start database, then run Java CLI in foreground
echo   frontend  run frontend only ^(default^)
echo   database  start Docker MySQL only
exit /b 0

:usage_error
call :usage
exit /b 1
