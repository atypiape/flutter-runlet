# FlutterRunlet

<img src="docs/design/assets/flutterrunlet-dock-128.png" alt="FlutterRunlet 应用图标" width="72" height="72">

FlutterRunlet 是一个面向 macOS 的轻量 Flutter 调试工具，专为习惯用终端或其他编辑器写代码的开发者设计。它将复用 Flutter 项目里的 `.vscode/launch.json` 和 `.vscode/tasks.json`，让开发者无需打开 VS Code 或 Android Studio 就能启动和调试 Flutter 应用。

**当前进度**　v0.1 的界面原型已通过设计验收，应用开发尚未开始，暂无可下载的安装包。最低系统版本暂定为 macOS 15，待实机验证。[开发路线图](docs/03-ROADMAP.md)

## v0.1 计划

- 打开 Flutter 项目，从现有配置中选启动环境，再选模拟器或真机。支持选择 Flutter SDK 和使用项目的 FVM 配置。
- 按项目配置执行启动前和调试后的任务。例如，启动时切换 Firebase 环境，停止后恢复，并在恢复失败时提示重试。
- 运行、停止、热重载或热重启 Debug 会话，查看状态和日志，并在默认浏览器中打开当前会话的 Flutter DevTools 或 Inspector。
- 从原生主窗口或 macOS 菜单栏操作同一个会话。界面提供简体中文和 English，并适配系统深浅色。

## 配置示例与设计

- 示例用本地文件模拟 Firebase 环境切换，可以单独运行脚本查看结果。[VS Code 配置示例](docs/examples/sample-flutter-app/README.md)
- 查看首版功能、使用流程和配置兼容范围。[产品需求](docs/01-PRODUCT.md) · [技术契约](docs/02-TECHNICAL.md)
- 查看主窗口、菜单栏、设置与应用图标的设计。[界面规格](docs/design/UI-SPEC.md) · [设计系统](docs/design/DESIGN-SYSTEM.md)

## 许可证

本仓库采用 MIT 许可证。应用计划在审查后复用 Flutter GUI Runner 的部分实现，并保留相应的许可证和版权声明。[许可证](LICENSE) · [上游项目](https://github.com/huseyiniriss/flutter-gui-runner)
