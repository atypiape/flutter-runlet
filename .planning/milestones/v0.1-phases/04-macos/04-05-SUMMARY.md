---
phase: 04-macos
plan: "05"
subsystem: testing
tags: [macos, xctest, appkit, accessibility, fvm]
requires:
  - phase: 04-macos
    provides: 双语设置、原生窗口、共享会话、诊断、关于与图标
provides:
  - 同一候选的 Debug 全量、Release 构建及应用包验证
  - 九项原生验收、设置窗标题修复与登录项剩余步骤
affects: [05-stability]
actuals:
  tokens: 1910
  tasks: 2
  commits: 2
  plan_head_before: 67a6270eb43bfd7a9e7cd4babaec7aea795834fd
  plan_head_after: 803d48a
tech-stack:
  added: []
  patterns: [XCTest, macOS Accessibility, 签名产物检查]
key-files:
  created: [.planning/milestones/v0.1-phases/04-macos/04-P4-ACCEPTANCE.md]
  modified: [FlutterRunlet/AuxiliaryWindows.swift]
key-decisions:
  - 设置详情沿用 SwiftUI 导航标题传播，保持两个分类的窗口标题与应用语言一致。
  - 用隔离候选复验实际会话、双语布局、品牌与 Release 夹具隔离。
patterns-established:
  - 对实际签名包、原生辅助功能树、截图及独立 Flutter 样例分别记录受测提交。
requirements-completed: [UI-01, UI-02, UI-03, UI-04, UI-05, UI-06]
coverage:
  - id: D1
    description: 最终候选通过回归、资源和签名检查，Release 历史参数隔离由审查前候选原生验证。
    verification:
      - kind: integration
        ref: /tmp/runlet-04-review-final.9Zc6wM/debug.xcresult
        status: pass
      - kind: other
        ref: /tmp/runlet-04-review-final.9Zc6wM/package.txt
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-05.VMZlFG/release-isolation-result.txt
        status: pass
    human_judgment: false
  - id: D2
    description: A03、A05、A06、A21、A23 至 A26 的原生行为及构建证据。
    verification:
      - kind: automated_ui
        ref: .planning/milestones/v0.1-phases/04-macos/04-P4-ACCEPTANCE.md
        status: pass
    human_judgment: false
  - id: D3
    description: A04 设置和启动行为的真实系统登录项补验。
    requirement: UI-03
    verification: []
    human_judgment: true
    rationale: 本机隔离重签候选返回 notFound，需要在可登记登录项及可注销的隔离用户中验证实际注册、批准、重新登录和移除。
  - id: D4
    description: 审查修正后从菜单栏打开设置保持 accessory，明确重开仅一扇主窗，退出清理诊断进程和目录。
    verification:
      - kind: automated_ui
        ref: /tmp/runlet-04-review-final.9Zc6wM/settings-only.txt
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-review-final.9Zc6wM/doctor-menu-quit.txt
        status: pass
    human_judgment: false
duration: 19min
completed: 2026-11-13
status: complete
---

# Phase 04 Plan 05 · 同一候选构建与原生验收

**最终候选 `97a6713` 通过 75 项 Debug 测试、Release 构建及审查修正复验。原生验收八项通过，实际系统登录项待适用环境补验。**

## Accomplishments

- 两套 App 均验证实际图标、菜单栏单色模板、编译语言资源、主程序与嵌入 worker 执行位及签名。Release 历史参数进入普通项目，固定 Debug 夹具和独立样例基线的文件摘要不变。
- 审查前候选 `988ac81` 的证据覆盖真实 iOS 模拟器、FVM 会话、快捷键、故障恢复、真实 doctor 和两语言两外观截图。审查后用 `97a6713` 复验菜单栏设置、显式主窗重开、诊断退出和双流 12 pt 等宽输出。
- 验收矩阵覆盖九项，A04 的实际登录项保留阻塞及补验步骤。其他八项在本阶段范围内通过。 [验收记录](04-P4-ACCEPTANCE.md)

## Task Commits

- `988ac81` 修复设置窗口标题在 Flutter 页面切回系统语言。
- `803d48a` 记录最终构建、原生交互、已知差异及剩余验收。
- `db71cc6` 复现退出时诊断进程未回收。
- `97a6713` 退出等待诊断收尾，菜单栏设置保持独立，完整诊断输出使用 12 pt 等宽字体。

## Deviations from Plan

- 首次原生复验发现英文设置窗口在切到 Flutter 页后出现中文系统标题。设置详情采用当前应用语言的导航标题，并补验两个页面往返及两语言、两外观。之后按审查修复退出收尾、设置激活及诊断字体，重跑双构建及受影响原生路径。
- 真实登录项在临时目录和用户 Applications 中的隔离重签候选均返回 `notFound`。用现有 XCTest 验证状态与写入边界，保留适用环境中的实际登录动作。

## Self-Check: PASSED

九项均有矩阵行，所有自动构建和包检查通过。两个任务提交和产物均存在。阶段验收结论仍等待 GSD 验证及实际登录项。
