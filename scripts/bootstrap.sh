#!/usr/bin/env bash
set -euo pipefail
cd /workspace
if ! k3d cluster list -o json | jq -e '.[] | select(.name=="elsa")' >/dev/null; then
  k3d cluster create elsa --agents 4 --image rancher/k3s:v1.33.5-k3s1 \
    --network elsa-devops-lab --port '8080:80@loadbalancer' --wait
fi
k3d kubeconfig get elsa > /root/.kube/config
kubectl config set-cluster k3d-elsa --server=https://k3d-elsa-server-0:6443
kubectl wait node --all --for=condition=Ready --timeout=240s
sh troubleshoot/prepare.sh
