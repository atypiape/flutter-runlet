# 阶段 06 · 现有实现映射

**映射日期** 2026-11-14。路径均相对仓库根目录，代码与测试参考均已确认纳入 Git。

## 文件与数据流

| 文件 | 角色与数据流 | 优先复用的实现 |
| --- | --- | --- |
| `FlutterRunlet/MainWindowView.swift`、`FlutterRunlet/MenuBarPanelView.swift` | 视图，状态驱动与操作事件 | 主窗的 `DebugControls`、`BrowserControls`、`RecoveryDetails` 已由两处调用。主窗的配置和设备入口可提取共享绑定。 |
| `FlutterRunlet/FlutterRunletApp.swift`、`FlutterRunlet/Localizable.xcstrings` | 场景路由、键盘事件与资源 | 共用 `liveSession`、`showSettings()`、`AppLanguageSettings` 及两处注册的 `DebugKeys`。 |
| `FlutterRunlet/SessionController.swift` | 会话控制器，偏好读写、预检、启动、调试回调与日志流 | `loadProject`、`applyDeviceSnapshot`、`retryRecovery`、`beginFlutterRun`、`restore`、`openBrowser` 和 `resetLogs`。 |
| `FlutterRunlet/FlutterToolchain.swift`、`FlutterRunlet/FlutterDebugSession.swift` | 发现与探测、当前会话连接 | `FlutterDevice`、`FlutterSimulator`、`FlutterDeviceAvailability` 与 `FlutterDebugSession.browserDestination`。沿用 CLI 查询和调试连接。 |
| `FlutterRunlet/ProjectRecoveryStore.swift`、`FlutterRunlet/SessionProcess.swift` | 项目身份、租约、风险记录与进程退出 | `ProjectRecoveryStore.lease/verifyDefinition/verifyExecution/remove`、`ProjectLease.verifyProject` 和 `SessionExit`。用于保护生命周期。 |
| `FlutterRunlet.xcodeproj/project.pbxproj` | 目标配置 | `PBXSourcesBuildPhase` 显式列出源文件。若共用视图单独成文件，按现有目标归属登记。 |
| `FlutterRunletTests/*Tests.swift` | XCTest，控制器和宿主行为 | 继续使用现有实例、测试数据与 worker，见下方用例映射。 |

## 参考实现

- **按钮、窗口与键盘**　`MainWindowView.swift:530–619` 的 `DebugControls` 按 `canPerformDebugAction` 和 `performDebugAction` 驱动按钮，`BrowserControls` 按 `canOpenBrowser` 启禁用。两处复用按钮语义，各自排列；保留仅在无法获得当前调试地址时显示原因的反馈。参照同文件 87–94 行齿轮的 `.help("Settings")` 和 `.accessibilityLabel("Settings")`。`FlutterRunletApp.swift:182–227,285–288` 已共享控制器、语言和设置路由。`DebugKeys.dispatchDebugKey`（464–472 行）在当前可见、已注册窗口且无系统模态窗口或附加表单时转发。要在注册时保留来源，菜单栏 F5 仍只走普通运行，主窗口获得恢复并启动入口。
- **项目历史**　`MainWindowView.openProject`（159–169 行）以 `NSOpenPanel` 选择目录。`SessionController.open`（363–366 行）再次守卫切换，`loadProject`（379–416 行）先规范化目录再更新偏好。历史点击重用 `open`，删除只作用于偏好。保留 `recentProjectPath` 启动兼容，第一次迁移后明确区分空历史与未迁移。视图需要不产生副作用的共享启用条件；现有 `requestProjectChange` 会写入反馈。
- **下次设备与当前会话**　`SessionController.selectDevice/storeDevice`（552–564 行）按项目保存所选 ID，`applyDeviceSnapshot`（711–719 行）只接受对应项目的发现结果。以已确认的设备发现和已有模拟器元数据形成两处共用的列表，设备查询失败保留明确反馈。`beginFlutterRun`（825–869 行）重新探测后按捕获的 `deviceID` 查找设备，`monitorDebugProcess`（1172–1207 行）持续使用传入的真实运行设备；`openBrowser`（960–970 行）从 `debug?.browserDestination(page)` 取地址。主窗 188–189 行从 `selection/selectedDevice` 展示当前会话，需要改用实际启动快照。保持启动与恢复过渡态的禁用边界。
- **恢复原任务与恢复后启动**　`SessionController.retryRecovery`（456–493 行）复读持久记录，固定读取 `record.taskLabel` 后校验任务定义和执行参数。`restore`（1077–1102 行）验证项目身份，等待后置任务结果 `.exited(0)`，成功移除风险记录后才清内存风险并重新检查。`SessionExit`（`SessionProcess.swift:11`）提供真实退出形式，适合作为结构化提示来源。普通 `run`（773–804 行）和 `revalidate`（806–823 行）各自阻断恢复风险；恢复并启动沿用原任务校验、租约和启动预检，通过受管操作衔接，并检查重新发现的风险及终止意图。两个点击处理器在异步调用完成后接力会留下可重入窗口。参照 `finishForTermination`（974–982 行）的终止状态与等待行为。
- **日志**　`MainWindowView` 的 `isLogExpanded`、`logs`（217–247 行）和 `SessionLogView`（272–282 行）已把呈现、空态和 AppKit 文本视图分开。`SessionController.clearLogs/copyLogs/resetLogs`（928–958 行）统一剪贴板反馈并推进 `logGeneration`，取消旧待刷批次。重用这些入口改造图标和折叠。现有 `RecoveryDetails`（250–269 行）与日志没有依赖，保留独立的可达入口。

## 现有用例

- `ProjectSelectionTests.testRecentProjectPreferenceReadsDiskAndNeverRunsTasks` 可作历史兼容基线，补逐条删除和空态持久化。`ProjectConcurrencyTests.testStopWaitsForSameGroupDescendantAndBlocksAliasSwitchAndRetry` 锁定项目切换和恢复边界。
- `FlutterToolchainTests.testSelectionPreservesConflictOfflineAndPerProjectHistory` 及 `FlutterDebugSessionTests.testBrowserUsesOnlyCurrentBoundAddressAndReconnectsBeforeOpeningAgain` 可作设备和 VM 绑定基线，补会话 A 与下次设备 B 同时存在。
- `ProjectRecoveryTests.testFailedPostRestartAndExplicitRetryUseOriginalLabelAndDefinition` 和 `testInvalidRecordAndFailedRemovalKeepRecoveryBlocked` 锁定原任务和风险持久化，补恢复成功后才按新配置启动的顺序及失败阻断。
- `SessionLogTests.testIncompleteAndQueuedLinesKeepTheirOriginalClearBoundary`、`testLiveTaskAndDebugLogsClearAndCopyWithoutChangingProdRecovery` 可复用。`LaunchPresentationTests.testAppBundleContainsEnglishAndSimplifiedChineseRunCopy` 适合补新增按钮的双语资源。

项目历史列表、两处共享的设备行及恢复后接续启动均为本阶段新增行为。通过以上接缝扩展现有状态和数据流。
