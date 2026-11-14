# FlutterRunlet

<img src="docs/design/assets/flutterrunlet-dock-128.png" alt="FlutterRunlet 应用图标" width="72" height="72">

FlutterRunlet 是面向 macOS 的轻量 Flutter 调试工具。它读取 Flutter 项目里的 `.vscode/launch.json` 和 `.vscode/tasks.json`，可以从原生主窗口或菜单栏启动和调试 Flutter 应用。

**当前进度**　v0.1.0 已通过 G3 本地验收并归档，公开发布暂缓。最低部署目标为 macOS 15.0，实测环境为 macOS 26.7.1。macOS 15 运行兼容性未验证。[发布说明](docs/RELEASE-NOTES.md) · [本地归档](.planning/MILESTONES.md) · [v0.1 历史路线图](docs/03-ROADMAP.md)

## 使用

- 打开 Flutter 项目，从现有配置中选启动环境，再选模拟器或真机。支持选择 Flutter SDK 和使用项目的 FVM 配置。
- 按项目配置执行启动前和调试后的任务。例如，启动时切换 Firebase 环境，停止后恢复，并在恢复失败时提示重试。
- 运行、停止、热重载或热重启 Debug 会话，查看状态和日志，并在默认浏览器中打开当前会话的 Flutter DevTools 或 Inspector。
- 从原生主窗口或 macOS 菜单栏操作同一个会话。界面提供简体中文和 English，并适配系统深浅色。

在 Flutter 设置中确认 SDK 和设备工具链。打开项目后选择 Debug 配置和可用设备，点击「运行」。结束 prod 会话后，等应用确认原后置任务完成。若应用提示环境仍需恢复，打开待恢复项目并重试原任务。

配置支持范围见技术契约。Profile、Release、后台常驻任务、复杂交互任务和部分 VS Code 扩展变量会显示不可用原因。[技术契约](docs/02-TECHNICAL.md)

## 打包 macOS 预发布版

安装完整的 Xcode 后，在仓库根目录运行以下命令，即可打包 v0.1.1。

```sh
./scripts/package-release.sh v0.1.1
```

版本号也可写成 `0.1.1`，只对本次构建生效。省略版本号时，使用项目的 Release 默认版本。构建号始终取当前 Git 提交及其全部祖先的数量（`git rev-list --count HEAD`）。例如，结果为 125 时，包内 App 的版本就是 0.1.1（build 125）。浅克隆需要先用 `git fetch --unshallow` 补齐历史。

脚本以 Release 配置构建 Apple Silicon 和 Intel 双架构应用，并在 `.build/release/` 下为每次打包生成独立目录。终端会显示 DMG 和对应的 `.dmg.sha256` 文件路径。

双击 DMG，把 FlutterRunlet 拖进「应用程序」，确认能打开后，将两个文件一起上传到 GitHub Release 并勾选 **This is a pre-release**。包使用临时签名，未经 Apple 公证。首次启动若被拦截，确认来源和校验值后，可尝试在「系统设置 → 隐私与安全性」选择「仍要打开」。

## 配置示例与设计

- 示例用本地文件模拟 Firebase 环境切换，可以单独运行脚本查看结果。[VS Code 配置示例](docs/examples/sample-flutter-app/README.md)
- 查看首版功能、使用流程和配置兼容范围。[产品需求](docs/01-PRODUCT.md) · [技术契约](docs/02-TECHNICAL.md)
- 查看主窗口、菜单栏、设置与应用图标的设计。[界面规格](docs/design/UI-SPEC.md) · [设计系统](docs/design/DESIGN-SYSTEM.md)

## 许可证

本仓库采用 MIT 许可证。应用关于窗口列出 Flutter GUI Runner 的上游归属和版权。[许可证](LICENSE) · [上游项目](https://github.com/huseyiniriss/flutter-gui-runner)
