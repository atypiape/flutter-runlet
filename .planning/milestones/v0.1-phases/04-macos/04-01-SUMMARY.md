---
phase: 04-macos
plan: "01"
subsystem: ui
tags: [swiftui, appkit, localization, macos, xctest]
requires:
  - phase: 03-flutter
    provides: 主窗和菜单栏共享调试会话、原生操作与日志遮罩
provides:
  - 通用设置语言偏好及四个场景的即时双语文案
  - 会话状态枚举与延迟解析的反馈、提示和原值插值
affects: [04-02, 04-03, 04-04, 04-05]
actuals:
  tokens: 41771
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [String Catalog, LocalizedStringResource, Observation]
key-files:
  created: [FlutterRunlet/Localizable.xcstrings]
  modified: [FlutterRunlet/FlutterRunletApp.swift, FlutterRunlet/AuxiliaryWindows.swift, FlutterRunlet/MainWindowView.swift, FlutterRunlet/MenuBarPanelView.swift, FlutterRunlet/SessionController.swift, FlutterRunlet/FlutterDebugSession.swift, FlutterRunlet/SessionProcess.swift, FlutterRunlet.xcodeproj/project.pbxproj, FlutterRunletTests/LaunchPresentationTests.swift, FlutterRunletTests/FlutterDebugSessionTests.swift]
key-decisions:
  - 应用持有一个语言偏好，注入各场景的 locale 并用于自有 AppKit 文案。
  - 会话状态使用枚举，反馈和应用错误保留资源与参数，外部文本用原值插值。
patterns-established:
  - SwiftUI 用 Text 渲染资源，AppKit 和动态纯文本用 locale.appString 解析同一资源。
  - 应用错误通过 SessionIssue(localized:) 携带待渲染资源。
requirements-completed: [UI-02]
coverage:
  - id: D1
    description: 系统语言优先顺序、英文回退、保存的偏好与应用包内 Run 文案
    requirement: UI-02
    verification:
      - kind: integration
        ref: FlutterRunletTests/LaunchPresentationTests.swift
        status: pass
    human_judgment: false
  - id: D2
    description: 在通用页切换后，原有窗口、再次打开的菜单栏面板和自有应用菜单即时更新
    requirement: UI-02
    verification:
      - kind: automated_ui
        ref: /tmp/runlet-04-01.OXLnme/four-scenes-en.ax
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-01.OXLnme/app-menu-en.ax
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-01.OXLnme/tracer-restarted.ax
        status: pass
    human_judgment: false
  - id: D3
    description: 已有会话反馈即时翻译，保留同一 VM Service、选项、工具原文和日志遮罩
    requirement: UI-02
    verification:
      - kind: integration
        ref: FlutterRunletTests/FlutterDebugSessionTests.swift#testHotOperationsWaitForCurrentFlutterResultAndKeepStopAvailable
        status: pass
      - kind: integration
        ref: FlutterRunletTests/SessionLogTests.swift
        status: pass
      - kind: integration
        ref: FlutterRunletTests/LaunchPresentationTests.swift#testLocalizedMessagesKeepDeviceAndDiagnosticArgumentsVerbatim
        status: pass
    human_judgment: false
  - id: D4
    description: 项目目录选择面板在英文应用中显示英文标题和说明
    requirement: UI-02
    verification:
      - kind: automated_ui
        ref: /tmp/runlet-04-01.OXLnme/project-panel-en.ax
        status: pass
    human_judgment: false
  - id: D5
    description: 同一最终候选在两种外观下呈现完整双语界面及应用自有 AppKit 提示
    requirement: UI-02
    verification: []
    human_judgment: true
    rationale: 04-05 复验两种外观、SDK 目录选择和实际退出提示，补齐原生视觉与交互证据。
duration: 12min
completed: 2026-11-13
status: complete
---

# Phase 04 Plan 01 · 应用语言与共享会话本地化

**通用页即时切换四个场景的中英文，共享会话保留当前 VM Service、配置与原始 CLI 输出。**

## Accomplishments

- 启动时恢复语言偏好。跟随系统按首选顺序选择英文或简体中文，未匹配时使用英文。
- 通用页切换后，现有主窗、设置、关于、重新打开的菜单栏面板及应用自有设置与关于命令更新文案。
- 会话状态、热操作、浏览器、日志和提示使用待渲染的资源。原值通过插值传入，保留路径、名称、版本及工具诊断。

## Task Commits

1. 双语运行按钮与偏好。RED `5a59e49`，GREEN `3e9909f`。
2. 原生窗口及会话反馈。RED `9e1b90d`，GREEN `a2e6ab4`。

两次 RED 均实际运行目标 XCTest。第一项因应用包语言资源目录缺失触发 `XCTUnwrap`，第二项因切换后热重载反馈仍显示中文触发等值断言。保留原始 xcresult 及日志，使用从 xcresult 转出的 JUnit 验证，两次均得到 `RED_EVIDENCE_OK`。

## 验证

- 示踪构建 `3e9909f` 的 LaunchPresentationTests 6 项通过。最终候选 `a2e6ab4` 的 LaunchPresentationTests、FlutterDebugSessionTests、SessionLogTests 共 21 项通过。原始结果见 `/tmp/runlet-04-01.OXLnme/tracer-green.xcresult` 与 `final-targeted.xcresult`。
- 原生探针在 macOS 26.7.1（25G241）、Xcode 27.1（27A9275）启动隔离重签的 Debug 副本，使用普通 App 路径。由 `ax` 探针打开设置，按 `AXPopUpButton` 的当前语言并选择目标语言，再读取原主窗和重新打开的菜单栏面板。Run 可访问名称由「运行当前调试配置」变为 “Run Current Debug Configuration”，切回并重启后保留简体中文。实际证据为 `tracer-*.ax`，构建散列与宿主记录见 `environment.txt`。
- 同一环境打开独立关于和设置，切换后既有三个窗口的标题、文案及日志辅助名称更新，重新打开菜单栏面板后看到相同语言。英文应用菜单含一个 Settings 命令和 About 命令，分别由设置与主窗场景提供。英文项目目录面板的自有标题和说明使用英文，macOS 绘制的「打开」「取消」仍用系统简体中文。证据为 `four-scenes-*.ax`、`app-menu-*.ax` 和 `project-panel-en.ax`。
- 同一测试会话中的热操作成功、失败、嵌套错误码和既有 VM Service 随语言更新。测试覆盖长名称、原样诊断、配置选择、日志原文与令牌遮罩。真实设备运行期间切换语言及两种外观补验留在 04-05。

## Deviations from Plan

- 为覆盖热操作拒绝原因和进程退出结果，提前在 SessionProcess.swift 和 FlutterDebugSession.swift 使用共享资源接口。既有会话、日志、工具链、配置及恢复测试同步改为断言语义状态或显式语言文本，保留原测试预期。
- 实测发现主窗场景添加 Settings 命令会与原生设置入口重复。改在 Settings 场景替换命令，保留原生设置窗口和 Command+逗号快捷键。最终 AX 检查确认仅出现一项。
- 配置、恢复存储和 SDK 内部错误暂通过原值适配。04-02 可将相关 SessionIssue、配置问题字段改为同一资源表示。UI-02 由共享要求门禁等待其余声明该要求的计划。

## Next Phase Readiness

04-02 可复用 `LocalizedStringResource`、`Locale.appString`、`SessionIssue(localized:)` 和 `SessionStatus`。04-05 复用 AX 探针及独立副本方式补验原生边界。
