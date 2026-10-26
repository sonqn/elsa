#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
SHA=$(git rev-parse HEAD)
IMAGE="ghcr.io/sonqn/elsa:$SHA"
# Published multi-platform images are pulled directly by Kubernetes.
# Do not export/import their indexes through k3d's archive path.
if docker pull "$IMAGE"; then
  echo "Published image available: $IMAGE; Kubernetes will pull it directly."
else
  PLATFORM=$(docker version --format '{{.Server.Os}}/{{.Server.Arch}}')
  TEMP_DIR=$(mktemp -d /tmp/quote-image.XXXXXX)
  ARCHIVE="$TEMP_DIR/image.tar"
  trap 'rm -f "$ARCHIVE"; rmdir "$TEMP_DIR"' EXIT
  docker build --platform="$PLATFORM" --provenance=false -t "$IMAGE" .
  docker image save --platform="$PLATFORM" -o "$ARCHIVE" "$IMAGE"
  k3d image import "$ARCHIVE" -c elsa
  # k3d can report success despite per-node import errors. Verify each node.
  for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
    docker exec "$node" crictl inspecti "$IMAGE" >/dev/null
  done
fi
