#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$PWD" != /workspace ]]; then
  docker compose up -d --build
  cid=$(docker compose ps -aq bootstrap)
  code=$(docker wait "$cid")
  docker compose logs bootstrap
  [[ "$code" == 0 ]] || exit 1
  exec docker compose exec -T toolbox bash /workspace/scripts/run-all.sh
fi
for script in scripts/10-build.sh scripts/20-deploy.sh scripts/25-reclaim-drill.sh scripts/30-troubleshoot.sh; do
  bash "$script"
done
