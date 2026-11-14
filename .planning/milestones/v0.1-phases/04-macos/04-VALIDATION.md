---
phase: "04"
slug: macos
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-13"
audited: "2026-11-13"
---

# Phase 04 · 验证覆盖审计

## Test Infrastructure

沿用 XCTest、`FlutterRunletTests` 和共享 `FlutterRunlet` scheme。各任务按计划运行定向验证，波次末运行 Debug 全量。最终候选 `97a6713` 在 macOS 26.7.1、Xcode 27.1 上通过 75/75 项 XCTest，失败与跳过均为 0，Xcode 记录测试环节约 26 秒。Release 构建、资源、主程序和 worker 签名通过。审查前候选 `988ac81` 通过 74/74 项测试，其原生证据涵盖 Release 夹具隔离、真实 iOS 模拟器和完整双语深浅验收。`97a6713` 补验菜单栏设置、主窗重开及诊断输出和退出。 [候选、构建命令及原生证据](04-P4-ACCEPTANCE.md)

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-04" -parallel-testing-enabled NO test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Release -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-04" build
```

## Wave 0 Requirements

现有 scheme、测试目标和夹具均已验证。新增的关键断言随各任务完成，最终 XCTest 结果包含九个测试类。

## Per-Task Verification Map

完整命令和失败条件见对应计划。通过状态基于各波定向结果、最终全量结果与辅助功能或真实工具证据。

| 任务 | 波次 | 验收 | 威胁 | 自动验证 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 04-01-01 | 1 | A23 | — | LaunchPresentationTests · 生产资源、偏好和 Run 标签 | 通过，6/6，主窗与面板语言切换及重启均有原生证据。[04-01](04-01-SUMMARY.md) |
| 04-01-02 | 1 | A05、A23 | T-04-01 | LaunchPresentationTests、FlutterDebugSessionTests、SessionLogTests · 动态提示与原值 | 通过，21/21，覆盖既有反馈、资源插值与令牌遮罩。[04-01](04-01-SUMMARY.md) |
| 04-02-01 | 2 | A03、A21 | T-04-02 | ProjectRecoveryTests、ProjectConcurrencyTests · 共享恢复与原任务 | 通过，13/13，含原任务定义、租约及故障恢复。[04-02](04-02-SUMMARY.md) |
| 04-02-02 | 2 | A03、A05、A21 | T-04-03 | FlutterDebugSessionTests · 四键与会话动作 | 通过，9/9，原生热操作、焦点、仅面板及后台探针见最终验收。[04-02](04-02-SUMMARY.md) |
| 04-02-03 | 2 | A23 | T-04-04 | ProjectConfigurationTests、FlutterToolchainTests、ProjectRecoveryTests、FlutterDebugSessionTests · 语义错误与既有契约 | 通过，34/34，覆盖错误文案、原始配置和恢复边界。[04-02](04-02-SUMMARY.md) |
| 04-03-01 | 3 | A04 | T-04-05 | LaunchPresentationTests、ProjectSelectionTests、ProjectRecoveryTests · 启动组合与恢复优先 | 通过，21/21，原生补证仅菜单栏启动、唯一主窗与显式恢复。[04-03](04-03-SUMMARY.md) |
| 04-03-02 | 3 | A04 | T-04-06 | LaunchPresentationTests · 登录项状态、显式登记与移除、待批准和失败 | 通过。定向测试覆盖状态映射与显式操作，最终候选通过系统登录和撤销复验。 [A04](04-UAT.md)[04-03](04-03-SUMMARY.md) |
| 04-03-03 | 3 | A24、A25 | T-04-07–09 | FlutterToolchainTests、FlutterDebugSessionTests · SDK、诊断、进程和过时请求 | 通过，22/22，真实 FVM、doctor 双流、取消与重试另有原生证据。最终候选新增退出等待当前和已取消诊断的测试，原生 Quit 验证进程组及工作目录清理。[04-03](04-03-SUMMARY.md) · [审查修正复验](04-P4-ACCEPTANCE.md#审查修正复验) |
| 04-04-01 | 4 | A04、A26 | T-04-10 | LaunchPresentationTests · Bundle 元数据与固定 URL | 通过，14/14，浏览器接收三个确认地址，公开访问按阶段决定留给发布复验。[04-04](04-04-SUMMARY.md) |
| 04-04-02 | 4 | A06 | T-04-11 | Debug 构建和 Dock 源文件字节比对 | 通过，七份 PNG 字节一致，审查前候选深浅外观截图显示实际图标，最终候选包资源摘要一致。[04-04](04-04-SUMMARY.md) |
| 04-05-01 | 5 | A06、A23、A26 | — | Debug 全量、Release 构建、资源、执行位和签名 | 通过，最终候选 75/75，双包与签名通过，Release 隔离引用审查前候选实测。[04-05](04-05-SUMMARY.md) |
| 04-05-02 | 5 | A03–A06、A21、A23–A26 | T-04-12–13 | 九项矩阵结构、独立样例前后比对及最终原生／工具证据 | 通过。九项均已验收，A04 由用户完成真实跨登录复验。[最终验收](04-P4-ACCEPTANCE.md#验收矩阵) |

| 需求 | 覆盖判定 | 关键证据 |
| --- | --- | --- |
| UI-01 | 已覆盖 | FlutterDebugSessionTests、ProjectRecoveryTests、ProjectConcurrencyTests 与 A03、A05、A21。 |
| UI-02 | 已覆盖 | LaunchPresentationTests、ProjectConfigurationTests、SessionLogTests 与两语言、两外观、四界面的 A05、A23 原生证据。 |
| UI-03 | 已覆盖 | A24 实测通过，A04 的系统登录项完成用户验收。 |
| UI-04 | 已覆盖 | FlutterToolchainTests 与 A25 的真实 SDK 摘要、原文和取消重试。 |
| UI-05 | 已覆盖 | LaunchPresentationTests 与 A26 的实际版本、上游归属和浏览器委派。 |
| UI-06 | 已覆盖 | 两套包的图标文件和源资产字节验证，A06 的原生 Dock 与菜单栏截图。 |

## Manual-Only Verifications

候选 `184ffc5` 的实际登录启动与撤销已通过用户验收。最终候选通过 75 项 Debug 测试和 Release 构建。 [A04 证据](04-UAT.md)

## Validation Sign-Off

- [x] 任务命令、测试目标和阶段证据逐项核对。
- [x] Debug 全量和 Release 构建通过，产物资源和签名已检查。
- [x] 九项均已记录受测候选、证据和结果。
- [x] A04 真实登录项已在适用宿主补验。

## Validation Audit 2026-11-13

| Metric | Count |
|---|---|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |
