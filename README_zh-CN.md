# nerdctl-docker-shim

[English](README.md)

一个轻量级的包装脚本，让 `nerdctl` 的行为和表现像 `docker` 一样。

主要设计用于那些硬编码了 `docker` CLI 的工具（例如 **VS Code Dev Containers**），使它们能够与 containerd/nerdctl 无缝配合工作。

## 为什么需要这个？

像 VS Code Dev Containers 这样的工具期望系统中存在 `docker` 并且行为符合特定预期。这个 shim 脚本拦截 `docker` 命令并将其转换为 `nerdctl` 命令。

## 主要特性

- **Buildx 模拟**: 伪造 `docker buildx` 命令，让 IDE 不会报错。
- **参数清洗**: 剔除 `nerdctl` 尚不支持的参数（如 `--provenance`, `--sbom`），防止构建失败。
- **输出修正**: 调整构建日志和 `inspect` JSON 输出，以匹配 Docker 客户端的预期。
- **自动命名**: 如果缺少容器名称，自动注入名称，这是某些 IDE 插件所必需的。
- **日志记录**: 调试日志默认写入 `/tmp/nerdctl-docker-shim.log`。

## 安装

1. **下载并安装**

   ```bash
   curl -L -o docker https://raw.githubusercontent.com/kiddingbaby/nerdctl-docker-shim/main/docker
   chmod +x docker
   sudo mv docker /usr/local/bin/docker
   ```

   > **注意**: 确保 `/usr/local/bin` 在你的 `$PATH` 中位于 `/usr/bin` 之前（如果你安装了真正的 docker）。

2. **验证**

   ```bash
   docker version
   # 应该显示 nerdctl 的输出
   ```

## 配置

可选的环境变量：

| 变量                | 默认值                         | 描述                            |
| :------------------ | :----------------------------- | :------------------------------ |
| `NERDCTL_BIN`       | `nerdctl`                      | 实际 nerdctl 二进制文件的路径。 |
| `NERDCTL_NAMESPACE` | `default`                      | Containerd 命名空间。           |
| `DOCKER_SHIM_LOG`   | `/tmp/nerdctl-docker-shim.log` | 调试日志位置。                  |

## 许可证

MIT
