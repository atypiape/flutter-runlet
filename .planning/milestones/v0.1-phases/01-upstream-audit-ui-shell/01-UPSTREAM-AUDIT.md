# Phase 1 · Flutter GUI Runner 上游审计

固定提交 `1c8468f54f1c7785aca31cfea0a5207feca30c06`。在独立的本地 Git 仓库取回该提交，通过 `git ls-tree` 和 `git show` 核对 Swift 源码、包清单、许可证、打包脚本和发布工作流。审计只读取文件。 [固定提交](https://github.com/huseyiniriss/flutter-gui-runner/tree/1c8468f54f1c7785aca31cfea0a5207feca30c06)

## 源码与依赖

| 类别 | 固定提交中的证据 |
| --- | --- |
| SwiftPM | `Package.swift` 声明 Swift tools 6.0、macOS 14 和单个 `FlutterRunner` 可执行 target，未声明第三方包。 [包清单](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Package.swift#L1-L13) |
| 系统框架 | SwiftUI 提供窗口和菜单栏场景。AppKit 提供应用激活、日志文本视图和浏览器入口。Foundation 提供进程、管道、文件和 JSON 解码。 [App 入口](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/FlutterRunnerApp.swift#L1-L36) · [进程和日志](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/AppModel.swift#L911-L1089) |
| 运行时外部工具 | `Process` 以登录 `/bin/zsh` 调用 Flutter SDK 或 shell 命令，Git 操作也经 shell。Flutter 提供设备、模拟器、调试和构建命令。 [Git 操作](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/AppModel.swift#L319-L348) · [设备和模拟器](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/AppModel.swift#L505-L554) · [Flutter 进程](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/AppModel.swift#L1033-L1041) |
| 构建及发布工具 | `build-app.sh` 用 `swift build` 生成可执行文件，复制图标、写入 Info.plist 并尝试本地签名。`scripts/make-dmg.sh` 用 `hdiutil` 打包。`scripts/make-icon.swift` 用 AppKit 生成图标。发布工作流在 macOS 15 使用 `actions/checkout@v4`、`actions/upload-artifact@v4` 和 `softprops/action-gh-release@v2`。 [App 打包](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/build-app.sh) · [DMG](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/scripts/make-dmg.sh) · [图标脚本](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/scripts/make-icon.swift) · [发布工作流](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/.github/workflows/release.yml#L14-L39) |

## 复用边界

| 区域 | 采用决定及理由 |
| --- | --- |
| 共享场景 | 采用 App 持有状态、主窗和菜单栏共同呈现的结构，独立实现。上游在主窗初始化时扫描项目、SDK 和 Flutter，通过第一个可成为主窗的窗口定位重开目标。G1 以固定启动状态和场景值实现无扫描、可定位的唯一主窗。 [场景](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/FlutterRunnerApp.swift#L11-L36) · [初始化](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/AppModel.swift#L146-L167) · [重开](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/ContentView.swift#L334-L341) |
| 设备发现 | G1 使用固定模拟器数据。上游以 `flutter devices --machine` 读取设备并恢复选择，后续接入时可评估解码和设备筛选，并验证命令退出状态与本项目 SDK 选择。 [发现](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/AppModel.swift#L505-L524) · [设备模型](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/Device.swift#L4-L29) |
| 进程控制 | G1 Run 只显示原生演示提示。上游以 `--pid-file` 定位调试进程，使用 SIGUSR1／SIGUSR2 执行热操作。该路径可供 Phase 3 评估，届时验证 PID 归属、退出状态、任务与环境恢复。 [Run、Stop 和热操作](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/AppModel.swift#L661-L717) |
| 日志 | G1 呈现默认展开的空日志结构。上游批次刷新、限制保留文本长度，并用只读 `NSTextView` 渲染。Phase 3 可评估流式输出和滚动表现，需单独验证清空与新输出的交互。 [批次与限长](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/AppModel.swift#L1054-L1089) · [日志控件](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/LogTextView.swift#L7-L38) |
| DevTools | G1 浏览器入口禁用。上游从日志提取 DevTools URL 并用 `NSWorkspace` 打开系统浏览器，同时将完整 URL 写入日志。Phase 3 接入时应按本项目契约限定当前 VM Service、重启后的 URL 和日志暴露范围。 [URL 提取](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/AppModel.swift#L1082-L1088) · [浏览器入口](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/AppModel.swift#L1134-L1143) |
| 其他入口 | G1 排除上游主窗侧栏及其模拟器管理、构建与签名、Git、包管理、SDK 工具、Doctor 和自定义参数入口，也排除菜单栏的 Build／Tools 菜单及 Profile、Release 运行模式。G1 使用已验收的主窗与面板结构。后续配置和 SDK 功能按 FlutterRunlet 自身契约实现。 [侧栏](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/MainWindow.swift#L5-L49) · [菜单栏](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/ContentView.swift#L285-L330) · [运行模式](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/Device.swift#L31-L43) |

## 许可证与实际导入

上游根许可证为 MIT，版权为 `Copyright (c) 2026 huseyiniriss`。后续导入上游代码或资源前，先登记原路径及提交，并随实际纳入的文件及分发包保留完整上游许可证和版权声明。上游 App／DMG 脚本只复制可执行文件、图标和 App 包，无法作为许可随包分发的证据。 [上游许可证](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/LICENSE) · [技术契约](../../../../docs/02-TECHNICAL.md#1-架构原则)

G1 实际导入清单为「无源码或资源导入」。原生骨架由 FlutterRunlet 自行实现，菜单栏位图使用本仓库已验收的同源模板。上游图标、脚本、构建工作流与依赖均未纳入 App。 [菜单栏资产](../../../../docs/design/assets/) · [G1 界面契约](01-UI-SPEC.md)
