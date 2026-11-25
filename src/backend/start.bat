@echo off
rem One-click launcher for the library backend (Windows).
rem Keep this file ASCII-only for cmd.exe compatibility.
setlocal
cd /d "%~dp0..\.."

echo == Library backend launcher (Java 21 + JDBC) ==

where mvn >nul 2>&1
if errorlevel 1 goto :no_mvn

echo [1/2] checking JDBC connection ...
mvn -q exec:java -Dexec.mainClass=com.library.util.ConnectionCheck
if errorlevel 1 goto :fail_conn

echo [2/2] starting command line program ...
mvn -q exec:java -Dexec.mainClass=com.library.Main
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
