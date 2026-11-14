---
phase: 01-upstream-audit-ui-shell
plan: "03"
subsystem: ui
tags: [macos, xcode, xctest, appkit, g1]
requires:
  - phase: 01-01
    provides: 固定上游审计、主窗和菜单栏及 Debug 演示入口
  - phase: 01-02
    provides: 原生设置、独立关于和长字段预览
provides:
  - G1 验收记录和六张实际 App 窗口截图
  - Debug 与 Release 的 macOS 15.0 构建证据
affects: [G1, Phase 5]
actuals:
  tokens: 2016
  tasks: 2
  commits: 2
commits: 2
plan_head_before: 0f5a5aee3b94abb04381e1b11bd75cbd587413e5
plan_head_after: 9b574e6c965e7f24afa3970faa3f16742f8791e5
tech-stack:
  added: []
  patterns: [实际产物 LC_BUILD_VERSION 核查, 原生窗口逻辑点与 PNG 像素分别记录]
key-files:
  created:
    - .planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-G1-ACCEPTANCE.md
    - .planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/g1/ready-main-light.png
    - .planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/g1/ready-main-dark.png
    - .planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/g1/ready-menu-light.png
    - .planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/g1/ready-menu-dark.png
    - .planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/g1/settings-general.png
    - .planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/g1/about.png
  modified: []
key-decisions:
  - 浅色证据使用仅影响本次 App 启动的外观参数。
  - macOS 15 部署目标构建与当前系统实测分别记录，D-09 仅适用于实机复验。
requirements-completed: [BASE-01, BASE-02, BASE-03]
coverage:
  - id: D1
    description: 固定提交的上游许可、工程资产和 Release 包来源核对
    requirement: BASE-01
    verification:
      - kind: integration
        ref: .build/phase-01/g1-provenance.txt
        status: pass
    human_judgment: false
  - id: D2
    description: 四个原生界面、Ready 交互、六张截图和长字段实测
    requirement: BASE-02
    verification:
      - kind: manual_procedural
        ref: .planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-G1-ACCEPTANCE.md
        status: pass
    human_judgment: true
    rationale: G1 需要用户确认原生视觉、完整键盘焦点顺序及面板外关闭行为。
  - id: D3
    description: 两种构建配置的有效部署目标、实际 Mach-O 及 API 兼容性
    requirement: BASE-03
    verification:
      - kind: integration
        ref: .build/phase-01/g1-build-evidence.txt
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-11-12
status: complete
---

# Phase 1 Plan 03 · G1 原生界面与部署证据

**四个原生界面已在 macOS 26.7.1 实测并归档六张窗口截图，两种 App 的实际 Mach-O 最低版本均为 15.0。**

## Performance

- 2026-11-12 03:23 至 03:31（UTC+08:00），约 8 分钟。
- 2 项任务，共 7 个验收文件。

## Accomplishments

- 清理后执行 3 项 Debug XCTest 和 Release 构建，全部通过。Debug arm64 与 Release 的 x86_64、arm64 切片均为 `MACOS minos 15.0 sdk 27.0`。
- 实测 Debug 普通启动及带演示参数的 Release 均为 Empty。Debug Ready 在两处共享固定数据，两处原生提示可关闭，重开和重复打开时保持唯一主窗。
- 归档 640 × 580 pt 主窗及 404 pt 菜单栏面板的深浅截图、672 × 520 pt 的通用设置和 440 × 480 pt 的独立关于。记录原生按钮高度和设置侧栏分隔线的实际值。
- 复核上游实际采用结果、项目内品牌资产及 Release 包。汇入六处长字段的单行省略和原生悬停全文记录。

## Task Commits

1. **Task 1: 验证两种配置并归档主窗证据** - `5593c17` (docs)
2. **Task 2: 补齐菜单栏、设置与关于的 G1 证据** - `9b574e6` (docs)

## Files Created/Modified

- [G1 原生界面验收记录](01-G1-ACCEPTANCE.md) 汇总 BASE-01、A01、A02、A31、设置与关于，以及 D-09 的适用范围。
- `g1/` 归档六张实际窗口 PNG。每张均按原生窗口编号采集，像素尺寸由 `sips` 验证。

## Verification

- Debug XCTest 退出 0，用时 6 秒，3 项通过。Release 构建退出 0，用时 14 秒。两种 App 可执行。有效 App target、`DEBUG` 条件、Mach-O 和证据产物 SHA-256 已核对。
- 本轮原生操作、尺寸、进程存活及窗口编号见 `.build/phase-01/g1-final-ui.txt`。六张截图逐张打开检查，仅含 App 窗口和固定示例。
- 已核对实际 Git 改动与上游清单。没有引入上游源码、资源或依赖。许可取证见 `.build/phase-01/g1-provenance.txt`。

## Deviations from Plan

- 本轮已验证重开后的 AX 主窗焦点、两处原生提示的回车关闭及禁用按钮的 AX 语义。远程工具下，主窗两次 Tab 的 AX 焦点都留在窗口，面板外点击受工具限制。完整 Tab 顺序、禁用按钮的键盘触发与面板外关闭交由 G1 人工验收。
- macOS 15 实机未执行，当前缺少可用环境。按 D-09，仅 Phase 5 的该系统实机复验适用例外。

## Threat Flags

无新增。两种配置均采纳本轮成功构建的产物。截图只保留 App 窗口，所示项目、配置及设备值为脱敏固定示例。

## Next Phase Readiness

阶段验证可使用本轮构建、实测和截图。G1 用户确认仍待阶段末验收。

## Self-Check: PASSED

已验证两个任务提交的七个路径与计划一致，文档和六张 PNG 均存在。两种构建、Mach-O、原生操作及上游核对记录可追溯。
