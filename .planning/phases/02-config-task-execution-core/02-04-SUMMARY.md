---
phase: 02-config-task-execution-core
plan: "04"
subsystem: verification
tags: [xctest, macos, release, acceptance]
requires:
  - phase: 02-config-task-execution-core
    provides: 02-03 的受管会话与认证恢复
provides: [最终 Debug 和 Release 构建, A07–A16 和 A32 验收证据]
affects: [03, 05]
tech-stack:
  added: []
  patterns: [构建摘要与原生验收绑定]
key-files:
  created: [.planning/phases/02-config-task-execution-core/02-P2-ACCEPTANCE.md]
  modified: [FlutterRunlet/SessionController.swift, FlutterRunlet/ProjectRecoveryStore.swift, FlutterRunletTests/ProjectConcurrencyTests.swift]
key-decisions:
  - "Debug 验收根从当前 OS 用户账号读取，避免 Foundation 环境覆盖改变执行边界"
requirements-completed: [CONF-01, CONF-02, CONF-03, CONF-04, CONF-05, TASK-01, TASK-02, SAFE-01, SAFE-02, SAFE-03, SAFE-04]
coverage:
  - id: final-builds
    description: 最终 Debug XCTest、Release 构建和监督进程签名验证
    verification:
      - kind: other
        ref: .planning/phases/02-config-task-execution-core/02-P2-ACCEPTANCE.md#最终构建
        status: pass
    human_judgment: false
  - id: p2-user-acceptance
    description: 主窗、菜单栏、异常恢复和 Release 的独立用户复验
    verification: []
    human_judgment: true
    rationale: 原生界面可用性及菜单栏同步由用户确认
duration: 22min
completed: 2026-11-12
status: complete
---

# 02-04 · 构建和验收证据

- 最终 Debug 通过 32 项 XCTest。Release 构建通过，两套 App 的主程序和内嵌监督进程均可执行并通过签名检查。
- 实际 macOS 主窗验证公开 prod → test、前置部分写入、后置失败与日志外重试、调试异常退出、强制终止后发现风险、切换约束、Profile 阻断以及 Release 参数隔离。矩阵覆盖 A07–A16、A32。
- 固定根复验发现系统环境可覆盖 Foundation 提供的主目录，改为从当前 OS 用户记录取得固定根。另覆盖派发前 Stop、改名与替换项目目录、macOS 启动覆盖及另一实例已完成恢复时的状态刷新。
- 菜单栏状态项在自动桌面环境未能定位。用户阶段末 UAT 保留菜单栏与主窗同步，以及原生验收复核。

## 验证

见 [P2 验收记录](02-P2-ACCEPTANCE.md)。执行者取证和独立用户验收分别记录。
