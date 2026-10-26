#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
NODE=
POD_NODES=$(kubectl -n quote-api get pods -l app=quote-api -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}')
for candidate in $(kubectl get nodes -l acme.io/capacity=spot -o jsonpath='{.items[*].metadata.name}'); do
  if grep -qx "$candidate" <<< "$POD_NODES"; then NODE=$candidate; break; fi
done
[[ -n "$NODE" ]] || { echo "No quote pod on a spot node to reclaim" >&2; exit 1; }
cleanup() { kubectl uncordon "$NODE"; [[ -z "${PID:-}" ]] || kill "$PID" 2>/dev/null || true; }
trap cleanup EXIT
kubectl -n quote-api get pods -o wide | tee evidence/reclaim-before.txt
: > evidence/reclaim-http.txt
(
  for i in $(seq 1 120); do
    if curl -fsS --max-time 5 http://k3d-elsa-serverlb/api/quote >/dev/null; then
      echo "$(date -Iseconds) OK"
    else
      echo "$(date -Iseconds) FAIL"
    fi
    sleep 1
  done
) > evidence/reclaim-http.txt &
PID=$!
kubectl drain "$NODE" --ignore-daemonsets --delete-emptydir-data --timeout=180s | tee evidence/reclaim-drain.txt
kubectl -n quote-api rollout status deployment/quote-api --timeout=180s
sleep 10
kubectl -n quote-api get pods -o wide | tee evidence/reclaim-after.txt
kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true
PID=
grep -q OK evidence/reclaim-http.txt
! grep -q FAIL evidence/reclaim-http.txt
# Assert at least one Ready app pod remains on on-demand.
OD=$(kubectl get nodes -l acme.io/capacity=on-demand -o jsonpath='{.items[0].metadata.name}')
kubectl -n quote-api get pods -l app=quote-api -o json | jq -e --arg node "$OD" \
  '.items | any(.spec.nodeName==$node and any(.status.conditions[]?; .type=="Ready" and .status=="True"))'
