---
phase: 03-flutter
verified: 2026-11-13T19:18:36Z
status: passed
score: 38/38 must-haves verified
covered_files: [
  ".planning/milestones/v0.1-phases/03-flutter/03-01-PLAN.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-01-SUMMARY.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-02-PLAN.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-02-SUMMARY.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-03-PLAN.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-03-SUMMARY.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-04-PLAN.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-04-SUMMARY.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-CONTEXT.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-G2-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-REVIEW-DISPOSITION.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-REVIEW.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-SECURITY.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-UI-REVIEW.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-UI-SPEC.md",
  ".planning/milestones/v0.1-phases/03-flutter/03-VALIDATION.md",
  ".planning/milestones/v0.1-phases/04-macos/04-P4-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-01-SUMMARY.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-ENVIRONMENT.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-G3-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-LOG-STRESS.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-RECOVERY.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-REVIEW-DISPOSITION.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-VALIDATION.md",
  "FlutterRunlet.xcodeproj/project.pbxproj",
  "FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme",
  "FlutterRunlet/AuxiliaryWindows.swift",
  "FlutterRunlet/FlutterDebugSession.swift",
  "FlutterRunlet/FlutterRunletApp.swift",
  "FlutterRunlet/FlutterToolchain.swift",
  "FlutterRunlet/MainWindowView.swift",
  "FlutterRunlet/MenuBarPanelView.swift",
  "FlutterRunlet/ProjectConfiguration.swift",
  "FlutterRunlet/ProjectRecoveryStore.swift",
  "FlutterRunlet/SessionController.swift",
  "FlutterRunlet/SessionProcess.swift",
  "FlutterRunletSessionWorker/main.swift",
  "FlutterRunletTests/FlutterDebugSessionTests.swift",
  "FlutterRunletTests/FlutterToolchainTests.swift",
  "FlutterRunletTests/SessionLogTests.swift",
  "docs/02-TECHNICAL.md",
  "docs/04-ACCEPTANCE.md",
  "docs/examples/sample-flutter-app/README.md",
  "docs/examples/sample-flutter-app/launch.jsonc",
  "docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh",
  "docs/examples/sample-flutter-app/tasks.jsonc"
]
covered_digest: "v3:sha256:17ba4b2647e41ed09ed5c83e08a9a17ca7951782df7296bef47c1b216b75d72c"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 16
  total: 16
  not_honored: []
---

# Phase 03 · Flutter 调试闭环验证

G2 最终候选 `0416505db76e7dde868db92110e8a0fb2d074520` 达成 G2。四条路线图成功标准、34 条计划断言及 RUN-01 至 RUN-06 均有源码接线与行为证据。Debug XCTest 57/57 通过，Release 构建成功，两套 App 与其内嵌 worker 的可执行性和签名均通过核对。独立复核重新比对了四个构建产物的 SHA-256，并运行了四个定向 XCTest。九个 G2 条目的适用分支均通过。真机按 A18 规则记为不适用，证据为无可用 Android 真机及已发现的无线 iOS 真机隧道断开、签名身份数为零。以下保留 G2 原始证据，v0.1 候选结论见末节。[G2 验收及最终候选复验](03-G2-ACCEPTANCE.md)

## 路线图成功标准

| 条目 | 状态 | 可观察证据 |
| --- | --- | --- |
| A17、A18、A24 · SDK 和设备 | 通过 | 主窗启动关机的 iPhone 17 模拟器并启动真实 Flutter。最终候选重新用 iPhone 17 和 `emulator-5560` 连接 VM Service。FVM 缺链阻断，修复后重新激活即可重检。手动 SDK 候选失败、设备冲突和同 ID 重连均有覆盖。 |
| A19、A21、A22 · 同一会话的运行和恢复 | 通过 | iOS 热重载与菜单栏热重启均保留同一 Flutter PID，计数分别继续与归零。关闭和重开主窗沿用同一进程。仅 DDS 中断后同一进程重连，实际关闭选中模拟器触发停止并恢复。 |
| A20 · DevTools 和 Inspector | 通过 | 默认 Edge 的两个入口跟随 dev、test、prod 重跑更新 DDS 端口。Inspector 实际选中 `MyHomePage`，显示对应属性和 test/v2 子树。目标版本外走已连接 DevTools 的回退路径，由 XCTest 证明。 |
| A13、A30 · 前后置恢复和流式日志 | 通过 | 真实 dev/test/prod 的 Dart defines 和样例标记一致。最终候选正常停止和关机断开时，Flutter 与 worker 退出后才观察到 prod → test，风险归零。清空日志后折叠、展开和重开无旧内容，真实输出继续追加。 |

## 计划断言覆盖

| 计划及断言 | 计数 | 可观察证据 |
| --- | ---: | --- |
| 03-01 · 首次真实 iOS 调试和当前 VM、prod 恢复顺序 | 2/2 | 真实设备 AX 记录、最终候选两条恢复时序记录及 `testCurrentMachineAppAndVMVerificationGateProdRecovery`。 |
| 03-01 · 执行前复验与去重、非空应用参数拦截、会话令牌隔离 | 3/3 | `testInvalidPreflightLeavesEnvironmentAndRiskUntouched`、`testAndroidUsesExactDeviceAndDefinesAndBlocksUnsupportedApplicationArguments` 及 G2 配置字节比对。浏览器取得内存中的当前地址，日志和恢复记录通过脱敏及边界核对。 |
| 03-02 · D-01–D-04 | 4/4 | `testSelectionPreservesConflictOfflineAndPerProjectHistory` 与 `testObsoleteDeviceScanCannotReplaceTheNewProjectsSelection` 断言自动选择边界、显式冲突、离线保留、旧回调及每项目会话历史。G2 复现冲突与同 ID 重连。 |
| 03-02 · D-05–D-08 | 4/4 | SDK 优先级、候选验证、激活重检和恢复期间锁定 XCTest。实测记录显示设置中的 FVM、Flutter/Dart 版本与实际执行 SDK 一致。 |
| 03-02 · 模拟器选择、E3 持久化与锁定、用户显式启动 | 3/3 | `testSimulatorStartWaitsForFlutterAndNeverLaunchesDebug`、`testValidatedSettingsPersistAndKeepTheActualSDKLockedThroughRecovery` 和 iOS、Android 实测。SDK 修复和模拟器启动均不派发调试进程。 |
| 03-03 · D-09–D-12 | 4/4 | `testWaitStartsAtWorkerSpawnAndRemainsStoppableAfterSixtySeconds`、`testVMReconnectDoesNotStopUntilDeviceScanConfirmsDisconnect` 和 G2 DDS 中断、同一模拟器关机及恢复时序。 |
| 03-03 · D-13–D-16 | 4/4 | SessionLogTests 覆盖失败预检、实际派发失败、跨项目、分片遮罩及超过 64 KiB 裁剪后的可见行和选区。G2 覆盖跟随、返回底部、整段与选区复制。 |
| 03-03 · 共享会话、浏览器绑定、日志清空后重开、操作反馈、清空隔离 | 5/5 | 菜单栏与主窗 PID 复核、Edge 重绑和 Inspector 截图、清空后重开及新输出记录。XCTest 断言当前热操作结果与浏览器回退反馈，并核对清空前后同一恢复记录。 |
| 03-04 · 构建与四组真实验收断言 | 5/5 | 最终候选 57/57、签名、旧参数隔离、iOS/Android 原生复验。原矩阵继续支持代码未改动的菜单栏热操作与浏览器路径，真机按 A18 约定不适用。 |

## 产物、接线与数据来源

`verify.artifacts` 对四份计划共 15 条产物声明全部通过。同一 Swift target 内的符号调用和 App 到 worker 的启动不会引用 Swift 文件路径，`verify.key-links` 的文件名检查直接确认两条文档链接。其余 11 条通过源码调用、target 接线及以下运行证据逐项核对。

| 路径 | 接线和数据流 | 结论 |
| --- | --- | --- |
| `FlutterRunletApp.swift` → 主窗、菜单栏、Flutter 设置 → `SessionController.swift` | 三处接收同一个 `liveSession`，主窗和菜单栏使用相同的 `DebugControls`、`BrowserControls`。App 激活调用 SDK 重检，设置将用户选择交给控制器验证。 | 已连接 |
| `SessionController.swift` → `FlutterToolchain.swift` → 真实 Flutter 或 simctl | 解析项目 SDK 并读取实际 Flutter/Dart 版本及设备 JSON。Run 持有项目租约，复验已选设备和任务，使用绝对 SDK 路径、实际 ID 与参数向量。 | 已连接 |
| `SessionController.swift` → `SessionProcess.swift` → `FlutterRunletSessionWorker/main.swift` | 进程监督器继承租约并分离机器 stdin 与停止管道。启动回执确认真正派发，退出报告和进程组退出决定能否运行原后置任务和清除风险。 | 已连接 |
| `SessionController.swift` → `FlutterDebugSession.swift` → VM、浏览器和日志 | 机器事件经当前 device ID、app ID 与 VM 协议验证后驱动共享状态。热操作匹配当前请求。DevTools 绑定当前 VM，日志在进入展示和复制前遮罩。 | 已连接 |
| `SessionController.swift` → `MainWindowView.swift` | 日志来自真实任务与 Flutter 流。日志代数隔离清空后的旧数据，裁剪的 UTF-16 长度驱动可见锚点与选区恢复。 | 已连接 |
| Xcode target 与 G2 证据 | `project.pbxproj` 注册实现、XCTest 和嵌入 worker。三组新增 XCTest 进入实际 scheme。G2 记录链接到验收矩阵和公开样例。 | 已连接 |

## 定向复验

使用共享 Debug scheme 和同一候选已有构建运行 `xcodebuild test-without-building`，以四个 `-only-testing` 参数各选一项，共执行 4 项、0 失败。构建与签名日志在 G2 最终候选证据目录，独立复验输出位于 `/tmp/runlet-03-verifier.TsKQgb/spot.log`。

| 测试 | 结果 |
| --- | --- |
| `FlutterDebugSessionTests/testCurrentMachineAppAndVMVerificationGateProdRecovery` | 通过。当前 VM 协议验证、prod 风险标记、退出后恢复。 |
| `FlutterDebugSessionTests/testVMReconnectDoesNotStopUntilDeviceScanConfirmsDisconnect` | 通过。健康 VM 的暂时设备缺席不停止，确认断开才停止并恢复。 |
| `FlutterDebugSessionTests/testBrowserUsesOnlyCurrentBoundAddressAndReconnectsBeforeOpeningAgain` | 通过。拒绝过期连接和不匹配地址，重连后使用当前连接。 |
| `SessionLogTests/testWorkerSpawnFailureBeforeFirstTaskKeepsPreviousLogs` | 通过。实际子任务派发失败后保留旧日志。 |

## 需求覆盖

| 需求 | 来源计划 | 状态 | 依据 |
| --- | --- | --- | --- |
| RUN-01 | 03-01、03-02、03-04 | 满足 | A17、A18。真实 iOS/Android、显式设备冲突和离线恢复。 |
| RUN-02 | 03-01、03-02、03-04 | 满足 | A24。FVM、手动 SDK 与 PATH 优先级，SDK 失效阻断与实际版本一致。 |
| RUN-03 | 03-01、03-03、03-04 | 满足 | A13、A17、A19、A22。当前 VM、热操作、停止和断开后恢复。 |
| RUN-04 | 03-03、03-04 | 满足 | A20。默认浏览器、真实 Inspector Widget、会话重绑及已连接回退。 |
| RUN-05 | 03-01、03-02、03-03、03-04 | 满足 | A21。关闭主窗后菜单栏控制同一 Flutter 进程。 |
| RUN-06 | 03-03、03-04 | 满足 | A30。日志查看、折叠、清空、持续输出和脱敏复制。 |

GSD 决策覆盖检查确认 D-01 至 D-16 全部有对应实现。要求关联的 XCTest 含行为、状态、进程和文件副作用断言，检查未发现跳过用例或未登记的债务标记。三项代码警告与三项界面偏差均在最终候选修正并复验。十项高危缓解均已核实，开放威胁数为零。[代码审查处置](03-REVIEW-DISPOSITION.md) · [原生界面复验](03-UI-REVIEW.md) · [安全复核](03-SECURITY.md) · [测试与跨阶段回归](03-VALIDATION.md)

适用的 G2 行为已有自动或实机证据。人工复核项为零。

## v0.1 最终候选复核（2026-11-14）

最终候选 `36916dd1f6a6f916a1c76ca93aa37ae84f8247f6` 的应用、worker、XCTest 和 Xcode 工程与本轮复核源码一致。38/38 项及 RUN-01–06 通过。复用同候选 Debug 77/77、Release 构建签名和 G3 验收。四份计划的 15 个产物通过 GSD 探针。Swift 同一 target 的接线按实际符号调用、共享实例注入、嵌入 worker、受管进程及机器事件逐项核对。决策覆盖 16/16。[最终验证](../05-stability-recovery-release/05-VERIFICATION.md) · [G3 矩阵](../05-stability-recovery-release/05-G3-ACCEPTANCE.md)

| 计划及验收 | 最终候选证据 |
| --- | --- |
| 03-01、03-02、03-04 · RUN-01、RUN-02，A17、A18、A24 | 最终 Release 用两款 iPhone 模拟器及 Android 模拟器实测当前 VM Service。FVM 版本与实际进程一致及缺链阻断沿用 P4 的 Flutter 3.47.4 实测。自该验收候选 `184ffc5` 至最终候选的工具链与设置生产文件相同。现有 `FlutterToolchainTests` 覆盖设备默认选择、离线、冲突、避免旧扫描覆写、按项目记忆、模拟器启动、手动 SDK 校验和无效 FVM 重检，实际 Android 设备 ID 与参数向量由测试和实机记录核对。真机沿用 A18 的不适用范围。[工具链验收](../04-macos/04-P4-ACCEPTANCE.md#验收矩阵) · [决定及测试](03-VALIDATION.md) |
| 03-01、03-03、03-04 · RUN-03、RUN-05，A13、A19、A21、A22 | 最终 Release 的 A13 确认退出后恢复 test，Android 两项热操作保持同一设备内 App PID。原生共享 Running 复验及 P4 关窗后仅在菜单栏操作同一 Flutter PID 覆盖跨窗口控制。等待满 60 秒、确认断开后停止且原任务恢复、仅 VM 中断不停止、多次启动守卫均有 `FlutterDebugSessionTests` 的状态和副作用断言。实际退出和设备关机证据来自 `c80ec88`，当前仅日志视图及测试相对该候选有变更。真实 WebSocket 重连另见下节。[P4 同会话与快捷键](../04-macos/04-P4-ACCEPTANCE.md#验收矩阵) · [恢复矩阵](../05-stability-recovery-release/05-RECOVERY.md) |
| 03-01、03-03、03-04 · RUN-04，A20 | 最终候选在默认浏览器两轮打开 DevTools 与 Inspector，两入口每轮绑定同一 VM，第二轮地址更新。G2 在 Flutter 3.47.4、DevTools 2.60.0 上选择 `MyHomePage` 并读取真实属性和子树。自 G2 至最终候选，`browserDestination`、`bindsService` 和版本限定语义未变。连接探活复用的变更已在真实会话和本轮回环补验覆盖。`testBrowserUsesOnlyCurrentBoundAddressAndReconnectsBeforeOpeningAgain` 与 `testUntestedInspectorVersionOpensConnectedDevToolsWithFallbackFeedback` 覆盖当前地址校验和已连接回退。[地址绑定](../../../../FlutterRunlet/FlutterDebugSession.swift#L190) · [G2 Widget 取证](03-G2-ACCEPTANCE.md#验收矩阵) · [G3 矩阵](../05-stability-recovery-release/05-G3-ACCEPTANCE.md) |
| 03-01、03-03、03-04 · RUN-06，A13、A30 | 最终候选 A29 对照真实工程三环境，A13 验证公开样例的普通 Release 顺序，G2 记录补充公开 dev/test 的实际参数及环境。最终候选 30 分钟样本验证清空、折叠展开和后续接收。`SessionLogTests` 覆盖日志在阻断、派发失败与项目切换时的保留或清空、代际隔离、链接脱敏、无损复制、裁剪后位置与选区和原始 Unicode 编码。日志控制器与日志视图分别管理数据与折叠态，重开主窗继续读取同一控制器。配置只读和令牌边界按测试及产物接线复核。[日志测试](../../../../FlutterRunletTests/SessionLogTests.swift) · [压力与清空记录](../05-stability-recovery-release/05-LOG-STRESS.md#最终候选-30-分钟实测) · [真实工程三环境](../05-stability-recovery-release/05-ENVIRONMENT.md#a29--真实项目) |

### VM Service 断链补验

G2 的单独 VM Service 断链取证早于 `c80ec88` 的连接复用改动。现成 XCTest 注入探针，覆盖上层状态及实际调试进程的保留和停止。此次补验直接用 Swift 6 编译现有 `FlutterDebugSession.swift`，以 `verifyVM: nil` 运行真实 Foundation WebSocket，向只监听 `127.0.0.1` 的临时 JSON-RPC 服务发送 `getVersion`，并用合成机器事件提供同一端点。服务端记录同一连接接收三个请求，前两个成功，第三个主动关闭连接。下一连接的错误响应 ID 未恢复许可，第三条连接返回正确 ID 后恢复同一会话。五次请求 ID 无重复，浏览器许可按关闭、开启、关闭、开启、关闭变化，恢复后 Inspector 路径正确，结束后禁用。探针退出 0。G3 提供真实 Flutter 连接及两轮浏览器取证，本轮仅补真实传输断开与重建分支。[生产探活](../../../../FlutterRunlet/FlutterDebugSession.swift#L302) · [上层断链回归](../../../../FlutterRunletTests/FlutterDebugSessionTests.swift#L292) · [探活变更记录](../05-stability-recovery-release/05-LOG-STRESS.md#vm-service-探活诊断)
