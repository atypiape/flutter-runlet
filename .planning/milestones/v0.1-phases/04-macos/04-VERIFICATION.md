---
phase: 04-macos
verified: 2026-11-13T19:16:00Z
status: passed
score: 12/12 must-haves verified
covered_files: [
  ".planning/milestones/v0.1-phases/03-flutter/03-G2-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/04-macos/04-01-PLAN.md",
  ".planning/milestones/v0.1-phases/04-macos/04-01-SUMMARY.md",
  ".planning/milestones/v0.1-phases/04-macos/04-02-PLAN.md",
  ".planning/milestones/v0.1-phases/04-macos/04-02-SUMMARY.md",
  ".planning/milestones/v0.1-phases/04-macos/04-03-PLAN.md",
  ".planning/milestones/v0.1-phases/04-macos/04-03-SUMMARY.md",
  ".planning/milestones/v0.1-phases/04-macos/04-04-PLAN.md",
  ".planning/milestones/v0.1-phases/04-macos/04-04-SUMMARY.md",
  ".planning/milestones/v0.1-phases/04-macos/04-05-PLAN.md",
  ".planning/milestones/v0.1-phases/04-macos/04-05-SUMMARY.md",
  ".planning/milestones/v0.1-phases/04-macos/04-CONTEXT.md",
  ".planning/milestones/v0.1-phases/04-macos/04-DISCUSSION-LOG.md",
  ".planning/milestones/v0.1-phases/04-macos/04-P4-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/04-macos/04-PATTERNS.md",
  ".planning/milestones/v0.1-phases/04-macos/04-RESEARCH.md",
  ".planning/milestones/v0.1-phases/04-macos/04-REVIEW.md",
  ".planning/milestones/v0.1-phases/04-macos/04-SECURITY.md",
  ".planning/milestones/v0.1-phases/04-macos/04-UAT.md",
  ".planning/milestones/v0.1-phases/04-macos/04-UI-REVIEW.md",
  ".planning/milestones/v0.1-phases/04-macos/04-UI-SPEC.md",
  ".planning/milestones/v0.1-phases/04-macos/04-VALIDATION.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-01-SUMMARY.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-ENVIRONMENT.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-G3-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-LOG-STRESS.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-RECOVERY.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-UI-REVIEW.md",
  "FlutterRunlet.xcodeproj/project.pbxproj",
  "FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme",
  "FlutterRunlet/Assets.xcassets/AppIcon.appiconset/Contents.json",
  "FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-1024.png",
  "FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-128.png",
  "FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-16.png",
  "FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-256.png",
  "FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-32.png",
  "FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-512.png",
  "FlutterRunlet/Assets.xcassets/AppIcon.appiconset/flutterrunlet-dock-64.png",
  "FlutterRunlet/AuxiliaryWindows.swift",
  "FlutterRunlet/FlutterDebugSession.swift",
  "FlutterRunlet/FlutterRunletApp.swift",
  "FlutterRunlet/FlutterToolchain.swift",
  "FlutterRunlet/JSONCReader.swift",
  "FlutterRunlet/LaunchPresentation.swift",
  "FlutterRunlet/Localizable.xcstrings",
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
  "FlutterRunletTests/SessionLogTests.swift",
  "LICENSE",
  "docs/01-PRODUCT.md",
  "docs/02-TECHNICAL.md",
  "docs/04-ACCEPTANCE.md",
  "docs/design/DESIGN-SYSTEM.md",
  "docs/design/UI-SPEC.md",
  "docs/examples/sample-flutter-app/README.md",
  "docs/examples/sample-flutter-app/launch.jsonc",
  "docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh",
  "docs/examples/sample-flutter-app/tasks.jsonc"
]
covered_digest: "v3:sha256:511659431d2cdfc3d144a65cb9fea72e591f7b27dc09b023f83f36a8e150f47f"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 7
  total: 7
---

# Phase 04 · macOS 界面与双语设置验证

目标为按 G0 基线完成原生界面、本地化、设置与图标。5 份计划均已执行，12 项可观察预期全部通过。A04 已获用户确认。 [路线](../../v0.1-ROADMAP.md#phase-4-macos-界面与双语设置) · [阶段验收](04-P4-ACCEPTANCE.md)

## 最终候选复核

在 2026-11-14 复核冻结候选 `36916dd1f6a6f916a1c76ca93aa37ae84f8247f6`。当前工作区的已跟踪应用源码、测试、worker 和 Xcode 工程与该候选逐文件一致。对照 5 份计划和摘要、路线图、需求追踪表及 G3，确认 UI-01–UI-06、原 12 项可观察预期和对应的 9 项验收均有证据。下方保留 Phase 04 原验证、候选标识和用户验收。此次复核沿用已完成的构建、自动测试与原生记录。

| 核对范围 | 最终候选及可沿用证据 |
| --- | --- |
| 原验证 1、4、5、6、7 · A03、A05、A21 · UI-01 | G3 复验主窗和面板的 Running、等待、停止、恢复错误、日志外恢复和同会话控制。对照 `184ffc5..36916dd`，主窗视图仅调整日志呈现，场景路由、菜单栏、长名控件和快捷键实现保持原样。Phase 04 的双外观、锁定长名、Tab／Shift-Tab、四功能键及前后台对照可沿用。G3 对受影响的日志、控件和深色布局复验通过。[G3 矩阵](../05-stability-recovery-release/05-G3-ACCEPTANCE.md) · [G3 原生审查](../05-stability-recovery-release/05-VERIFICATION.md) · [P4 原生基线](04-P4-ACCEPTANCE.md#原生复验与差异) |
| 原验证 1、8 · A05、A23 · UI-02 | G3 复验主窗、面板、控件名及日志的中英文。场景 locale 注入、偏好持久化和本地化资源自登录候选未变，沿用 Phase 04 的即时切换、重启、跟随系统、原始参数保真和系统原生按钮差异。最终 Debug 全量与定向启动回归通过。[G3 矩阵](../05-stability-recovery-release/05-G3-ACCEPTANCE.md) · [最终自动验证](../05-stability-recovery-release/05-VERIFICATION.md) · [P4 验收](04-P4-ACCEPTANCE.md#验收矩阵) |
| 原验证 2、9、10、12 · A04、A24、A25 · UI-03、UI-04 | `184ffc5` 的登录项登记、真实重新登录、主窗偏好和撤销由系统日志及用户确认。App、设置视图、SDK 与 Doctor 实现在该提交至最终候选无变。G3 复验启动偏好与待恢复优先，最终工具链 XCTest 复核 FVM 解析、无效 SDK、诊断与收尾路径。沿用 Phase 04 对真实 FVM 版本、阻断、Doctor 三项摘要、双流输出、取消及重试的原生实测。登录项用户验收 · [P4 验收](04-P4-ACCEPTANCE.md#验收矩阵) · [G3 恢复矩阵](../05-stability-recovery-release/05-VERIFICATION.md) |
| 原验证 3、11 · A06、A26 · UI-05、UI-06 | G3 复验独立关于页 0.1.0（1）、上游归属、版权和三个浏览器目标，并核对最终 Release 包资源。Dock 源图、两倍率状态模板、资源编译设置和两语言资源自 Phase 04 保持一致，双外观辨识沿用其已验收结果。冻结候选的同源 Debug 77/77、Release 构建与签名均通过。[G3 原生审查](../05-stability-recovery-release/05-VERIFICATION.md) · [最终构建证据](../05-stability-recovery-release/05-VERIFICATION.md) · [P4 图标与关于验收](04-P4-ACCEPTANCE.md#验收矩阵) |

复核结论为通过。已核对 Phase 04 安全记录无开放威胁、任务验证已签核。匿名访问沿用 A26 已确认的发布验收边界。

## 可观察结果

| 序号 | 预期 | 判定 | 证据 |
| --- | --- | --- | --- |
| 1 | 路线要求的主窗与菜单栏一致，日志外有恢复操作，双语、两种系统外观和长名称有原生证据。 | 已验证 | 同一会话、四组布局、原名弹出层与恢复状态均有 AX、按键或截图证据。 [A03、A05、A21、A23](04-P4-ACCEPTANCE.md#验收矩阵) |
| 2 | 路线要求的通用与 Flutter 设置分工、真实 SDK/FVM 信息与环境检测摘要和原文。 | 已验证 | 原生设置仅含两类，实际 SDK 元数据仅在 Flutter 页。三类摘要与双流详情均在生产设置接通。登录项系统实测在第 12 项。 [设置实现](../../../../FlutterRunlet/AuxiliaryWindows.swift) · [A04、A24、A25](04-P4-ACCEPTANCE.md#验收矩阵) |
| 3 | 路线要求的独立关于、真实版本与许可、已确认链接、两种外观的图标及原生差异记录。 | 已验证 | 实际版本 0.1.0、构建 1，Flutter GUI Runner 归属、上游版权和 MIT，三个 HTTPS 链接交给默认浏览器。Dock 与同源模板在两种外观显示。 [A06、A26](04-P4-ACCEPTANCE.md#验收矩阵) |
| 4 | 空白、就绪、启动、等待、运行、停止、恢复和错误使用共享会话。运行中 Run 禁用，等待连接时热操作与浏览器受守卫。关主窗后仍可控制原会话。 | 已验证 | 主窗和面板共享同一生产控制器，真实会话的 PID、状态和操作验证，以及会话生命周期回归。 [应用路由](../../../../FlutterRunlet/FlutterRunletApp.swift) · [A03、A21](04-P4-ACCEPTANCE.md#验收矩阵) |
| 5 | 恢复失败的原原因和任务两处一致。折叠主窗日志后仍可显式恢复原任务。 | 已验证 | 原生后置失败保留退出码 1 和风险记录。菜单栏重试后从 prod 恢复 test、风险由 1 变 0。恢复和并发回归验证原任务、租约与重试守卫。 [恢复实现](../../../../FlutterRunlet/SessionController.swift#L452) · [恢复复验](04-P4-ACCEPTANCE.md#原生复验与差异) |
| 6 | 四个功能键和按钮共用启用条件，只在受管窗口焦点生效，重复键及后台无动作，原生键盘导航保留。 | 已验证 | 前台主窗、日志焦点、仅菜单栏和 Finder 对照证据，F5 映射和会话动作回归，Tab、Shift-Tab 和 Space 记录。 [本地键盘路由](../../../../FlutterRunlet/FlutterRunletApp.swift#L460) · [A05、A21](04-P4-ACCEPTANCE.md#验收矩阵) |
| 7 | 双语四键标签同排，长名截断时可查完整原名，选择锁定期间入口仍可达。 | 已验证 | 640 pt 主窗与 404 pt 面板均有浅深和英中布局证据，锁定配置可点击，设备全名可经键盘打开，辅助提示保留原值。 [长名与按钮实现](../../../../FlutterRunlet/MainWindowView.swift) · [A05](04-P4-ACCEPTANCE.md#验收矩阵) |
| 8 | 四场景和应用自有提示即时使用同一语言，重启恢复偏好，跟随系统按顺序选择，应用生成的错误翻译且原始参数保留。 | 已验证 | 四场景共享可观察语言及资源。现存错误、应用自有菜单和 AppKit 提示有切换证据。Bundle 回归、系统语言排序、已保存偏好、原值插值及日志遮罩均通过。原生系统按钮仍由 macOS 本地化，差异已记录。 [语言实现](../../../../FlutterRunlet/FlutterRunletApp.swift) · [A23](04-P4-ACCEPTANCE.md#验收矩阵) |
| 9 | 主窗和最近项目偏好持续生效，关闭主窗启动时无 Dock 项。待恢复、显式打开或重开时仅一扇主窗，任务等待明确操作。 | 已验证 | 生产启动决定接入场景与激活策略。候选从仅菜单栏打开设置保持 accessory 和零主窗，显式打开为 regular 和一窗。恢复优先与未记住项目组合通过。 [启动回归](../../../../FlutterRunletTests/LaunchPresentationTests.swift#L120) · [原生复验](04-P4-ACCEPTANCE.md#审查修正复验) |
| 10 | 实际 SDK/FVM 解析和原锁定、无效 FVM 阻断、环境检测失败重试与过期结果丢弃。 | 已验证 | 真实 Flutter 3.47.4 / Dart 3.13.3 与 FVM 一致，缺失链接时 Run 禁用。真实 doctor 的状态对应原文。脚本回归验证调用参数、双流、取消、超时、超限与过时请求。最终候选原生 Quit 及 XCTest 验证诊断清理。 [诊断实现](../../../../FlutterRunlet/FlutterToolchain.swift#L409) · [A24、A25](04-P4-ACCEPTANCE.md#验收矩阵) |
| 11 | 同一候选 Debug 全量及 Release 构建，图标、两种语言与签名 worker 齐全。九项证据可追溯并记录差异。 | 已验证 | `97a6713` Debug 75/75，Release 成功，双包图标、1x/2x 模板、编译语言资源、执行位和签名均通过。验收逐项说明完整原生基线与审查修正复验的来源。 [构建及签名](04-P4-ACCEPTANCE.md#受测构建) |
| 12 | 登录项默认不注册，反映系统授权状态，实际可登记、批准、重新登录启动及取消。 | 已验证 | 生产使用 `SMAppService.mainApp`，初始化只查询，用户明确切换才调用写入。候选 `184ffc5` 已实际验证登录启动和主窗偏好，用户确认撤销后重新登录无自动启动。 [系统接口](../../../../FlutterRunlet/FlutterRunletApp.swift#L63) · [A04 剩余验收](04-P4-ACCEPTANCE.md#剩余验收) |

## 产物与关键连接

| 产物 | 已核对的生产连接及动态数据 |
| --- | --- |
| 主窗、菜单栏和共享会话 | App 向主窗与菜单栏传入同一个控制器。两处渲染生产状态、恢复原因和当前操作条件，调用同一 `RecoveryDetails` 和 `DebugControls`；本地功能键调用同一动作守卫。 [主窗](../../../../FlutterRunlet/MainWindowView.swift) · [菜单栏](../../../../FlutterRunlet/MenuBarPanelView.swift) · [控制器](../../../../FlutterRunlet/SessionController.swift) |
| 双语资源与四个场景 | 通用绑定写入语言偏好。主窗、菜单栏、设置和关于使用同一 locale，AppKit 走同一翻译资源。编译产物含两个语言目录，已形成的会话错误按当前 locale 渲染。 [场景注入](../../../../FlutterRunlet/FlutterRunletApp.swift) · [资源](../../../../FlutterRunlet/Localizable.xcstrings) |
| 通用和 Flutter 设置 | 默认启动窗口及恢复优先来自已加载恢复记录。登录项 UI 接系统状态。诊断按钮经控制器把当前 SDK 与项目、请求 ID 绑定给 `FlutterToolchain.doctor`。摘要和完整输出来自实际两路输出。 [设置](../../../../FlutterRunlet/AuxiliaryWindows.swift) · [诊断归属](../../../../FlutterRunlet/SessionController.swift#L632) |
| 关于与图标 | 关于从运行 Bundle 取真实版本和构建号，使用三个固定链接。Xcode 应用目标的 Debug 和 Release 设置都选择 AppIcon，图标槽指向已验收源图。菜单栏原有模板带两种密度。 [关于实现](../../../../FlutterRunlet/AuxiliaryWindows.swift#L267) · [构建设置](../../../../FlutterRunlet.xcodeproj/project.pbxproj) · [图标槽](../../../../FlutterRunlet/Assets.xcassets/AppIcon.appiconset/Contents.json) |
| 验收与覆盖记录 | 阶段记录以九个验收编号关联构建、原生观察、回归及系统登录项用户验收。 [矩阵](../../../../docs/04-ACCEPTANCE.md) · [阶段验收](04-P4-ACCEPTANCE.md) · 覆盖审计 |

## 验收矩阵与需求覆盖

| 验收 | 关联需求 | 结果 |
| --- | --- | --- |
| A03 | UI-01 | 通过。共享状态、日志外恢复与原任务重试。 |
| A04 | UI-03、UI-05 | 通过。系统登记、登录启动、主窗偏好和撤销均已验证。两类设置、独立关于、偏好、主窗与恢复入口通过。 |
| A05 | UI-01、UI-02 | 通过。两种语言、外观、原生同排控件、长名悬停和键盘操作。 |
| A06 | UI-06 | 通过。双包图标及模板，两种外观实际辨识。 |
| A21 | UI-01 | 通过。关闭主窗仍操作同一会话，前台焦点与后台对照通过。 |
| A23 | UI-02 | 通过。四场景与自有 AppKit 反馈，系统跟随、重启保留与原值。 |
| A24 | UI-03 | 通过。真实 FVM 身份及版本、锁定与无效路径阻断。 |
| A25 | UI-04 | 通过。三类摘要、双流原文、取消、重试和退出清理。 |
| A26 | UI-05 | 通过。真实版本、归属、版权及三条确认链接的浏览器委派。匿名可访问性由 D-07 明确留待发布验收。 |

UI-01 至 UI-06 均已覆盖。GSD 决策覆盖检查返回 7/7，验证阶段未将该结果作为实际登录的运行证据。 [需求](../../v0.1-REQUIREMENTS.md#界面与设置) · [候选矩阵证据](04-P4-ACCEPTANCE.md#验收矩阵) · 阶段决定

## 回归与证据边界

- 独立读取最终候选 `97a6713` 的 `debug.xcresult`，确认九个测试类共 75 项通过、0 失败、0 跳过。Release 构建日志成功，两个包的图标、编译语言资源、主程序与 worker 哈希与验收清单一致。新候选的菜单栏设置保持零主窗、显式重开保持唯一、诊断双流显示及菜单栏 Quit 清理均有可复查原生证据。 [受测构建](04-P4-ACCEPTANCE.md#受测构建) · [审查后原生复验](04-P4-ACCEPTANCE.md#审查修正复验)
- 审查前候选 `988ac81` 的完整原生证据包含 16 张四窗口截图、真实 iOS 模拟器、语言与 FVM 操作、恢复、快捷键、图标和 Release 夹具隔离。两候选的生产差异集中在退出诊断、菜单栏设置激活和诊断详情字体。确认相应路径已在最终候选复验，其余原生结论引用基线。 [原生复验与差异](04-P4-ACCEPTANCE.md#原生复验与差异) · UI 审查
- 代码复审关闭两项历史问题。安全审计 14 项关闭、0 项未关闭。A04 经用户实测关闭覆盖缺口。生产连接抽查未发现阻断性缺失。 代码审查 · 安全复核 · 覆盖审计

## 用户验收

用户确认新版登录后主窗行为符合偏好，并确认撤销登录项后重新登录，菜单栏图标未自动出现。只读复核未发现应用进程或系统登录项记录。 A04 用户验收
