---
phase: "05"
slug: stability-recovery-release
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-13"
---

# Phase 05 · 验证策略

## Test Infrastructure

使用现有 `FlutterRunletTests` XCTest 目标及共享 scheme `FlutterRunlet`。各任务优先运行对应定向类。每波运行 Debug 全量。候选建立或替换时构建 Release 并验证实际应用包。命令从仓库根目录执行，失败、意外跳过或缺失的证据均须记录。

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-05" -parallel-testing-enabled NO -only-testing:FlutterRunletTests/ProjectRecoveryTests test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-05" -parallel-testing-enabled NO test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Release -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-05" build
```

## Sampling Rate

- 每项任务运行计划中的快速验证，变更安全或恢复行为时在相同验证中运行对应回归。
- 每波后汇总 Debug 全量结果。候选或测试环境变更后追踪需重跑的证据。A27 的 30 分钟实测独立记录起止时间。
- 最终按适用 A 编号核对提交、构建、系统、复现方法和结果，再进入 G3。

## Per-Task Verification Map

确切命令及失败信号见各计划的 `<verify>`。以最终候选 `36916dd` 的 Debug 77 项、Release 构建及签名为基线。最终候选 A27 及 A30 的 30 分钟实测已通过。

| 任务 | 波次 | 需求与验收 | 威胁 | 自动验证与补证 |
| --- | --- | --- | --- | --- |
| 05-01-01 | 1 | REL-01 · A13 | T-05-01 | Debug 全量、Release 构建、真实会话事件顺序、配置和候选摘要断言 |
| 05-01-02 | 1 | REL-01 · A15 | T-05-02 | Shell 语法、SessionLifecycleTests、同候选端到端复验 |
| 05-02-01 | 2 | REL-01 · A13–A16、A22、A28 | T-05-03 | SessionLifecycleTests、ProjectConcurrencyTests、ProjectRecoveryTests、FlutterDebugSessionTests。真实进程、环境和原生反馈补证 |
| 05-02-02 | 2 | REL-01 · A15 | T-05-04 | ProjectRecoveryTests、ProjectConcurrencyTests、SessionLifecycleTests。两个 Debug 强退点的真实重启证据 |
| 05-02-03 | 2 | REL-01 · A15 | T-05-04 | LaunchPresentationTests、每个必需场景恰有一条通过记录且含证据、真实 Release 的双偏好与强退重启 |
| 05-03-01 | 2 | REL-02 · A27、A30 | T-05-05、T-05-06 | SessionLogTests、隔离负载和日志探针的短测及失败样本 |
| 05-03-02 | 2 | REL-02 · A27、A30 | T-05-05、T-05-06 | 同候选 30 分钟探针验证时间、编号、时延、UTF-8、清空和 RSS，复核曲线 |
| 05-04-01 | 3 | REL-04 · 归档 | T-05-07 | ZIP SHA-256、解包比对、权限和签名，另测解包候选真实启动和恢复 |
| 05-04-02 | 3 | REL-03 · A29 | T-05-08、T-05-09 | ProjectConfigurationTests、授权副本双工具对照、实际 Firebase 备份和恢复证据 |
| 05-04-03 | 3 | REL-03 · A31 | T-05-07 | 两个 Mach-O 各架构最低版本、环境记录结构和候选一致性 |
| 05-05-01 | 4 | REL-04 · A26、G3 | T-05-11 | LaunchPresentationTests、实际默认浏览器、受影响界面、文档及矩阵结构 |
| 05-05-02 | 4 | REL-04 · G3 | T-05-10 | 补验后从同候选环境证据刷新 G3 的 A29、A31 行，复核同步和人工记录完整性。仅实际剩余输入和待确认项触发人工停点 |
| 05-05-03 | 4 | REL-04 · G3 | T-05-10 | 同候选环境结果一致且通过，人工项无待确认，适用矩阵全通过。同候选 ZIP 校验值、执行位和签名 |

所有任务均有通过证据。恢复见 [05-RECOVERY](05-RECOVERY.md)，日志见 [05-LOG-STRESS](05-LOG-STRESS.md)，归档与环境见 [05-ENVIRONMENT](05-ENVIRONMENT.md)，交付及界面见 [05-G3-ACCEPTANCE](05-G3-ACCEPTANCE.md)。定向配置及启动测试 22 项通过，Debug 全量 77 项通过，零跳过。

## Wave 0 Requirements

现有 XCTest 和共享 scheme 可直接运行。05-01 准备公开样例与隔离存储、可观测有界暂停及对应固定摘要验证。05-03-01 在真实 Flutter 会话短测后验证压力探针，再进行完整采样。

## Manual-Only Verifications

原生及真实设备流程优先采集可复现的自动或辅助功能证据。对覆盖不足的预期保留人工步骤，G3 仅提交新增或改变的视觉差异给用户确认。A29 的授权隔离运行已在最终候选复验。A31 经用户确认取消 macOS 15 运行验收，核对两个二进制的最低部署版本。

## Validation Sign-Off

- [x] 定向验证命令、失败信号和任务编号齐全。
- [x] 候选完成 Debug 全量、Release 构建和应用包验证。
- [x] G3 的适用预期均有通过证据，剩余视觉差异已确认。

最终签核通过。[技术调研](05-RESEARCH.md#validation-architecture) · [验收矩阵](../../../../docs/04-ACCEPTANCE.md)

## Validation Audit 2026-11-13

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
