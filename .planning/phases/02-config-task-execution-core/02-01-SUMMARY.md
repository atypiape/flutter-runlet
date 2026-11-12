---
phase: 02-config-task-execution-core
plan: "01"
subsystem: session
tags: [swift, macos, process, recovery]
requires:
  - phase: 01-upstream-audit-ui-shell
    provides: 原生主窗与菜单栏
provides: [受管任务与调试进程, 持久恢复记录, Debug 验收装配]
affects: [02-02, 02-03, 03]
tech-stack:
  added: []
  patterns: [共享会话, 继承的项目租约, 文件与目录项持久提交]
key-files:
  created: [FlutterRunlet/SessionController.swift, FlutterRunlet/SessionProcess.swift, FlutterRunlet/ProjectRecoveryStore.swift, FlutterRunlet/ProjectConfiguration.swift, FlutterRunletSessionWorker/main.swift, FlutterRunletTests/SessionLifecycleTests.swift]
  modified: [FlutterRunlet.xcodeproj/project.pbxproj, FlutterRunlet/FlutterRunletApp.swift, FlutterRunlet/MainWindowView.swift, FlutterRunlet/MenuBarPanelView.swift]
requirements-completed: [CONF-01, CONF-02, CONF-03, CONF-05, TASK-01, TASK-02, SAFE-01, SAFE-02, SAFE-04]
coverage:
  - id: session-lifecycle
    description: 公开样例的持久记录、真实前后置任务及受管进程顺序
    verification:
      - kind: integration
        ref: FlutterRunletTests/SessionLifecycleTests.swift
        status: pass
    human_judgment: false
  - id: native-fixture
    description: 主窗与菜单栏共用隔离验收会话
    verification: []
    human_judgment: true
    rationale: 原生窗口和菜单栏操作在 02-04 验收
duration: 10min
completed: 2026-11-12
status: complete
---

# 02-01 · 贯通公开样例的受管会话

- Debug 验收启动使用固定 App Support 目录，选择项目、配置和 Run 均使用共享控制器。受管进程使用内嵌且签名的监督进程。
- 监督进程继承项目锁，通过管道取得命令和停止请求。实际退出并确认进程组静止后才返回结果。测试复现 prod、Stop 和 test，校验配置字节保持原样。
- 前置或仅后置配置的调试进程启动前验证记录数据和目录项同步。独立注入文件同步、目录同步失败均观察到零进程执行。前置部分写入、仅后置及调试启动失败有单独的真实进程测试。
- 首轮回归定位到 macOS 临时目录别名导致的路径差异，统一解析后通过。验收装配还校验公开脚本内容、状态文件类型及目录权限。

## 验证

共享 scheme 全量 Debug XCTest 通过，共 10 项。主要提交为 `8011f43`、`0704336`、`1ab86f3`。主窗及菜单栏的实际操作在 02-04 取证。
