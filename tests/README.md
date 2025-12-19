# Tests

This directory contains tests for `nerdctl-docker-shim`.

## Unit Tests (`unit_test.sh`)

These tests mock the `nerdctl` binary to verify that the shim script correctly parses arguments, cleans flags, and constructs the expected `nerdctl` commands.

- **Requirements**: Bash
- **Runs**: Fast, no container runtime needed.

```bash
bash tests/unit_test.sh
```

## Integration Tests (`integration_test.sh`)

These tests run against a **real** `nerdctl` installation. They simulate the lifecycle of a VS Code Dev Container:

1. Build an image using `buildx build` (with flag cleaning).
2. Run a container (with auto-naming).
3. Inspect the container (checking JSON compatibility).
4. Exec a command inside the container.
5. Remove the container.

- **Requirements**: `nerdctl` installed and configured.
- **Runs**: Slower, builds actual images.

```bash
bash tests/integration_test.sh
```

## Dev Container Simulation (`simulate_devcontainer.sh`)

This script performs an end-to-end test using a real `.devcontainer` configuration structure. It mimics the exact commands VS Code issues when opening a folder in a container.

- **Requirements**: `nerdctl` installed.
- **Uses**: `tests/devcontainer-demo` project.

```bash
bash tests/simulate_devcontainer.sh
```

