#!/bin/bash

# ==============================================================================
# Dev Container Simulation Test
# ==============================================================================
# This script simulates the exact commands VS Code issues when opening a
# Dev Container, ensuring the shim handles the full lifecycle correctly.
# ==============================================================================

set -e

# Setup paths
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
SHIM_BIN="$PROJECT_ROOT/docker"
DEMO_DIR="$TEST_DIR/devcontainer-demo"
LOG_FILE="/tmp/nerdctl-docker-shim-simulation.log"

# Check prerequisites
if ! command -v nerdctl &>/dev/null; then
    echo "Error: nerdctl is not installed or not in PATH."
    exit 1
fi

# Ensure shim is executable
chmod +x "$SHIM_BIN"

# Mock VS Code environment by putting shim in PATH
export PATH="$PROJECT_ROOT:$PATH"
export DOCKER_SHIM_LOG="$LOG_FILE"

echo "=== Starting Dev Container Simulation ==="
echo "Shim: $SHIM_BIN"
echo "Demo Dir: $DEMO_DIR"
echo "Log: $LOG_FILE"

# Cleanup log
echo "" >"$LOG_FILE"

cd "$DEMO_DIR"

echo -e "\n[SIMULATION] 1. VS Code Build"
# VS Code typical build command with specific flags that need cleaning
echo "Running: docker buildx build ..."
"$SHIM_BIN" buildx build \
    --builder=desktop-linux \
    --load \
    --provenance=false \
    -f .devcontainer/Dockerfile \
    -t devcontainer-demo-image \
    .

echo -e "\n[SIMULATION] 2. VS Code Run"
# VS Code runs container detached, usually without a name initially (or with a generated one)
# The shim should inject a name if missing.
echo "Running: docker run -d ..."
CONTAINER_ID=$("$SHIM_BIN" run -d devcontainer-demo-image sleep infinity)
echo "Container ID: $CONTAINER_ID"

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Failed to start container"
    exit 1
fi

echo -e "\n[SIMULATION] 3. VS Code Inspect"
# VS Code inspects the container to check status and ports
if "$SHIM_BIN" inspect "$CONTAINER_ID" >/dev/null; then
    echo "✅ Inspect successful"
else
    echo "❌ Inspect failed"
    exit 1
fi

echo -e "\n[SIMULATION] 4. VS Code Exec"
# VS Code installs server or checks files
OUTPUT=$("$SHIM_BIN" exec "$CONTAINER_ID" cat /var/log/build-time.log)
echo "Output: $OUTPUT"
if [[ -n "$OUTPUT" ]]; then
    echo "✅ Exec successful"
else
    echo "❌ Exec failed"
    exit 1
fi

echo -e "\n[SIMULATION] 5. Cleanup"
"$SHIM_BIN" rm -f "$CONTAINER_ID"
echo "✅ Cleanup successful"

echo -e "\n================================================================"
echo "Simulation passed!"
