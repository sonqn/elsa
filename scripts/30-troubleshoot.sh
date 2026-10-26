#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
kubectl apply -f troubleshoot/broken-app.yaml
sleep 10
kubectl -n troubleshoot get pods -o wide > evidence/broken-pods.txt
kubectl -n troubleshoot describe pods > evidence/broken-describe.txt
kubectl -n troubleshoot get events --sort-by=.lastTimestamp > evidence/broken-events.txt
kubectl apply -f troubleshoot/fixed-app.yaml
kubectl -n troubleshoot rollout status deployment/web --timeout=180s
kubectl -n troubleshoot rollout status deployment/ai-inference --timeout=180s
sh troubleshoot/verify.sh | tee evidence/verify.txt
