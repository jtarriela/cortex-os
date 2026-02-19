#!/usr/bin/env bash
set -euo pipefail

# Runs a full interactive usability session:
# 1) starts frontend dev server on the port expected by Tauri devUrl
# 2) waits until frontend is reachable
# 3) launches `cargo tauri dev`
#
# Usage:
#   ./scripts/usability-session.sh
#   ./scripts/usability-session.sh -- --verbose

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"
TAURI_APP_DIR="$ROOT_DIR/backend/crates/app"
TAURI_CONF="$TAURI_APP_DIR/tauri.conf.json"

if [[ ! -f "$TAURI_CONF" ]]; then
  echo "tauri.conf.json not found at $TAURI_CONF" >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required but not found in PATH." >&2
  exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
  echo "cargo is required but not found in PATH." >&2
  exit 1
fi

if ! cargo tauri --version >/dev/null 2>&1; then
  echo "cargo tauri CLI is required. Install with: cargo install tauri-cli --version '^2'" >&2
  exit 1
fi

# Extract dev port from tauri.conf.json: "devUrl": "http://localhost:5173"
DEV_PORT="$(
  sed -n 's/.*"devUrl"[[:space:]]*:[[:space:]]*"http:[/][/][^:]*:\([0-9][0-9]*\)".*/\1/p' "$TAURI_CONF" \
    | head -n 1
)"
DEV_PORT="${DEV_PORT:-5173}"

echo "Workspace root: $ROOT_DIR"
echo "Frontend dir:   $FRONTEND_DIR"
echo "Tauri app dir:  $TAURI_APP_DIR"
echo "Using dev port: $DEV_PORT"

cleanup() {
  if [[ -n "${FRONTEND_PID:-}" ]] && kill -0 "$FRONTEND_PID" 2>/dev/null; then
    echo "Stopping frontend dev server (pid=$FRONTEND_PID)..."
    kill "$FRONTEND_PID" 2>/dev/null || true
    wait "$FRONTEND_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

echo "Starting frontend dev server..."
(
  cd "$FRONTEND_DIR"
  npm run dev -- --host 0.0.0.0 --port "$DEV_PORT"
) &
FRONTEND_PID=$!

echo "Waiting for frontend readiness at http://localhost:$DEV_PORT ..."
for _ in $(seq 1 90); do
  if curl -fsS "http://localhost:$DEV_PORT" >/dev/null 2>&1; then
    echo "Frontend is ready."
    break
  fi
  sleep 1
done

if ! curl -fsS "http://localhost:$DEV_PORT" >/dev/null 2>&1; then
  echo "Frontend did not become ready in time." >&2
  exit 1
fi

echo "Launching Tauri dev app..."
cd "$TAURI_APP_DIR"

# Pass any extra args after `--` through to `cargo tauri dev`.
if [[ "${1:-}" == "--" ]]; then
  shift
fi
cargo tauri dev "$@"
