---
phase: 05-stability-recovery-release
plan: "04"
subsystem: testing
tags: [release, environment, firebase, macos]
provides: [同候选归档与解包复验, 真实工程双工具对照, 最低部署目标]
affects: [05-05]
requirements-completed: [REL-03]
coverage:
  - id: A29
    description: 真实工程三环境的参数、任务顺序与恢复
    requirement: REL-03
    verification:
      - kind: e2e
        ref: "05-ENVIRONMENT.md 逐环境结果及私有原始证据"
        status: pass
    human_judgment: false
  - id: A31
    description: 最终候选的 macOS 15.0 最低部署目标
    requirement: REL-03
    verification:
      - kind: other
        ref: "05-ENVIRONMENT.md 主程序与 worker 的各架构 Mach-O"
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-11-14
status: complete
---

# Phase 05 · Plan 04 · 归档、真实环境和部署目标

最终候选 `36916dd` 的同一 ZIP 通过 SHA-256、字节、执行位及签名校验。解包后真实启动、连接当前 VM Service、停止和恢复 test，风险清零。VS Code 和最终候选的 dev、test、prod 参数及环境一致，用户授权的隔离 prod 在连接后立即停止并按原任务恢复，五项 Firebase 相关配置与 test 基线逐字节一致。原项目 16 项摘要和 Git 状态均与基线一致。

主程序与 worker 的 arm64、x86_64 最低部署目标均为 15.0。用户取消该系统的实机和虚拟机验收，运行兼容性未验证。配置及启动定向合计 22 项、Debug 全量 77 项通过。 [环境与归档记录](05-ENVIRONMENT.md)
