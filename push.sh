#!/bin/bash
set -euo pipefail

IMAGE_NAME="devbox"
TAG="${1:-latest}"

USERNAME=$(gh api user -q .login)
REMOTE="ghcr.io/${USERNAME}/${IMAGE_NAME}:${TAG}"

echo "Authenticating with ghcr.io..."
gh auth token | docker login ghcr.io -u "${USERNAME}" --password-stdin

echo "Tagging ${IMAGE_NAME}:${TAG} as ${REMOTE}..."
docker tag "${IMAGE_NAME}:${TAG}" "${REMOTE}"

echo "Pushing..."
docker push "${REMOTE}"

echo "Done: ${REMOTE}"
