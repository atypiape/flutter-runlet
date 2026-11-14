---
phase: 05-stability-recovery-release
plan: "05"
subsystem: release
tags: [g3, macos, release, acceptance]
provides: [G3 验收, 签名 App 与 ZIP 交付, 发布说明]
requirements-completed: [REL-04]
coverage:
  - id: G3
    description: 适用验收矩阵、同候选交付及人工复核
    requirement: REL-04
    verification:
      - kind: e2e
        ref: "05-G3-ACCEPTANCE.md 与私有 g3/verify.py --seal"
        status: pass
    human_judgment: false
  - id: A26
    description: 关于窗口版本、构建、上游归属及默认浏览器
    requirement: REL-04
    verification:
      - kind: e2e
        ref: "私有 g3/about-unicode/ 和 LaunchPresentationTests"
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-11-14
status: complete
---

# Phase 05 · Plan 05 · G3 与本地交付

G3 通过。冻结候选为 `36916dd`，版本 0.1.0（1）。适用预期均已验证，原生界面对照无新增视觉差异。关于窗口三条链接实际委派给默认浏览器。最终候选复验 DevTools 和 Inspector 两轮地址绑定，项目三环境、强退恢复和 30 分钟压力证据齐全。

同一目录保留签名 App、ZIP 和 ZIP SHA-256。归档比对及解包启动恢复通过。Debug 全量 77 项和定向 22 项通过。 [G3 记录](05-G3-ACCEPTANCE.md) · [环境与归档](05-ENVIRONMENT.md) · [发布说明](../../../../docs/RELEASE-NOTES.md)
