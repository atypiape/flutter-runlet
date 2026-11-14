---
phase: 06-main-window-menu-bar
verified: 2026-11-15
candidate: f96a8d6096fccec5e1a8b5e7e93f6d36f670c105
status: passed
score: 14/14 must-haves verified in approved scope
prior_automated_verification:
  candidate: f96a8d6096fccec5e1a8b5e7e93f6d36f670c105
  passed_tests: 90
  failures: 0
  skipped: 0
  release_build: passed
  signature: passed
covered_files: [
  ".planning/REQUIREMENTS.md",
  ".planning/ROADMAP.md",
  ".planning/phases/06-main-window-menu-bar/.continue-here.md",
  ".planning/phases/06-main-window-menu-bar/06-01-PLAN.md",
  ".planning/phases/06-main-window-menu-bar/06-01-SUMMARY.md",
  ".planning/phases/06-main-window-menu-bar/06-02-PLAN.md",
  ".planning/phases/06-main-window-menu-bar/06-02-SUMMARY.md",
  ".planning/phases/06-main-window-menu-bar/06-03-PLAN.md",
  ".planning/phases/06-main-window-menu-bar/06-03-SUMMARY.md",
  ".planning/phases/06-main-window-menu-bar/06-04-PLAN.md",
  ".planning/phases/06-main-window-menu-bar/06-04-SUMMARY.md",
  ".planning/phases/06-main-window-menu-bar/06-ACCEPTANCE.md",
  ".planning/phases/06-main-window-menu-bar/06-CONTEXT.md",
  ".planning/phases/06-main-window-menu-bar/06-PATTERNS.md",
  ".planning/phases/06-main-window-menu-bar/06-RESEARCH.md",
  ".planning/phases/06-main-window-menu-bar/06-REVIEW-DISPOSITION.md",
  ".planning/phases/06-main-window-menu-bar/06-REVIEW.md",
  ".planning/phases/06-main-window-menu-bar/06-SECURITY.md",
  ".planning/phases/06-main-window-menu-bar/06-UAT.md",
  ".planning/phases/06-main-window-menu-bar/06-UI-REVIEW.md",
  ".planning/phases/06-main-window-menu-bar/06-UI-SPEC.md",
  ".planning/phases/06-main-window-menu-bar/06-VALIDATION.md",
  "FlutterRunlet.xcodeproj/project.pbxproj",
  "FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme",
  "FlutterRunlet/Assets.xcassets/RunletCollapse.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletConfigArrow.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletCopy.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletDevTools.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletDevice.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletDeviceArrow.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletFolder.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletGlyph.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletHistory.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletHistoryFolder.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletInspector.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletQuit.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletRecovery.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletReload.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletRestart.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletRun.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletSettings.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletStop.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletTrash.imageset/image.svg",
  "FlutterRunlet/Assets.xcassets/RunletWindow.imageset/image.svg",
  "FlutterRunlet/FlutterDebugSession.swift",
  "FlutterRunlet/FlutterRunletApp.swift",
  "FlutterRunlet/FlutterToolchain.swift",
  "FlutterRunlet/Fonts/NotoSansSC-Medium.ttf",
  "FlutterRunlet/Fonts/NotoSansSC-Regular.ttf",
  "FlutterRunlet/Fonts/RobotoMono-Regular.ttf",
  "FlutterRunlet/Localizable.xcstrings",
  "FlutterRunlet/MainWindowView.swift",
  "FlutterRunlet/MenuBarPanelView.swift",
  "FlutterRunlet/ProjectConfiguration.swift",
  "FlutterRunlet/ProjectRecoveryStore.swift",
  "FlutterRunlet/RunletAppearance.swift",
  "FlutterRunlet/SessionController.swift",
  "FlutterRunlet/SessionProcess.swift",
  "FlutterRunletSessionWorker/main.swift",
  "FlutterRunletTests/FlutterDebugSessionTests.swift",
  "FlutterRunletTests/FlutterToolchainTests.swift",
  "FlutterRunletTests/LaunchPresentationTests.swift",
  "FlutterRunletTests/ProjectConcurrencyTests.swift",
  "FlutterRunletTests/ProjectRecoveryTests.swift",
  "FlutterRunletTests/ProjectSelectionTests.swift",
  "FlutterRunletTests/SessionLifecycleTests.swift",
  "FlutterRunletTests/SessionLogTests.swift",
  "docs/02-TECHNICAL.md",
  "docs/04-ACCEPTANCE.md",
  "docs/design/DESIGN-SYSTEM.md",
  "docs/design/FIGMA-HANDOFF.md",
  "docs/examples/sample-flutter-app/README.md",
  "docs/examples/sample-flutter-app/launch.jsonc",
  "docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh",
  "docs/examples/sample-flutter-app/tasks.jsonc"
]
prior_covered_digest: "v3:sha256:4bdd8841138e5259770d83a37eaab1f9815a6cb8eddfb55722b79265d5c7cbae"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 6
  total: 6
  not_honored: []
human_verification: []
---

# 阶段 06 · 验证报告

## 2026-11-15 · 阶段签核通过

最终 Release `f96a8d6` 已实际运行。同一候选完成两处各 24 张状态实拍，核对中英文、系统深浅、布局与启禁用语义。菜单栏 348 × 313 pt，主窗口 640 × 520 pt。英文等待、恢复中和失败标签均完整。历史、设备关联、真实浏览器连接、日志和恢复均通过同候选复验。Tab 焦点与 VoiceOver 专项按用户决定移出签核范围，Tab 蓝框有实拍并登记为后续变更。 [界面复核](06-UI-REVIEW.md) · [本地验收](06-UAT.md)

UI-08、UI-09、UI-10、UI-11、UI-12、RUN-07、RUN-08、RUN-09 通过。UI-07 的主窗和菜单栏部分通过。设置和关于窗口尚待阶段 07 的四处界面联验。

## 较早候选与独立验证记录

2026-11-15 复验改用 `57fc4b3`。90 项 Debug、Release 构建和严格签名通过。已渲染两处六状态、双语和深浅外观，完成八张中文深色原稿的数值对照。该轮记录了系统控件差异及仍待补的菜单栏实机证据，判定仍为 **待验收**。本报告以下保留原候选的独立验证与需求追踪，新增候选及证据详见[逐张对照与修订候选](06-UI-REVIEW.md)。

最新候选 `f96a8d6` 的 Debug 90 项、Release 构建和严格签名通过。用户接受目录选择器、标题栏窗口按钮及弹层外框的原生差异，取消 Tab 焦点和 VoiceOver 专项。下面较早的证据按原取证身份保留。最终真实菜单栏逐状态取证及其他待验项目见[交接](.continue-here.md)。

## 2026-11-14 · 原候选验证

阶段目标是交付已确认的主窗口和菜单栏体验，验证设备选择、日志与环境恢复。判定为 **待人工验收**。四波实现和联验记录齐备，最终 Release 源码为 `ad7ee14`，90 项 Debug 测试通过。本轮取证已识别一个英文状态标签的显示限制。现有源码与测试没有证实必须改动的功能阻断。 [路线图](../../ROADMAP.md) · [本地候选和联验](06-ACCEPTANCE.md)

## 可观察结果

| # | 必须成立的行为 | 判定 | 依据 |
| --- | --- | --- | --- |
| 1 | 两处共享会话，运行紧邻配置，六项调试动作常驻并随状态启禁用 | 已验证 | 实际场景传入同一 `liveSession`。运行按钮和按键统一走状态守卫。实测等待 VM、运行、就绪及菜单栏恢复失败，自动化验证当前 app ID、等待与停止边界。 |
| 2 | 历史及系统目录按项目守卫打开，单删及空态可持久保存 | 已验证 | 原生打开、取消和归焦有证据。主窗逐条删除和重启已实测。项目测试覆盖规范路径、旧目录复连后的迁移、历史持久化及运行和恢复的切换锁。跨表面单删观察留人工验收。 |
| 3 | 面板 348 pt、主窗默认 640 × 520 pt、两处同一设置 | 已验证 | 源码尺寸与原生实测一致。齿轮共用 `showSettings`，菜单栏底部打开主窗及退出已实际执行。 |
| 4 | 双语与系统深浅下可辨、键盘可达、图标名称可用 | 待人工 | 部分组合及 AX 名称可核对。英文长状态在菜单栏截断，等候与失败需要分别验证。 |
| 5 | 下一次选择 B 时保留 A 的进程、热操作和当前浏览器关联 | 已验证 | 最终候选菜单栏改选 B，两处仍可对 A 热操作。测试核对启动命令、监测、当前 URL 和重新发现后的新启动。最终候选真实浏览器路径仍须复验。 |
| 6 | 同一选择器显示设备原名、类型及在线、离线或未知状态 | 已验证 | 共享弹层直接读取 Flutter 和模拟器数据。实际主窗探测及测试共同覆盖离线、复连、扫描错误后未知。两处离线和复连的同步观察留人工验收。 |
| 7 | 固定 ID 冲突、离线和探测失败在前置任务前拦截 | 已验证 | 测试断言无新 Flutter 标记、环境与风险均不变，覆盖目标冲突、离线和重查错误。 |
| 8 | 主窗原位呈现真实退出结果和运行提示，两处快捷重试仅运行原任务 | 已验证 | 结构化 `SessionExit` 驱动文案。前一候选实测主窗，最终候选实测面板。测试核对原任务、实际退出码、风险持久清除及菜单栏运行受限。 |
| 9 | 只有主窗能在恢复失败后选配置并在恢复成功后启动 | 已验证 | 恢复完成和预检结束都复核风险、目标配置和设备。持久化失败、风险库不可读、项目目录更换、配置变化及设备离线均有测试证据。 |
| 10 | 恢复与接续共用受管操作和项目租约，重入及确认退出能阻止接续 | 已验证 | 暂停样例过程记录真实风险和环境变化。两项退出回归覆盖恢复暂停及接续预检，结束时无新启动。 |
| 11 | 日志复制、清空与折叠互不干扰，恢复详情独立（UI-12） | 已验证 | 主窗独立状态区和日志工具栏。已有实测记录旧内容不会重现且新日志可追加。测试断言代际清除、脱敏复制、继续输出及 Unicode 阅读边界。 |
| 12 | 同一最终 Release 的真实调试、当前浏览器、停止及设备变更完整链路 | 待人工 | 最终候选已验证产物、双入口和设备关联，浏览器实连及部分离线复连证据属于前一候选。 |
| 13 | 同一最终 Release 的两窗布局、外观、语言、状态、焦点和历史矩阵 | 待人工 | 最终候选已实测菜单栏目录选择、取消归焦及两处英文弹层。完整组合和实际键盘及辅助技术仍待验。 |
| 14 | 同一最终 Release 隔离样例的故障、接续、退出和日志证据 | 待人工 | 最终候选记录面板重试。主窗全套故障与日志原生证据属于前一候选，自动化覆盖核心行为。 |

没有用旧候选结果替代第 4 波要求的同候选取证。四项路线图条件都能追溯到上表，完成判定等同候选矩阵闭环。设置和关于窗口内部、更新及四处联验按阶段 07 另行规划。 [阶段规格](06-UI-SPEC.md) · [本地联验](06-ACCEPTANCE.md)

## 产物、连接及数据

四份计划声明的 9 个产物条目均通过存在及内容检查。关键连接工具只按文件路径文字匹配，Swift 同模块通过类型及调用连接，联验与验证方案以相对链接连接。逐项检查了六条 Swift 路径的字面调用，另检查了联验到验证方案及隔离样例的两个可打开链接。

| 路径 | 数据及已接通的行为 |
| --- | --- |
| 应用场景 → 两处视图 → 会话控制器 | 同一个生产控制器的项目、配置、历史、运行数据和设备状态用于两处渲染。历史由持久偏好读写，选择器调用受保护的 `open`。快捷键按原生窗口注册来源映射至同一控制器，设置按钮进入同一窗口。 [应用场景](../../../FlutterRunlet/FlutterRunletApp.swift#L180) · [主窗](../../../FlutterRunlet/MainWindowView.swift) · [菜单栏](../../../FlutterRunlet/MenuBarPanelView.swift) |
| 菜单栏 → 共享设备控件 → 控制器 → 当前调试会话 | 两处设备行从同一个 `deviceChoices` 读取实际发现结果。预检捕获设备创建 `activeLaunch`，进程监测和浏览器读活动会话。更改下一次设备只写选择偏好，不改已运行的目标。 [设备控件](../../../FlutterRunlet/MainWindowView.swift#L173) · [启动预检](../../../FlutterRunlet/SessionController.swift#L1008) · [浏览器绑定](../../../FlutterRunlet/FlutterDebugSession.swift#L190) |
| 恢复按钮及主窗 Run → 原恢复记录 → 受管操作 | `beginRecovery` 持有同一个租约，按实际原记录认证任务和执行参数。进程结果直接提供退出状态。仅在恢复成功并持久确认、再次预检通过时调用新启动。 [恢复入口](../../../FlutterRunlet/SessionController.swift#L587) · [结果和完成确认](../../../FlutterRunlet/SessionController.swift#L1267) · [持久风险库](../../../FlutterRunlet/ProjectRecoveryStore.swift#L122) |
| 受管输出 → 脱敏缓冲 → 日志视图和复制 | 发布前脱敏，清空推进代际，折叠只决定视图是否显示，恢复状态在独立区域。 [日志控件](../../../FlutterRunlet/MainWindowView.swift#L116) · [日志模型](../../../FlutterRunlet/SessionController.swift#L1111) |
| 联验 → 验证方案及隔离样例 | 命令、候选摘要、样例复制和故障步骤可追溯，提交只包含脱敏结果。 [验证方案](06-VALIDATION.md) · [公开样例](../../../docs/examples/sample-flutter-app/README.md) |

三项禁止条件均有源码和用例支撑。下次设备的赋值与当前会话隔离。恢复、持久清除或身份验证不通过即禁止接续。退出码来自真实 `SessionExit`，不从日志提取。人工验收第 4、5 项对这些状态和时序补同候选观察。 [安全复核](06-SECURITY.md)

## 自动化与审查

只读核对最终原始 Debug 记录 `debug-focus.log`，90 项全量通过，无失败或跳过。最终普通 Release 的 `release-focus.log` 有构建成功，候选身份文件的应用和 worker 摘要与联验表一致。未启动应用或重复执行宿主测试，本表引用最终测试实际执行记录。

| 行为 | 已执行的关键回归 |
| --- | --- |
| 启动、切换设备及浏览器关联 | `testChangingNextDeviceKeepsRunningSessionAndItsToolsOnOriginalDevice`、`testInvalidPreflightLeavesEnvironmentAndRiskUntouched`、`testUntestedInspectorVersionOpensConnectedDevToolsWithFallbackFeedback` 通过。 |
| 历史迁移和阻断切换 | `testUnavailableLegacyProjectMigratesWhenItsDirectoryReturns`、`testRecentHistoryMigratesAndRemembersCanonicalProjectsInOpeningOrder`、`testProjectSwitchRemainsBlockedWhileRunningAndAfterRecoveryFailure` 通过。 |
| 原任务、风险持久确认和退出顺序 | `testMainRunKeepsOriginalRiskAfterAnotherRecoveryFailureThenRunsSelectedConfiguration`、`testRunAfterRecoveryRequiresDurableRemovalAndReadableRiskStore`、两项 `testConfirmedQuit` 及 `testRecoveryContinuationRechecksConfigurationAndDeviceBeforeNewPreTask` 通过。 |
| 日志及双语资源 | `testLiveTaskAndDebugLogsClearAndCopyWithoutChangingProdRecovery` 和 `testRecoveryAndLogButtonsUseBothBundleLanguages` 通过。 |

没有发现生产改动中的未登记债务标记或断开的接线。现有回归使用独立项目、预设故障标记、持久风险读回及过程结果，未发现把被测输出当作预期的断言。两项代码审查发现均有修复及复验记录。D-01–D-06 六项决定均能追溯到产物，这一覆盖计数不代替原生签核。 [审查处置](06-REVIEW-DISPOSITION.md)

## 需求追踪

| 需求 | 来源 | 判定 |
| --- | --- | --- |
| UI-07 | 06-01、06-02、06-04 | 待人工完成两处外观、英文长状态和辅助技术检查。 |
| UI-08 | 06-01、06-02、06-03、06-04 | 共享状态和常驻操作已验证，最终候选待复跑真实浏览器关联。 |
| UI-09 | 06-01、06-04 | 选择、单删、持久化和守卫已验证，待补跨窗口逐次删除和 Escape 键。 |
| UI-10 | 06-01、06-04 | 菜单栏尺寸、顺序、状态区域、设置和底部入口通过。英文标签可辨程度随 UI-07 复核。 |
| UI-11 | 06-01、06-04 | 主窗尺寸、布局和共享设置通过。 |
| UI-12 | 06-03、06-04 | 日志工具栏和状态区独立已验证。最终同候选复跑合并到恢复矩阵。 |
| RUN-07 | 06-02、06-04 | 设备关联和前置阻断已验证，待补最终候选反向操作、两处离线复连、当前浏览器关联。 |
| RUN-08 | 06-03、06-04 | 真实退出码、两处呈现和重试已验证，需在最终候选复跑主窗路径。 |
| RUN-09 | 06-03、06-04 | 分流、持久风险、重入和终止已验证，需在最终候选复跑主窗完整序列。 |

九项均由计划声明，无孤立需求。

## 原待人工验收清单

最终判定见本页首节。

| # | 操作与预期 |
| --- | --- |
| 1 | 在两处用中英文及深浅色核对无项目、就绪、等待 VM、运行、恢复中、恢复失败。尺寸、控件及状态可辨。英文卡片若继续截断，分别检查等待与失败能否按现有反馈明确分辨，并记录结果。 |
| 2 | 在主窗和菜单栏用 VoiceOver 确认可读动作及禁用状态，重复 Tab／Shift-Tab、Return 和 Escape。弹层与原生目录取消后焦点回到各自触发项并能从那里继续，取消保留当前项目。 |
| 3 | 用两个样例从一处逐条删历史，在另一处看到实时变更及最终空态。删除当前条目不关闭项目，重启仍为空。运行、恢复时尝试切换仍维持原项目。 |
| 4 | 用最终候选从菜单栏在 A 启动 prod，在主窗改选 B。热操作与浏览器仍绑定 A。正常停止后原任务恢复 test、风险清零。两处同步显示 B 离线及复连状态，离线不能启动，复连后下一次确实用 B。 |
| 5 | 在最终候选主窗重跑后置退出 1、二次失败、仅重试、恢复后启动和恢复中确认退出。观察实际任务、风险、Flutter 顺序并复验日志清空和折叠独立。 |

目前需要的是原生验收证据。英文状态截断是实际显示差异，保留待验判定。若人工验收确认因此无法辨识状态，应把它转为 UI-07 实现缺口。 [原生界面复核](06-UI-REVIEW.md)
