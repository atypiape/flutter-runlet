---
phase: 04-macos
reviewed: 2026-11-13T05:57:53Z
rechecked: 2026-11-13T06:01:24Z
rechecked_commit: 97a6713d3a65d3d49fbad2012e26bff3c40266d3
depth: standard
files_reviewed: 30
files_reviewed_list:
  - FlutterRunlet.xcodeproj/project.pbxproj
  - FlutterRunlet/Assets.xcassets/AppIcon.appiconset/Contents.json
  - FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-1024.png
  - FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-128.png
  - FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-16.png
  - FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-256.png
  - FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-32.png
  - FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-512.png
  - FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-64.png
  - FlutterRunlet/AuxiliaryWindows.swift
  - FlutterRunlet/FlutterDebugSession.swift
  - FlutterRunlet/FlutterRunletApp.swift
  - FlutterRunlet/FlutterToolchain.swift
  - FlutterRunlet/JSONCReader.swift
  - FlutterRunlet/Localizable.xcstrings
  - FlutterRunlet/MainWindowView.swift
  - FlutterRunlet/MenuBarPanelView.swift
  - FlutterRunlet/ProjectConfiguration.swift
  - FlutterRunlet/ProjectRecoveryStore.swift
  - FlutterRunlet/SessionController.swift
  - FlutterRunlet/SessionProcess.swift
  - FlutterRunletTests/FlutterDebugSessionTests.swift
  - FlutterRunletTests/FlutterToolchainTests.swift
  - FlutterRunletTests/LaunchPresentationTests.swift
  - FlutterRunletTests/ProjectConcurrencyTests.swift
  - FlutterRunletTests/ProjectConfigurationTests.swift
  - FlutterRunletTests/ProjectRecoveryTests.swift
  - FlutterRunletTests/ProjectSelectionTests.swift
  - FlutterRunletTests/SessionLifecycleTests.swift
  - FlutterRunletTests/SessionLogTests.swift
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 04 · 代码审查

审查 `15dad44..988ac81` 的 App、测试、资源及 Xcode 工程变更。部署目标是 macOS 15.0。SwiftUI 启动和恢复控制在 SDK 接口中标为 macOS 15 可用，诊断工作目录的 macOS 26 POSIX API 有可用性分支。原生复验使用 macOS 26.7.1 的隔离候选。

## 定向复审

修复候选为 `97a6713`，含回归测试提交 `db71cc6`。两项原始 Warning 已关闭。本次定向复审未发现新增问题。候选 Debug XCTest 75/75 通过，无失败或跳过。原始结果位于 `/tmp/runlet-wave5-review.UdXPxN/tests.xcresult`。

- **WR-01 已关闭。** 允许退出但诊断尚未完成时，应用委派延迟退出。控制器保留当前及已取消诊断的句柄，取消并等待它们完成，再按现有会话与恢复条件回复。复审确认等待期间禁止新的诊断和调试启动。回归测试覆盖正在执行、刷新时已取消两种情形，均验证诊断主进程已回收、临时目录已删除。见 `FlutterRunlet/FlutterRunletApp.swift:498-517`、`FlutterRunlet/SessionController.swift:632-659`、`FlutterRunlet/SessionController.swift:968-976`、`FlutterRunletTests/FlutterToolchainTests.swift:126-164`。
- **WR-02 已关闭。** 设置入口用 AppKit 激活当前应用。SDK 头文件标明该 API 支持 macOS 14.0 及以上。隔离候选从仅菜单栏状态打开设置后仍为 accessory、0 个主窗，辅助功能树确认设置窗已获得焦点。显式重开后为 regular、1 个主窗，重复重开仍是 1 个。见 `FlutterRunlet/FlutterRunletApp.swift:281-284` 和 `/tmp/runlet-settings-fix.RQdYDW/{before,settings-only,explicit-reopen,repeated-reopen}.txt`、`settings.ax`。

## Narrative Findings (AI reviewer)

以下保留候选 `988ac81` 的两条历史 Warning 和当时的源文件行号。

### WR-01 · 退出应用前回收进行中的 Flutter 环境检测

**File:** `FlutterRunlet/FlutterRunletApp.swift:498-501`

**Issue:** 通用退出判定允许空闲会话立即退出。`FlutterRunlet/SessionController.swift:123` 未考虑正在执行的 doctor，`FlutterRunlet/FlutterToolchain.swift:440-469` 使用独立进程组启动诊断，只有 App 内部执行的 defer 才会在中止时发信号并回收。诊断中选择退出会直接终止 App。已启动的 Flutter 和工具子进程可能继续运行，诊断临时目录失去清理路径。

**Fix:** 保留现有会话与恢复阻断条件。当退出条件已满足且有活动诊断时返回 `.terminateLater`，请求取消并等待诊断进程组回收及临时目录清理后回复退出。`FlutterRunlet/SessionController.swift:651-656` 目前在取消后立即丢弃任务句柄。切换项目或 SDK 期间取消的诊断也应跟踪到实际收尾。补充活动诊断退出及切换后立即退出的回归。

### WR-02 · 从独立菜单栏打开设置时保留主窗关闭状态

**File:** `FlutterRunlet/FlutterRunletApp.swift:281-284`

**Issue:** Settings 菜单栏操作会关闭面板并进入 `showSettings()`。如果应用不活跃，`FlutterRunlet/FlutterRunletApp.swift:301-313` 通过 Launch Services 打开同一个 App。新增的 reopen 委派（`FlutterRunlet/FlutterRunletApp.swift:487-490`）将该内部激活处理为显式重开，从而打开主窗并恢复 Dock 图标。在关闭「启动后显示主窗口」的隔离候选中，以 Finder 为前台，点击菜单栏 Settings。原生状态由 accessory、0 个主窗变为 regular、1 个主窗及设置窗。证据见 `/tmp/runlet-04-review.COUxPE/settings-accessory-{before,after}.txt`。

**Fix:** 设置路径只前置并激活目标窗口，避免向 reopen 委派发出语义为「打开主窗」的请求。保留独立的「打开主窗口」和用户显式 Launch Services 重开。复测从 accessory 状态分别点击设置、打开主窗及重复重开。
