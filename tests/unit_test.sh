#!/bin/bash

# ==============================================================================
# Unit Tests for nerdctl-docker-shim
# ==============================================================================
# This script mocks 'nerdctl' to verify argument parsing and logic
# without requiring a running container runtime.
# ==============================================================================

set -e

# Setup paths
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
SHIM_BIN="$PROJECT_ROOT/docker"
MOCK_BIN="$TEST_DIR/mock_nerdctl"
LOG_FILE="$TEST_DIR/test_shim.log"

# Export variables for the shim
export NERDCTL_BIN="$MOCK_BIN"
export DOCKER_SHIM_LOG="$LOG_FILE"
export NERDCTL_NAMESPACE="test-ns"

# Create mock nerdctl
cat <<EOF >"$MOCK_BIN"
#!/bin/bash
echo "MOCK_NERDCTL_CALLED_WITH: \$@"
EOF
chmod +x "$MOCK_BIN"

# Ensure shim is executable
chmod +x "$SHIM_BIN"

# Clear log
rm -f "$LOG_FILE"

echo "=== Starting Unit Tests ==="

run_test() {
    local desc="$1"
    local cmd="$2"
    local expected_pattern="$3"

    echo "----------------------------------------------------------------"
    echo "TEST: $desc"
    echo "CMD: $cmd"

    # Run command and capture stdout/stderr
    # We use eval to handle arguments with spaces correctly if needed,
    # but here we are calling the shim directly.
    output=$($cmd 2>&1)

    echo "OUTPUT: $output"

    if echo "$output" | grep -q "$expected_pattern"; then
        echo "✅ PASS"
    else
        echo "❌ FAIL: Expected pattern '$expected_pattern' not found"
        rm -f "$MOCK_BIN" "$LOG_FILE"
        exit 1
    fi
}

# 1. buildx version
run_test "buildx version" "$SHIM_BIN buildx version" "github.com/docker/buildx"

# 2. buildx inspect
run_test "buildx inspect" "$SHIM_BIN buildx inspect" "Driver: docker-container"

# 3. buildx build (check argument cleaning and passthrough)
run_test "buildx build args" "$SHIM_BIN buildx build --builder=foo -t test:latest ." "MOCK_NERDCTL_CALLED_WITH: --namespace test-ns build --progress=plain -t test:latest ."

# 4. inspect (check mode flag)
run_test "inspect mode" "$SHIM_BIN inspect mycontainer" "MOCK_NERDCTL_CALLED_WITH: --namespace test-ns inspect --mode=dockercompat mycontainer"

# 5. run without name (check auto-naming)
run_test "run auto-name" "$SHIM_BIN run -d nginx" "MOCK_NERDCTL_CALLED_WITH: --namespace test-ns run --name vsc-docker-.* -d nginx"

# 6. run with name (check no override)
run_test "run explicit name" "$SHIM_BIN run --name my-app -d nginx" "MOCK_NERDCTL_CALLED_WITH: --namespace test-ns run --name my-app -d nginx"

# 7. context ls
run_test "context ls" "$SHIM_BIN context ls" "default \*   nerdctl (test-ns)"

# 8. passthrough
run_test "passthrough images" "$SHIM_BIN images" "MOCK_NERDCTL_CALLED_WITH: --namespace test-ns images"

# 9. compose
run_test "compose passthrough" "$SHIM_BIN compose up -d" "MOCK_NERDCTL_CALLED_WITH: --namespace test-ns compose up -d"

# 10. context use (should exit 0 silently)
# We check that it DOES NOT call nerdctl (output should be empty or just not contain MOCK_NERDCTL)
# Actually, the shim exits 0 directly.
if "$SHIM_BIN" context use default >/dev/null; then
    echo "----------------------------------------------------------------"
    echo "TEST: context use"
    echo "✅ PASS (Exit code 0)"
else
    echo "❌ FAIL: context use failed"
    exit 1
fi

echo "================================================================"
echo "All unit tests passed!"

# Cleanup
rm -f "$MOCK_BIN" "$LOG_FILE"
