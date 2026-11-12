---
phase: "03"
slug: flutter
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| 03-01-01 | 1 | A13、A17 | T-03-01–03 | FlutterDebugSessionTests、SessionLifecycleTests、ProjectConcurrencyTests、ProjectConfigurationTests | 待运行 |
| 03-02-01 | 2 | A24 | T-03-04–05 | FlutterToolchainTests、FlutterDebugSessionTests | 待运行 |
| 03-02-02 | 2 | A17、A18 | T-03-05 | FlutterToolchainTests、ProjectSelectionTests、FlutterDebugSessionTests | 待运行 |
| 03-03-01 | 3 | A19、A21、A22 | T-03-06 | FlutterDebugSessionTests、ProjectConcurrencyTests、ProjectRecoveryTests | 待运行 |
| 03-03-02 | 3 | A20 | T-03-07–08 | FlutterDebugSessionTests | 待运行 |
| 03-03-03 | 3 | A30 | T-03-08 | SessionLogTests、ProjectSelectionTests、FlutterDebugSessionTests | 待运行 |
| 03-04-01 | 4 | G2 构建 | T-03-10 | Debug 全量 XCTest、Release 构建、App 与 worker 产物及签名检查、独立 Release 夹具隔离观察 | 待运行 |
| 03-04-02 | 4 | A13、A17–A22、A24、A30 | T-03-09–10 | 验收矩阵记录完整性，加独立 Flutter 工程与实际设备环境的行为证据 | 待运行 |

## Manual-Only Verifications

| 验收 | 真实环境证据 | 需要人工补验的条件 |
| --- | --- | --- |
| G2 构建 | 带历史 Debug 参数的 Release 仍进入普通项目模式，隔离样例与 Debug 专用存储无副作用 | 对可访问性接口无法读取的实际窗口补验 |
| A13、A17–A19、A22、A24 | 独立 Flutter 工程、实际 SDK/设备、热操作、设备断开和真实进程退出、dev/test/prod 顺序及 prod 恢复 | 对无法自动驱动的实际设备操作补验，记录环境原因 |
| A20 | 默认浏览器连当前会话、Inspector 选取 Widget、新会话更新，记录直达或回退 | 对浏览器自动化未覆盖的 Widget 选择和实际连接补验 |
| A21、A30 | 原生窗口关闭和菜单栏控制、日志清空后折叠与继续流入 | 对未能用自动交互断言的原生窗口和滚动行为补验 |

## Validation Sign-Off

- [ ] 每任务有可运行的验证命令，引用的新增测试随任务创建。
- [ ] 每波 Debug 全量通过，最终 Release 及 worker 产物核对通过。
- [ ] A13、A17–A22、A24、A30 按矩阵记录受测构建、证据和状态。
- [ ] G2 中仅未自动覆盖的实际操作待人工补验。
