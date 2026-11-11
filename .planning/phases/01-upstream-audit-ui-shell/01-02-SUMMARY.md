---
phase: 01-upstream-audit-ui-shell
plan: "02"
subsystem: ui
tags: [swiftui, appkit, macos, xcode, previews]
requires:
  - phase: 01-01
    provides: 主窗、菜单栏、原生启动场景与共享演示状态
provides:
  - 原生设置及独立关于窗口
  - 两个使用生产字段视图的 Debug 长字段预览
affects: [01-03, Phase 4]
actuals:
  tokens: 3646
  tasks: 2
  commits: 2
commits: 2
plan_head_before: 3e2a97b9d259b8bc0dc2346005e6455f27a2126b
plan_head_after: 1b5fde16a2c349e655f0fcc02d870ee42f41a2e2
tech-stack:
  added: []
  patterns: [SwiftUI Settings, 独立 Window, Debug Canvas]
key-files:
  created:
    - FlutterRunlet/AuxiliaryWindows.swift
    - FlutterRunlet/Assets.xcassets/BrandGlyph.imageset/Contents.json
    - FlutterRunlet/Assets.xcassets/BrandGlyph.imageset/flutterrunlet-glyph.svg
  modified:
    - FlutterRunlet.xcodeproj/project.pbxproj
    - FlutterRunlet/FlutterRunletApp.swift
    - FlutterRunlet/LaunchPresentation.swift
    - FlutterRunlet/MainWindowView.swift
    - FlutterRunlet/MenuBarPanelView.swift
key-decisions:
  - 两个设置入口调用同一个 Settings 场景，关于窗口显示运行 bundle 的实际版本。
  - 项目、配置和设备选择字段保留单行省略，会话详情保留多行空间。
patterns-established:
  - Debug 预览复用实际界面及相同脱敏长字段值。
requirements-completed: [BASE-02]
coverage:
  - id: D1
    description: 原生设置同窗聚焦与独立关于窗口
    requirement: BASE-02
    verification:
      - kind: automated_ui
        ref: .build/phase-01/g1-aux-smoke.txt
        status: pass
    human_judgment: true
    rationale: G1 需用户确认原生布局、品牌与构建信息的可读性。
  - id: D2
    description: 两个长字段预览的单行省略、会话换行及悬停全文
    requirement: BASE-02
    verification:
      - kind: manual_procedural
        ref: .build/phase-01/g1-long-fields.txt
        status: pass
      - kind: manual_procedural
        ref: "G1 长字段预览的原生悬停提示"
        status: unknown
    human_judgment: true
    rationale: Canvas 已核对省略与换行，原生悬停仍需移动指针复验。
duration: 9min
completed: 2026-11-12
status: complete
---

# Phase 1 Plan 02 · 原生设置、关于与长字段

**主窗和菜单栏打开同一个原生设置窗口。独立关于窗口展示品牌与实际构建版本，两个 Debug 预览复现长字段溢出。**

## Performance

- 2026-11-12 03:05:24 至 03:15:10（UTC+08:00），约 9 分钟。
- 2 项任务，共 8 个实现文件。

## Accomplishments

- 设置首次显示「通用」，左侧仅列出「通用」「Flutter」，两页可以往返。
- 主窗标题栏和应用菜单的关于命令指向独立 `about` 场景。该窗口使用已验收的青蓝矢量标志，并从运行 bundle 读取版本和构建号。
- `G1 主窗长字段` 与 `G1 菜单栏长字段` 调用生产视图。项目、配置和设备固定值分别为 144、154、142 个字符，尾段分别为 `PROJECT-END`、`CONFIG-END`、`DEVICE-END`。

## Task Commits

1. **Task 1: 接通原生设置与关于窗口** - `b358708` (feat)
2. **Task 2: 增加原生界面长字段预览** - `1b5fde1` (feat)

## Files Created/Modified

- `FlutterRunlet/FlutterRunletApp.swift` 声明设置和关于场景，复用现有前台激活路径。
- `FlutterRunlet/AuxiliaryWindows.swift` 实现原生两栏设置与关于内容。
- `FlutterRunlet.xcodeproj/project.pbxproj` 注册窗口源码、品牌目录和 Debug／Release 版本元数据。
- `FlutterRunlet/Assets.xcassets/BrandGlyph.imageset` 保存本仓库标志的原样副本，编译后保留矢量表示。
- `FlutterRunlet/LaunchPresentation.swift`、`MainWindowView.swift`、`MenuBarPanelView.swift` 提供两个仅供 Debug Canvas 使用的预览及会话详情的换行。

## Verification

- 两项任务均按计划的共享 scheme 完成 Debug 构建，可执行文件存在。实际 bundle 的 `CFBundleShortVersionString` 为 `0.1.0`，`CFBundleVersion` 为 `1`。`assetutil` 确认 `BrandGlyph` 保留矢量表示，SVG 与设计资源逐字节一致。
- macOS 26.7.1（25G241）上通过 `open -n .build/phase-01/Build/Products/Debug/FlutterRunlet.app --args --g1-ready` 启动。主窗设置入口打开 672 × 520 pt 的原生窗口 6137，首次选中「通用」。实点 Flutter 再点通用，两次选择均与详情标题一致。菜单栏设置入口聚焦同一个 6137。标题栏关于入口打开独立的 440 × 480 pt 窗口 6162，主窗和设置窗仍在，品牌、`0.1.0` 与 `1` 可见。见 `.build/phase-01/g1-aux-smoke.txt`。
- Xcode 27.1 Live Canvas 中，主窗 640 pt 外部布局内的 600 pt 正文，以及 404 pt 菜单栏面板的项目、配置、设备均单行尾部省略。主窗的配置和设备会话详情各换为两行，`CONFIG-END` 与 `DEVICE-END` 可见，空日志及底部状态完整。见 `.build/phase-01/g1-long-fields.txt`。
- 生产字段将完整值绑定到原生 `help`。Canvas 点击与拖动未触发原生悬停提示，六项悬停全文仍需在 G1 UAT 复验。固定启动示例及 `--g1-ready` 解析分支沿用 01-01。

## Decisions Made

- 使用原生 Settings 及 `openSettings`。关于场景在同一 bundle 中读取构建信息，项目链接交由 Phase 4 的 A26。
- 当前系统的原生设置分隔线实测约 150 pt，设计参考为 142 pt。保留系统侧栏工具栏控件。

## Deviations from Plan

- Canvas 揭示会话详情长值被压成单行。会话区增加布局优先级，每个长值最多三行并保留其需要的垂直空间。复验时两项长值完整换行，日志仍可见。提交 `1b5fde1`。

## Issues Encountered

Live Canvas 已完成省略和会话换行观察。当前控制方式的点击与拖动无法完成真实悬停，六个字段的原生悬停提示留待 G1 UAT。

## User Setup Required

使用 Xcode 的 `FlutterRunlet` 共享 scheme 和 Debug 配置可运行两处 Canvas 预览。

## Next Phase Readiness

01-03 可采集设置、关于和主界面的最终截图，并核对 Debug、Release 及 G1 部署目标。悬停提示的人工复验随 G1 证据记录。

## Self-Check: PASSED

已核对两个任务提交、8 个实现文件、两次 Debug 构建、实际 bundle 与本机原生窗口记录。悬停验证状态单独保留为待复验。
