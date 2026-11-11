---
phase: 01-upstream-audit-ui-shell
plan: "01"
subsystem: ui
tags: [swiftui, appkit, macos, xcode, xctest, upstream-audit]
requires: []
provides:
  - 固定上游提交的依赖、复用和许可证审计
  - Swift 6 原生 App 与 XCTest 共享 scheme
  - 唯一主窗、菜单栏及共享的 Empty 和 Debug Ready
affects: [01-02, 01-03]
actuals:
  tokens: 10602
  tasks: 3
  commits: 3
commits: 3
plan_head_before: 573e93e61d853c70b785020d5502b12c708c1c6e
plan_head_after: 1c69840dca5134504b9d598f18727fbb109c6c40
tech-stack:
  added: [SwiftUI, AppKit, XCTest]
  patterns: [数据型 WindowGroup, App 持有不可变启动状态, 双比例 NSImage template]
key-files:
  created: [01-UPSTREAM-AUDIT.md, FlutterRunlet.xcodeproj/project.pbxproj, FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme, FlutterRunlet/FlutterRunletApp.swift, FlutterRunlet/LaunchPresentation.swift, FlutterRunlet/MainWindowView.swift, FlutterRunlet/MenuBarPanelView.swift, FlutterRunletTests/LaunchPresentationTests.swift]
  modified: [.gitignore]
key-decisions:
  - "G1 采用上游的共享场景结构，App 源码与品牌资源自行实现或取自本仓库。"
  - "通过固定 SwiftUI 路由与 AppKit 主窗标识维持窗口唯一性，后台入口经 Launch Services 聚焦当前实例。"
patterns-established:
  - "Debug 专用参数在 App 初始化时解析一次，主窗和菜单栏读取同一启动呈现。"
requirements-completed: [BASE-01, BASE-02, BASE-03]
coverage:
  - id: D1
    description: 固定提交和实际导入清单
    requirement: BASE-01
    verification:
      - kind: other
        ref: 01-UPSTREAM-AUDIT.md
        status: pass
    human_judgment: false
  - id: D2
    description: Empty 与 Ready 的原生主窗、菜单栏及运行提示
    requirement: BASE-02
    verification:
      - kind: automated_ui
        ref: .build/phase-01/g1-ui-smoke.txt
        status: pass
    human_judgment: true
    rationale: G1 需用户确认原生布局与控件的可读性。
  - id: D3
    description: 启动参数精确匹配与固定示例
    requirement: BASE-02
    verification:
      - kind: unit
        ref: FlutterRunletTests/LaunchPresentationTests.swift
        status: pass
    human_judgment: false
duration: 16min
completed: 2026-11-12
status: complete
---

# Phase 1 Plan 01 · 上游审计与主窗、菜单栏

**固定提交的复用边界已核对，原生 App 可从菜单栏重开唯一主窗，两处共享 Debug Ready 与原生运行提示。**

## Performance

- 开始时间为 2026-11-12 02:46（UTC+08:00），执行耗时约 16 分钟。
- 完成 3 项任务，提交 9 个交付文件和本总结。

## Accomplishments

- 审计 Flutter GUI Runner 固定提交 `1c8468f54f1c7785aca31cfea0a5207feca30c06` 的源码、依赖、打包和 MIT 许可。G1 无源码或资源导入。 [上游审计](01-UPSTREAM-AUDIT.md)
- 原生 Xcode App 和 XCTest targets 采用 Swift 6 与 macOS 15.0 部署目标，共享 `FlutterRunlet` scheme。本地 ad-hoc 签名可启动。
- 实际 Debug App 无参数进入 Empty。加 `--g1-ready` 后，两处均显示 `sample-flutter-app`、`sample-flutter-app(dev)` 和 `iPhone 17 Pro (iOS Simulator)`。三项启动策略 XCTest 通过。
- 主窗外框实测 640 × 580 pt，四个调试按钮同排且标签完整，日志默认展开且为空。Ready 菜单栏面板实测 404 × 278 pt。两处运行提示均显示批准文案，关闭后保留 Ready。

## Task Commits

1. `65d5a7f` 审计上游并接通原生主窗与菜单栏。
2. `05083c2` 增加 Debug 就绪状态与启动测试。
3. `1c69840` 完成原生就绪界面与运行演示。

## Files Created/Modified

- `01-UPSTREAM-AUDIT.md` 记录固定提交、依赖、许可证及实际导入。
- `FlutterRunlet.xcodeproj` 提供 App、XCTest targets 和共享 scheme。
- `FlutterRunlet/FlutterRunletApp.swift` 持有状态、路由、原生提示和菜单栏模板。
- `FlutterRunlet/LaunchPresentation.swift` 和 `FlutterRunletTests/LaunchPresentationTests.swift` 定义并验证启动策略。
- `FlutterRunlet/MainWindowView.swift` 和 `FlutterRunlet/MenuBarPanelView.swift` 实现原生界面及共享字段和按钮。
- `.gitignore` 忽略本阶段构建与本地取证目录。

## Verification

- 固定 Git 对象、`Package.swift`、`LICENSE`、审计 SHA 与派生目录忽略规则均已核对。App bundle 内的 18 × 18 与 36 × 36 PNG 和仓库模板逐字节一致。
- Debug 构建成功。共享 scheme 的 `LaunchPresentationTests` 运行 3 项，0 失败。最后一次测试使用本计划最终提交的 Debug 编译条件。
- 在 macOS 26.7.1（25G241）执行 `open -n .build/phase-01/Build/Products/Debug/FlutterRunlet.app`。Empty 主窗关闭后 PID 21817 存活，状态图标和面板可打开。两次打开主窗使用同一窗口 5925。在应用隐藏并切到后台后，菜单栏入口将该窗恢复到前台并聚焦。 `.build/phase-01/g1-main-smoke.txt`
- 追加 `--args --g1-ready` 启动，主窗和菜单栏的三个 AX 字段完全一致。 `.build/phase-01/g1-ready-smoke.txt`
- 完整 Ready 界面中，两处 `NSAlert` 的标题、正文和关闭按钮可见。关闭 Ready 主窗后 PID 23369 存活，经菜单栏重开，只有窗口 6007 获焦，示例数据保留。 `.build/phase-01/g1-ui-smoke.txt`

## Decisions Made

- 采用 AppKit `NSWindow.identifier` 和 `makeKeyAndOrderFront` 定位已打开的主窗。窗口关闭时使用数据型 `WindowGroup` 的固定路由。
- 主窗与菜单栏共用 AppKit `NSAlert`。原生标题栏高度由系统确定，菜单栏高度随内容。

## Deviations from Plan

- Xcode 默认将两张同名高分辨率 PNG 合并为 TIFF。App target 设置 `COMBINE_HIDPI_IMAGES=NO` 后，实际 bundle 保留两份原始位图，字节校验通过。提交 `65d5a7f`。
- 菜单栏按钮在 App 后台时能创建主窗，单独调用 AppKit 激活请求未能在当前系统将 App 恢复前台。依据计划允许的 AppKit 路径标识主窗，并在后台使用 `NSWorkspace.openApplication` 激活同一个 bundle 的运行实例。复测同一 PID、同一已开窗口和前台焦点均通过。提交 `65d5a7f`。

## Issues Encountered

阶段前台验证采用原生状态项与窗口的可访问性信息，并通过 WindowServer 核对窗口身份与尺寸。

## Known Stubs

- `FlutterRunlet/FlutterRunletApp.swift:17` 和 `:35` 的设置、关于入口当前禁用，由 01-02 接通。
- `FlutterRunlet/MainWindowView.swift:39` 的打开项目入口当前禁用，由 Phase 2 接通。
- `FlutterRunlet/MainWindowView.swift:84`、`:120` 和 `:142` 保留空日志区与禁用的停止、热重载、热重启和浏览器入口。真实会话行为由 Phase 3 接通。

## User Setup Required

本计划可用 Xcode 共享 scheme 和本机签名直接运行。

## Next Phase Readiness

01-02 可在现有两个界面的入口接入设置和独立关于窗口。Release 实际运行、Mach-O 部署版本与六张 G1 截图由 01-03 归档。

## Self-Check: PASSED

已核对 9 个交付文件、3 个任务提交、Debug 测试与 3 份本机冒烟记录。
