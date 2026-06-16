#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PID_FILE="$ROOT_DIR/.watch-reports.pid"

if [[ ! -f "$PID_FILE" ]]; then
  echo "watcher is not running"
  exit 0
fi

pid="$(cat "$PID_FILE")"
if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
  kill "$pid"
  echo "stopped watcher (PID $pid)"
else
  echo "stale PID file removed"
fi

rm -f "$PID_FILE"
