---
phase: 02-config-task-execution-core
verified: 2026-11-13T19:18:36Z
status: passed
score: 16/16
covered_files: [
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-01-PLAN.md",
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-01-SUMMARY.md",
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-02-PLAN.md",
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-02-SUMMARY.md",
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-03-PLAN.md",
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-03-SUMMARY.md",
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-04-PLAN.md",
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-04-SUMMARY.md",
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-CONTEXT.md",
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-P2-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-REVIEW-DISPOSITION.md",
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-REVIEW.md",
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-SECURITY.md",
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-UAT.md",
  ".planning/milestones/v0.1-phases/02-config-task-execution-core/02-VALIDATION.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-G2-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/04-macos/04-P4-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-01-SUMMARY.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-ENVIRONMENT.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-G3-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-LOG-STRESS.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-RECOVERY.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-REVIEW-DISPOSITION.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-VALIDATION.md",
  "FlutterRunlet.xcodeproj/project.pbxproj",
  "FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme",
  "FlutterRunlet/AuxiliaryWindows.swift",
  "FlutterRunlet/FlutterDebugSession.swift",
  "FlutterRunlet/FlutterRunletApp.swift",
  "FlutterRunlet/FlutterToolchain.swift",
  "FlutterRunlet/JSONCReader.swift",
  "FlutterRunlet/LaunchPresentation.swift",
  "FlutterRunlet/MainWindowView.swift",
  "FlutterRunlet/MenuBarPanelView.swift",
  "FlutterRunlet/ProjectConfiguration.swift",
  "FlutterRunlet/ProjectRecoveryStore.swift",
  "FlutterRunlet/SessionController.swift",
  "FlutterRunlet/SessionProcess.swift",
  "FlutterRunletSessionWorker/main.swift",
  "FlutterRunletTests/FlutterDebugSessionTests.swift",
  "FlutterRunletTests/FlutterToolchainTests.swift",
  "FlutterRunletTests/LaunchPresentationTests.swift",
  "FlutterRunletTests/ProjectConcurrencyTests.swift",
  "FlutterRunletTests/ProjectConfigurationTests.swift",
  "FlutterRunletTests/ProjectRecoveryTests.swift",
  "FlutterRunletTests/ProjectSelectionTests.swift",
  "FlutterRunletTests/SessionLifecycleTests.swift",
  "docs/02-TECHNICAL.md",
  "docs/04-ACCEPTANCE.md",
  "docs/examples/sample-flutter-app/README.md",
  "docs/examples/sample-flutter-app/launch.jsonc",
  "docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh",
  "docs/examples/sample-flutter-app/tasks.jsonc"
]
covered_digest: "v3:sha256:e0500319ac2467a4d238b28abf1c1991d3f6150bcfef43cdc351452225df5745"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 15
  total: 15
  not_honored: []
re_verification:
  previous_status: passed
  previous_score: 16/16
  gaps_closed: []
  gaps_remaining: []
  regressions: []
behavior_unverified_items: []
human_verification: []
---

# Phase 02 · 配置和任务执行内核验证

**目标** 建立只读项目配置、任务与恢复内核，让启动和环境切换具备可测试的行为。

**历史结论** Phase 02 及其 Phase 03 集成复验通过 16/16 项，覆盖 A07–A16 和 A32。以下保留原始证据，v0.1 候选结论见末节。

## 目标与计划行为

| # | 行为 | 结论 | 证据 |
|---|---|---|---|
| 1 | 打开、切换及重读项目，公开四套名称、JSONC、旧 define、macOS PATH 和工作目录保真 | 通过 | 项目选择和配置测试，主窗观察与两份配置文件字节比对。 |
| 2 | 非 Debug、非法参数、缺失或不支持任务、失败前置任务均阻断适用进程 | 通过 | 真实任务退出码及零启动断言，覆盖 macOS 模式覆盖、Profile、无运行适配器和不支持配置。 |
| 3 | prod 前置写入、受管组退出后才恢复 test，部分写入或异常退出保留风险 | 通过 | 真实公开脚本 XCTest 和原生主窗验收覆盖强制退出、重启发现及明确重试。当前候选的等同产物已在 iOS 模拟器验证 Flutter 和监督进程先退出，随后原后置恢复 test 并清除风险。 |
| 4 | 重复 Run、运行中切换及正常退出服从项目锁和恢复约束 | 通过 | 并发 XCTest 覆盖同会话 Stop、别名、竞争重试、切换和退出。原生系统退出已观察。 |
| 5 | 有前置或仅有后置时，先完成风险记录和目录项同步再派发 | 通过 | 同步故障注入覆盖两个写入阶段，并核对零任务和零调试副作用。 |
| 6 | 主窗与菜单栏共享会话且实际联动 | 通过 | 两处接入同一控制器。用户在 UAT 第 2 项确认两处同步、停止和退出服从原恢复约束，G2 原生矩阵继续覆盖共享会话。 |
| 7 | Debug 验收只执行固定根内的公开样例，重启复用隔离存储 | 通过 | 本轮 Debug XCTest 通过固定验收标志、越界别名、修改脚本及链接状态文件的回归，原生验收覆盖外部目录拒绝。实机确认环境目录覆盖不改变验收根。 |
| 8 | 省略或空数组为零个任务参数，空串保留，null 拒绝，Unicode 和 shell 元字符保持字节 | 通过 | 真实任务输出与独立预期 argv 字节比对。 |
| 9 | 损坏重读、删除、重名、配置数量、独立任务文件错误保留约定的选择和可用性 | 通过 | 项目选择、独立任务文件错误及原生重读测试。 |
| 10 | 有效定义变化需要二次 Run，注释变化不阻断，最近项目重开不执行任务 | 通过 | 项目选择 XCTest 和原生主窗二次确认。 |
| 11 | 会话中修改磁盘任务后，首次恢复仍执行已确认快照 | 通过 | 恢复 XCTest 替换任务定义，核对旧任务实际效果。 |
| 12 | 重试限定原项目和原标签，校验定义、显式环境及真实后置退出码 | 通过 | XCTest 覆盖任务定义变更、环境值改变或缺失、损坏记录、目录替换和另一实例清除记录。 |
| 13 | 启动发现风险，在日志外显示项目和原标签，按偏好等待用户打开 | 通过 | 启动偏好和恢复 XCTest，原生主窗风险与折叠日志观察。 |
| 14 | Stop 或父控制管道关闭且同组后代仍活动时继续持锁 | 通过 | 两个真实进程组回归核对组长先退出、后代仍活动、竞争租约失败和后代退出后释放。 |
| 15 | 同提交 Debug 和 Release 构建、签名及监督进程产物，Release 排除验收装配 | 通过 | 本轮 Debug 57/57、Release 构建通过，两套 App 与 worker 通过可执行及严格签名检查。等同 Release 产物同时传入两个历史参数后进入普通模式，未点 Run 时无 worker，样例及固定验收存储摘要与启动前一致。 |
| 16 | 恢复记录清理失败或结果不明仍保留可用记录 | 通过 | 完成凭据目录同步失败时保留原记录，重启仍阻断。凭据已持久而旧记录删除失败时，重启确认原会话完成，凭据无法抵销下一会话的新风险。两个定向回归通过。 |

行为证据见 [P2 验收记录](02-P2-ACCEPTANCE.md)、[任务验证策略](02-VALIDATION.md)、[阶段验收矩阵](../../../../docs/04-ACCEPTANCE.md) 和 [公开样例](../../../../docs/examples/sample-flutter-app/README.md)。

## 工件与调用链

四份计划的工件检查分别通过 6/6、4/4、4/4、1/1。GSD 文件名匹配无法识别同模块 Swift 类型引用。逐项源码核查确认以下调用链。

- App 将同一 `SessionController` 传给主窗、菜单栏和退出委托。设置将最近项目偏好绑定到该实例，主窗在日志区域外呈现恢复记录。 [场景入口](../../../../FlutterRunlet/FlutterRunletApp.swift) · [设置](../../../../FlutterRunlet/AuxiliaryWindows.swift) · [恢复界面](../../../../FlutterRunlet/MainWindowView.swift)
- 配置读取调用 JSONC 解码器并分开保存任务及启动配置错误。Run 重新读取并比较有效定义。重试使用记录中的任务标签，并在租约内核对定义、环境和项目身份。 [配置读取](../../../../FlutterRunlet/ProjectConfiguration.swift) · [会话控制](../../../../FlutterRunlet/SessionController.swift)
- App 将租约和已打开的工作目录交给内嵌监督进程。监督进程等待受管组静止才报告退出结果，后置返回 0 后进入持久清理。 [进程派发](../../../../FlutterRunlet/SessionProcess.swift) · [监督进程](../../../../FlutterRunletSessionWorker/main.swift) · [恢复存储](../../../../FlutterRunlet/ProjectRecoveryStore.swift)

## 需求核对

| 需求 | 证据 |
|---|---|
| CONF-01 | ProjectSelectionTests 覆盖项目打开、重读和最近项目，原生验收覆盖切换。 |
| CONF-02 | ProjectConfigurationTests 覆盖 JSONC、文件名与原始行列及四套名称。 |
| CONF-03 | ProjectConfigurationTests 与 SessionLifecycleTests 证实模式、覆盖项和无适配器时零执行。 |
| CONF-04 | ProjectConfigurationTests 核对新旧 define、应用参数、顺序及冲突。 |
| CONF-05 | ProjectConfigurationTests 核对 cwd、入口、PATH、启动与任务环境，样例字节比对通过。 |
| TASK-01 | ProjectConfigurationTests 读取原标签并实际执行参数向量。 |
| TASK-02 | ProjectConfigurationTests 与 SessionLifecycleTests 覆盖不支持配置及非零前置退出。 |
| SAFE-01 | SessionLifecycleTests 与 ProjectRecoveryTests 核对进程退出和原任务快照。 |
| SAFE-02 | SessionLifecycleTests 核对派发前同步和部分写入，实机确认异常退出后发现风险。 |
| SAFE-03 | ProjectRecoveryTests 与原生验收确认后置失败阻断、原任务重试及退出 0。持久完成与清理故障两条重启回归通过。 |
| SAFE-04 | ProjectConcurrencyTests 验证组退出、别名互斥、切换和正常退出，用户确认菜单栏联动。 |

GSD 决策覆盖 15/15。检查未发现跳过、预期失败标记或循环生成的预期值。测试以公开样例及显式预期值核对字节、磁盘标记、退出码和锁竞争。原阶段候选 `9a843d0864039639e370de01ec75f85e22c12e27` 的 Debug XCTest 34/34，含 G1 回归 3/3。

## 本轮复验

- 受测源码为 `a0ca3ba6ccb9bf2d27db29526159642f6dca27a0`。用 macOS 共享 scheme 执行全量 Debug XCTest，57/57 通过，含 G1 和全部 P2 回归。Release 构建通过，Debug 和 Release 的 App 主程序及内嵌监督进程共四个文件均可执行。两套监督进程的严格签名和 App 的深度严格签名均通过。原始日志与摘要存于 `/tmp/flutter-runlet-phase02-refresh.hKllJY`。 [验证策略](02-VALIDATION.md)
- 四个可执行文件的 SHA-256 与 G2 最终原生候选 `0416505db76e7dde868db92110e8a0fb2d074520` 逐一相同。两提交的 App、worker、XCTest 和 Xcode 工程文件也无差异。复用该候选的原生证据核对普通模式 Stop 与原任务恢复顺序、Release 参数隔离。 [G2 原生复验](../03-flutter/03-G2-ACCEPTANCE.md#审查修正复验)
- Phase 02 原始 Release 候选尚无生产适配器，原验收观察到 prod 的 Run 禁用。当前普通模式具备生产适配器，合法配置和设备可供用户主动运行。两个历史参数仍无法启用验收装配，G2 实测未点 Run 时，样例、固定 Debug 存储与 worker 数保持不变。 [P2 原始 Release 验收](02-P2-ACCEPTANCE.md#release-参数隔离自动复验) · [G2 原生复验](../03-flutter/03-G2-ACCEPTANCE.md#审查修正复验)
- 路线四项均通过。第 1、8–10 项覆盖项目配置与只读行为，第 2 项覆盖执行阻断，第 3、5、11–13、16 项覆盖任务顺序与风险恢复，第 4、6、14 项覆盖会话和项目租约。共享文件增量审查未发现 P2 回归。 [路线](../../v0.1-ROADMAP.md#phase-2-配置和任务执行内核) · [增量审查](02-REVIEW.md) · [安全复核](02-SECURITY.md)

## 审查边界

- WR-02 中同组后代长期不退出会延长 Stop。身份无法确认时实现继续持锁，符合本阶段先等待静止再允许恢复的约束。
- WR-03 的特殊 YAML 项目识别仍是兼容性限制。公开样例及常规 Flutter 项目目录已覆盖。
- WR-04 已修复。只有真实后置退出 0 后才写入绑定该会话记录的认证完成凭据。凭据持久前不删除原记录。重启读取时重新确认凭据同步，凭据与新会话记录不能互认。最终 Debug 原生 Stop 已复验恢复 `test`，风险与完成凭据文件均已清理。 [恢复存储](../../../../FlutterRunlet/ProjectRecoveryStore.swift) · [重启回归](../../../../FlutterRunletTests/ProjectRecoveryTests.swift)

详见 [审查处置](02-REVIEW-DISPOSITION.md) 与 [安全复核](02-SECURITY.md)。

## 验收结果

原 UAT 三项全部通过。前两项由用户确认，Release 项由自动交互和磁盘断言覆盖。已验收路径有本轮自动验证及等同产物证据支持，无待人工复验项。 [UAT 记录](02-UAT.md) · [P2 原始 Release 验收](02-P2-ACCEPTANCE.md#release-参数隔离自动复验)

## v0.1 最终候选复核（2026-11-14）

最终候选 `36916dd1f6a6f916a1c76ca93aa37ae84f8247f6` 的应用、worker、XCTest 和 Xcode 工程与本轮复核源码一致。当前 16/16 项及 11/11 项需求通过。复用同候选 Debug 全量 77/77、配置和启动定向 22/22、两套构建的签名记录及已完成的 G3 实测。前四份计划的 15 个产物通过 GSD 探针。Swift 同一 target 的调用未引用文件路径，另按实际类型调用、嵌入 worker 和任务结果核对接线。决策覆盖为 15/15。[G3 验证](../05-stability-recovery-release/05-VERIFICATION.md) · [两套构建](../05-stability-recovery-release/05-01-SUMMARY.md#替换候选) · [验收判定](../05-stability-recovery-release/05-G3-ACCEPTANCE.md)

| 原验证项 | 最终候选证据 |
| --- | --- |
| 1、8–10 · CONF-01–05，A07–A11 | `ProjectConfigurationTests` 核对四个原名、JSONC 精确位置、旧 define、PATH、参数字节及任务目录。`ProjectSelectionTests` 断言无效、删除和重名配置、有效定义变化需两次 Run、注释变化和最近项目零执行。`ProjectConfiguration` 只读两份 JSONC，`SessionController` 在持锁时重读并比较。A29 绑定同候选复验授权隔离项目，确认原工程摘要和 Git 状态一致。[配置读取](../../../../FlutterRunlet/ProjectConfiguration.swift#L145) · [运行前复验](../../../../FlutterRunlet/SessionController.swift#L806) · [真实工程对照](../05-stability-recovery-release/05-ENVIRONMENT.md#a29--真实项目) |
| 2 · TASK-01、TASK-02，A12、A32 | `testRealTaskArgumentsDirectoryEnvironmentAndExitStatus` 以真实命令核对 argv、cwd、环境及退出码。`testZeroAndNullArgumentsAndUnsupportedTasksHaveDistinctResults` 和 `testNoAdapterAndNonDebugLeaveConfigurationAndProjectUntouched` 覆盖不适用输入的阻断。故障矩阵包含前置失败后未启动 Flutter。其候选 `c80ec88` 至最终候选仅有日志视图和测试变更。[任务实现](../../../../FlutterRunlet/ProjectConfiguration.swift#L233) · [恢复矩阵](../05-stability-recovery-release/05-RECOVERY.md) |
| 3–6、11–14、16 · SAFE-01–04，A13–A16 | 最终候选的 A13 先确认受管组退出，再执行原后置任务，约 123 ms 后观察到退出 0，最终恢复 test、风险清零。三处强退复验和同实现的后置失败、切换与第二实例证据补足异常路径。现有 `SessionLifecycleTests`、`ProjectRecoveryTests`、`ProjectConcurrencyTests` 断言 fsync 失败零派发、原后置快照、重试等价性、目录及环境身份、同组后代持锁和持久凭据失败等边界。两窗口共用控制器，日志外恢复入口在最终候选复验。[执行与恢复](../../../../FlutterRunlet/SessionController.swift#L985) · [持久记录](../../../../FlutterRunlet/ProjectRecoveryStore.swift#L103) · [受管组退出](../../../../FlutterRunletSessionWorker/main.swift#L44) · [恢复矩阵](../05-stability-recovery-release/05-RECOVERY.md) |
| 7、15 · Debug 夹具与 Release 隔离 | 最终 Debug 两处强退用固定项目根、专用命名空间和独立样例，重启后实际找到记录并完成原任务。`testFixtureAssemblyRequiresExactFlagAndRejectsOutsideProjectAlias`、`testFixtureRootRunsPublicSampleAndRejectsModifiedScriptAndLinkedState` 覆盖根外及符号链接。普通 Release 的历史参数隔离沿用 P4 原生记录。`988ac81` 至最终候选的 `LaunchPresentation` 未变，`SessionController` 的 `#if DEBUG` 入口和 Xcode 编译条件保持一致。最终签名 Release 的独立存储、普通启动和真实调试恢复已有 G3 取证。[P4 参数隔离](../04-macos/04-P4-ACCEPTANCE.md#release-历史参数隔离) · [编译分支](../../../../FlutterRunlet/SessionController.swift#L290) · [签名及解包复验](../05-stability-recovery-release/05-ENVIRONMENT.md#归档) |

G3 的本地交付证据覆盖当期改动涉及的执行行为，原参数隔离和界面证据按上述代码边界沿用。复核无需重复设备或原生界面操作。
