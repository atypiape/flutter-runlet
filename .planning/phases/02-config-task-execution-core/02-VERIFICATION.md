---
phase: 02-config-task-execution-core
verified: 2026-11-12T08:26:12Z
status: passed
score: 16/16
covered_files: [
    ".planning/phases/02-config-task-execution-core/02-01-PLAN.md",
    ".planning/phases/02-config-task-execution-core/02-01-SUMMARY.md",
    ".planning/phases/02-config-task-execution-core/02-02-PLAN.md",
    ".planning/phases/02-config-task-execution-core/02-02-SUMMARY.md",
    ".planning/phases/02-config-task-execution-core/02-03-PLAN.md",
    ".planning/phases/02-config-task-execution-core/02-03-SUMMARY.md",
    ".planning/phases/02-config-task-execution-core/02-04-PLAN.md",
    ".planning/phases/02-config-task-execution-core/02-04-SUMMARY.md",
    ".planning/phases/02-config-task-execution-core/02-CONTEXT.md",
    ".planning/phases/02-config-task-execution-core/02-P2-ACCEPTANCE.md",
    ".planning/phases/02-config-task-execution-core/02-REVIEW-DISPOSITION.md",
    ".planning/phases/02-config-task-execution-core/02-SECURITY.md",
    ".planning/phases/02-config-task-execution-core/02-VALIDATION.md",
    "FlutterRunlet.xcodeproj/project.pbxproj",
    "FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme",
    "FlutterRunlet/AuxiliaryWindows.swift",
    "FlutterRunlet/FlutterRunletApp.swift",
    "FlutterRunlet/JSONCReader.swift",
    "FlutterRunlet/LaunchPresentation.swift",
    "FlutterRunlet/MainWindowView.swift",
    "FlutterRunlet/MenuBarPanelView.swift",
    "FlutterRunlet/ProjectConfiguration.swift",
    "FlutterRunlet/ProjectRecoveryStore.swift",
    "FlutterRunlet/SessionController.swift",
    "FlutterRunlet/SessionProcess.swift",
    "FlutterRunletSessionWorker/main.swift",
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
covered_digest: "v3:sha256:87954f01bbff2a31a2acec6eacf5e884435e0c83fe65af741b17a0af69dc03f0"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 15
  total: 15
  not_honored: []
re_verification:
  previous_status: gaps_found
  previous_score: 14/16
  gaps_closed:
    - "WR-04：完成凭据未确认持久前，原风险记录始终保留；确认完成后，重启可识别清理中断。"
  gaps_remaining: []
  regressions: []
behavior_unverified_items: []
human_verification: []
---

# Phase 02 · 配置和任务执行内核验证

**目标** 建立只读项目配置、任务与恢复内核，让启动和环境切换具备可测试的行为。

**结论** 16/16 项验证通过。用户确认隔离项目、配置重读与菜单栏联动，自动复验确认最终 Release 参数隔离。

## 目标与计划行为

| # | 行为 | 结论 | 证据 |
|---|---|---|---|
| 1 | 打开、切换及重读项目，公开四套名称、JSONC、旧 define、macOS PATH 和工作目录保真 | 通过 | 项目选择和配置测试，主窗观察与两份配置文件字节比对。 |
| 2 | 非 Debug、非法参数、缺失或不支持任务、失败前置任务均阻断适用进程 | 通过 | 真实任务退出码及零启动断言，覆盖 macOS 模式覆盖、Profile、无运行适配器和不支持配置。 |
| 3 | prod 前置写入、受管组退出后才恢复 test，部分写入或异常退出保留风险 | 通过 | 真实公开脚本 XCTest 和原生主窗验收，已观察到强制退出、重启发现及明确重试。 |
| 4 | 重复 Run、运行中切换及正常退出服从项目锁和恢复约束 | 通过 | 并发 XCTest 覆盖同会话 Stop、别名、竞争重试、切换和退出。原生系统退出已观察。 |
| 5 | 有前置或仅有后置时，先完成风险记录和目录项同步再派发 | 通过 | 同步故障注入覆盖两个写入阶段，并核对零任务和零调试副作用。 |
| 6 | 主窗与菜单栏共享会话且实际联动 | 通过 | 两处接入同一控制器。用户在 UAT 第 2 项确认两处同步、停止和退出服从原恢复约束。 |
| 7 | Debug 验收只执行固定根内的公开样例，重启复用隔离存储 | 通过 | XCTest 和实机拒绝外部目录、越界别名、修改脚本及链接状态文件。实机确认环境目录覆盖不改变验收根。 |
| 8 | 省略或空数组为零个任务参数，空串保留，null 拒绝，Unicode 和 shell 元字符保持字节 | 通过 | 真实任务输出与独立预期 argv 字节比对。 |
| 9 | 损坏重读、删除、重名、配置数量、独立任务文件错误保留约定的选择和可用性 | 通过 | 项目选择、独立任务文件错误及原生重读测试。 |
| 10 | 有效定义变化需要二次 Run，注释变化不阻断，最近项目重开不执行任务 | 通过 | 项目选择 XCTest 和原生主窗二次确认。 |
| 11 | 会话中修改磁盘任务后，首次恢复仍执行已确认快照 | 通过 | 恢复 XCTest 替换任务定义，核对旧任务实际效果。 |
| 12 | 重试限定原项目和原标签，校验定义、显式环境及真实后置退出码 | 通过 | XCTest 覆盖任务定义变更、环境值改变或缺失、损坏记录、目录替换和另一实例清除记录。 |
| 13 | 启动发现风险，在日志外显示项目和原标签，按偏好等待用户打开 | 通过 | 启动偏好和恢复 XCTest，原生主窗风险与折叠日志观察。 |
| 14 | Stop 或父控制管道关闭且同组后代仍活动时继续持锁 | 通过 | 两个真实进程组回归核对组长先退出、后代仍活动、竞争租约失败和后代退出后释放。 |
| 15 | 同提交 Debug 和 Release 构建、签名及监督进程产物，Release 排除验收装配 | 通过 | Debug 34/34、Release 成功、两套签名与四个 SHA-256 均匹配。最终 Release 同时传两种参数，自动操作确认 prod 仍禁用 Run，磁盘状态与启动前一致。 |
| 16 | 恢复记录清理失败或结果不明仍保留可用记录 | 通过 | 完成凭据目录同步失败时保留原记录，重启仍阻断。凭据已持久而旧记录删除失败时，重启确认原会话完成，凭据无法抵销下一会话的新风险。两个定向回归通过。 |

行为证据见 [P2 验收记录](02-P2-ACCEPTANCE.md)、[任务验证策略](02-VALIDATION.md)、[阶段验收矩阵](../../../docs/04-ACCEPTANCE.md) 和 [公开样例](../../../docs/examples/sample-flutter-app/README.md)。

## 工件与调用链

四份计划的工件检查分别通过 6/6、4/4、4/4、1/1。GSD 文件名匹配无法识别同模块 Swift 类型引用。逐项源码核查确认以下调用链。

- App 将同一 `SessionController` 传给主窗、菜单栏和退出委托。设置将最近项目偏好绑定到该实例，主窗在日志区域外呈现恢复记录。 [场景入口](../../../FlutterRunlet/FlutterRunletApp.swift) · [设置](../../../FlutterRunlet/AuxiliaryWindows.swift) · [恢复界面](../../../FlutterRunlet/MainWindowView.swift)
- 配置读取调用 JSONC 解码器并分开保存任务及启动配置错误。Run 重新读取并比较有效定义。重试使用记录中的任务标签，并在租约内核对定义、环境和项目身份。 [配置读取](../../../FlutterRunlet/ProjectConfiguration.swift) · [会话控制](../../../FlutterRunlet/SessionController.swift)
- App 将租约和已打开的工作目录交给内嵌监督进程。监督进程等待受管组静止才报告退出结果，后置返回 0 后进入持久清理。 [进程派发](../../../FlutterRunlet/SessionProcess.swift) · [监督进程](../../../FlutterRunletSessionWorker/main.swift) · [恢复存储](../../../FlutterRunlet/ProjectRecoveryStore.swift)

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

GSD 决策覆盖 15/15。检查未发现跳过、预期失败标记或循环生成的预期值。测试以公开样例及显式预期值核对字节、磁盘标记、退出码和锁竞争。最终代码与受测提交 `9a843d0864039639e370de01ec75f85e22c12e27` 一致，G1 回归 3/3。

## 审查边界

- WR-02 中同组后代长期不退出会延长 Stop。身份无法确认时实现继续持锁，符合本阶段先等待静止再允许恢复的约束。
- WR-03 的特殊 YAML 项目识别仍是兼容性限制。公开样例及常规 Flutter 项目目录已覆盖。
- WR-04 已修复。只有真实后置退出 0 后才写入绑定该会话记录的认证完成凭据。凭据持久前不删除原记录。重启读取时重新确认凭据同步，凭据与新会话记录不能互认。最终 Debug 原生 Stop 已复验恢复 `test`，风险与完成凭据文件均已清理。 [恢复存储](../../../FlutterRunlet/ProjectRecoveryStore.swift) · [重启回归](../../../FlutterRunletTests/ProjectRecoveryTests.swift)

详见 [审查处置](02-REVIEW-DISPOSITION.md) 与 [安全复核](02-SECURITY.md)。

## 验收结果

[UAT 记录](02-UAT.md)共三项，全部通过。前两项由用户确认，Release 项由[自动交互和磁盘断言](02-P2-ACCEPTANCE.md#release-参数隔离自动复验)覆盖。
