#!/usr/bin/env bash
# One-key launcher for the library project (Linux / macOS / WSL).
# Frontend runs in the background; backend CLI stays in the foreground.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if [ ! -f "$ROOT_DIR/.env" ] && [ -f "$ROOT_DIR/.env.example" ]; then
    cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
    echo "[hint] created repo root .env from .env.example; fill DB_PASSWORD before connecting"
fi

LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$LOG_DIR"

echo "== Library one-key launcher =="

echo "[1/2] starting frontend in background ..."
"$ROOT_DIR/src/frontend/start.sh" > "$LOG_DIR/frontend.log" 2>&1 &
FRONTEND_PID=$!

cleanup() {
    kill "$FRONTEND_PID" 2>/dev/null || true
    wait "$FRONTEND_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

sleep 2
if ! kill -0 "$FRONTEND_PID" 2>/dev/null; then
    echo "Frontend exited early. Check logs/frontend.log"
else
    echo "Frontend is running. Log: logs/frontend.log"
fi

echo "[2/2] starting backend in foreground ..."
"$ROOT_DIR/src/backend/start.sh"
