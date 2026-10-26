#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
if [[ "$ROOT" != /workspace ]]; then
  docker compose exec -T toolbox bash "/workspace/scripts/$(basename "$0")" "$@"
  exit $?
fi
RUN_LOG_DIR="$ROOT/.runs"
mkdir -p "$RUN_LOG_DIR"
