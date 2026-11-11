# Phase 1 · G1 原生界面验收记录

2026-11-12 在 macOS 26.7.1（25G241，arm64）上验证提交 `0f5a5aee3b94abb04381e1b11bd75cbd587413e5` 的 App。Xcode 为 27.1（27A9275），构建 SDK 为 macOS 27.0。本文记录执行者实测结果，G1 用户确认由阶段末验收记录。 [验收矩阵](../../../docs/04-ACCEPTANCE.md) · [G1 界面契约](01-UI-SPEC.md)

## A01 · 主窗口

**执行者实测通过。** 从仓库根目录执行以下命令，每次启动前退出上一轮 FlutterRunlet 实例。

| 配置与命令 | 实测结果 |
| --- | --- |
| `open -n .build/phase-01/Build/Products/Debug/FlutterRunlet.app` | Empty。项目未选择，配置与设备为「—」，无调试会话。运行禁用，日志默认展开且为空。 |
| `open -n .build/phase-01/Build/Products/Debug/FlutterRunlet.app --args --g1-ready` | Ready。项目为 `sample-flutter-app`，配置为 `sample-flutter-app(dev)`，设备为 `iPhone 17 Pro (iOS Simulator)`。 |
| `open -n .build/phase-01/Build/Products/Release/FlutterRunlet.app --args --g1-ready` | Empty。Release 下该参数没有触发演示状态。 |

Ready 主窗无侧栏。原生 AX 窗口外框为 **640 × 580 pt**，工具栏高 52 pt，其下内容区为 640 × 528 pt。正文左右各留 20 pt，可用宽度 600 pt。四个调试按钮同排，标签完整。AX 实测按钮高 24 pt，G0 画板参考为 26 pt，实际高度由原生控件确定。 [G1 视觉约定](01-UI-SPEC.md#spacing-scale)

Ready 的「运行」可用，停止、热重载、热重启、DevTools 和 Inspector 禁用。日志默认展开且为空。点击运行弹出原生「演示模式」，显示「当前为运行演示。」和「关闭提示」。回车关闭提示后，焦点回到主窗并保持 Ready。运行入口仅调用本地 `NSAlert`。 [App 场景](../../../FlutterRunlet/FlutterRunletApp.swift)

| 外观 | 截图像素 | 原生窗口证据 |
| --- | --- | --- |
| 浅色 | 640 × 580 px | [Ready 主窗浅色](g1/ready-main-light.png) |
| 深色 | 640 × 580 px | [Ready 主窗深色](g1/ready-main-dark.png) |

深色使用本机系统外观。浅色取证启动时在 `--g1-ready` 后附加 `-NSRequiresAquaSystemAppearance YES`，该参数仅用于本次 App 启动。窗口逻辑点来自 AX 与 WindowServer，截图像素由 `sips` 读取。原始操作与几何记录位于 `.build/phase-01/g1-final-ui.txt`。

## A31 · macOS 15 部署目标与 API

**通过。** 使用共享 scheme `FlutterRunlet` 清理派生构建，再执行 Debug 测试与 Release 构建。两份 App 均可执行，并在本机 26.7.1 上启动。

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath .build/phase-01 clean
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath .build/phase-01 -parallel-testing-enabled NO -only-testing:FlutterRunletTests/LaunchPresentationTests test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Release -destination 'platform=macOS' -derivedDataPath .build/phase-01 build
```

| 命令结果 | 退出码 | 墙钟耗时 | 本机日志 |
| --- | --- | --- | --- |
| 清理成功 | 0 | 1 秒 | `.build/phase-01/g1-clean.log` |
| Debug 构建与 XCTest，3 项通过 | 0 | 6 秒 | `.build/phase-01/debug-tests.log` |
| Release 构建成功 | 0 | 14 秒 | `.build/phase-01/release-build.log` |

XCTest 覆盖普通参数、完整 Debug 专用参数和相似参数。通过 `xcodebuild -showBuildSettings -json` 分别读取两个配置的唯一 App target 设置，再用 `xcrun vtool -show-build` 检查对应 App 主可执行文件的 `LC_BUILD_VERSION`。Release 的两个架构切片分别通过。命令、输出、产物路径与 SHA-256 记录在 `.build/phase-01/g1-build-evidence.txt`。

| 配置 | 产物 | 有效部署目标 | `DEBUG` | Mach-O 架构与最低版本 | Mach-O SDK |
| --- | --- | --- | --- | --- | --- |
| Debug | `.build/phase-01/Build/Products/Debug/FlutterRunlet.app` | 15.0 | 有 | arm64，`MACOS minos 15.0` | 27.0 |
| Release | `.build/phase-01/Build/Products/Release/FlutterRunlet.app` | 15.0 | 无 | x86_64、arm64 均为 `MACOS minos 15.0` | 两者均为 27.0 |

实际源码以 15.0 为目标完成两种构建。下表中的可用版本以本机 SDK 的 SwiftUI 声明、AppKit 头文件及 Apple 文档核对。

| 实际 API | macOS 可用性与路径 |
| --- | --- |
| 数据型 `WindowGroup`、`openWindow(id:value:)`、`Window`、`defaultSize` | macOS 13 起可用。固定主窗路由用于关闭后重建，独立 `about` 场景用于关于。主窗已显示时，按 AppKit 窗口标识查找并聚焦。 [WindowGroup](https://developer.apple.com/documentation/swiftui/windowgroup) · [OpenWindowAction](https://developer.apple.com/documentation/swiftui/openwindowaction) · [Window](https://developer.apple.com/documentation/swiftui/window) · [默认窗口尺寸](https://developer.apple.com/documentation/swiftui/scene/defaultsize(width:height:)) |
| `MenuBarExtra` 与 `.menuBarExtraStyle(.window)` | macOS 13 起可用。面板沿用系统结构，`NSImage`、`NSBitmapImageRep` 提供 1×／2× 模板位图。 [菜单栏样式](https://developer.apple.com/documentation/swiftui/menubarextrastyle/window) · [NSImage](https://developer.apple.com/documentation/appkit/nsimage) |
| `Settings`、`openSettings`、`NavigationSplitView`、`toolbar(removing:)` | `Settings` 自 macOS 11，`NavigationSplitView` 自 13，`openSettings` 和 `toolbar(removing:)` 自 14。标题栏和面板调用同一个 Settings 场景，系统设置命令提供原生入口。 [Settings](https://developer.apple.com/documentation/swiftui/settings) · [OpenSettingsAction](https://developer.apple.com/documentation/swiftui/opensettingsaction) · [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview) |
| `NSViewRepresentable`、`NSView.viewDidMoveToWindow()`、`NSWindow.identifier`、`makeKeyAndOrderFront` | 均可用于 macOS 15。视图挂接时标记主窗。当前主窗可见时聚焦同一实例，关闭后由 SwiftUI 场景重建。 [NSViewRepresentable](https://developer.apple.com/documentation/swiftui/nsviewrepresentable) · [NSWindow](https://developer.apple.com/documentation/appkit/nswindow) |
| `NSWorkspace.openApplication(at:configuration:completionHandler:)`、`NSAlert.runModal()`、`NSApplication.terminate` | 激活所用的 `NSWorkspace` 接口自 macOS 10.15 可用。App 在后台时，以当前 bundle URL 激活现有实例，禁止创建新实例或替换成另一安装路径。原生提示和退出调用均可用于 macOS 15。 [NSWorkspace](https://developer.apple.com/documentation/appkit/nsworkspace) · [OpenConfiguration](https://developer.apple.com/documentation/appkit/nsworkspace/openconfiguration) · [NSAlert](https://developer.apple.com/documentation/appkit/nsalert) · [NSApplication](https://developer.apple.com/documentation/appkit/nsapplication) |

## D-09 · macOS 15 实机

**未执行。** 当前没有可用的 macOS 15 环境。D-09 的例外限于 Phase 5 的该系统实机复验，适用于 A31、REL-03 和路线中的实机部分。A31 的 15.0 目标构建与 API 核查已在本轮完成，四个界面的运行证据来自 macOS 26.7.1。 [D-08、D-09](01-CONTEXT.md#macos-兼容性证据)
