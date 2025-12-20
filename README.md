# nerdctl-docker-shim

[中文版](README_zh-CN.md)

A lightweight wrapper that makes `nerdctl` look and act like `docker`.

Designed primarily for tools that hardcode `docker` CLI usage (e.g., **VS Code Dev Containers**), allowing them to work seamlessly with containerd/nerdctl.

## Why?

Tools like VS Code Dev Containers expect `docker` to be present and behave in specific ways. This shim intercepts `docker` commands and translates them for `nerdctl`.

## Key Features

- **Buildx Simulation**: Fakes `docker buildx` commands so IDEs don't complain.
- **Argument Sanitization**: Strips unsupported flags (e.g., `--provenance`, `--sbom`) that cause `nerdctl` to fail.
- **Output Fixing**: Massages build logs and `inspect` JSON output to match what Docker clients expect.
- **Auto-Naming**: Injects container names if missing, required by some IDE plugins.
- **Logging**: Debug logs are written to `/tmp/nerdctl-docker-shim.log`.

## Installation

1. **Download & Install**

   ```bash
   curl -L -o docker https://raw.githubusercontent.com/kiddingbaby/nerdctl-docker-shim/main/docker
   chmod +x docker
   sudo mv docker /usr/local/bin/docker
   ```

   > **Note**: Ensure `/usr/local/bin` is in your `$PATH` before `/usr/bin` if you have the real docker installed.

2. **Verify**

   ```bash
   docker version
   # Should show nerdctl output
   ```

## Configuration

Optional environment variables:

| Variable            | Default                        | Description                        |
| :------------------ | :----------------------------- | :--------------------------------- |
| `NERDCTL_BIN`       | `nerdctl`                      | Path to the actual nerdctl binary. |
| `NERDCTL_NAMESPACE` | `default`                      | Containerd namespace.              |
| `DOCKER_SHIM_LOG`   | `/tmp/nerdctl-docker-shim.log` | Debug log location.                |

## License

MIT
