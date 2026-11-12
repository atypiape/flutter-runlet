---
phase: 02-config-task-execution-core
plan: "03"
subsystem: recovery
tags: [swift, appkit, flock, hmac]
requires:
  - phase: 02-config-task-execution-core
    provides: 02-02 的配置与任务准备、重读及偏好
provides: [待恢复项目入口, 原任务与环境指纹, 跨进程互斥, 原生退出协调]
affects: [02-04, 03, 05]
tech-stack:
  added: []
  patterns: [认证风险记录, 文件系统身份锁, AppKit 延迟退出]
key-files:
  created: [FlutterRunletTests/ProjectRecoveryTests.swift, FlutterRunletTests/ProjectConcurrencyTests.swift]
  modified: [FlutterRunlet/ProjectRecoveryStore.swift, FlutterRunlet/SessionController.swift, FlutterRunletSessionWorker/main.swift, FlutterRunlet/FlutterRunletApp.swift]
requirements-completed: [CONF-01, TASK-02, SAFE-01, SAFE-02, SAFE-03, SAFE-04]
coverage:
  - id: verified-recovery
    description: 按原项目、任务和显式环境重试
    verification:
      - kind: integration
        ref: FlutterRunletTests/ProjectRecoveryTests.swift
        status: pass
    human_judgment: false
  - id: process-lease
    description: 包装进程先退出、进程组仍活跃时保留租约
    verification:
      - kind: integration
        ref: FlutterRunletTests/ProjectConcurrencyTests.swift
        status: pass
    human_judgment: false
  - id: native-recovery
    description: 主窗和菜单栏显示恢复状态，正常退出等候收尾
    verification: []
    human_judgment: true
    rationale: 原生退出对话框及菜单栏操作由阶段末验收确认
duration: 10min
completed: 2026-11-12
status: complete
---

# 02-03 · 恢复重试、进程组互斥和退出协调

- 重启发现认证的恢复记录。用户显式打开待恢复项目后可重试原标签。记录核对规范路径和文件系统身份，任务定义和展开后的执行路径使用分域 HMAC，显式环境变更仅显示变量名。
- 首次自动后置沿用运行前快照。任务退出 0 且记录目录项清除持久化后才解除阻断。实测后置失败、定义变更、认证失败和清除同步失败均保留恢复状态。
- XCTest 使用真实包装进程和同组后代，覆盖 Stop、父控制管道关闭、目录别名、竞争恢复及切换阻断。监督进程只在能确认原组长时发信号，组长退出后继续等待进程组静止。
- 系统和菜单栏退出走同一 AppKit 委托，活动会话确认后等待 Stop 和适用后置任务。收尾失败取消该次退出。

## 验证

共享 scheme 全量 Debug XCTest 通过，共 27 项。强制终止真实 App 和原生窗口操作在 02-04 取证。
