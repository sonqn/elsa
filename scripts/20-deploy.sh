#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
SHA=$(cat evidence/image-sha)
# Export a committed snapshot of this repository for offline/local GitOps.
if [[ ! -d /tmp/git/quote.git ]]; then
  mkdir -p /tmp/git
  git clone --bare /workspace /tmp/git/quote.git
else
  git -C /tmp/git/quote.git fetch /workspace '+HEAD:refs/heads/main'
fi
if ! pgrep -f 'git daemon' >/dev/null; then
  git daemon --detach --reuseaddr --export-all --base-path=/tmp/git /tmp/git
fi
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
    repoURL: git://toolbox/quote.git
    targetRevision: $SHA
    path: charts/quote-api
    helm:
      parameters:
        - name: image.repository
          value: quote-api
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
  if [[ $(jq -r '.status.sync.status' <<< "$status") == Synced && $(jq -r '.status.health.status' <<< "$status") == Healthy ]]; then
    kubectl -n quote-api get pods -o wide
    curl -fsS http://k3d-elsa-serverlb/api/quote
    exit 0
  fi
  sleep 5
done
kubectl -n argocd get application quote-api -o yaml
exit 1
