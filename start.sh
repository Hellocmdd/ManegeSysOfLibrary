#!/usr/bin/env bash
# One-key launcher for the library project (Linux / macOS / WSL).
# Starts the Flask frontend in the foreground so its output is visible.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if [ ! -f "$ROOT_DIR/.env" ] && [ -f "$ROOT_DIR/.env.example" ]; then
    cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
    echo "[hint] created repo root .env from .env.example; fill DB_PASSWORD before connecting"
fi

echo "== Library one-key launcher =="
echo "[1/1] starting frontend in foreground ..."
echo "Browser: http://127.0.0.1:5000"
echo "Java CLI is optional: src/backend/start.sh --cli"
echo "Press Ctrl+C to stop."

exec "$ROOT_DIR/src/frontend/start.sh"
