#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PID_FILE="$ROOT_DIR/.watch-reports.pid"
LOG_FILE="$ROOT_DIR/.watch-reports.log"

source "$ROOT_DIR/scripts/load-env.sh"

cd "$ROOT_DIR"

if [[ -f "$PID_FILE" ]]; then
  pid="$(cat "$PID_FILE")"
  if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
    echo "watcher already running (PID $pid)"
    echo "log: $LOG_FILE"
    exit 0
  fi
  rm -f "$PID_FILE"
fi

nohup python3 scripts/watch-and-serve.py >"$LOG_FILE" 2>&1 &
pid=$!
echo "$pid" > "$PID_FILE"
sleep 1

if ! kill -0 "$pid" >/dev/null 2>&1; then
  echo "failed to start watcher; check $LOG_FILE" >&2
  exit 1
fi

echo "watcher started (PID $pid)"
echo "log: $LOG_FILE"
