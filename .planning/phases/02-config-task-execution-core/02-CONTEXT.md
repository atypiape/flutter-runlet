# Phase 02 · 配置和任务执行内核

**讨论日期** 2026-11-12

**状态** 待规划

<domain>
## 阶段范围

交付 Flutter 项目打开、切换和配置重读，按现有契约解析并校验 JSONC、启动参数、工作目录、环境和前后置任务。实现项目互斥、任务失败阻断、持久恢复记录和恢复重试。覆盖 CONF-01 至 CONF-05、TASK-01 至 TASK-02、SAFE-01 至 SAFE-04，以及 A07–A16 和 A32。

`.vscode/launch.json` 和 `.vscode/tasks.json` 是启动和任务的权威来源，应用只读。配置名称原样显示，仅允许有效的 Dart Flutter Debug 配置进入执行阶段。主窗口和菜单栏共用项目及会话状态，沿用 G1 原生结构。

</domain>

<decisions>
## 实施决定

### 配置重读

- **D-01** 手动重读 `.vscode/launch.json` 遇到语法错误时，保留当前项目及上次成功加载的列表和选中项。将列表标为过期并禁用，禁用 Run，并显示文件名、错误位置及原因。
- **D-02** 重读成功后，如果原选中项被删除或改名，清除选择并提示原配置已不存在，由用户重新选择。
- **D-03** Run 前重新读取并校验配置和所引用的任务。如果当前选择的有效启动参数或任务已变更且新内容合法，先更新界面并提示变更。这次点击到此结束，用户再次点击 Run 才进入任务执行。注释和格式变化由解析结果判断是否影响实际执行。
- **D-04** 启用「记住最近打开的项目」时，App 重启自动打开上次成功打开的项目并重读配置。调试启动由用户主动发起。待恢复项目的入口遵循 D-08。

### 恢复触发

- **D-05** 凡是声明 `postDebugTask` 的有效配置都写入持久恢复记录，包含只有后置任务的配置。有前置任务时，在启动前置任务之前写入。只有后置任务时，在启动 Flutter 进程之前写入。恢复任务以配置中声明的任务为准。

### 恢复执行与重试

- **D-06** 正常退出后的首次自动恢复使用启动前已验证、保留在内存中的原后置任务。会话中对 `tasks.json` 的改动留待后续加载，首次恢复仍按本次会话的任务定义执行。
- **D-07** 重试使用风险记录中的项目和原后置任务标签，对照当前任务定义。原任务缺失、无效或命令、参数、工作目录等任务定义发生变更时，保留风险并指出阻断原因。恢复原任务定义后，用户可重试。同名任务也要通过此检查。
- **D-08** 启动发现待恢复记录时，在启动界面显示对应项目和待恢复任务，恢复入口放在日志之外。若按偏好本来会打开另一个项目，或已关闭「记住最近打开的项目」，用户点击恢复入口后再打开待恢复项目。
- **D-09** 重试时也要核对原后置任务显式引用的环境变量解析值。若发生变化，保留风险，只提示发生变化的变量名，恢复原值后可重试。任务成功退出后才清除风险。

### 项目切换与初始选择

- **D-10** Flutter 仍在运行时发起项目切换，提示先停止当前会话并完成适用的恢复。切换由用户在完成后重新发起。恢复进行中或失败时仍按项目锁及恢复约束处理。
- **D-11** 目标目录通过 Flutter 项目校验后，若 `launch.json` 缺失或格式错误，打开目标项目、显示配置错误并禁用 Run。用户修复后可以重读。
- **D-12** 首次打开项目并成功读取配置时，只有一项可用就自动选中，多项可用则留空，由用户明确选择。运行始终由用户发起。

### 任务文件损坏

- **D-13** `tasks.json` 缺失或无法解析时，显示任务文件错误，只阻断引用了前置或后置任务的配置。其余合法配置仍可进入正常运行校验。

### 启动配置重名

- **D-14** 同名启动配置均保留原显示名，标为不可用，提示用户在配置文件中改名。重读时若已选中的配置变为重名，按不可用配置处理。

### 人工验收入口

- **D-15** 用 Debug 版 App 主窗和隔离的公开样例走完整任务与恢复流程。前后置脚本实际执行，Flutter 进程用可控进程代替。验收入口走实际的项目、任务、互斥和恢复逻辑，观察状态和提示，并保留适用的截图或命令输出。

</decisions>

<canonical_refs>
## 规划与实施依据

### 项目与阶段

- `AGENTS.md` · 文档优先级、用户项目保护、UI 修改范围和测试约定。
- `.planning/PROJECT.md` · 项目范围和约束。
- `.planning/REQUIREMENTS.md` · CONF、TASK、SAFE 的需求与阶段映射。
- `.planning/ROADMAP.md` · Phase 02 目标、依赖和完成条件。
- `docs/01-PRODUCT.md` §2–§5 · 配置权威来源、项目操作与恢复安全原则。
- `docs/02-TECHNICAL.md` §1–§4、§8 · 共享状态、只读配置、任务执行、项目锁、恢复与最小测试。
- `docs/03-ROADMAP.md` §3–§4 · P2 范围和阶段验收流程。
- `docs/04-ACCEPTANCE.md` · A07–A16、A32 及 P3、P5 的对应复验。

### 界面、复用与验收样例

- `docs/design/UI-SPEC.md` §1–§3 · 主窗与菜单栏职责、不可用配置原因、日志外恢复入口、记住最近项目偏好。
- `.planning/phases/01-upstream-audit-ui-shell/01-CONTEXT.md` · G1 演示入口和已确认的原生结构。
- `.planning/phases/01-upstream-audit-ui-shell/01-UPSTREAM-AUDIT.md` · 上游进程、日志及依赖的复用边界。
- `docs/examples/sample-flutter-app/README.md` · 隔离样例准备、任务顺序及故障注入。
- `docs/examples/sample-flutter-app/launch.jsonc` · 四套配置原名、旧 `args`、`toolArgs` 和 macOS PATH。
- `docs/examples/sample-flutter-app/tasks.jsonc` · 脚本命令、参数、工作目录和前后置任务标签。
- `docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh` · 模拟 Firebase 环境切换及失败场景。

</canonical_refs>

<code_context>
## 现有代码和接入点

- `FlutterRunlet/FlutterRunletApp.swift` 创建主窗口和菜单栏面板，向两处传入同一个 `LaunchPresentation` 值与演示 Run 回调。可从此接入共享项目和会话状态。
- `FlutterRunlet/LaunchPresentation.swift` 定义 Empty 和 Ready，以及 Debug 专用 `--g1-ready` 演示。正式项目选择、错误和恢复状态需要对应的真实数据。
- `FlutterRunlet/MainWindowView.swift` 已有「打开项目」工具栏位置、项目与配置显示、会话状态和日志区。`FlutterRunlet/MenuBarPanelView.swift` 复用 `PresentationField` 和 `DebugControls`。沿用现有结构接入项目显示、操作和阻断原因。
- `FlutterRunletTests/LaunchPresentationTests.swift` 已覆盖 G1 的启动呈现。公开 JSONC 和脚本可用于配置、真实任务执行和恢复回归。Phase 01 审计未导入上游代码，进程复用按审计结论评估。

</code_context>

<specifics>
## 验收要点

- 在隔离的样例项目中使用原样 JSONC，核对四套配置原名、路径含空格、参数原值与顺序、macOS PATH、非 Debug 与无效任务的执行层阻断。比较执行前后的配置文件内容。
- 使用公开脚本的 `fail-before-dev`、`fail-before-test`、`fail-after-prod` 验证前置阻断、后置恢复失败和前置部分写入。配合可控进程核对退出后才执行后置任务、重启能发现风险、重试成功清除记录，以及运行和切换互斥。
- 增补本次确认的边界覆盖，包括重读失败后禁用过期项、当前任务改动后再次点击 Run、同名项禁用、与任务文件错误无关的配置可用，以及恢复任务定义或其显式环境引用变化时阻断重试。

</specifics>

<deferred>
## 后续阶段

- Phase 03 接入真实 Flutter 进程、SDK/FVM、设备、热操作与浏览器调试，并用真实调试会话复验任务顺序和恢复。
- Phase 04 验收完整双语、设置与主窗及菜单栏状态。Phase 05 按验收矩阵复验异常退出、恢复与获授权的真实项目。

</deferred>

---

*Phase 02 · 配置和任务执行内核*

*上下文确认于 2026-11-12*
