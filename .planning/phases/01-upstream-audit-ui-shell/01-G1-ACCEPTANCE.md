# Phase 1 · G1 原生界面验收记录

2026-11-12 在 macOS 26.7.1（25G241，arm64）上验证提交 `0f5a5aee3b94abb04381e1b11bd75cbd587413e5` 的 App。Xcode 为 27.1（27A9275），构建 SDK 为 macOS 27.0。本文记录执行者实测结果，G1 用户确认由阶段末验收记录。 [验收矩阵](../../../docs/04-ACCEPTANCE.md) · [G1 界面契约](01-UI-SPEC.md)

## BASE-01 · 上游来源与许可

**通过。** 复核 Flutter GUI Runner 固定提交 `1c8468f54f1c7785aca31cfea0a5207feca30c06` 的根许可为 MIT，版权声明为 `Copyright (c) 2026 huseyiniriss`。G1 采用共享场景的架构思路，App、测试及工程均为本项目实现。实际导入清单为「无源码或资源导入」。 [固定上游审计](01-UPSTREAM-AUDIT.md)

核对 `573e93e..0f5a5ae` 的工程、源码与资源清单，逐个对比上游提交的 Git blob，未发现相同内容。两种 App 的菜单栏 1×／2× PNG 逐字节匹配本仓库的设计资产。关于窗的 SVG 同样匹配仓库资产，两个 bundle 的 `Assets.car` 均包含 `BrandGlyph`。Release 包的文件清单及链接库没有上游代码、资源或依赖，G1 分发清单没有需附带上游许可证的文件。核对记录位于 `.build/phase-01/g1-provenance.txt`。 [项目设计资源](../../../docs/design/assets/) · [上游 MIT 许可](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/LICENSE)

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

## A02 · 菜单栏快捷面板

**执行者实测通过。** 点击状态图标打开系统面板，Ready 面板外框为 **404 × 278 pt**。根视图约束宽 404 pt，左右各留 16 pt，正文可用宽度 372 pt。面板高度随内容变化。项目、配置、设备和 Ready 操作的可用性与主窗一致。点击面板「运行」弹出与主窗相同的原生提示，回车关闭后仍为 Ready。再次点击状态图标关闭面板。面板外点击子项未执行，远程窗口控制工具拒绝从面板点击其他窗口坐标。 [面板实现](../../../FlutterRunlet/MenuBarPanelView.swift)

普通 Debug 和带 `--g1-ready` 的 Release 面板均显示 Empty。项目未选择，配置与设备为「—」，无调试会话，四个调试动作与两个浏览器动作均禁用，与对应主窗状态一致。

关闭 Ready 主窗后，PID 31979 仍存活，状态图标继续可用。第一次点击「打开主窗口」建立窗口 6651，第二次聚焦同一窗口，主窗数量为一，固定示例仍为 Ready。 [01-01 主窗重开实测](01-01-SUMMARY.md#verification)

| 外观 | 截图像素 | 原生面板证据 |
| --- | --- | --- |
| 浅色 | 404 × 278 px | [Ready 面板浅色](g1/ready-menu-light.png) |
| 深色 | 404 × 278 px | [Ready 面板深色](g1/ready-menu-dark.png) |

## 设置与关于

**执行者实测通过。** 从主窗打开原生设置，首屏选中「通用」，侧栏仅有「通用」「Flutter」。点击 Flutter 再返回通用，两次选中项与右侧标题一致。从菜单栏再次打开设置，聚焦同一窗口 6655。原生外框为 **672 × 520 pt**，分隔线距左边 150 pt，G0 的侧栏参考为 142 pt。标题显示系统生成的 `FlutterRunlet Settings`，保留原生侧栏工具按钮。 [设置「通用」截图，672 × 520 px](g1/settings-general.png)

主窗标题栏打开独立 `about` 窗口 6673，外框 **440 × 480 pt**，主窗与设置仍可见。关于窗显示项目青蓝矢量标志、FlutterRunlet、版本 `0.1.0`、构建号 `1`。两个构建的 `CFBundleShortVersionString` 与 `CFBundleVersion` 均与显示值一致。项目链接交由 Phase 4 的 A26 验收。 [独立关于截图，440 × 480 px](g1/about.png) · [A26](../../../docs/04-ACCEPTANCE.md)

## 键盘焦点与 G1 用户验收

两处原生提示均可用回车关闭。重开及重复打开后，AX 焦点回到唯一主窗。主窗连续两次按 Tab 时，AX 焦点留在窗口，已观察到禁用按钮的 AX 语义。完整 Tab 焦点顺序与禁用按钮的键盘触发验证，以及点击面板外关闭，留待 G1 用户验收。 [G1 验收步骤](01-UI-SPEC.md#g1-验收)

## 长字段复验

**执行者实测通过。** 在 Xcode 27.1 的 `FlutterRunlet` 共享 scheme 和 Debug 配置中，打开主窗与面板源文件的 Live Canvas。分别运行「G1 主窗长字段」（640 pt 外宽，600 pt 正文）和「G1 菜单栏长字段」（404 × 278 pt）。在每份预览中查看项目、配置、设备三个值，并把指针依次悬停在每个值上。部分预览切换后，在目标值上停留并刷新 Live Canvas 可重新登记提示区域。 [主窗预览](../../../FlutterRunlet/MainWindowView.swift) · [面板预览](../../../FlutterRunlet/MenuBarPanelView.swift)

两份预览的三个选择字段均单行尾部省略。六个原生 Help Tag 显示各自全文，可见 `PROJECT-END`、`CONFIG-END`、`DEVICE-END`。主窗会话详情中的配置与设备各换成两行，尾段、空日志与底部状态仍可见。执行记录位于 `.build/phase-01/g1-long-fields.txt`。 [01-02 长字段实测](01-02-SUMMARY.md#verification)

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
