---
phase: 04-macos
plan: "04"
subsystem: ui
tags: [swiftui, appkit, localization, asset-catalog, macos, xctest]
requires:
  - phase: 04-macos
    provides: 独立关于场景、应用双语资源及原生菜单栏模板
provides:
  - 双语关于窗口、实际构建信息、上游署名与三个固定项目链接
  - Debug 与 Release 的 macOS AppIcon 资源
affects: [04-05]
actuals:
  tokens: 3363
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [SwiftUI Link, macOS AppIcon]
key-files:
  created: [FlutterRunlet/Assets.xcassets/AppIcon.appiconset/Contents.json, FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-1024.png]
  modified: [FlutterRunlet/AuxiliaryWindows.swift, FlutterRunlet/Localizable.xcstrings, FlutterRunlet.xcodeproj/project.pbxproj, FlutterRunletTests/LaunchPresentationTests.swift]
key-decisions:
  - 上游审计记录采用独立实现，关于窗口以灵感来源呈现上游身份、版权和 MIT 许可。
  - 由 SwiftUI Link 交给默认浏览器，目标取已确认的 D-07 固定地址。
patterns-established:
  - Dock 资产编译验证同时核对实际包声明、原设计字节与系统识别结果。
requirements-completed: [UI-05, UI-06]
coverage:
  - id: D1
    description: 独立双语关于窗口、真实版本与构建号、上游身份和三个项目链接
    requirement: UI-05
    verification:
      - kind: integration
        ref: FlutterRunletTests/LaunchPresentationTests.swift#testAboutInformationUsesHostedAppBundleAndConfirmedLinks
        status: pass
      - kind: integration
        ref: FlutterRunletTests/LaunchPresentationTests.swift#testAboutWindowHasBothBundleTranslations
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-04.ev6bNN/delegation-home.txt
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-04.ev6bNN/delegation-documentation.txt
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-04.ev6bNN/delegation-license.txt
        status: pass
    human_judgment: false
  - id: D2
    description: Debug 与 Release 包含 Dock 图标和两种密度的菜单栏模板
    requirement: UI-06
    verification:
      - kind: integration
        ref: /tmp/runlet-04-04.ev6bNN/icon-bundle-verification.txt
        status: pass
      - kind: integration
        ref: /tmp/runlet-04-04.ev6bNN/dock-png-source-match.txt
        status: pass
    human_judgment: false
  - id: D3
    description: Dock 与菜单栏图标在当前 macOS 浅色和深色系统外观中清晰
    requirement: UI-06
    verification:
      - kind: manual_procedural
        ref: /tmp/runlet-04-04.ev6bNN/fresh-verified
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-11-13
status: complete
---

# Phase 04 Plan 04 · 关于窗口与原生图标

**关于窗口展示真实构建信息、上游署名与固定项目链接，Debug 和 Release 使用已验收的 Dock 图标。**

## Accomplishments

- 约 440 × 480 pt 的独立关于窗口保留品牌标志，显示当前应用包的版本与构建号。英文和简体中文均显示简述、Flutter GUI Runner 归属、版权、MIT 许可和三条项目链接。
- 七份 Dock PNG 与 G0 导出逐字节一致，覆盖 macOS 五种逻辑尺寸的 1x、2x 共十个槽。Debug、Release 都由应用目标编译。菜单栏沿用原有 18 px、36 px 单色模板及系统着色。

## Task Commits

1. 独立关于窗口及三个链接。RED `2c4d6d8`，GREEN `b1a34e2`。目标 XCTest 实际执行，因中英文目录缺少新文案，12 个等值断言均返回 `<missing>`。原始 xcresult 导出的 JUnit 通过 GSD `RED_EVIDENCE_OK`。修正后 LaunchPresentationTests 14/14。
2. Dock 图标与构建设置。`a9fda3c`。Debug、Release 构建和七份 PNG 原字节比对通过。

## 验证

- 在 macOS 26.7.1（25G241）、Xcode 27.1（27A9275）核验隔离普通 App。关于窗口 AX 外框及根内容组均为 440 × 480 pt，原生标题栏含在根组的 AX 范围内，截图中标题栏约 31 pt。主窗同时存在，关于拥有独立场景标识。中英文 AX 显示构建版本 0.1.0、构建号 1 与同一版权原文。
- 在关于窗口逐一触发三个原生 AXLink。AXPress 返回成功，系统默认 Microsoft Edge 的前台地址栏分别确认 D-07 仓库、README、LICENSE 的完整 HTTPS 目标。匿名可访问性按阶段约定由 Phase 05 复验。
- 两包的 Info.plist 均声明 AppIcon，包内含非空 AppIcon.icns、编译资产和与设计导出字节一致的 18 × 18、36 × 36 px 菜单栏模板。两包严格深度签名验证通过。Debug 的 Assets.car 确认十个 AppIcon 槽均存在。
- 首次注册的隔离 Release 副本在深浅外观均显示可辨识的青蓝 Dock 标志与清晰菜单栏 glyph。系统为 Dock 图标应用圆角和边缘高光，图标外可见的是 Dock 材质。该宿主两种外观的菜单栏仍为深色背景，glyph 由系统保持白色。关于窗口背景随系统切换。完成后已还原原先深色外观。
- 证据位于 `/tmp/runlet-04-04.ev6bNN`。关于双语 AX 为 `about-{zh,en}.ax`，默认浏览器为 `delegation-*.txt`，构建和资源为 `icon-*-build.log`、`icon-bundle-verification.txt`、`icon-assetutil.json`，有效深浅截图和 AX 边界为 `fresh-verified/`。

## Deviations from Plan

- 曾运行无图标候选的两个 bundle 标识在本机继续显示旧 Dock 占位图。通过 AXURL 确认受测 Dock 项目身份，系统图标接口对原始包返回正确资源。同一 Release 构建换首次注册的隔离标识后，实际 Dock 与系统运行图标均显示正确图案。证据保留在 `original-verified/`、`nsicon-raw.png`、`running-fresh.png` 与 `fresh-verified/`。

## Next Phase Readiness

04-05 可用相同的 AXURL 定位候选，使用首次注册的隔离标识复验系统图标，并对最终提交重跑完整测试与双构建。
