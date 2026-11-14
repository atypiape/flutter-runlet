---
phase: "03"
slug: flutter
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-12"
---

# Phase 03 · 验证策略

沿用 Xcode XCTest、`FlutterRunletTests` 和共享 `FlutterRunlet` scheme。每任务运行计划的 `<automated>` 指定测试类。每波运行 Debug 全量，G2 收口再构建 Release 并核对随包的 worker。冷构建与单类反馈耗时在执行阶段记录，单类迭代目标 120 秒。

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-03" -parallel-testing-enabled NO test
```

## Wave 0

复用现有测试目标、会话夹具、项目和恢复断言。每个新增测试类及隔离夹具随首次依赖它的任务创建，在 Xcode 工程登记后运行。不另行安装测试框架。

## Per-Task Verification Map

| 任务 | 波次 | 验收 | 威胁 | 自动验证（完整命令见各计划） | 状态 |
| --- | --- | --- | --- | --- | --- |
| 03-01-01 | 1 | A13、A17 | T-03-01–03 | FlutterDebugSessionTests、SessionLifecycleTests、ProjectConcurrencyTests、ProjectConfigurationTests | 通过，21/21；真实 iOS 切片见 [03-01](03-01-SUMMARY.md) |
| 03-02-01 | 2 | A24 | T-03-04–05 | FlutterToolchainTests、FlutterDebugSessionTests | 通过，6/6；实际 FVM 重检见 [03-02](03-02-SUMMARY.md) |
| 03-02-02 | 2 | A17、A18 | T-03-05 | FlutterToolchainTests、ProjectSelectionTests、FlutterDebugSessionTests | 通过，14/14；实际 iOS 启动与设备选择见 [03-02](03-02-SUMMARY.md) |
| 03-03-01 | 3 | A19、A21、A22 | T-03-06 | FlutterDebugSessionTests、ProjectConcurrencyTests、ProjectRecoveryTests | 通过，19/19；同一会话的响应、等待、断线与退出 |
| 03-03-02 | 3 | A20 | T-03-07–08 | FlutterDebugSessionTests | 通过，8/8；地址归属、重连、旧会话和 Inspector 回退 |
| 03-03-03 | 3 | A30 | T-03-08 | SessionLogTests、ProjectSelectionTests、FlutterDebugSessionTests | 通过，16/16；任务及调试输出、清空、保留和分片遮罩 |
| 03-04-01 | 4 | G2 构建 | T-03-10 | Debug 全量 XCTest、Release 构建、App 与 worker 产物及签名检查、独立 Release 夹具隔离观察 | 通过；候选 `9300b9c` 的 54/54 XCTest、双构建与签名、原生隔离检查见 [G2 构建](03-G2-ACCEPTANCE.md#候选构建) |
| 03-04-02 | 4 | A13、A17–A22、A24、A30 | T-03-09–10 | 验收矩阵记录完整性，加独立 Flutter 工程与实际设备环境的行为证据 | 通过；九项适用行为见 [G2 矩阵](03-G2-ACCEPTANCE.md#g2-验收矩阵)，无可用真机按 A18 记不适用 |

## 原生与真实环境补验

[G2 验收记录](03-G2-ACCEPTANCE.md)已收录 Release 隔离、真实 iOS／Android、FVM 修复、默认 Edge 和 Inspector Widget 选择、菜单栏共享会话、日志滚动与复制。适用行为已有自动回归或可复现的真实操作证据，无待用户重复验证的项目。

审查修正 `0416505` 增加了设备列表漏报与确认关机、实际派发失败保留日志、64 KiB 裁剪后的 AppKit 位置和选区回归。定向 23/23、全量 57/57 通过，更新候选的构建、签名和设备复验见 [G2 验收记录](03-G2-ACCEPTANCE.md)。

跨阶段回归使用 `0416505` 的同一全量 Debug 结果。Phase 01／02 的 `LaunchPresentationTests`、`ProjectConcurrencyTests`、`ProjectConfigurationTests`、`ProjectRecoveryTests`、`ProjectSelectionTests`、`SessionLifecycleTests` 均在其中通过。原始日志见 G2 证据目录的 `recheck-0416505/debug.log`。

## Validation Sign-Off

- [x] 每任务有可运行的验证命令，引用的新增测试随任务创建。
- [x] 四波 Debug 全量分别通过 36、44、54、54 项，最终 Release 及两套 worker 产物核对通过。
- [x] A13、A17–A22、A24、A30 按矩阵记录受测构建、证据和状态。
- [x] 未由 XCTest 覆盖的适用操作已在真实环境取证。

## Validation Audit 2026-11-12

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
