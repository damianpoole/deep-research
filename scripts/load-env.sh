#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE. Copy .env.example to .env and set RESEARCH_DIR." >&2
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [[ -z "${RESEARCH_DIR:-}" ]]; then
  echo "RESEARCH_DIR is not set in $ENV_FILE." >&2
  exit 1
fi