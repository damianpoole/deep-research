#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PID_FILE="$ROOT_DIR/.watch-reports.pid"
LOG_FILE="$ROOT_DIR/.watch-reports.log"

if [[ ! -f "$PID_FILE" ]]; then
  echo "watcher: stopped"
  exit 0
fi

pid="$(cat "$PID_FILE")"
if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
  echo "watcher: running (PID $pid)"
  echo "log: $LOG_FILE"
else
  echo "watcher: stale pid file ($pid)"
  exit 1
fi
