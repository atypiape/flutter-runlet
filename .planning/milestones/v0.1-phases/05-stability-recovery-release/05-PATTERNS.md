# Phase 05 · 现有实现与取证参照

**日期** 2026-11-13

## File Classification

| 计划中的文件或产物 | 角色 | 数据流 | 最接近的现有参照 |
| --- | --- | --- | --- |
| `docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh`、`FlutterRunlet/ProjectConfiguration.swift` | 验收脚本、输入校验 | 文件写入、受限任务 | 现有故障标记及 `ProjectLocation.validateFixtureTask`，原位复用 |
| `FlutterRunletTests/SessionLifecycleTests.swift` | 生命周期回归测试 | 事件驱动、文件断言 | `SessionFixture` 与 `testFixtureRootRunsPublicSampleAndRejectsModifiedScriptAndLinkedState`，原位复用 |
| 生命周期及强退验收记录 | 验收证据 | 会话事件、进程和磁盘状态 | Phase 02 P2 验收、Phase 04 恢复入口验收 |
| 隔离样例的日志负载与验收记录 | 验收脚本、证据 | 真实 Flutter 日志流、定时采样 | Phase 03 G2 真实调试、`SessionLogTests` 的边界断言 |
| A29、A31 验收记录 | 验收证据 | 双工具逐环境对照、目标系统交互 | 公开样例设置方法、Phase 01 最低目标取证、Phase 04 原生窗口取证 |
| G3 本地交付、发布说明与验收记录 | Release 归档、文档 | 构建、签名核验、压缩和解包、矩阵汇总 | Phase 04 同源 Debug/Release 核验及逐条验收表 |

## Pattern Assignments

### Debug 夹具与摘要

公开脚本在 `fail-before-$environment` 检查之后执行 `printf '%s\n' "$environment" > "$state_dir/firebase-environment"`，随后检查 `fail-after-$environment`。以既有 `.runlet-fixture` 标记扩展有界暂停及就绪信号，维持失败优先级与无标记行为。`ProjectLocation.validateFixtureTask` 严格校验 `/bin/sh`、固定相对脚本、三项实参、项目 cwd 及 `fixtureScriptDigest`，并复验状态文件为当前用户所有的普通单链接文件。脚本和摘要同一改动更新。 [公开脚本](../../../../docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh#L12) · [固定任务校验](../../../../FlutterRunlet/ProjectConfiguration.swift#L26)

`SessionController.fixtureEnabled(arguments:)` 通过 `#if DEBUG` 和精确 `--phase-02-fixture` 选择隔离项目、偏好与存储。既有 `SessionFixture.state(_:)`、`marker()` 可用于检查暂停信号和环境内容。定向回归复用正常恢复 `XCTAssertEqual(try fixture.marker(), "test\n")`、风险为空、篡改脚本禁止 Run 及链接状态拒绝断言。 [隔离入口](../../../../FlutterRunlet/SessionController.swift#L288) · [夹具测试](../../../../FlutterRunletTests/SessionLifecycleTests.swift#L137)

### 生命周期、重启与退出

`SessionController.restore` 在持有 `ProjectLease` 时验证项目和原任务，`guard result == .exited(0)` 通过后才调用 `store.remove(record, lease: lease)` 并清除内存风险。`ProjectRecoveryStore.remove` 校验预期记录并持久化完成凭据。worker 先等受管组清空才返回退出结果，控制管道关闭时执行现有进程组清理。以该顺序核对每个强退点的进程、文件及重启证据。 [恢复实现](../../../../FlutterRunlet/SessionController.swift#L1071) · [存储实现](../../../../FlutterRunlet/ProjectRecoveryStore.swift#L122) · [worker](../../../../FlutterRunletSessionWorker/main.swift#L41)

`SessionController.recoveryAction` 按当前项目返回 `.openProject` 或 `.retry`。`testMainWindowLaunchPreferencePersistsAndRecoveryTakesPriority` 覆盖持久偏好和风险优先，Phase 04 的 `pending-recovery-at-launch.ax` 提供真实界面类比。`FlutterRunletApp` 的退出委托使用 `.terminateLater` 和 `finishForTermination()`，取消和恢复失败分别覆盖。关键回归复用 `testClosedParentControlPipeKeepsWorkerLeaseUntilDescendantExits`、`testNormalTerminationWaitsForPostAndRejectsUnresolvedRisk`、`testFailedPostRestartAndExplicitRetryUseOriginalLabelAndDefinition` 和 `testVMReconnectDoesNotStopUntilDeviceScanConfirmsDisconnect`。 [启动验收](../04-macos/04-P4-ACCEPTANCE.md#L47) · [启动测试](../../../../FlutterRunletTests/LaunchPresentationTests.swift#L122) · [退出确认](../../../../FlutterRunlet/FlutterRunletApp.swift#L515) · [并发测试](../../../../FlutterRunletTests/ProjectConcurrencyTests.swift#L52) · [恢复测试](../../../../FlutterRunletTests/ProjectRecoveryTests.swift#L76) · [断线测试](../../../../FlutterRunletTests/FlutterDebugSessionTests.swift#L292)

### 真实日志与界面反馈

沿 Phase 03 的真实调试方式启动隔离样例。`FlutterToolchain` 构建 `run --machine --debug` 调用，`FlutterDebugSession.receive` 处理当前应用的 `app.log`，`SessionController` 核对 `generation == self.logGeneration`、遮罩后交给 `appendLog`。`appendLog` 按 64 KiB 截断，并向前跳过 UTF-8 续字节直至字符边界。`MainWindowView` 的 `DisclosureGroup` 保存折叠状态，清空和复制使用同一控制器，清空时更新日志视图代际。`testIncompleteAndQueuedLinesKeepTheirOriginalClearBoundary`、`testLiveTaskAndDebugLogsClearAndCopyWithoutChangingProdRecovery` 和 `testTrimmingLiveLogPreservesTheVisibleLineAndSelection` 可复用为可控回归。 [真实调试验收](../03-flutter/03-G2-ACCEPTANCE.md) · [Flutter 调用](../../../../FlutterRunlet/FlutterToolchain.swift#L398) · [日志事件](../../../../FlutterRunlet/FlutterDebugSession.swift#L172) · [代际过滤](../../../../FlutterRunlet/SessionController.swift#L1109) · [UTF-8 截断](../../../../FlutterRunlet/SessionController.swift#L1203) · [原生日志控件](../../../../FlutterRunlet/MainWindowView.swift#L218) · [日志测试](../../../../FlutterRunletTests/SessionLogTests.swift#L8)

### A29、A31 与 Release

- A29 的流程参照公开样例配置、任务顺序和恢复判定。使用已授权真实项目的私有映射及隔离副本，按环境对照两个工具的参数类别、任务次序和结果。配置、地址、日志原件及私有映射留在本地。 [公开样例](../../../../docs/examples/sample-flutter-app/README.md) · [A29](../../../../docs/04-ACCEPTANCE.md#L35) · [证据脱敏](../../../../docs/PUBLIC-RELEASE-AUDIT.md)
- A31 复用 Phase 01 的 Mach-O 最低版本证据方法和 Phase 04 辅助功能、按键探针及窗口实测。目标系统运行同一最终 Release。宿主和构建证据保留来源，macOS 15 实机或虚拟机环境缺失、或关键流程覆盖缺失记阻塞。 [Phase 01 部署证据](../01-upstream-audit-ui-shell/01-VERIFICATION.md#L88) · [Phase 04 原生取证](../04-macos/04-P4-ACCEPTANCE.md#L65) · [A31](../../../../docs/04-ACCEPTANCE.md#L37)
- Release 使用共享 scheme 和 Phase 04 的 `test -x`、`codesign --verify --strict "$worker"`、`codesign --verify --deep --strict "$bundle"` 模式。`AboutInformation.Destination.url` 和 `testAboutInformationUsesHostedAppBundleAndConfirmedLinks` 是候选信息和三条地址的基础断言，实际浏览器接收行为参照 Phase 04 A26。 [构建与签名](../04-macos/04-P4-ACCEPTANCE.md#L12) · [地址定义](../../../../FlutterRunlet/AuxiliaryWindows.swift#L281) · [关于测试](../../../../FlutterRunletTests/LaunchPresentationTests.swift#L7) · [A26 浏览器证据](../04-macos/04-P4-ACCEPTANCE.md#L54)

## Shared Patterns

阶段验收记录沿用 A 编号、候选身份、系统、复现方式和结果。复用既有自动证据时注明覆盖范围。实测记录中的风险状态以应用重启后的实际发现与原任务完成为准。私有原始证据在本地留存。 [验收矩阵](../../../../docs/04-ACCEPTANCE.md#如何使用) · [Phase 02 证据](../02-config-task-execution-core/02-P2-ACCEPTANCE.md)

## No Analog Found

仓库未见独立的 30 分钟编号日志负载及 RSS 采样工具、同一 `.app` 的 ZIP 与 SHA-256 交付流程，或现成发布说明模板。按 [05-RESEARCH.md](05-RESEARCH.md) 补齐本轮验收负载和归档步骤。日志负载仅用于隔离样例。
