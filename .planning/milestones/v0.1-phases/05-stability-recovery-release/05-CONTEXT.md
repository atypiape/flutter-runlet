# Phase 05 · 稳定性、异常恢复与最终验收

**讨论日期** 2026-11-13

**状态** 待规划

<domain>
## 阶段范围

完成 REL-01 至 REL-04，复验启动失败、任务失败、设备断线、并发启动、正常退出和强制终止后的恢复。覆盖 A13–A16、A22、A27–A31 和 G3 适用验收项。最终交付本地 Release 验收包。G3 以所有适用用例通过为前提，其中包括 `prod` 恢复和 macOS 15.0 最低部署目标核对。

沿用 Phase 02 的项目锁、风险记录、原任务核对和重试规则，Phase 03 的共享会话和日志行为，以及 Phase 04 已验收的原生界面和启动偏好。自动证据完整覆盖预期时直接记录结果，人工复核剩余的界面差异。

</domain>

<decisions>
## 实施决定

### 强退恢复

- **D-01:** 在隔离的公开样例及独立恢复存储上覆盖三个强退时点。前置任务写入 `prod` 后尚未退出和后置任务写入 `test` 后尚未以退出码 0 完成，使用 Debug 隔离验收入口。Flutter 调试运行中使用最终 Release 候选和真实 Flutter 模拟器。
- **D-02:** 在后置任务已写入 `test` 的场景，以任务成功退出并确认恢复为清除风险的条件。重启后应仍显示风险，按原后置任务手动重试成功后才清除。用可观察的暂停点定位前后置边界，记录强退前后的环境标记、任务状态和风险记录。
- **D-03:** A15 的 Release 运行中强退场景同时关闭「启动后显示主窗口」和「记住最近打开的项目」。重启仍自动显示主窗口及待恢复项目和入口。用户通过入口打开该项目并手动重试，确认恢复到 `test` 后清除风险。沿用项目锁和受管进程退出确认。

### 日志压力

- **D-04:** A27 使用最终 Release 候选和隔离公开样例，运行真实 Flutter 调试会话共 30 分钟。前 25 分钟低频输出，最后 5 分钟约 200 行/秒，使用带递增编号的中英文混合短行。用编号核对 64 KiB 缓冲裁剪处的 UTF-8 完整性、清空边界和新输出。
- **D-05:** 高频输出时实际操作清空、折叠、展开和停止。各操作从触发到界面反馈在 1 秒内，停止以进入「停止中」为准。在高频时段末尾触发停止并记录耗时。核对清空后折叠再展开仍无清空前的旧日志，并继续收到新输出（A30）。
- **D-06:** 采样 FlutterRunlet 主进程 RSS，以低频阶段最后 5 分钟的采样中位数为基线。高频阶段采样峰值较基线增长不超过 50 MiB，且曲线无持续上升。归档采样曲线、基线、峰值和增长量。

### 真实项目与最低系统

- **D-07:** A29 使用用户在 Phase 05 对话中指定的「真实项目 A」。授权范围是在隔离副本中用 VS Code 和 FlutterRunlet 运行 `dev`、`test`、`prod`。按验收矩阵为 `prod` 用例准备可恢复测试环境及 Firebase 文件基线备份。公开记录逐环境列出脱敏后的参数类别、任务顺序、环境结果及 `prod` 停止后恢复 `test` 的结果。原始路径、配置值及原始证据留在本地私有环境。
- **D-08:** A31 接受 macOS 15 虚拟机作为实机替代，最低部署目标维持 macOS 15.0。规划时核实虚拟机能否用最终 Release 候选覆盖适用的原生窗口、控件和关键调试流程。优先用独立的公开样例复验。虚拟机不可用或无法覆盖的预期记为阻塞。本轮决定更新了原有的实机限定，规划时将相应验收口径同步到项目文档。

**2026-11-14 更新。** 用户确认取消 A31 的 macOS 15 实机及虚拟机运行验收。保留 15.0 部署目标，核对最终候选的两个 Mach-O 文件，明确记录该系统运行兼容性未验证。

### Release 交付

- **D-09:** G3 交付本地 Release `.app`、同一 `.app` 的 ZIP 归档及 ZIP 的 SHA-256。归档保留 App 和内嵌 worker 的签名与执行权限，解包后复验。交付记录关联受测提交和构建，备齐文档、许可证及发布说明。
- **D-10:** G3 复核关于窗口的项目主页、README 和 LICENSE 目标地址及浏览器打开行为。公开分发前再复验三个地址的匿名可访问性。
- **D-11:** G3 沿用 G0 与 Phase 04 的视觉基线及已通过的证据。最终 Release 候选重跑受影响界面的自动检查，仅将受影响界面和新增或改变的视觉差异交给用户确认。

</decisions>

<canonical_refs>
## 规划与实施依据

### 范围与验收

- `AGENTS.md` · 文档优先级、用户项目保护、UI 修改范围和阶段验收。
- `.planning/PROJECT.md`、`.planning/milestones/v0.1-REQUIREMENTS.md`、`.planning/milestones/v0.1-ROADMAP.md` · v0.1 范围、REL-01 至 REL-04 和 Phase 05 完成条件。
- `docs/01-PRODUCT.md` · 产品范围和支持边界。
- `docs/02-TECHNICAL.md` §3–§6、§8 · 任务、项目锁、恢复、设备、进程、日志和关键测试。
- `docs/03-ROADMAP.md` §3–§5 · P5、G3 和里程碑收尾顺序。
- `docs/04-ACCEPTANCE.md` · A13–A16、A22、A26–A31、证据规则和 `prod` 测试准备。A31 的环境选择按 D-08 执行。
- `docs/PUBLIC-RELEASE-AUDIT.md` · 公开分发前的脱敏和复核。

### 已验收的行为和界面

- `.planning/milestones/v0.1-phases/02-config-task-execution-core/02-CONTEXT.md`、`.planning/milestones/v0.1-phases/02-config-task-execution-core/02-P2-ACCEPTANCE.md` · 原任务重试、进程退出确认、公开样例、强退及风险持久化的已有证据。
- `.planning/milestones/v0.1-phases/03-flutter/03-CONTEXT.md`、`.planning/milestones/v0.1-phases/03-flutter/03-G2-ACCEPTANCE.md` · 真实 Flutter 调试、设备断线、VM Service 和日志交互基线。
- `.planning/milestones/v0.1-phases/04-macos/04-CONTEXT.md`、`.planning/milestones/v0.1-phases/04-macos/04-P4-ACCEPTANCE.md` · 启动偏好、原生窗口、关于页链接、Release 构建及 worker 签名证据。
- `docs/design/UI-SPEC.md`、`docs/design/DESIGN-SYSTEM.md`、`docs/design/FIGMA-HANDOFF.md` · G0 视觉基线、原生控件和恢复入口。
- `docs/examples/sample-flutter-app/README.md`、`docs/examples/sample-flutter-app/launch.jsonc`、`docs/examples/sample-flutter-app/tasks.jsonc`、`docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh` · 可隔离复现的任务与恢复样例。

</canonical_refs>

<code_context>
## 现有代码和接入点

- `FlutterRunlet/SessionController.swift` 管理 Run、停止、后置任务、重启发现风险和日志。`FlutterRunlet/ProjectRecoveryStore.swift` 保存风险记录，核对原任务并确认完成持久化。
- `FlutterRunlet/SessionProcess.swift` 和 `FlutterRunletSessionWorker/main.swift` 提供受管进程及项目租约的退出边界。`FlutterRunlet/FlutterRunletApp.swift` 管理启动时的恢复入口和原生退出确认。
- `FlutterRunlet/SessionController.swift` 保留最近 64 KiB 的 UTF-8 日志，以日志代际处理清空边界。`FlutterRunletTests/SessionLogTests.swift` 已覆盖清空、实时日志和裁剪时保持阅读位置。
- `FlutterRunletTests/ProjectRecoveryTests.swift`、`FlutterRunletTests/ProjectConcurrencyTests.swift`、`FlutterRunletTests/SessionLifecycleTests.swift`、`FlutterRunletTests/FlutterDebugSessionTests.swift` 可复用为原任务重试、进程树与并发、任务顺序和设备断线的回归基础。
- `FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme` 是 Debug 测试及 Release 构建的现有入口，沿用 Phase 04 的 App 与 worker 验证方式。

</code_context>

<specifics>
## 取证要求

- 每项关联 A 编号、候选提交或构建、受测系统与复现方式。记录自动证据覆盖的预期和剩余人工复核项。
- Phase 04 的宿主是 macOS 26.7.1。其构建和原生证据可用于各自已验证的条目，A31 以实际 macOS 15 环境的证据判定。
- 强退与压力使用独立公开样例，A29 使用获授权的真实项目副本。用户项目原件由应用只读。

</specifics>

<deferred>
## 后续事项

公开分发安排、面向外部用户的签名和公证、匿名链接复验，以及公开前审计留到分发前处理。

</deferred>
