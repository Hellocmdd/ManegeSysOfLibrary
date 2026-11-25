#!/usr/bin/env bash
# One-click launcher for the library frontend (Linux / macOS / WSL).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$SCRIPT_DIR"

VENV=".venv"
PY="$VENV/bin/python"
PYPI_TUNA="https://pypi.tuna.tsinghua.edu.cn/simple"
PYPI_ALIYUN="https://mirrors.aliyun.com/pypi/simple"

echo "== Library frontend launcher (src/frontend) =="

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found. Install Python 3.11+ first."
    exit 1
fi

ensure_pip() {
    if "$PY" -m pip --version >/dev/null 2>&1; then
        return 0
    fi
    echo "    pip missing in venv, trying ensurepip ..."
    if "$PY" -m ensurepip --upgrade >/dev/null 2>&1 \
        && "$PY" -m pip --version >/dev/null 2>&1; then
        return 0
    fi
    if command -v uv >/dev/null 2>&1; then
        echo "    ensurepip unavailable, rebuilding venv with uv --seed ..."
        rm -rf "$VENV"
        UV_INDEX_URL="$PYPI_TUNA" uv venv --python "$(command -v python3)" --seed "$VENV" >/dev/null
        if "$PY" -m pip --version >/dev/null 2>&1; then
            return 0
        fi
    fi
    echo "Cannot bootstrap pip. Install python3-venv or uv, then rerun."
    exit 1
}

if [ ! -x "$PY" ]; then
    echo "[1/3] creating venv with python3 ..."
    python3 -m venv "$VENV"
else
    echo "[1/3] venv found, skip creation"
fi

ensure_pip

echo "[2/3] checking dependencies ..."
if ! "$PY" -c "import flask, pymysql" >/dev/null 2>&1; then
    echo "    installing from Tsinghua mirror ..."
    PIP_INDEX_URL="$PYPI_TUNA" "$PY" -m pip install --disable-pip-version-check -q -r requirements.txt \
        || { echo "    Tsinghua failed, trying Aliyun ..."; PIP_INDEX_URL="$PYPI_ALIYUN" "$PY" -m pip install --disable-pip-version-check -q -r requirements.txt; } \
        || { echo "    Aliyun failed, trying PyPI ..."; "$PY" -m pip install --disable-pip-version-check -q -r requirements.txt; }
fi

if [ ! -f "$REPO_ROOT/.env" ] && [ -f "$REPO_ROOT/.env.example" ]; then
    cp "$REPO_ROOT/.env.example" "$REPO_ROOT/.env"
    echo "[hint] created repo root .env from .env.example; fill DB_PASSWORD before connecting"
fi

echo "[3/3] starting on http://127.0.0.1:5000  press Ctrl+C to stop"
exec "$PY" app.py
