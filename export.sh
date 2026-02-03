#!/bin/bash
set -euo pipefail

# Export running or stopped container as new image with all changes (dotfiles, plugins, etc.)
# Usage: ./export.sh [container_name] [new_image_name:tag]

CONTAINER="${1:-devbox}"
NEW_IMAGE="${2:-devbox-configured:latest}"

echo "Committing container '${CONTAINER}' as '${NEW_IMAGE}'..."
docker commit "${CONTAINER}" "${NEW_IMAGE}"

echo "Done. New image size:"
docker images "${NEW_IMAGE}" --format "{{.Size}}"

echo ""
echo "To save as tarball for airgapped transfer:"
echo "  docker save ${NEW_IMAGE} | gzip > devbox.tar.gz"
echo ""
echo "To load on airgapped machine:"
echo "  docker load < devbox.tar.gz"
