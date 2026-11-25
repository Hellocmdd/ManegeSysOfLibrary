@echo off
rem One-click launcher for the library frontend (Windows).
rem Keep this file ASCII-only: cmd.exe decodes batch files with the console code
rem page, and UTF-8 Chinese text makes it mis-parse lines.
setlocal
cd /d "%~dp0"

set "VENV=.venv"
set "VENV_PY=%VENV%\Scripts\python.exe"

echo == Library frontend launcher (src/frontend) ==

if not exist "%VENV_PY%" goto :make_venv
echo [1/3] venv found, skip creation
goto :check_deps

:make_venv
echo [1/3] creating venv .venv with py -3.11 ...
py -3.11 -m venv "%VENV%"
if errorlevel 1 goto :try_py3
goto :check_deps

:try_py3
echo     py -3.11 not found, trying py -3 ...
py -3 -m venv "%VENV%"
if errorlevel 1 goto :fail_venv

:check_deps
echo [2/3] checking dependencies ...
"%VENV_PY%" -c "import flask, pymysql" >nul 2>&1
if not errorlevel 1 goto :check_env
echo     installing Flask and PyMySQL, first run needs network ...
"%VENV_PY%" -m pip install --disable-pip-version-check -q -r requirements.txt
if not errorlevel 1 goto :check_env
echo     PyPI unreachable, retrying with Tsinghua mirror ...
"%VENV_PY%" -m pip install --disable-pip-version-check -q -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
if not errorlevel 1 goto :check_env
echo     Tsinghua mirror failed, retrying with Aliyun mirror ...
"%VENV_PY%" -m pip install --disable-pip-version-check -q -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple
if not errorlevel 1 goto :check_env
echo     HTTPS blocked, retrying over plain HTTP ...
"%VENV_PY%" -m pip install --disable-pip-version-check -q -r requirements.txt -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com
if errorlevel 1 goto :fail_pip

:check_env
if exist ".env" goto :run
if not exist ".env.example" goto :run
copy /y ".env.example" ".env" >nul
echo [hint] created .env from .env.example, edit DB_PASSWORD if your MySQL has one

:run
echo [3/3] starting on http://127.0.0.1:5000  press Ctrl+C to stop
"%VENV_PY%" app.py
goto :eof

:fail_venv
echo.
echo Failed to create the venv. Check Python 3.11: py -3.11 --version
pause
exit /b 1

:fail_pip
echo.
echo Failed to install dependencies. Try a reachable mirror or install from local wheels.
pause
exit /b 1
