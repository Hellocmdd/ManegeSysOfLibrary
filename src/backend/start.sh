#!/usr/bin/env bash
# One-click launcher for the library backend (Linux / macOS / WSL).
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

echo "[2/2] starting command line program ..."
exec mvn -q exec:java -Dexec.mainClass=com.library.Main
