#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/load-env.sh"

cd "$ROOT_DIR"
exec python3 scripts/watch-and-serve.py