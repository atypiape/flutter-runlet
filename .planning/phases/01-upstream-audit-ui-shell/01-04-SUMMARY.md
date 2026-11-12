---
phase: 01-upstream-audit-ui-shell
plan: "04"
subsystem: ui
tags: [macos, swiftui, appkit, xctest, g1]
requires:
  - phase: 01-03
    provides: G1 原生界面、验收基线和两种配置的部署证据
provides:
  - 打开主窗和设置时收起菜单栏面板
  - 主窗关闭与重开时同步 Dock 运行指示
  - 禁用项目入口的原生悬停提示与两处键盘焦点复验证据
  - 同一最终 Debug Ready 构建的两项用户确认
affects: [G1, Phase 5]
actuals:
  tokens: 2490
  tasks: 3
  commits: 4
commits: 4
plan_head_before: da45b2564d7da5c75cebf8164b621405ce229478
plan_head_after: 2a3df3b67e51ee32c2f8c59deb1d39ac205fc6bb
tech-stack:
  added: []
  patterns: [原生窗口生命周期与激活策略同步, 独立 AppKit 悬停区域]
key-files:
  created:
    - .planning/phases/01-upstream-audit-ui-shell/01-G1-RETEST.md
  modified:
    - FlutterRunlet/FlutterRunletApp.swift
    - FlutterRunlet/MainWindowView.swift
key-decisions:
  - 保留系统菜单栏窗口，两个开窗入口在调用原有路由前收起面板。
  - 主窗关闭后当前进程切换为菜单栏常驻模式，重开前恢复普通激活策略。
  - 键盘焦点沿用原生机制，在系统偏好恢复同步后使用同一构建复验。
requirements-completed: [BASE-02, BASE-03]
coverage:
  - id: D1
    description: 菜单栏开窗收起、Dock 运行指示和唯一主窗恢复
    requirement: BASE-02
    verification:
      - kind: manual_procedural
        ref: .planning/phases/01-upstream-audit-ui-shell/01-G1-RETEST.md#最终用户复验
        status: pass
    human_judgment: true
    rationale: 面板收起和 Dock 指示由用户在最终构建上现场核对。
  - id: D2
    description: 主窗和菜单栏面板的双向键盘焦点，以及禁用项目入口的悬停提示
    requirement: BASE-02
    verification:
      - kind: manual_procedural
        ref: .planning/phases/01-upstream-audit-ui-shell/01-G1-RETEST.md#2026-11-12-最终确认
        status: pass
    human_judgment: true
    rationale: 用户在最终构建上确认两处焦点环可见和原生悬停文字。
  - id: D3
    description: Debug XCTest、Release 构建与 macOS 15.0 部署证据
    requirement: BASE-03
    verification:
      - kind: unit
        ref: .build/phase-01-gaps/debug-tests.log
        status: pass
      - kind: integration
        ref: .planning/phases/01-upstream-audit-ui-shell/01-G1-RETEST.md#构建
        status: pass
    human_judgment: false
duration: 31min
completed: 2026-11-12
status: complete
---

# Phase 1 Plan 04 · G1 缺口修复与复验

**菜单栏开窗后收起面板，关闭主窗后进程继续运行并更新 Dock 指示。用户在同一最终构建确认原生悬停提示及两处可见的双向键盘焦点。**

## Performance

- 2026-11-12 10:17:51 至 10:48:43（UTC+08:00）的提交跨度约 31 分钟。
- 3 项任务，4 个提交，涉及 3 个文件。

## Accomplishments

- 菜单栏的「打开主窗口」和「设置」先收起面板，再调用既有窗口路由。主窗关闭后当前进程进入菜单栏常驻模式，重开时恢复普通激活策略。
- 在禁用的「打开项目」图标上通过独立 AppKit 视图显示提示，保留按钮禁用语义与可访问名称。
- 恢复系统键盘导航偏好同步后，主窗和面板均实测 Tab、Shift-Tab 的焦点环、顺序、回绕和 Space 激活。用户在同一 Debug Ready 构建确认两项缺口通过。[G1 复验记录](01-G1-RETEST.md)

## Task Commits

1. **任务 01-04-01** `ba752d8` 收起菜单栏面板并同步 Dock 窗口状态。
2. **任务 01-04-02** `b3f2062` 恢复项目图标提示并记录构建。`e0663d2` 记录首次用户复验与原生键盘焦点。
3. **任务 01-04-03** `2a3df3b` 归档同一构建的两项最终复验。

## Files Created/Modified

- `FlutterRunlet/FlutterRunletApp.swift` 绑定面板宿主窗口，维护主窗关闭和重开时的激活策略。
- `FlutterRunlet/MainWindowView.swift` 在项目按钮区域注册原生悬停提示。
- [G1 复验记录](01-G1-RETEST.md) 保存构建 SHA-256、执行者证据与用户原话。[原始验收记录](01-UAT.md)

## Decisions Made

- 继续使用 SwiftUI `MenuBarExtra(.window)`，通过 AppKit 关闭当前面板窗口。
- 保留原生焦点路径。在系统开关重新同步后，两处键盘导航均可见并能触发可用控件。

## Verification

- Debug 的 `LaunchPresentationTests` 3 项通过，Release 构建成功。有效设置和 Mach-O 均显示最低 macOS 15.0，SDK 为 27.0。仅 Debug 有 `DEBUG` 编译条件。Release 包含 arm64 和 x86_64。
- 已对照本机文件复核 Debug 主程序、Debug 动态库和 Release 主程序的 SHA-256。两次用户复验对应同一 Debug 构建。焦点截图和自动化日志保存在 `.build/phase-01-gaps/`。[构建和最终用户确认](01-G1-RETEST.md)
- 原始 UAT 五项结果、反馈和两个缺口编号可追溯。用户确认 G-01-2 通过，确认 G-01-3 的悬停提示和主窗、面板的双向焦点可见。[原始验收记录](01-UAT.md)

## Deviations from Plan

- 当前系统为 macOS 26.7.1。D-09 的 macOS 15 实机复验未执行。面板外观与长字段预览沿用此前 G1 基线。[G1 基线](01-G1-ACCEPTANCE.md)

## Issues Encountered

- 首次用户复验时，系统设置显示键盘导航已开启，AppKit 实际读取为关闭。关闭并恢复开关后 AppKit 读取为开启。执行者和用户在同一构建上通过焦点复验。[现场记录](01-G1-RETEST.md#2026-11-12-用户复验与本机追查)

## Next Phase Readiness

G-01-2 和 G-01-3 的最终用户复验已归档，可用于 Phase 01 阶段验证。

## Self-Check: PASSED

四个任务相关提交均处于记录的提交区间内。构建日志、部署设置、Mach-O 输出、构建哈希和用户确认均可追溯。
