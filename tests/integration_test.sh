#!/bin/bash

# ==============================================================================
# Integration Tests for nerdctl-docker-shim
# ==============================================================================
# This script simulates VS Code Dev Container behaviors using the shim
# and a real 'nerdctl' runtime.
# REQUIRES: nerdctl installed and configured.
# ==============================================================================

set -e

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
SHIM_BIN="$PROJECT_ROOT/docker"
FIXTURES_DIR="$TEST_DIR/fixtures"
LOG_FILE="/tmp/nerdctl-docker-shim-integration.log"

# Check prerequisites
if ! command -v nerdctl &>/dev/null; then
    echo "Error: nerdctl is not installed or not in PATH."
    exit 1
fi

# Setup environment
export DOCKER_SHIM_LOG="$LOG_FILE"
chmod +x "$SHIM_BIN"

echo "=== Starting Integration Tests ==="
echo "Shim: $SHIM_BIN"
echo "Log:  $LOG_FILE"

# Cleanup previous run
echo "" >"$LOG_FILE"

# 1. Build
echo -e "\n[TEST] Build Image"
echo "Running: docker buildx build ..."
"$SHIM_BIN" buildx build \
    --builder=desktop-linux \
    --load \
    --provenance=false \
    -f "$FIXTURES_DIR/Dockerfile" \
    -t shim-test-image \
    "$FIXTURES_DIR"

# 2. Run
echo -e "\n[TEST] Run Container"
echo "Running: docker run -d ..."
CONTAINER_ID=$("$SHIM_BIN" run -d shim-test-image sleep infinity)
echo "Container ID: $CONTAINER_ID"

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Failed to start container"
    exit 1
fi

# 3. Inspect
echo -e "\n[TEST] Inspect Container"
if "$SHIM_BIN" inspect "$CONTAINER_ID" >/dev/null; then
    echo "✅ Inspect successful"
else
    echo "❌ Inspect failed"
    exit 1
fi

# 4. Exec
echo -e "\n[TEST] Exec Command"
OUTPUT=$("$SHIM_BIN" exec "$CONTAINER_ID" cat /var/log/build-time.log)
echo "Output: $OUTPUT"
if [[ -n "$OUTPUT" ]]; then
    echo "✅ Exec successful"
else
    echo "❌ Exec failed (empty output)"
    exit 1
fi

# 5. Cleanup
echo -e "\n[TEST] Cleanup"
"$SHIM_BIN" rm -f "$CONTAINER_ID"
echo "✅ Cleanup successful"

# 6. Failure Propagation
echo -e "\n[TEST] Failure Propagation"
if "$SHIM_BIN" run non-existent-image-$(date +%s) 2>/dev/null; then
    echo "❌ Failed: Should have returned error code for non-existent image"
    exit 1
else
    echo "✅ Success: Correctly propagated error code"
fi

echo -e "\n================================================================"
echo "Integration tests passed!"
