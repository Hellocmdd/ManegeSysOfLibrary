@echo off
rem Launcher for the library backend (Windows).
rem Keep this file ASCII-only for cmd.exe compatibility.
rem By default it only checks the JDBC connection; pass --cli to start the Java CLI.
setlocal
cd /d "%~dp0..\.."

echo == Library backend launcher (Java 21 + JDBC) ==

where mvn >nul 2>&1
if errorlevel 1 goto :no_mvn

echo [1/2] checking JDBC connection ...
mvn -q exec:java -Dexec.mainClass=com.library.util.ConnectionCheck
if errorlevel 1 goto :fail_conn

if "%~1"=="--cli" (
    echo [2/2] starting command line program ...
    mvn -q exec:java -Dexec.mainClass=com.library.Main
    goto :eof
)

echo [2/2] JDBC connection is OK; command line program not started.
echo To start the Java CLI, run: src\backend\start.bat --cli
goto :eof

:no_mvn
echo.
echo Maven not found. Install Maven 3.9+ and add it to PATH.
pause
exit /b 1

:fail_conn
echo.
echo JDBC connection check failed. Check your .env and remote MySQL.
pause
exit /b 1
