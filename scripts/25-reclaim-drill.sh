#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
NODE=
TRAEFIK_NODES=$(kubectl -n kube-system get pods -l app.kubernetes.io/name=traefik -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}')
[[ -n "$TRAEFIK_NODES" ]] || { echo "No scheduled Traefik pod found; cannot safely select a drain target" >&2; exit 1; }
POD_NODES=$(kubectl -n quote-api get pods -l app=quote-api -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}')
for candidate in $(kubectl get nodes -l acme.io/capacity=spot -o jsonpath='{.items[*].metadata.name}'); do
  if ! grep -qx "$candidate" <<< "$TRAEFIK_NODES" && grep -qx "$candidate" <<< "$POD_NODES"; then NODE=$candidate; break; fi
done
[[ -n "$NODE" ]] || { echo "No spot node hosting quote pods outside the Traefik nodes; no safe drill target" >&2; exit 1; }
printf 'Excluded Traefik nodes: %s\nSelected spot node: %s\n' "$TRAEFIK_NODES" "$NODE" | tee "$RUN_LOG_DIR/reclaim-selection.txt"
cleanup() { kubectl uncordon "$NODE"; [[ -z "${PID:-}" ]] || kill "$PID" 2>/dev/null || true; }
trap cleanup EXIT
kubectl -n quote-api get pods -o wide | tee "$RUN_LOG_DIR/reclaim-before.txt"
: > "$RUN_LOG_DIR/reclaim-http.txt"
(
  while true; do
    if curl -fsS --max-time 5 http://k3d-elsa-serverlb/api/quote >/dev/null; then
      echo "$(date -Iseconds) OK"
    else
      echo "$(date -Iseconds) FAIL"
    fi
    sleep 1
  done
) > "$RUN_LOG_DIR/reclaim-http.txt" &
PID=$!
kubectl drain "$NODE" --ignore-daemonsets --delete-emptydir-data --timeout=180s | tee "$RUN_LOG_DIR/reclaim-drain.txt"
kubectl -n quote-api rollout status deployment/quote-api --timeout=180s
sleep 10
kubectl -n quote-api get pods -o wide | tee "$RUN_LOG_DIR/reclaim-after.txt"
kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true
PID=
grep -q OK "$RUN_LOG_DIR/reclaim-http.txt"
! grep -q FAIL "$RUN_LOG_DIR/reclaim-http.txt"
# Assert at least one Ready app pod remains on on-demand.
OD=$(kubectl get nodes -l acme.io/capacity=on-demand -o jsonpath='{.items[0].metadata.name}')
kubectl -n quote-api get pods -l app=quote-api -o json | jq -e --arg node "$OD" \
  '.items | any(.spec.nodeName==$node and any(.status.conditions[]?; .type=="Ready" and .status=="True"))'
