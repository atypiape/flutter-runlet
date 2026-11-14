---
phase: 05-stability-recovery-release
verified: 2026-11-13T18:41:10Z
status: passed
score: 13/13 must-haves verified
covered_files: [
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-01-PLAN.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-01-SUMMARY.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-02-PLAN.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-02-SUMMARY.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-03-PLAN.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-03-SUMMARY.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-04-PLAN.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-04-SUMMARY.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-05-PLAN.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-05-SUMMARY.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-CONTEXT.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-ENVIRONMENT.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-G3-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-LOG-STRESS.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-RECOVERY.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-REVIEW-DISPOSITION.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-SECURITY.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-UI-REVIEW.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-VALIDATION.md",
  "FlutterRunlet/FlutterDebugSession.swift",
  "FlutterRunlet/FlutterRunletApp.swift",
  "FlutterRunlet/MainWindowView.swift",
  "FlutterRunlet/ProjectConfiguration.swift",
  "FlutterRunlet/ProjectRecoveryStore.swift",
  "FlutterRunlet/SessionController.swift",
  "FlutterRunletSessionWorker/main.swift",
  "FlutterRunletTests/LaunchPresentationTests.swift",
  "FlutterRunletTests/SessionLifecycleTests.swift",
  "FlutterRunletTests/SessionLogTests.swift",
  "LICENSE",
  "README.md",
  "docs/04-ACCEPTANCE.md",
  "docs/RELEASE-NOTES.md",
  "docs/examples/sample-flutter-app/README.md",
  "docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh"
]
covered_digest: "v3:sha256:ec1a9d2f770d8eba6bb7b9ce491dfe79c8d8afa0fe46b9044156eab8057ed800"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 10
  total: 11
  not_honored: [D-08]
---

# Phase 05 · 最终验证

阶段目标为验证异常与恢复行为、目标系统和发布准备，通过 G3。最终候选为 `36916dd1f6a6f916a1c76ca93aa37ae84f8247f6`，Release 0.1.0（1）。核对源码、现存原始证据及实际构建产物后，判定通过。

## 可观察结果

| 项 | 验证范围 | 判定 | 证据 |
|---|---|---|---|
| 1 | A13 普通 Release 停止及恢复 | 通过 | 真实 iOS 会话进入 Running。单调时钟记录旧组消失时仍为 prod、风险为 1，约 123 ms 后原任务退出 0，最终 test、风险为 0。配置和日常存储保持原摘要。 [候选和时序](05-01-SUMMARY.md#替换候选) |
| 2 | D-01、D-02 Debug 暂停及强退 | 通过 | 最终候选前置与后置各有强退前、待恢复、打开项目及重试 AX。后置已写入 test 时风险仍在。脚本先处理故障标记，限定等待 30 秒。Shell 语法、脚本摘要与 XCTest 结果通过。 [恢复记录](05-RECOVERY.md) |
| 3 | 候选身份与替换复验 | 通过 | 冻结源码工作树干净，HEAD 与 `candidate.json` 一致。最终候选重新验证 A13、强退、长测、真实工程、部署目标、受影响界面及解包运行。 [构建记录](05-01-SUMMARY.md#替换候选) |
| 4 | A14–A16、A22、A28 失败、并发、断线及退出 | 通过 | 16 个场景均有真实记录。`c80ec88` 的可复用结果保留身份，最终替换仅改日志视图编码比较和对应测试。 [恢复矩阵](05-RECOVERY.md) |
| 5 | D-03 两项偏好关闭时的强退恢复 | 通过 | 最终候选有双偏好关闭、正在运行、重启自动主窗、打开待恢复项目及重试的 AX 证据。 [恢复矩阵](05-RECOVERY.md) |
| 6 | 主窗、菜单栏及退出对话框的会话反馈 | 通过 | 等待、运行、租约阻断、后置失败和退出取消有原生 AX。取消保留原会话，确认退出等待恢复，恢复失败时保留重试。 [恢复矩阵](05-RECOVERY.md) · [原生审查](05-UI-REVIEW.md) |
| 7 | D-04、D-05 真实日志负载、反馈和清空 | 通过 | 真实会话 1,801.01 秒，1,500 条低频及 59,973 条高频编号，约 200.51 行/秒。清空、折叠、展开、停止分别为 183.05、99.51、117.03、140.01 ms。64 KiB 复制严格 UTF-8，清空后旧编号未重现。 [长测记录](05-LOG-STRESS.md#最终候选-30-分钟实测) |
| 8 | D-06 同一进程的 RSS | 通过 | 基线 53.09 MiB，高频峰值 61.34 MiB，增量 8.25 MiB。两次阶跃后进入平台并末段回落，判定窗口独立采样完整。 [长测记录](05-LOG-STRESS.md#最终候选-30-分钟实测) |
| 9 | D-07、A29 真实工程与可恢复 prod | 通过 | 授权副本三环境的两工具参数及结果一致。prod 在调试就绪后发出停止，原后置任务恢复五项 test 基线。原工程 16 项摘要和 Git 状态核对一致。 [环境对照](05-ENVIRONMENT.md) |
| 10 | 更新后的 A31 最低部署目标 | 通过 | 主程序与内嵌 worker 的 arm64 和 x86_64 均实测 `minos 15.0`。用户取消 macOS 15 实机和虚拟机运行验收，该系统的运行兼容性未验证。 [阶段决定](05-CONTEXT.md) · [部署记录](05-ENVIRONMENT.md) |
| 11 | D-09 同一签名归档与解包运行 | 通过 | ZIP 摘要、解包目录逐字节比较、两文件执行位与两包严格签名通过。解包运行证据绑定同一候选，停止后 test、零风险。 [归档记录](05-ENVIRONMENT.md#归档) |
| 12 | D-10、D-11 关于和受影响原生界面 | 通过 | 最终候选关于页有版本、构建和上游归属，以及实际点击委派的三个浏览器目标。双语主窗与面板、日志和会话状态已复验，沿用 Phase 04 的浅色、长名和焦点证据。无新增或改变的视觉差异。 [原生审查](05-UI-REVIEW.md) · [人工复核](05-G3-ACCEPTANCE.md#人工复核) |
| 13 | G3 适用矩阵与本地交付 | 通过 | A01–A32 各有一条，A29/A31 与同候选记录同步。只读封存通过，签名 App、ZIP、摘要、使用说明、发布说明及许可证齐备。 [G3 矩阵](05-G3-ACCEPTANCE.md) · [发布说明](../../../../docs/RELEASE-NOTES.md) · [许可证](../../../../LICENSE) |

## 实现和证据关联

| 来源 | 关联 | 核对结果 |
|---|---|---|
| 公开样例与配置检查 | `validateFixtureTask` 对脚本路径、参数、项目身份和 SHA-256 的校验 | 现有脚本的实际 SHA-256 与常量一致，前置、后置暂停及退出 1 走原任务。 [配置检查](../../../../FlutterRunlet/ProjectConfiguration.swift#L41) · [样例脚本](../../../../docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh) |
| App 与受管会话 | 终止时等待受管进程，恢复沿用项目租约并检查原任务结果 | 控制器只在受管进程退出已确认后执行后置，只在后置退出 0 后移除持久风险。A13 和三时点强退均有对应状态。 [终止入口](../../../../FlutterRunlet/FlutterRunletApp.swift#L512) · [恢复实现](../../../../FlutterRunlet/SessionController.swift#L1077) · [受管进程](../../../../FlutterRunletSessionWorker/main.swift) |
| Flutter 到原生日志 | 当前会话 `app.log`、代际过滤、UTF-8 裁剪和增量视图 | 只发布当前代际，批量缓冲裁剪于有效 UTF-8 边界。视图按字面 UTF-16 比较，Unicode 回归和真实长测均通过。 [机器事件](../../../../FlutterRunlet/FlutterDebugSession.swift#L175) · [日志处理](../../../../FlutterRunlet/SessionController.swift#L1210) · [视图实现](../../../../FlutterRunlet/MainWindowView.swift#L349) |
| 环境、签名与验收 | 冻结清单、当前二进制摘要、A29/A31 汇总、G3 及发布说明 | `--review-status` 和 `--seal` 独立执行通过。归档的 SHA-256 为 `5e4e29423b539090e8ed3867b94c0b6e50637e4f6abc8e9581928f756d262e55`。 [验收契约](../../../../docs/04-ACCEPTANCE.md) · [候选环境](05-ENVIRONMENT.md) · [G3 矩阵](05-G3-ACCEPTANCE.md) |

## 行为与探针复核

- 从最终候选的 XCTest 结果核对 Debug 77/77，配置和启动定向 22/22，均零失败、零跳过。宿主原生界面和模拟器操作按本轮已存的取证复核。 [验证策略](05-VALIDATION.md)
- 重新执行 G3 `--review-status`、`--seal`、日志 `--full` 核验、样例 `sh -n`、`vtool`、ZIP 摘要、解包比对、执行位和严格签名检查，均通过。长测探针复算原始取样。 [日志压力](05-LOG-STRESS.md) · [环境记录](05-ENVIRONMENT.md)
- 用内存副本验证 G3 封存拒绝阻塞项、环境与 G3 不同步、重复行、陈旧候选和待确认人工项。复核模式允许记录已同步的阻塞项，封存模式拒绝该状态。 [G3 门槛](05-05-PLAN.md)

## 需求与决定覆盖

| 需求 | 计划 | 判定 | 证据 |
|---|---|---|---|
| REL-01 | 05-01、05-02 | 通过 | [A13 时序](05-01-SUMMARY.md#替换候选) · [16 项恢复](05-RECOVERY.md) |
| REL-02 | 05-03 | 通过 | [A27、A30 长测](05-LOG-STRESS.md#最终候选-30-分钟实测) |
| REL-03 | 05-04 | 通过 | [A29、A31 同候选记录](05-ENVIRONMENT.md) |
| REL-04 | 05-04、05-05 | 通过 | [G3 封存和本地交付](05-G3-ACCEPTANCE.md#G3-判定与本地交付) |

GSD 决策覆盖探针识别 10/11 条。提示项 D-08 指向原 macOS 15 运行范围。2026-11-14 用户决定更新了这一范围，保留 15.0 部署目标。Roadmap、需求、验收矩阵及最终候选记录采用更新后的标准。 [阶段决定](05-CONTEXT.md) · [验收矩阵](../../../../docs/04-ACCEPTANCE.md)

## 剩余范围

无阻塞项或待人工确认项。实体 Android 设备沿用 G2 适用性，已验证 Android 模拟器。旧版 Debug 夹具的挂起记录须用匹配旧脚本的构建处理。公开分发、公证及链接匿名访问按发布审计执行。 [审查处置](05-REVIEW-DISPOSITION.md) · [G3 交付范围](05-G3-ACCEPTANCE.md#G3-判定与本地交付)
