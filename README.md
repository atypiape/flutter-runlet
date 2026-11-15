# FlutterRunlet

<img src="docs/design/assets/flutterrunlet-dock-128.png" alt="FlutterRunlet 应用图标" width="72" height="72">

FlutterRunlet 是 macOS 上的 Flutter 调试工具。它复用项目里的 VS Code 启动配置和任务，让你从主窗口或菜单栏启动同一个 Debug 会话、查看日志、热重载和热重启。

## 获取应用

**v0.2.0 的功能已通过本地验收，公开发布暂缓。** 现有安装包可在 [GitHub Releases](https://github.com/atypiape/flutter-runlet/releases) 获取。按对应发布页的说明核对下载包后，打开 DMG，将 FlutterRunlet 拖入「应用程序」。

应用最低部署目标为 macOS 15.0，包含 Apple Silicon 和 Intel 架构。已在 Apple Silicon（macOS 26.7.1）上验证运行，macOS 15 和 Intel 实机运行尚未验证。[版本说明](docs/RELEASE-NOTES.md)

## 开始调试

以下以 v0.2.0 为准。开始前，请安装项目所需的 Flutter SDK，并准备好模拟器或真机。

1. 在「设置 → Flutter」确认 SDK 来源和版本。可以使用系统 PATH 中的 Flutter、手动选择 SDK，或优先使用项目的 FVM 配置。环境有问题时，可在这里运行诊断。
2. 打开含有 `.vscode/launch.json` 的 Flutter 项目，选一个 Debug 配置和可用设备，点击「运行」。如果配置引用了任务，也要准备好 `.vscode/tasks.json`。
3. 等调试连接建立后，即可热重载、热重启，或在浏览器中打开当前会话的 DevTools 和 Inspector。主窗口可以查看、复制和清空日志。
4. 点击「停止」，等待配置中的后置任务完成。如果提示环境需要恢复，请打开待恢复的项目，点「重试恢复」再次执行原任务。

主窗口和菜单栏共享项目和会话状态。调试中可以选择下一次运行的设备，当前会话仍留在原设备。界面支持简体中文和 English，并跟随系统深浅外观。

## 配置与更新

仅支持 Flutter Debug。Profile、Release、后台常驻任务、复杂交互任务及部分 VS Code 扩展变量不在支持范围内。FlutterRunlet 不会改写项目的配置文件；你配置的前后置任务仍会按原命令执行。可用 [VS Code 配置示例](docs/examples/sample-flutter-app/README.md) 试用环境切换与恢复流程，或查阅[配置兼容说明](docs/02-TECHNICAL.md#2-launchjson-基本契约v01)。

在「设置 → 关于」或独立的「关于」窗口，可以查看版本并手动检查更新。应用内更新仅面向符合校验要求的正式版本，预发布包需手动安装。

## 开发

想修改 FlutterRunlet、从源码运行或打包？参阅[开发者指南](docs/DEVELOPMENT.md)，其中有构建、测试和发布准备说明。

## 许可证

本仓库采用 MIT 许可证。应用关于窗口列出 Flutter GUI Runner 的上游归属和版权。[许可证](LICENSE) · [上游项目](https://github.com/huseyiniriss/flutter-gui-runner)
