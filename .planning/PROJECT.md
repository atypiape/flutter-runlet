# FlutterRunlet

## What This Is

FlutterRunlet 是面向使用终端或其他编辑器的 Flutter 开发者的 macOS 原生调试工具。开发者可以打开项目，从现有 VS Code 配置选择启动环境和设备，在主窗口或菜单栏管理 Debug 会话，并用默认浏览器检查当前运行实例。

## Core Value

开发者无需打开 VS Code 即可复用项目已有配置完成 Flutter Debug，并在会话结束后按原配置恢复环境。

## Requirements

### Validated

- G0 最终 Figma 原型已通过视觉验收，覆盖主要窗口、双语、深浅外观和恢复流程。
- Phase 1 已完成 Flutter GUI Runner 上游审计、原生窗口和菜单栏骨架、macOS 15.0 部署构建验证，并通过 G1 用户验收。[阶段验证](milestones/v0.1-phases/01-upstream-audit-ui-shell/01-VERIFICATION.md)
- Phase 2 已验证只读项目配置、JSONC、启动参数和任务执行。单项目租约保护前后置任务及 prod 恢复，失败后可重试原恢复任务。[阶段验证](milestones/v0.1-phases/02-config-task-execution-core/02-VERIFICATION.md)
- Phase 3 已在真实 iOS 和 Android 模拟器验证 SDK、设备、热操作、共享会话、默认浏览器 Inspector、实时日志和 prod 恢复，通过 G2。[验收记录](milestones/v0.1-phases/03-flutter/03-G2-ACCEPTANCE.md) · [阶段验证](milestones/v0.1-phases/03-flutter/03-VERIFICATION.md)
- Phase 4 已验收双语、系统深浅外观、通用与 Flutter 设置、独立关于窗口及图标。系统登录项已实测启动、主窗偏好和撤销。[阶段验证](milestones/v0.1-phases/04-macos/04-VERIFICATION.md)
- Phase 5 已完成异常恢复、30 分钟日志压力、授权工程三环境与 VS Code 对照、最低部署目标核对和同一候选签名交付，通过 G3。[最终验收](milestones/v0.1-phases/05-stability-recovery-release/05-G3-ACCEPTANCE.md)
- v0.2 交付共用调试控件、项目与设备选择、原位恢复和日志、设置与关于，以及正式版查询和隔离安装回退。14 项需求全部通过本地验收。[需求档案](milestones/v0.2-REQUIREMENTS.md)

### Active

- [ ] 独立 DevTools 按需连接当前会话，Inspector 复用标签并跳转到所选编辑器。
- [ ] 修复启动期间丢失页面请求、服务退出后重开旧地址及源码订阅失败后不重试。
- [ ] 整理 DevTools 设置页，在通用设置补上应用外观选择。
- [ ] 保留 真实项目验收、内存对比及测量口径，评估进程拆分能否降低整套调试占用。

### Out of Scope

- IDE 的内嵌源码编辑和 DAP 调试界面超出轻量调试工具范围。
- 构建签名发布管理、包管理、Git、复杂脚本和 SDK 安装升级由现有工具处理。
- 独立全功能 Doctor、内嵌 DevTools 和自建 Inspector 超出调试入口范围。
- Windows/Linux、远程调试、云账号、遥测和多设备并行运行超出当前范围。
- 自定义环境变量编辑器会引入第二套配置来源，继续以用户项目配置为准。

## Current State

- v0.2 已完成本地验收并归档。两阶段、10 份计划和 14 项需求全部通过。新 DMG 为 v0.2.0（构建 201），已验证双架构签名、解包启动及三处版本显示。[里程碑审计](milestones/v0.2-MILESTONE-AUDIT.md)
- 最低部署目标为 macOS 15.0，实测宿主为 Apple Silicon macOS 26.7.1。Intel 实机、最低系统实机与 VoiceOver 实际朗读仍待覆盖。[验收边界](milestones/v0.2-MILESTONE-AUDIT.md#nyquist-与验收边界)
- 公开发布、Developer ID 签名、公证和公开可用性复核继续暂缓。[公开发布检查](../docs/PUBLIC-RELEASE-AUDIT.md)

## Current Milestone: v0.3 Inspector 与设置

在不更改项目 Flutter 与 Dart SDK 的情况下，完善独立 DevTools 和 Inspector 工作流，并使 DevTools 与外观偏好更容易找到。[需求](REQUIREMENTS.md) · [路线图](ROADMAP.md)

## Context

- [产品需求](../docs/01-PRODUCT.md)定义范围，[技术契约](../docs/02-TECHNICAL.md)定义配置、任务、会话与恢复行为。
- [开发路线](../docs/03-ROADMAP.md)定义 G1 原生骨架、G2 调试闭环和 G3 最终验收。[验收矩阵](../docs/04-ACCEPTANCE.md)定义各阶段测试条件。
- [设计交接](../docs/design/FIGMA-HANDOFF.md)、[UI 规格](../docs/design/UI-SPEC.md)和[设计系统](../docs/design/DESIGN-SYSTEM.md)记录 G0 基线及开发待处理项。
- [公开示例](../docs/examples/sample-flutter-app/README.md)覆盖 dev、physical、test、prod 与模拟 Firebase 恢复。配置名称原样展示，由实际选择确定设备。
- Inspector 直达保留按版本判断及已连接 DevTools 回退。G3 复验两轮会话地址绑定，最终验证复核补验了传输断开及同端点重连。

## Constraints

- **平台**：Swift 6，SwiftUI 优先，AppKit 按需补充。最低部署目标为 macOS 15.0，P1 验证构建和 API 可用性，P5 核对最终候选的实际部署目标。
- **配置来源**：现有 `.vscode/launch.json` 与 `.vscode/tasks.json` 为权威来源。应用保留原文件，按契约透传值并明确报告不支持项。
- **环境恢复**：同项目的会话和环境切换互斥。prod 启动前持久化风险，Flutter 退出后按配置执行恢复，成功后才清除风险。恢复是发布门槛。
- **隐私**：应用默认避免持久化未遮罩的 VM Service URL。真实项目源码、私有配置与设计播放入口留在独立环境。
- **设计**：v0.2 按已确认原型采用自定义控件外观，保留 macOS 窗口、键盘与辅助功能行为。私有原型入口见本地交接。
- **验收**：各阶段优先使用可复现的自动证据。自动验证完整覆盖且通过的验收项无需人工复核，只把未覆盖部分交给用户。按[验收矩阵](../docs/04-ACCEPTANCE.md#如何使用)归档证据与提交记录，达到门槛后再进入下一阶段。

## Key Decisions

| 决策 | 依据 | 状态 |
|---|---|---|
| 沿用 G0 最终同步稿与原生控件 | 设计交接及原生实验 | G1 原生骨架已验收 |
| 先审计，再按需导入 Flutter GUI Runner | 优先复用可验证的能力并保留必要许可与版权 | P1 已审计，未导入上游源码或资源 |
| 仅支持 Debug，复用项目原有任务与参数 | 保持日常调试和环境恢复与现有工作流一致 | G2 实测通过 |
| 主窗口与菜单栏控制同一会话 | 窗口关闭后仍可管理当前实例 | G2 实测通过 |
| Inspector 直达按实测版本启用，其余打开已连接的 DevTools | 入口只连接当前会话，并提供可用回退 | G2 实测及回归通过 |
| 登录时启动由用户启用，主窗按已保存偏好呈现 | 登录启动和窗口显示分别遵循系统登记及应用偏好 | P4 实测通过 |
| 沿用 P1–P5 及 G1–G3 门槛 | 按交接顺序交付骨架、调试闭环及本地验收 | 5 个阶段全部验收 |
| 恢复完成后解除风险 | 等待整个受管进程组退出，原后置任务成功后清除持久标记 | G3 复验正常、失败与强退恢复 |
| 按同一冻结候选验收 | 将原生、模拟器、真实工程、日志负载、签名和解包证据关联到构建 | G3 本地验收通过 |
| 分开当前调试设备与下次启动选择 | 热操作和浏览器继续使用发起会话时的设备快照 | v0.2 双设备及恢复联验通过 |
| 主窗与菜单栏停用 Tab 焦点，辅助窗口保留原生键盘行为 | 两类窗口按已获批准的交互规则复验 | v0.2 AX 和原生键盘检查通过 |
| 先冻结视觉证据，再接通正式版查询及隔离安装 | 在同一状态验收基础上核对真实数据、安装门禁与失败回退 | v0.2 视觉和隔离 A/B 验收通过 |

## Evolution

1. 每次 Phase 验收后同步已验证需求、失效需求、新增需求和关键决策。
2. 每次里程碑结束后复核产品定义、核心价值、范围和当前上下文。

---
*最后更新于 2026-11-16，开始 v0.3。*
