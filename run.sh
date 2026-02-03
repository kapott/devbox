#!/bin/bash
set -euo pipefail

IMAGE_NAME="devbox"
CONTAINER_NAME="devbox"
WORKSPACE="${1:-$(pwd)}"

docker run -it --rm \
    --name "${CONTAINER_NAME}" \
    -v "${WORKSPACE}:/workspace" \
    -v devbox-home:/root \
    "${IMAGE_NAME}:latest"
