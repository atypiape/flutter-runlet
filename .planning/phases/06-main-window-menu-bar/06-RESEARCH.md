# 阶段 06 · 主窗口与菜单栏调研

调研日期 2026-11-14。代码和测试定位置信度高，本机真实流程和视觉效果待实现后验收。

<user_constraints>

- D-01、D-04 以已核对的 Figma 两处画板和 `06-UI-SPEC.md` 为基线，保留 macOS 原生交互。
- D-02、D-03 两处共用项目历史、启动配置和下次运行设备。保持项目切换限制及当前会话设备绑定。
- D-05、D-06 区分仅重试和先恢复再运行，保留恢复阻断、独立详情及日志清空语义。
- 阶段 07 承接设置、关于与更新。阶段 06 的两个齿轮使用现有设置入口。公开发布暂缓。本轮只规划和核验计划。

</user_constraints>

## 实施接缝

| 范围 | 仓库现状与可复用入口 | 需要落实的行为 |
| --- | --- | --- |
| 布局、按钮与快捷键 | `FlutterRunlet/FlutterRunletApp.swift` 的 `liveSession` 供两个场景共用，`showSettings` 已供两个入口调用。`MainWindowView.swift` 已含 `DebugControls`、`BrowserControls`、`PresentationField`、`SessionFeedbackView`、`RecoveryDetails`，`MenuBarPanelView.swift` 已调用多项共用控件。目前主窗默认 640 × 580，菜单栏 404；菜单栏的配置与设备是只读展示。 | 按两张画板组合控件并保留共享绑定、六项操作常驻、当前状态的启用守卫和原生窗口行为。主窗和菜单栏的 F5 均经 `DebugKeys` 的事件监视器和 `SessionController.performDebugAction`，需显式区分操作来源，主窗允许的恢复后启动不可从菜单栏按 F5 绕过。系统对话框、弹层关闭、焦点和现有配置显式刷新入口需回归。`FlutterRunlet/Localizable.xcstrings` 已为两处供词。需要新增 Swift 文件时，`FlutterRunlet.xcodeproj/project.pbxproj` 使用显式文件归属。 |
| 历史项目 | `SessionController` 原来用 `UserDefaults` 的 `recentProjectPath` 单值自动打开项目，`rememberRecentProject` 控制初始化恢复。目录通过 `MainWindowView.openProject` 的 `NSOpenPanel`，`open(_:)` 在执行前再次调用 `requestProjectChange`；`loadProject` 通过 `validate` 规范化目录，然后才加载和写最近值。待恢复项目还走独立 `openRecoveryProject`。 | 在控制器复用偏好与有效打开入口。按规范化路径去重，兼容旧值，记录只在有效打开后更新。删除当前记录不卸载项目、不启动任务、不触碰项目目录、设备偏好、恢复记录及租约。历史清空后重启不因兼容逻辑重新读回旧值。明确保留「记住最近打开的项目」的启动行为。两个图标按同一项目切换守卫禁用，取消系统对话框无副作用，菜单栏调用原生选择器时验证激活和返回焦点。 |
| 设备与会话 | `FlutterToolchain.swift` 的 `FlutterDevice` 提供 `id`、原始 `name`、`platform`、`isSimulator`。Flutter 发现列表仅供可用设备；`FlutterSimulator` 是现有已关闭的可启动 iOS 模拟器信息。`FlutterDeviceAvailability` 区分 `.available`、`.missing`、`.disconnected`、`.unknown`。`SessionController` 的 `DevicePreference` 和 `projectDevices` 表示下次偏好。`beginFlutterRun` 捕获所选设备 ID 并重新发现，`execute(launch:...)` 将当时的 `device` 绑定于 `FlutterDebugSession` 与 `monitorDebugProcess`。当前主窗状态区却直接从 `selectedDevice` 和 `selection` 读运行内容。 | 将「当前会话展示」从启动快照或已绑定会话读取，启动时锁定设备和配置，运行时改变下次偏好只更新共享选择，不影响当前命令、监测、VM Service 或 DevTools。权限可放宽到运行中，继续守住启动与恢复的过渡态。确认在线来自成功的实际设备发现；离线可据已知关闭模拟器或前次已知设备在成功扫描后消失呈现。探测出错、尚未完成时保留未知反馈，防止拿旧快照标在线或把失败直接标红。未发现且无元数据的真实设备不可凭原型生成。在线与离线按 ID 合并，保留已有刷新、启动模拟器和固定 `deviceId` 不匹配提示。 |
| 单独重试 | `SessionController.retryRecovery()` 验证规范化项目、获取 `ProjectLease`、比对预期与当前恢复记录，使用原 `taskLabel`，校验定义和解析结果。`restore` 校验租约与项目，调用原命令，在退出 0 且 `ProjectRecoveryStore.remove` 持久确认完成后才清除风险。`SessionExit` 区分实际退出、信号、启动失败及未确认。 | 复用上述路径并以结构化失败信息向视图提供原任务和真实退出码。不能从翻译文本或已清空日志反推退出码。保留无真实退出码时的原始原因和既有恢复入口，例如待打开其他项目、定义变化、记录不可用和进程组未确认。单击两处图标仅用原记录执行恢复。 |
| 恢复后运行 | 普通 `canRun` 和 `run()` 遇到 `recovery` 直接阻断。`beginFlutterRun` 另起 `operation` 并获取新租约。`revalidate` 重读配置和原任务，检查项目与运行定义是否变化。`ProjectLease` 按目录身份互斥，worker 继续持有租约至子进程组退出。 | 主窗上新增显式的运行意图，点击时捕获配置、设备与项目以及待恢复记录。与单独重试共用同一受管恢复过程。推荐用同一 `operation` 持有同一租约贯穿恢复成功、重查阻断条件及新启动，避免用 UI 串接 `retryRecovery` 后递归 `run()` 造成重入、嵌套锁及错误提示丢失。若选择交接租约，必须在接手后重新读取风险和验证身份，并保持控制器无可重入空窗。启动前再次校验所选配置、设备可用性及 `deviceId`；其他未解决风险、终止请求、执行未确认、持久清除失败、定义或项目变化均不得被当成恢复成功。恢复阶段保持 Run、重试与项目切换阻断，退出请求应取消后续启动意图，复用原本的终止确认方式。 |
| 日志与恢复详情 | `MainWindowView` 持有 `isLogExpanded`，AppKit `SessionLogScrollView` 管理可选文本、滚动和阅读定位。`SessionController.clearLogs` 清空缓冲并推进 `logGeneration`，`copyLogs` 复用已过滤的内容和反馈，`resetLogs` 不操作恢复记录。现有 `RecoveryDetails` 被两处视图调用。 | 调整工具栏排列、同色图标、方向和辅助名称，沿用日志模型及视图。测试清空时的排队输出边界、折叠独立性、复制反馈。保持状态区外独立可达的详情路径，清空日志或隐藏日志后仍可发现恢复原因和动作。 |

实现默认沿用现有 Swift 6、SwiftUI/AppKit、XCTest、内嵌 worker 和 Flutter CLI 管道。有关项目历史偏好的一项实施假设是沿用当前 `rememberRecentProject` 的自动重开语义，使用既有偏好存储兼容旧数据。阶段 06 无须新增偏好界面或改写用户 Flutter 文件。

## Validation Architecture

已用 `xcodebuild -list -project FlutterRunlet.xcodeproj` 确认 macOS scheme `FlutterRunlet` 和测试 target `FlutterRunletTests`。本机 Xcode 27.1 与 Flutter 可执行入口可见。未运行产品测试或实机验收。真实 Flutter 运行时先确认有效 iOS 模拟器、第二个可用设备、SDK 与默认浏览器环境，设备未就绪时在证据中准确记为阻塞或依项目验收矩阵判断不适用。

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-06" -parallel-testing-enabled NO -only-testing:FlutterRunletTests/ProjectSelectionTests test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-06" -parallel-testing-enabled NO -only-testing:FlutterRunletTests/FlutterToolchainTests -only-testing:FlutterRunletTests/FlutterDebugSessionTests test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-06" -parallel-testing-enabled NO -only-testing:FlutterRunletTests/ProjectRecoveryTests -only-testing:FlutterRunletTests/ProjectConcurrencyTests -only-testing:FlutterRunletTests/SessionLifecycleTests test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-06" -parallel-testing-enabled NO -only-testing:FlutterRunletTests/SessionLogTests -only-testing:FlutterRunletTests/LaunchPresentationTests test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-06" -parallel-testing-enabled NO test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Release -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-06" build
```

按任务使用上面的目标测试，波次结束执行全量，最终用同一候选完成原生验收。已有 `SessionFixture`、`DeviceScanner`、可注入的 `FlutterToolchain`、真实内嵌 worker 和 `.runlet-fixture` 脚本足以补行为回归，无额外测试框架或独立的 Wave 0 安装。初次构建耗时随本机缓存，暂无计时证据。

| 需求 | 自动验证及需补缺口 | 实际验收 |
| --- | --- | --- |
| UI-07、UI-08 | `LaunchPresentationTests` 双语资源、现有偏好和调试文案，`FlutterDebugSessionTests` VM 可用前后和快捷键。补主窗按键允许、菜单栏按键阻断的场景。 | 两处分别核对空态、就绪、等待 VM、运行、恢复和恢复失败。两种语言 × 两种外观核对标签、顺序、对比、长字段可读性、Tab/Shift-Tab、回车、Escape、图标 VoiceOver 名称以及禁用控件。 |
| UI-09 | `ProjectSelectionTests` 启动偏好、重读、切换。补旧单值迁移、别名去重、选择历史、删除单项及最终空态持久化，历史提取与删除无项目文件/恢复副作用。`ProjectConcurrencyTests` 保证控制器守卫。 | 收集两个隔离样例，两处打开历史和原生目录选择。测试取消、删除当前记录与最后一项，运行与恢复期间尝试切换。 |
| RUN-07 | `FlutterToolchainTests.testSelectionPreservesConflictOfflineAndPerProjectHistory`，`FlutterDebugSessionTests.testBrowserUsesOnlyCurrentBoundAddressAndReconnectsBeforeOpeningAgain`。补 A 上运行、切换 B、A 的命令/VM 连接和设备监测继续使用 A、下次 B 离线可阻断以及可用后确实走 B。 | 同一候选选 A 启动并在另一处选 B，核对两处下次选择同步而状态区、热操作和已连接 DevTools 留在 A；停止恢复后在 B 再启动。核对设备离线、重新出现与配置设备冲突。 |
| UI-10、UI-11 | 两处共用生命周期和资源测试，目标测试或本地构建验证 Xcode 场景可编译。 | 核对 348 pt 面板、640 × 520 pt 默认窗口外框及其原生标题栏差异，菜单栏底部操作、两处齿轮进入同一设置。观察原生系统对话框打开和返回焦点。 |
| RUN-08、RUN-09 | 复用 `ProjectRecoveryTests.testFailedPostRestartAndExplicitRetryUseOriginalLabelAndDefinition` 与风险清除故障用例。补一次点击只跑旧任务、连续恢复失败、新配置启动严格晚于旧任务和风险持久完成、重复输入和终止均不会续启动、清除失败或配置变化阻断。 | 先用独立样例初始化 `test`。用 `fail-before-test` 在 prod 停止后制造退出码 1。分别验证失败时双处反馈、保留故障时阻断并保留风险、清除故障后菜单栏/主窗单点重试只恢复，再另起一轮失败后从主窗选不同配置、点运行并记录恢复 / 新前置 / Flutter 顺序。 |
| UI-12 | `SessionLogTests.testLiveTaskAndDebugLogsClearAndCopyWithoutChangingProdRecovery` 等现有边界、过滤和阅读位置测试。 | 查看复制及清空同色、方向和键盘可用，清空后折叠并再次展开无旧日志，新输出可继续进入。折叠和清空后仍可独立查看恢复详情。 |

真实 Flutter 验收使用 [`docs/examples/sample-flutter-app/README.md`](../../../docs/examples/sample-flutter-app/README.md) 的隔离项目副本。在该副本内放置原样例 `launch.jsonc`、`tasks.jsonc` 和脚本，运行 `/bin/sh scripts/simulate-firebase-switch.sh test --quiet` 初始化环境。实际设备用普通本地构建打开该样例，使用测试账号或独立应用数据隔离恢复库。Debug `--phase-02-fixture` 使用 shell 调试替身，可复现恢复和暂停，但不能作为 Flutter 设备、VM Service 或真实 DevTools 的通过证据。正式运行验证记录候选、操作、状态、顺序和脱敏证据索引，采用[验收矩阵](../../../docs/04-ACCEPTANCE.md)的结果口径。v0.1 的布局尺寸与本阶段不同，沿用对应功能步骤和证据方法。

## 安全与并发边界

- 项目输入与身份边界由 `SessionController.validate`、`ProjectLocation`、`ProjectLease.verifyProject`、`ProjectRecoveryStore.verifyProject` 保证。项目历史仅是偏好，恢复记录独立保存，原任务定义匹配和参数引用规则来自技术契约。
- 运行与恢复流程经同一 `SessionController` 管控在途操作。Worker 确认旧进程组退出后才允许原恢复任务，恢复退出 0 及持久清除通过后才可能启动。项目租约和恢复记录继续约束 UI 状态跳转、日志清空、历史记录删除和另一实例的操作。
- 会话地址包含 VM Service 令牌，只有该会话实际绑定的浏览器动作可用。继续复用日志遮罩，截图和命令证据留在本地，仅提交可复验的脱敏摘要。
- 故障标记、主动失败模拟与设备断线仅用于可恢复的独立样例，不修改业务项目。项目配置与脚本可用前后摘要核对，用户自己的 Flutter 文件由应用只读处理。

<phase_requirements>

| ID | 调研覆盖 |
| --- | --- |
| UI-07 | 共享状态语义、双语资源、两种外观和原生辅助功能 |
| UI-08 | 双场景共享控制器、固定动作、当前会话启用规则 |
| UI-09 | 偏好迁移、规范化项目、历史单删、系统目录和切换限制 |
| UI-10 | 菜单栏现有接线、348 pt 和状态动作 |
| UI-11 | 主窗场景、640 × 520 pt 和共享齿轮 |
| UI-12 | 日志缓冲清空边界、阅读定位及独立详情 |
| RUN-07 | 设备发现和可用性来源、下次选择与运行快照分离 |
| RUN-08 | 当前状态、结构化恢复失败和退出码来源 |
| RUN-09 | 仅恢复及恢复后启动的路径、租约、持久状态和重入 |

</phase_requirements>
