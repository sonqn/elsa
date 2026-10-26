#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
SHA=$(git rev-parse HEAD)
# Local verification fallback; public CI publishes this same SHA to GHCR.
docker build -t "quote-api:$SHA" .
k3d image import "quote-api:$SHA" -c elsa
printf '%s' "$SHA" > evidence/image-sha
