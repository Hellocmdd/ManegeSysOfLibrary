@echo off
rem One-click launcher for the library frontend (Windows).
rem Keep this file ASCII-only: cmd.exe decodes batch files with the console code page.
setlocal
cd /d "%~dp0"

set "VENV=.venv"
set "VENV_PY=%VENV%\Scripts\python.exe"
set "PIP_TUNA=https://pypi.tuna.tsinghua.edu.cn/simple"
set "PIP_ALIYUN=https://mirrors.aliyun.com/pypi/simple"

echo == Library frontend launcher (src/frontend) ==

if not exist "%VENV_PY%" goto :make_venv
echo [1/4] venv found, skip creation
goto :check_pip

:make_venv
echo [1/4] creating venv .venv with py -3.10 ...
py -3.10 -m venv "%VENV%" >nul 2>&1
if not errorlevel 1 goto :check_pip
echo     py -3.10 not found, trying py -3.11 ...
py -3.11 -m venv "%VENV%"
if not errorlevel 1 goto :check_pip

:try_py3
echo     py -3.11 not found, trying py -3 ...
py -3 -m venv "%VENV%"
if errorlevel 1 goto :fail_venv

:check_pip
"%VENV_PY%" -m pip --version >nul 2>&1
if not errorlevel 1 goto :check_deps
echo     pip missing in venv, trying ensurepip ...
"%VENV_PY%" -m ensurepip --upgrade >nul 2>&1
"%VENV_PY%" -m pip --version >nul 2>&1
if not errorlevel 1 goto :check_deps
where uv >nul 2>&1
if errorlevel 1 goto :no_pip
echo     ensurepip unavailable, rebuilding venv with uv --seed ...
rmdir /s /q "%VENV%" >nul 2>&1
set "UV_INDEX_URL=%PIP_TUNA%"
uv venv --seed "%VENV%"
"%VENV_PY%" -m pip --version >nul 2>&1
if errorlevel 1 goto :no_pip

:check_deps
echo [2/4] checking dependencies ...
"%VENV_PY%" -c "import flask, pymysql" >nul 2>&1
if not errorlevel 1 goto :check_env
echo     installing from Tsinghua mirror ...
set "PIP_INDEX_URL=%PIP_TUNA%"
"%VENV_PY%" -m pip install --disable-pip-version-check -q -r requirements.txt
if not errorlevel 1 goto :check_env
echo     Tsinghua failed, trying Aliyun ...
set "PIP_INDEX_URL=%PIP_ALIYUN%"
"%VENV_PY%" -m pip install --disable-pip-version-check -q -r requirements.txt
if not errorlevel 1 goto :check_env
echo     Aliyun failed, trying PyPI ...
set "PIP_INDEX_URL="
"%VENV_PY%" -m pip install --disable-pip-version-check -q -r requirements.txt
if not errorlevel 1 goto :check_env
echo     HTTPS blocked (old pip + local TLS proxy), retrying over plain HTTP ...
set "PIP_INDEX_URL=http://mirrors.aliyun.com/pypi/simple"
set "PIP_TRUSTED_HOST=mirrors.aliyun.com"
"%VENV_PY%" -m pip install --disable-pip-version-check -q -r requirements.txt
if errorlevel 1 goto :fail_pip
set "PIP_INDEX_URL="
set "PIP_TRUSTED_HOST="

:check_env
if exist "..\..\.env" goto :check_db
if not exist "..\..\.env.example" goto :check_db
copy /y "..\..\.env.example" "..\..\.env" >nul
echo [hint] created repo root .env from .env.example; fill DB_PASSWORD before connecting

:check_db
echo [3/4] checking database connection ...
"%VENV_PY%" -c "from db import check_connection; check_connection()" >nul 2>&1
if not errorlevel 1 goto :run
echo     [warn] database unreachable. Check Tailscale login, Clash proxy for
echo            100.64.0.0/10, and DB_* values in the repo root .env.
echo     [warn] the app still starts, pages will show the error page.

:run
echo [4/4] starting on http://127.0.0.1:5000  press Ctrl+C to stop
"%VENV_PY%" app.py
goto :eof

:fail_venv
echo.
echo Failed to create the venv. Check Python 3.10: py -3.10 --version
pause
exit /b 1

:no_pip
echo.
echo Cannot bootstrap pip. Install python3-venv or uv, then rerun.
pause
exit /b 1

:fail_pip
echo.
echo Failed to install dependencies from all configured mirrors.
pause
exit /b 1
