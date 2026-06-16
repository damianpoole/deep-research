#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/load-env.sh"
RESEARCH_DIR="${RESEARCH_DIR}"
LOCAL_PORT="${LOCAL_PORT:-3000}"
PID_FILE="$ROOT_DIR/.tailscale-serve-http.pid"
LOG_FILE="$ROOT_DIR/.tailscale-serve-http.log"

cd "$ROOT_DIR"

echo "Building Deep Research from: $RESEARCH_DIR"
RESEARCH_DIR="$RESEARCH_DIR" npm run build

if ! command -v tailscale >/dev/null 2>&1; then
  echo "tailscale CLI not found. Build is ready at: $ROOT_DIR/dist"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to run the local static file server. Build is ready at: $ROOT_DIR/dist"
  exit 0
fi

if [[ -f "$PID_FILE" ]]; then
  old_pid="$(cat "$PID_FILE")"
  if [[ -n "$old_pid" ]] && kill -0 "$old_pid" >/dev/null 2>&1; then
    echo "Stopping previous local file server (PID $old_pid)"
    kill "$old_pid" >/dev/null 2>&1 || true
    sleep 1
  fi
  rm -f "$PID_FILE"
fi

echo "Starting local static file server on 127.0.0.1:$LOCAL_PORT"
nohup python3 -m http.server "$LOCAL_PORT" --bind 127.0.0.1 --directory "$ROOT_DIR/dist" >"$LOG_FILE" 2>&1 &
server_pid=$!
echo "$server_pid" > "$PID_FILE"
sleep 1

if ! kill -0 "$server_pid" >/dev/null 2>&1; then
  echo "Local static file server failed to start. Check: $LOG_FILE"
  exit 1
fi

echo "Configuring Tailscale Serve to proxy http://127.0.0.1:$LOCAL_PORT"
tailscale serve --bg "$LOCAL_PORT"

dns_name="$(tailscale status --self --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["Self"]["DNSName"].rstrip("."))')"

echo "Local server PID: $server_pid"
echo "Local server log: $LOG_FILE"
echo "Site is being served over Tailscale at: https://$dns_name/"
