---
phase: 06-main-window-menu-bar
verified: 2026-11-15T13:32:34Z
candidate: 2fcb4a3d4dbb3ee9b7acaf287582ea126dfcd2a7
status: passed
score: 14/14 must-haves verified in approved scope
automated_verification:
  targeted_passed_tests: 93
  full_passed_tests: 133
  failures: 0
  skipped: 0
  initial_targeted_passed_tests: 92
  initial_targeted_aborted_tests: 1
  doctor_repro_passes: 5
  release_build: passed
  signature: passed
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
  ".planning/phases/07-settings-about-updates/07-ACCEPTANCE.md",
  ".planning/phases/07-settings-about-updates/07-CONTEXT.md",
  ".planning/phases/07-settings-about-updates/07-REVIEW-DISPOSITION.md",
  ".planning/phases/07-settings-about-updates/07-REVIEW.md",
  ".planning/phases/07-settings-about-updates/07-SECURITY.md",
  ".planning/phases/07-settings-about-updates/07-UI-REVIEW.md",
  ".planning/phases/07-settings-about-updates/07-VALIDATION.md",
  "FlutterRunlet.xcodeproj/project.pbxproj",
  "FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme",
  "FlutterRunlet/AppTermination.swift",
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
  "FlutterRunlet/AuxiliaryWindows.swift",
  "FlutterRunlet/FlutterDebugSession.swift",
  "FlutterRunlet/FlutterRunletApp.swift",
  "FlutterRunlet/FlutterToolchain.swift",
  "FlutterRunlet/Fonts/NotoSansSC-Medium.ttf",
  "FlutterRunlet/Fonts/NotoSansSC-Regular.ttf",
  "FlutterRunlet/Fonts/RobotoMono-Regular.ttf",
  "FlutterRunlet/LaunchPresentation.swift",
  "FlutterRunlet/Localizable.xcstrings",
  "FlutterRunlet/MainWindowView.swift",
  "FlutterRunlet/MenuBarPanelView.swift",
  "FlutterRunlet/ProjectConfiguration.swift",
  "FlutterRunlet/ProjectRecoveryStore.swift",
  "FlutterRunlet/RunletAppearance.swift",
  "FlutterRunlet/SessionController.swift",
  "FlutterRunlet/SessionProcess.swift",
  "FlutterRunlet/UpdateActivityLease.swift",
  "FlutterRunlet/UpdateCoordinator.swift",
  "FlutterRunlet/UpdatePackage.swift",
  "FlutterRunlet/UpdatePresentationSource.swift",
  "FlutterRunlet/UpdateTransaction.swift",
  "FlutterRunletSessionWorker/main.swift",
  "FlutterRunletTests/FlutterDebugSessionTests.swift",
  "FlutterRunletTests/FlutterToolchainTests.swift",
  "FlutterRunletTests/LaunchPresentationTests.swift",
  "FlutterRunletTests/ProjectConcurrencyTests.swift",
  "FlutterRunletTests/ProjectRecoveryTests.swift",
  "FlutterRunletTests/ProjectSelectionTests.swift",
  "FlutterRunletTests/SessionLifecycleTests.swift",
  "FlutterRunletTests/SessionLogTests.swift",
  "FlutterRunletTests/UpdateInstallGateTests.swift",
  "FlutterRunletUpdateHelper/main.swift",
  "docs/02-TECHNICAL.md",
  "docs/04-ACCEPTANCE.md",
  "docs/design/DESIGN-SYSTEM.md",
  "docs/design/FIGMA-HANDOFF.md",
  "docs/design/UI-SPEC.md",
  "docs/examples/sample-flutter-app/README.md",
  "docs/examples/sample-flutter-app/launch.jsonc",
  "docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh",
  "docs/examples/sample-flutter-app/tasks.jsonc"
]
covered_digest: "v3:sha256:0ada7d98d7b2ca8bd0170d624d7b3ee81676ed490fe87f7c9b215202675d2cc8"
prior_covered_digest: "v3:sha256:4bdd8841138e5259770d83a37eaab1f9815a6cb8eddfb55722b79265d5c7cbae"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 6
  total: 9
  not_honored: [D-07, D-08, D-09]
  manually_verified: [D-07, D-08, D-09]
human_verification: []
---

# 阶段 06 · 验证报告

## 2026-11-15 · 当前独立复核

**阶段 06 验证门槛通过（`passed`）。** 按当前已批准的键盘合同核对 14/14 项必备行为和路线图的四条验收条件，九项需求均有依据。UI-07 在本阶段覆盖主窗口与菜单栏，四处联验由阶段 07 最终签核覆盖。未发现实质缺口或待补人工门槛。本轮只读复核源码、既有测试结果与原生验收记录。以下原签核与更早候选按当时的范围和身份保留。 [路线图](../../v0.2-ROADMAP.md#phase-06-主窗口与菜单栏) · [需求](../../v0.2-REQUIREMENTS.md) · [阶段 07 独立签核](../07-settings-about-updates/07-VERIFICATION.md)

### 候选与证据

- **当前实现。** 阶段 07 最终普通 Release 的程序提交为 `2fcb4a3d4dbb3ee9b7acaf287582ea126dfcd2a7`。应用、会话 worker、更新助手、测试、Xcode 工程和脚本的完整目录树与复核时 HEAD `82c08d56723cd2b2364771b32c7c8aa84f8ad003` 一致，工作区对应路径也无差异。复算现存构建原件的应用可执行 SHA-256 为 `2f1aec11c2ae39c30d99a0666903cf9c3895ed97e6950b23328d1f78cda50de7`，与最终 AX／动作记录及固定候选摘要一致。构建日志成功，原件通过双架构严格签名复验。本机普通程序为 v0.1.0（构建 1）。 [阶段 07 最终验收](../07-settings-about-updates/07-ACCEPTANCE.md)
- **阶段 06 原生签核。** `f96a8d6` 当时在批准范围内通过 14/14。复核了 `.private/phase-06/pixel-uat/native-final.html`、两处各 24 张原生图的文件和最终联验记录。它们覆盖两语言、两外观、六状态，以及历史逐条清空／重启、A/B 反向切换和两处离线复连、A 的浏览器 Inspector、恢复后按所选 dev 配置接续与日志复制／清空／折叠。原生目录选择器、标题栏按钮和弹层外框按 D-07 接受系统差异。原签核按 D-08 移出 Tab 焦点和 VoiceOver 专项，UAT 为 4 通过、1 按决定跳过。 [阶段 06 联验](06-ACCEPTANCE.md) · [界面复核](06-UI-REVIEW.md) · [本地验收](06-UAT.md) · [验证方案](06-VALIDATION.md)
- **最终普通候选的原生复验。** 在 `.private/phase-07/review-fixes/ordinary/windows/` 核对中英 × 深浅四组的 28 个捕获 ID、图像摘要和尺寸、进程及可执行摘要。主窗为 640 × 520 pt，带 FVM 诊断的菜单栏样本为 348 × 372 pt，原阶段标准状态实拍为 348 × 313 pt。四组均有两齿轮复用同一设置窗口、控件 AX 名称和禁用状态。按 D-09 后续授权，`c791538` 移除主窗与菜单栏的 Tab 焦点，阶段 07 D-10 确认沿用。四组在两处分别实发六次 Tab、六次 Shift-Tab，AX 焦点始终未进入各自操作按钮。设置、关于和系统目录选择器保留原生键盘行为。早先移除焦点的原生复验另记录目录返回、弹层关闭及等待 VM／运行期间无残留蓝框。最终 AX／HID 记录覆盖键盘合同，VoiceOver 实际朗读仍在本次取证范围之外。 [阶段 06 决定](06-CONTEXT.md) · [移除焦点复验](06-UI-REVIEW.md) · [阶段 07 决定](../07-settings-about-updates/07-CONTEXT.md) · [当前界面规格](../../../../docs/design/UI-SPEC.md#7-可访问性与键盘)
- **最终普通候选的真实 Flutter。** 同一证据根的 `flutter-normal-retry/`、`flutter-failure/`、`flutter-pause-retry/` 各有完成回执和同摘要 AX。核对专用 iOS 模拟器的 prod 配置、F5、等待 VM、关闭再由菜单栏重开主窗后延续同一会话、默认浏览器打开当前 DevTools、热重载及热重启，正常停止后任务结束、环境 test、风险 0。故障轮确认为原后置退出 1、两处显示失败、prod 和风险 1 保留、F5 阻断、单点重试后回到 test 且风险为 0。暂停轮在 Flutter 已退出、原后置仍在途时阻止 F5、运行与项目入口，确认退出后等待原任务释放，最终无新 Flutter、风险 0。双设备、完整历史、恢复后启动与日志的专项实机矩阵沿用 `f96a8d6` 的签核；当前源码接线和已执行回归覆盖这些边界。 [阶段 07 最终验收](../07-settings-about-updates/07-ACCEPTANCE.md) · [阶段 07 独立签核](../07-settings-about-updates/07-VERIFICATION.md)

### 必备行为与需求

路线图第 1 条对应下表 1、3、4、13，第 2 条对应 2、5–7，第 3 条对应 1、11、12，第 4 条对应 8–10、14。四份计划声明的 9 条产物均通过检查。关键连接共 8 条，工具识别了 1 条字面引用，其余按 Swift 同模块真实调用、共享控制器及相对文档链接核对。 [计划 06-01](06-01-PLAN.md) · [计划 06-02](06-02-PLAN.md) · [计划 06-03](06-03-PLAN.md) · [计划 06-04](06-04-PLAN.md)

| # | 计划 | 必备行为及需求 | 复核依据 |
| --- | --- | --- | --- |
| 1 | 06-01 | 两处共用会话、绿色运行紧邻配置、六项调试操作常驻并按状态启禁用（UI-08） | 通过。同一 `liveSession` 注入两处，共用运行、热操作和浏览器组件。AX、原生等待／运行及快捷键回归印证。 |
| 2 | 06-01 | 历史打开、逐条清除、持久空态、原生目录和项目切换守卫（UI-09） | 通过。`ProjectControls` 走 `requestProjectChange`／`open`，单删只写历史及相关偏好。阶段 06 跨窗口和重启实测、当前目录操作及项目回归。 |
| 3 | 06-01 | 348 pt 面板、默认 640 × 520 pt 主窗、布局及共享设置（UI-10、UI-11） | 通过。实际尺寸，面板的主窗／退出入口，以及两齿轮汇入同一 `showSettings`。 |
| 4 | 06-01 | 双语、深浅、可读 AX 名称及已批准键盘行为（UI-07） | 通过。两轮矩阵、最终 HID 和 AX。按窗口注册来源的 `DebugKeys` 只拦截主窗／菜单栏 Tab，原生模态窗和其他窗口由系统处理。 |
| 5 | 06-02 | 运行中选择 B，当前进程、监测、热操作及浏览器保留在 A（UI-08、RUN-07） | 通过。下次偏好与 `activeLaunch`／当前 `FlutterDebugSession` 分离。阶段 06 A/B 及 Inspector 实测，当前用例重验 A 和 B 的边界。 |
| 6 | 06-02 | 两处显示同一真实设备名称、类型、在线／离线或未知（RUN-07） | 通过。两处共用 `DeviceSelectionControls` 和发现数据，阶段 06 两处离线复连与当前双语及探测失败用例。 |
| 7 | 06-02 | 固定设备冲突、离线或重新探测失败时在前置任务前停止（RUN-07） | 通过。启动重新解析配置和实际设备，`testInvalidPreflightLeavesEnvironmentAndRiskUntouched` 验证环境和风险均未改变。 |
| 8 | 06-03 | 两处原位失败信息、真实退出码及单点仅重试原任务（RUN-08、RUN-09） | 通过。结构化 `SessionExit` 驱动状态。两轮原生退出 1 与风险读回，原生重试和宿主用例。 |
| 9 | 06-03 | 仅主窗可择配置恢复后启动，未持久清除或无法确认时阻断（RUN-09） | 通过。`beginRecovery(thenRun:)` 校验原任务，持久确认后及预检结束时复查风险、身份、配置和设备。阶段 06 接续实测和当前风险／预检回归。 |
| 10 | 06-03 | 恢复与接续共用项目身份、租约、互斥和退出意图（RUN-09） | 通过。当前租约同时保护 worker 与受管进程，退出确认先取消接续意图。暂停实机、并发及两项确认退出回归。 |
| 11 | 06-03 | 日志复制、清空、折叠和独立恢复详情（UI-12） | 通过。视图折叠仅控制显示，共用脱敏缓冲及清空代际，状态区独立。阶段 06 真实日志矩阵和当前 `SessionLogTests`。 |
| 12 | 06-04 | 同一普通 Release 的真实调试、会话关联、停止与正常恢复（UI-08、RUN-07） | 通过。阶段 06 完成同候选 A/B 和当前 Inspector 全链路；当前普通 Release 实证同会话控制、真实 DevTools、热操作及正常恢复。 |
| 13 | 06-04 | 同候选两处原生布局、主题、语言、状态、历史及键盘（UI-07、UI-09、UI-10、UI-11） | 通过。原 48 张状态矩阵、历史和目录联验；当前四组实拍与适用键盘合同复验。 |
| 14 | 06-04 | 隔离样例的原后置失败、单点重试、接续、再次失败阻断及日志边界（RUN-08、RUN-09、UI-12） | 通过。阶段 06 完整同候选故障和日志矩阵；当前原生失败、只重试及暂停退出，当前回归补足接续和日志。 |

三项禁止条件逐项有现行源码及可观察证据。下次设备选择只更新偏好，当前进程、设备监测与 VM 使用启动快照。恢复失败、项目身份变化或未持久确认时无新前置或 Flutter。退出码只从受管任务的结构化退出结果取得。  [会话控制器](../../../../FlutterRunlet/SessionController.swift) · [当前调试会话](../../../../FlutterRunlet/FlutterDebugSession.swift) · [恢复存储](../../../../FlutterRunlet/ProjectRecoveryStore.swift) · [阶段 06 安全复核](06-SECURITY.md)

### 回归、安全与审查

- **阶段 06 当前八套件复跑。** `.private/phase-06/final-regression/latest.txt` 指向 `20261115T132036Z`，同批 JSON、日志和退出码一致（93 通过、0 失败、0 跳过、退出 0）。从结果包核对 `FlutterDebugSessionTests` 11、`FlutterToolchainTests` 17、`LaunchPresentationTests` 25、`ProjectConcurrencyTests` 5、`ProjectRecoveryTests` 10、`ProjectSelectionTests` 8、`SessionLifecycleTests` 10、`SessionLogTests` 7。阶段 07 独立的 `debug-final.xcresult` 为 133/0/0，含同样八套件共 93 项。
- **首次中止。** `regression-20261115T131428Z` 为 92 通过、1 中止、0 跳过，测试命令退出 65。执行 `FlutterToolchainTests.testTerminationWaitsForCurrentAndCancelledDoctorCleanup` 时，`initial-run-quit-event.log` 记录测试宿主收到 Quit AppleEvent，AppKit 批准终止，XCTest 记录宿主在用例完成前以退出码 0 结束。发送方未确认。同一用例的独立 `doctor-repro-20261115T131915Z.log` 记录连续五次通过，随后八套件整组通过，现有后续记录未见复发。
- **共享安全边界。** 阶段 06 九项威胁原登记均关闭。复核阶段 07 变更后，项目与更新活动租约由会话进程继承，原项目身份及风险的持久校验仍生效；不确认进程退出或风险库状态时保持阻断。Doctor 取消和终止等待有现行宿主结果。阶段 07 威胁登记 16 项开放为 0，相关的设置／生产行为、跨实例和受管退出以最终候选验证为准。 [阶段 06 安全复核](06-SECURITY.md) · [阶段 07 安全复核](../07-settings-about-updates/07-SECURITY.md)
- **审查处置。** 阶段 06 WR-01 的原生目录返回面板路由仍接通，按钮 Tab 回焦由现行授权调整；WR-02 的旧目录重新可用后迁移由当前历史回归覆盖。阶段 07 与共用路径直接相关的 WR-01 按跨 OS 启动、独占租约、可读且已清理的风险库回收 worker 标记，同次启动和不确定状态继续阻断；IN-01 在偏好加载后决定主窗及激活策略，最终普通候选已有偏好复验。复核了对应处置及影响共用启动／退出的 CR-01、CR-02，阶段 07 审查所列发现均有最终处置。菜单栏长 FVM 诊断仍会缩略，AX、主窗和 Flutter 设置有完整原因及设置入口，按现有原生复核为非阻塞。 [阶段 06 审查](06-REVIEW.md) · [阶段 06 处置](06-REVIEW-DISPOSITION.md) · [阶段 07 审查](../07-settings-about-updates/07-REVIEW.md) · [阶段 07 处置](../07-settings-about-updates/07-REVIEW-DISPOSITION.md) · [阶段 07 界面复核](../07-settings-about-updates/07-UI-REVIEW.md)
- **决定与指纹。** GSD 自动匹配 D-01～D-06（6/9，软提示）。逐条核对 D-07 原生外框差异及最终逐状态实拍、D-08 原签核缩减范围、D-09 后续去 Tab 和阶段 07 最终键盘复验，人工复核 9/9。指纹采用 `verification.fingerprint` 实际输出，输入包含原覆盖文件、阶段 07 相关共享实现及仓库内证据，GSD 会从输出中排除验证报告本身。本机原始记录以仓库相对位置引用。 [阶段 06 决定](06-CONTEXT.md) · [阶段 07 决定](../07-settings-about-updates/07-CONTEXT.md)

_复核人 Codex（gsd-verifier）_

## 2026-11-15 · 阶段签核通过

最终 Release `f96a8d6` 已实际运行。同一候选完成两处各 24 张状态实拍，核对中英文、系统深浅、布局与启禁用语义。菜单栏 348 × 313 pt，主窗口 640 × 520 pt。英文等待、恢复中和失败标签均完整。历史、设备关联、真实浏览器连接、日志和恢复均通过同候选复验。Tab 焦点与 VoiceOver 专项按用户决定移出签核范围，Tab 蓝框有实拍并登记为后续变更。 [界面复核](06-UI-REVIEW.md) · [本地验收](06-UAT.md)

UI-08、UI-09、UI-10、UI-11、UI-12、RUN-07、RUN-08、RUN-09 通过。UI-07 的主窗和菜单栏部分通过。设置和关于窗口尚待阶段 07 的四处界面联验。

## 较早候选与独立验证记录

2026-11-15 复验改用 `57fc4b3`。90 项 Debug、Release 构建和严格签名通过。已渲染两处六状态、双语和深浅外观，完成八张中文深色原稿的数值对照。该轮记录了系统控件差异及仍待补的菜单栏实机证据，判定仍为 **待验收**。本报告以下保留原候选的独立验证与需求追踪，新增候选及证据详见[逐张对照与修订候选](06-UI-REVIEW.md)。

最新候选 `f96a8d6` 的 Debug 90 项、Release 构建和严格签名通过。用户接受目录选择器、标题栏窗口按钮及弹层外框的原生差异，取消 Tab 焦点和 VoiceOver 专项。下面较早的证据按原取证身份保留。最终真实菜单栏逐状态取证及其他待验项目见[交接](.continue-here.md)。

## 2026-11-14 · 原候选验证

阶段目标是交付已确认的主窗口和菜单栏体验，验证设备选择、日志与环境恢复。判定为 **待人工验收**。四波实现和联验记录齐备，最终 Release 源码为 `ad7ee14`，90 项 Debug 测试通过。本轮取证已识别一个英文状态标签的显示限制。现有源码与测试没有证实必须改动的功能阻断。 [路线图](../../v0.2-ROADMAP.md) · [本地候选和联验](06-ACCEPTANCE.md)

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
| 应用场景 → 两处视图 → 会话控制器 | 同一个生产控制器的项目、配置、历史、运行数据和设备状态用于两处渲染。历史由持久偏好读写，选择器调用受保护的 `open`。快捷键按原生窗口注册来源映射至同一控制器，设置按钮进入同一窗口。 [应用场景](../../../../FlutterRunlet/FlutterRunletApp.swift#L180) · [主窗](../../../../FlutterRunlet/MainWindowView.swift) · [菜单栏](../../../../FlutterRunlet/MenuBarPanelView.swift) |
| 菜单栏 → 共享设备控件 → 控制器 → 当前调试会话 | 两处设备行从同一个 `deviceChoices` 读取实际发现结果。预检捕获设备创建 `activeLaunch`，进程监测和浏览器读活动会话。更改下一次设备只写选择偏好，不改已运行的目标。 [设备控件](../../../../FlutterRunlet/MainWindowView.swift#L173) · [启动预检](../../../../FlutterRunlet/SessionController.swift#L1008) · [浏览器绑定](../../../../FlutterRunlet/FlutterDebugSession.swift#L190) |
| 恢复按钮及主窗 Run → 原恢复记录 → 受管操作 | `beginRecovery` 持有同一个租约，按实际原记录认证任务和执行参数。进程结果直接提供退出状态。仅在恢复成功并持久确认、再次预检通过时调用新启动。 [恢复入口](../../../../FlutterRunlet/SessionController.swift#L587) · [结果和完成确认](../../../../FlutterRunlet/SessionController.swift#L1267) · [持久风险库](../../../../FlutterRunlet/ProjectRecoveryStore.swift#L122) |
| 受管输出 → 脱敏缓冲 → 日志视图和复制 | 发布前脱敏，清空推进代际，折叠只决定视图是否显示，恢复状态在独立区域。 [日志控件](../../../../FlutterRunlet/MainWindowView.swift#L116) · [日志模型](../../../../FlutterRunlet/SessionController.swift#L1111) |
| 联验 → 验证方案及隔离样例 | 命令、候选摘要、样例复制和故障步骤可追溯，提交只包含脱敏结果。 [验证方案](06-VALIDATION.md) · [公开样例](../../../../docs/examples/sample-flutter-app/README.md) |

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
