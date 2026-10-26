#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
SHA=$(cat evidence/image-sha)
helm repo add argo https://argoproj.github.io/argo-helm --force-update
helm upgrade --install argocd argo/argo-cd --version 8.5.8 --namespace argocd --create-namespace \
  --set dex.enabled=false --set notifications.enabled=false --set applicationSet.enabled=false \
  --wait --timeout 10m
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: quote-api
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/sonqn/elsa.git
    targetRevision: $SHA
    path: charts/quote-api
    helm:
      parameters:
        - name: image.repository
          value: ghcr.io/sonqn/elsa
        - name: image.tag
          value: "$SHA"
  destination:
    server: https://kubernetes.default.svc
    namespace: quote-api
  syncPolicy:
    automated: {prune: true, selfHeal: true}
    syncOptions: [CreateNamespace=true]
EOF
for i in $(seq 1 120); do
  status=$(kubectl -n argocd get application quote-api -o json)
  if [[ $(jq -r '.status.sync.status' <<< "$status") == Synced && $(jq -r '.status.health.status' <<< "$status") == Healthy ]] && [[ $(kubectl -n quote-api get deployment quote-api -o jsonpath='{.status.readyReplicas}') -ge 3 ]]; then
    kubectl -n quote-api get pods -o wide
    curl -fsS http://k3d-elsa-serverlb/api/quote
    exit 0
  fi
  sleep 5
done
kubectl -n argocd get application quote-api -o yaml
exit 1
