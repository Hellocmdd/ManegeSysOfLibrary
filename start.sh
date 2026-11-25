#!/usr/bin/env bash
# One-key launcher for the library project (Linux / macOS / WSL).
# Usage: ./start.sh [--content=all|backend|frontend|database]
#   all      Docker DB + JDBC check + Flask frontend in foreground
#   backend  Docker DB + Java CLI in foreground
#   frontend Flask frontend only (default)
#   database Docker MySQL only
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

print_usage() {
    echo "Usage: ./start.sh [--content=all|backend|frontend|database]"
    echo "  all       start database, check JDBC, then run frontend in foreground"
    echo "  backend   start database, then run Java CLI in foreground"
    echo "  frontend  run frontend only (default)"
    echo "  database  start Docker MySQL only"
}

CONTENT="frontend"
for arg in "$@"; do
    case "$arg" in
        --content=*)
            CONTENT="${arg#--content=}"
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg"
            print_usage
            exit 1
            ;;
    esac
done

case "$CONTENT" in
    all|backend|frontend|database) ;;
    *)
        echo "Invalid --content value: $CONTENT"
        print_usage
        exit 1
        ;;
esac

if [ ! -f "$ROOT_DIR/.env" ] && [ -f "$ROOT_DIR/.env.example" ]; then
    cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
    echo "[hint] created repo root .env from .env.example; fill DB_PASSWORD before connecting"
fi

start_database() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "Docker not found. Install Docker first, or use --content=frontend."
        exit 1
    fi
    echo "== Starting Docker MySQL =="
    docker compose up -d --wait
}

echo "== Library launcher: $CONTENT =="

case "$CONTENT" in
    database)
        start_database
        echo "Database is up. Run ./start.sh --content=frontend to start the web app."
        ;;
    frontend)
        echo "Browser: http://127.0.0.1:5000"
        exec "$ROOT_DIR/src/frontend/start.sh"
        ;;
    backend)
        start_database
        exec "$ROOT_DIR/src/backend/start.sh" --cli
        ;;
    all)
        start_database
        echo "== Checking JDBC connection =="
        "$ROOT_DIR/src/backend/start.sh"
        echo "Browser: http://127.0.0.1:5000"
        echo "Java CLI is available via: ./start.sh --content=backend"
        echo "Press Ctrl+C to stop."
        exec "$ROOT_DIR/src/frontend/start.sh"
        ;;
esac
