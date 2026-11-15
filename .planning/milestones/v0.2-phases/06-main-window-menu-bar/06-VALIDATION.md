---
phase: "06"
slug: main-window-menu-bar
status: passed
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-14"
---

# 阶段 06 · 验证方案

## 测试入口

使用现有 macOS scheme `FlutterRunlet` 和 `FlutterRunletTests`。无需新框架。每个实现任务先运行计划中列明的 XCTest 子集。每波结束执行 Debug 全量，最终构建本地 Release 候选。首次测试记录实测耗时和非预期跳过项。

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-06" -parallel-testing-enabled NO test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Release -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-06" build
```

## 验证映射

| 行为和需求 | 自动化 | 同一候选的原生验收 |
| --- | --- | --- |
| UI-07、UI-08、UI-10、UI-11 共用动作、两处布局与设置入口 | `LaunchPresentationTests`、`FlutterDebugSessionTests`、构建 | 348 pt 菜单栏、640 × 520 pt 主窗。两处分别检查中文和英文 × 系统深浅外观，核对状态标签、六项操作及可用性、键盘和图标可读名称。两齿轮打开同一现有设置。 |
| UI-09 历史与目录 | `ProjectSelectionTests`、`ProjectConcurrencyTests` | 使用两个隔离样例从两处打开历史、单删至空列表并重启、选择和取消系统目录。运行及恢复时无法切换。 |
| RUN-07 在线状态与下次选择 | `FlutterToolchainTests`、`FlutterDebugSessionTests` | 在 A 启动，在另一处选 B，两处下次选择同步，当前会话、热操作及 DevTools 仍在 A。停止后走 B，另测 B 离线阻断和复连。 |
| RUN-08、RUN-09 原位反馈、重试、恢复后启动 | `ProjectRecoveryTests`、`ProjectConcurrencyTests`、`SessionLifecycleTests` | 用隔离样例制造后置任务退出 1。主窗核对任务、退出码、提示，菜单栏核对失败状态及快捷重试。验证重复失败保留风险、两处单点重试、主窗选择 dev 后先恢复再启动、菜单栏运行键及 F5 在失败态均禁用。使用样例暂停标记验证在途重入、切换与确认退出阻断后续启动，详细步骤见 06-04-03。 |
| UI-12 日志 | `SessionLogTests` | 复制，清空，折叠及展开，新输出追加，清空和折叠后恢复详情仍可看。 |

通过普通候选运行真实 Flutter。先按 [样例说明](../../../../docs/examples/sample-flutter-app/README.md) 建立脱离业务项目的样例和恢复存储，确认有效 SDK、模拟器及第二个设备。记录候选及证据，按 [验收矩阵](../../../../docs/04-ACCEPTANCE.md) 标记通过、失败或阻塞。缺少实际设备或会话证据的场景保留对应阻塞项。调试替身只用于故障验证。截图、私有路径和服务令牌保留在本地。详细操作和命令子集参见 [调研](06-RESEARCH.md#validation-architecture)。

## 签核

- [x] 核对所有任务的校验命令及失败条件。
- [x] 执行各波次测试及最终 Release 构建，记录实际输出和有无跳过。
- [x] 完成同一候选的 Figma 对照、原生窗口与真实 Flutter 验收。
- [x] 按验收结果更新状态和未覆盖项。

**签核状态** 2026-11-15 本地联验通过。候选 `f96a8d6` 的 Debug 90 项全通过，普通 Release 构建及严格签名校验通过。同一 Release 的主窗和系统菜单栏各取证 24 张，真实 Flutter、设备、历史、恢复和日志联验通过。按用户决定取消 Tab 焦点和 VoiceOver 专项，蓝框移除作为后续改动。 [本地联验](06-ACCEPTANCE.md)
