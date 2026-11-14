---
phase: 05-stability-recovery-release
plan: "02"
subsystem: testing
tags: [macos, flutter, recovery]
provides: [16 个退出和恢复场景证据]
affects: [05-04, 05-05]
requirements-completed: [REL-01]
coverage:
  - id: REL-01
    description: 任务失败、重复运行、退出、设备断线及强退恢复
    requirement: REL-01
    verification:
      - kind: e2e
        ref: "05-RECOVERY.md 的 16 项场景及私有证据"
        status: pass
      - kind: integration
        ref: "Debug 全量 76 项，含会话、恢复、并发、工具链及启动偏好"
        status: pass
    human_judgment: false
duration: 46min
completed: 2026-11-14
status: complete
---

# Phase 05 · Plan 02 · 会话退出与恢复

[16 项恢复场景](05-RECOVERY.md)均通过。`c80ec88` 复验全部场景，`36916dd` 再次验证 A13、两个 Debug 写入边界强退和真实 Release 运行中强退。

Release 运行前在原生设置关闭两项启动偏好。终止本轮 App PID 后等待旧调试组退出，环境仍为 prod。重启时主窗自动显示待恢复项目。打开该项目后仍为 prod，手动重试原任务成功才恢复 test 并清零风险。两项 Debug 强退分别确认前置写入后尚未启动调试、后置已写入 test 但尚未确认成功。原风险在重启后仍可见。

Debug 全量 76 项通过，零跳过。记录同时关联真实模拟器、原生控件、项目锁、原任务、退出原因和恢复结果。
