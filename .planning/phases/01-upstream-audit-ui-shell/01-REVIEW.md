---
phase: 01-upstream-audit-ui-shell
reviewed: 2026-11-12T02:55:37Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - .gitignore
  - FlutterRunlet.xcodeproj/project.pbxproj
  - FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme
  - FlutterRunlet/Assets.xcassets/BrandGlyph.imageset/Contents.json
  - FlutterRunlet/Assets.xcassets/BrandGlyph.imageset/flutterrunlet-glyph.svg
  - FlutterRunlet/AuxiliaryWindows.swift
  - FlutterRunlet/FlutterRunletApp.swift
  - FlutterRunlet/LaunchPresentation.swift
  - FlutterRunlet/MainWindowView.swift
  - FlutterRunlet/MenuBarPanelView.swift
  - FlutterRunletTests/LaunchPresentationTests.swift
findings:
  critical: 0
  warning: 3
  info: 1
  total: 4
status: issues_found
---

# Phase 1 · 代码审查

## Summary

首次审查于 2026-11-11T19:36:36Z 按任务提交解析 11 个文件，核查两种构建配置、Debug 演示入口、窗口路由、资源和启动测试。未发现 Critical 问题。以下保留工程中的失效 SDK 引用、一个图标的悬停提示缺口，以及额外的 Release 测试配置限制。 [G1 验收记录](01-G1-ACCEPTANCE.md)

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Cocoa 引用绑定到当前工具链不存在的 SDK 路径

**文件** [project.pbxproj](/Users/atypiape/Develop/svame/flutter-runlet/FlutterRunlet.xcodeproj/project.pbxproj:37)

**问题** App 与 XCTest 的 Frameworks 阶段共享一条指向 `MacOSX26.0.sdk` 的引用。当前 Xcode 选用 macOS 27.0 SDK，该旧路径不存在，而两种构建的 `CopySwiftLibs` 日志仍将旧路径传入扫描。已验收的构建能成功链接，工程引用随 SDK 切换会失效。

**修复** 将 Cocoa 文件引用设为 `sourceTree = SDKROOT`，路径设为 `System/Library/Frameworks/Cocoa.framework`，使两个 target 使用各自的当前 SDK。

### WR-02: 图标式打开项目按钮缺少显式悬停提示

**文件** [MainWindowView.swift](/Users/atypiape/Develop/svame/flutter-runlet/FlutterRunlet/MainWindowView.swift:40)

**问题** 工具栏保留禁用的「打开项目」入口。其按钮名称由原生标签提供，源码仅给相邻的设置、关于按钮配置了 `.help`。G1 的图标入口契约还要求悬停说明，现有证据没有验证这个入口的提示。 [G1 图标交互约定](01-UI-SPEC.md#design-system)

**修复** 为该按钮补上 `.help("打开项目")`，保持原有禁用状态，并在原生窗口检查帮助标签。

## Info

### IN-01: 当前测试 target 只覆盖共享 scheme 的 Debug 测试配置

**文件** [LaunchPresentationTests.swift](/Users/atypiape/Develop/svame/flutter-runlet/FlutterRunletTests/LaunchPresentationTests.swift:2)

**问题** 共享 scheme 的 Test 动作选择 Debug。额外用 `swiftc -typecheck` 将现有测试链接到本轮 Release 模块时，`@testable import` 返回 `ModuleNotTestable`，与 Release 的 `ENABLE_TESTABILITY=NO` 一致。这个限制不影响 G1 的 Debug XCTest、Release 构建和实际 Release 启动核对。 [共享 scheme](/Users/atypiape/Develop/svame/flutter-runlet/FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme:25)

**修复** 若要增加自动化的 Release 行为回归，使用面向成品 App 的启动验证，直接检查 `--g1-ready` 仍进入 Empty。

_Reviewer: gsd-code-reviewer_

## 01-04 补审 · 2026-11-12

按标准深度复核 `da45b25..b3f2062` 的 `FlutterRunletApp.swift` 和 `MainWindowView.swift`，并对照最终构建、用户确认和原阶段审查。以下为新增的一项兼容性警告。 [G1 最终复验](01-G1-RETEST.md)

### WR-03: 主窗关闭通知的选择器缺少通知参数

**文件** [FlutterRunletApp.swift](../../../FlutterRunlet/FlutterRunletApp.swift#L148)

**问题** `NotificationCenter` 的选择器注册接口要求回调接收一个通知参数。当前传入无参 `windowWillClose()`。最终构建在 macOS 26.7.1 实测收到通知并完成 Dock 策略切换，用户也通过了该路径。签名与 Foundation 的文档契约仍有差异。 [Foundation 接口契约](https://developer.apple.com/documentation/foundation/notificationcenter/addobserver(_:selector:name:object:))

**修复** 让 `windowWillClose(_:)` 接收一个 `Notification`，并使注册选择器指向该签名。
