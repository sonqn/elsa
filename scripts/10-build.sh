#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
SHA=$(git rev-parse HEAD)
IMAGE="ghcr.io/sonqn/elsa:$SHA"
# Prefer the public CI artifact. A source build keeps fresh commits runnable while CI completes.
if ! docker pull "$IMAGE"; then
  docker build -t "$IMAGE" .
fi
k3d image import "$IMAGE" -c elsa
printf '%s' "$SHA" > evidence/image-sha
