---
phase: 05-stability-recovery-release
plan: "03"
subsystem: testing
tags: [macos, flutter, logs, performance]
provides: [真实日志压力与 RSS 验收]
affects: [05-04, 05-05]
requirements-completed: [REL-02]
coverage:
  - id: A27
    description: 真实会话 30 分钟高低频日志、原生反馈与 RSS
    requirement: REL-02
    verification:
      - kind: e2e
        ref: "05-LOG-STRESS.md 最终候选实测及 RSS 曲线"
        status: pass
    human_judgment: false
  - id: A30
    description: 清空边界、折叠展开、新输出与严格 UTF-8
    requirement: REL-02
    verification:
      - kind: e2e
        ref: "05-LOG-STRESS.md 最终候选实测、SessionLogTests"
        status: pass
    human_judgment: false
duration: 30min
completed: 2026-11-14
status: complete
---

# Phase 05 · Plan 03 · 日志响应与内存

最终候选 `36916dd` 完整通过 A27、A30。高频约 200.51 行/秒，四项原生操作反馈低于 184 ms。RSS 基线 53.09 MiB，峰值 61.34 MiB，末段回落。复制 65,536 字节可严格按 UTF-8 解码，清空前编号在折叠再展开后没有重现。Stop 后确认进程组退出和原任务恢复。

短测和堆取证分别促成日志批量发布、VM Service 探活复用和字面编码比较。Debug 全量 77 项通过，包含新 Unicode 回归。 [日志压力证据](05-LOG-STRESS.md) · [代码审查处置](05-REVIEW-DISPOSITION.md)
