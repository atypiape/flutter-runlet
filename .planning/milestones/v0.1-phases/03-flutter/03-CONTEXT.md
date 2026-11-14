# Phase 03 · Flutter 调试闭环

**讨论日期** 2026-11-12

**状态** 待规划

<domain>
## 阶段范围

用真实 Flutter 工程跑通 G2。接入 SDK/FVM、设备刷新与选择、iOS 模拟器启动、Debug 会话的启动与停止、热重载与热重启、VM Service、浏览器 DevTools/Inspector 和实时日志。主窗口与菜单栏控制同一会话。覆盖 RUN-01 至 RUN-06，以及 A13、A17–A22、A24 和 A30。

沿用 G1 验收的原生布局和 Phase 02 的配置复验、项目锁、任务顺序、持久恢复记录和重试规则。VS Code 配置是权威来源，由应用只读。Inspector 直达以目标环境实测为准。直达不可用时，打开连接当前会话的 DevTools，并提示用户进入 Inspector。

</domain>

<decisions>
## 实施决定

### 设备选择

- **D-01:** 首次打开项目时，如果启动配置未指定设备，且没有本次应用打开期间的历史选择，只有一台可用设备就自动选中。多台时留空，由用户选择。运行由用户发起。
- **D-02:** 启动前刷新发现已选设备离线时，保留选择并标记离线，禁用「运行」。同一设备重连且其他启动条件满足后，恢复「运行」。
- **D-03:** 切换配置后，如果显式 `deviceId` 与已选设备冲突，保留当前选择，提示目标设备并禁用「运行」。由用户在现有设备菜单中选中配置指定的设备。
- **D-04:** 设备选择只在应用本次打开期间按项目记住。重新打开应用后按当前可用设备和配置规则选择。

### SDK 修复提示

- **D-05:** 项目要求的 FVM SDK 不可用，或已生效的手动 SDK 路径无效时，禁用「运行」，显示具体原因，并提供「打开 Flutter 设置」直达入口。使用技术契约规定的 SDK 解析规则，界面显示与实际执行一致。
- **D-06:** 应用重新激活时，自动重检此前无效的 SDK，让用户在终端修复后切回即可更新状态。重检通过且其他启动条件满足后恢复「运行」，由用户发起启动。
- **D-07:** 当前 SDK 有效时，如果新选的手动路径验证失败，在设置内报错并保留原设置。新路径验证通过后才应用。
- **D-08:** 调试期间可查看当前会话实际使用的 SDK 和版本。会话停止并完成适用的环境恢复后，才允许修改 SDK 设置。

### 等待调试连接

- **D-09:** Flutter 进程仍在而 VM Service 等待过久时，显示「等待较久」，继续等待并保留「停止」。等待期间热重载、热重启和浏览器入口不可用。
- **D-10:** 等待提示的阈值为 60 秒，从 Flutter 调试进程启动时开始计时。前置任务耗时不计入。
- **D-11:** 只有 VM Service 断线且 Flutter 进程和设备仍正常时，显示连接中断，尝试重连当前会话。期间禁用热重载、热重启和浏览器入口，保留「停止」。重连后按当前连接恢复操作。
- **D-12:** 确认调试设备断开时，提示设备断开并主动停止当前会话。如果进程仍在，等确认退出后执行适用的环境恢复。项目锁和未确认退出的处理遵循 Phase 02。

### 日志跨会话

- **D-13:** 停止和适用的恢复结束后，保留本轮日志供查看和复制。下一轮通过启动检查并开始执行时清空。仅校验、配置变更提示或启动被阻断时，保留已有日志。
- **D-14:** 成功切换到另一项目时清空旧项目日志。取消切换或切换失败时保留。
- **D-15:** 日志默认跟随新输出。用户向上查看旧内容时保持阅读位置，滚回底部后恢复跟随。
- **D-16:** 显示和复制日志时保留 VM Service 与 DevTools 链接的地址和端口，遮住连接令牌。其余日志保留原文。浏览器入口使用当前会话的有效连接，按技术契约处理敏感链接。

</decisions>

<canonical_refs>
## 规划与实施依据

规划和实施前须读取以下资料。

### 范围、契约与验收

- `AGENTS.md` · 文档优先级、用户项目保护、UI 修改范围与测试约定。
- `.planning/PROJECT.md` · 产品约束和 G2 调试闭环。
- `.planning/milestones/v0.1-REQUIREMENTS.md` · RUN-01 至 RUN-06 及后续阶段分工。
- `.planning/milestones/v0.1-ROADMAP.md` · Phase 03 目标、依赖与完成条件。
- `docs/01-PRODUCT.md` §2–§7 · 已确认的调试、设备、浏览器和恢复工作流。
- `docs/02-TECHNICAL.md` §2、§4–§6、§8 · 显式设备、生命周期和恢复、SDK/FVM、浏览器连接与关键测试。
- `docs/03-ROADMAP.md` §3–§4 · G2 范围与阶段顺序。
- `docs/04-ACCEPTANCE.md` · A13、A17–A22、A24、A30 及证据判定方式。

### 界面与已有实现

- `docs/design/UI-SPEC.md` §1–§3 · 主窗、菜单栏、调试按钮状态与 Flutter 设置位置。
- `docs/design/DESIGN-SYSTEM.md` · 原生布局、状态和日志设计约束。
- `docs/design/FIGMA-HANDOFF.md` · 已验收视觉基线及日志清空的开发待处理项。
- `.planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-CONTEXT.md` · G1 界面与窗口行为决定。
- `.planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-UPSTREAM-AUDIT.md` · 设备发现、进程与浏览器连接的上游复用边界。
- `.planning/milestones/v0.1-phases/02-config-task-execution-core/02-CONTEXT.md` · 配置重读、任务、项目锁、恢复和重试决定。
- `.planning/milestones/v0.1-phases/02-config-task-execution-core/02-P2-ACCEPTANCE.md` · 任务、监督进程、恢复与隔离样例的已有证据。

### 公开测试样例

- `docs/examples/sample-flutter-app/README.md` · 独立 Flutter 项目准备、真实任务和恢复检查。
- `docs/examples/sample-flutter-app/launch.jsonc` · 启动配置、参数和环境原值。
- `docs/examples/sample-flutter-app/tasks.jsonc` · 前后置任务定义。
- `docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh` · 环境标记与可复现的故障场景。

</canonical_refs>

<code_context>
## 现有代码和接入点

- `FlutterRunlet/FlutterRunletApp.swift` 将同一个 `SessionController` 提供给主窗口、菜单栏和设置。真实调试状态和操作沿用该共享入口。
- `FlutterRunlet/SessionController.swift` 已负责 Run 前配置复验、项目锁、任务调度和恢复。目前正式会话尚无真实调试命令，日志在进程退出后汇入。接入真实会话时沿用其启动和恢复边界。
- `FlutterRunlet/SessionProcess.swift` 与 `FlutterRunletSessionWorker/main.swift` 提供进程监督、输出读取和退出确认。规划时在此评估实时输出、会话控制与进程归属验证。
- `FlutterRunlet/ProjectConfiguration.swift` 已解析显式 `deviceId`。设备校验可复用该字段及现有配置变更复验。
- `FlutterRunlet/MainWindowView.swift` 和 `FlutterRunlet/MenuBarPanelView.swift` 已共用调试与浏览器按钮组件。主窗已有可折叠的日志区。`FlutterRunlet/AuxiliaryWindows.swift` 已提供「Flutter」设置页入口。
- `FlutterRunletTests/SessionLifecycleTests.swift`、`FlutterRunletTests/ProjectConcurrencyTests.swift` 和 `FlutterRunletTests/ProjectSelectionTests.swift` 可作为任务时序、进程退出、项目互斥和配置复验的回归基础。

</code_context>

<specifics>
## G2 验收要点

- 在独立的真实 Flutter 工程中使用公开样例，至少完成 iOS 模拟器的 Debug 启动。Android 模拟器和真机按实际可用性实测或记录不适用原因。
- 核对 SDK 版本显示与实际运行一致、FVM 无效阻断、设备重连与显式设备冲突。验证主窗关闭后仍能从菜单栏控制同一会话。
- 确认热重载和热重启实际作用于当前会话。验证 VM Service 等待、仅连接断开和设备确认断开时的行为。验证 DevTools 和 Inspector 连接本次会话、Inspector 可选取 Widget，以及新会话绑定更新。
- 用公开 dev/test/prod 配置验证任务顺序和正常停止后的 `prod` → `test`。验证日志清空后折叠、展开不会恢复旧内容，仍能接收新输出。

</specifics>

<deferred>
## 后续阶段

完整双语、外观与设置验收按 Phase 04 推进。压力测试、应用强制终止后恢复和获授权的真实项目回归按 Phase 05 推进。此次讨论未新增延后事项。

</deferred>

---

*Phase 03 · Flutter 调试闭环*

*上下文确认于 2026-11-12*
