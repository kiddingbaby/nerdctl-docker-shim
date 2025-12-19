# 测试

[English](README.md)

此目录包含 `nerdctl-docker-shim` 的测试。

## 单元测试 (`unit_test.sh`)

这些测试 mock 了 `nerdctl` 二进制文件，以验证 shim 脚本是否正确解析参数、清理标志并构建预期的 `nerdctl` 命令。

- **要求**：Bash
- **运行**：快速，无需容器运行时。

```bash
bash tests/unit_test.sh
```

## 集成测试 (`integration_test.sh`)

这些测试针对**真实**的 `nerdctl` 安装运行。它们模拟 VS Code Dev Container 的生命周期：

1. 使用 `buildx build` 构建镜像（带有标志清理）。
2. 运行容器（带有自动命名）。
3. Inspect 容器（检查 JSON 兼容性）。
4. 在容器内 Exec 命令。
5. 删除容器。

- **要求**：已安装并配置 `nerdctl`。
- **运行**：较慢，构建实际镜像。

```bash
bash tests/integration_test.sh
```

## Dev Container 模拟 (`simulate_devcontainer.sh`)

此脚本使用真实的 `.devcontainer` 配置结构执行端到端测试。它模仿 VS Code 在容器中打开文件夹时发出的确切命令。

- **要求**：已安装 `nerdctl`。
- **使用**：`tests/devcontainer-demo` 项目。

```bash
bash tests/simulate_devcontainer.sh
```
