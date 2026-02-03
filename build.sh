#!/bin/bash
set -euo pipefail

IMAGE_NAME="devbox"
TAG="${1:-latest}"
PLATFORM="${2:-}"

echo "Building ${IMAGE_NAME}:${TAG}..."

if [[ -n "${PLATFORM}" ]]; then
    echo "Platform: ${PLATFORM} (via buildx)"
    docker buildx build --platform "${PLATFORM}" --load -t "${IMAGE_NAME}:${TAG}" .
else
    docker build -t "${IMAGE_NAME}:${TAG}" .
fi

echo "Done. Image size:"
docker images "${IMAGE_NAME}:${TAG}" --format "{{.Size}}"
