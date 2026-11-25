#!/usr/bin/env bash
# Launcher for the library backend (Linux / macOS / WSL).
# By default it only checks the JDBC connection; pass --cli to start the Java CLI.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

echo "== Library backend launcher (Java 21 + JDBC) =="

if ! command -v mvn >/dev/null 2>&1; then
    echo "Maven not found. Install Maven 3.9+ and add it to PATH."
    exit 1
fi

echo "[1/2] checking JDBC connection ..."
mvn -q exec:java -Dexec.mainClass=com.library.util.ConnectionCheck

if [ "${1:-}" = "--cli" ]; then
    echo "[2/2] starting command line program ..."
    exec mvn -q exec:java -Dexec.mainClass=com.library.Main
fi

echo "[2/2] JDBC connection is OK; command line program not started."
echo "To start the Java CLI, run: src/backend/start.sh --cli"
