#!/bin/bash

# Docker runner
# Usage: 
#   ./run_docker.sh              # Opens interactive shell
#   ./run_docker.sh ls -la       # Runs command and exits

set -ex

# Source the centralized configuration
source ./docker_config.sh

# Global variable to track the current container ID
CURRENT_CONTAINER_ID=""

# Trap handler to kill container on script exit
cleanup() {
    if [ -n "$CURRENT_CONTAINER_ID" ]; then
        echo "Cleaning up container: $CURRENT_CONTAINER_ID"
        docker kill "$CURRENT_CONTAINER_ID" 2>/dev/null || true
    fi
}

# Set trap for various exit signals
trap cleanup EXIT INT TERM

# Build the Docker image (no-op if layers are cached)
echo "Building Docker image..."
docker build --tag "$DOCKER_IMAGE" .

# If no arguments, open interactive shell
if [ $# -eq 0 ]; then
    echo "Running Docker container with interactive shell..."
    CURRENT_CONTAINER_ID=$(docker run -d -it "${DOCKER_FLAGS[@]}" "$DOCKER_IMAGE" /bin/bash)
    echo "Container ID: $CURRENT_CONTAINER_ID"
    docker attach "$CURRENT_CONTAINER_ID"
else
    # Run the command passed as arguments
    echo "Running command in Docker container: $@"
    CURRENT_CONTAINER_ID=$(docker run -d "${DOCKER_FLAGS[@]}" "$DOCKER_IMAGE" "$@")
    echo "Container ID: $CURRENT_CONTAINER_ID"
    docker logs -f "$CURRENT_CONTAINER_ID"
fi