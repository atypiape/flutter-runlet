# Phase 04 · 代码复用图

**日期** 2026-11-13

依据为 [阶段决定](04-CONTEXT.md)、[技术研究](04-RESEARCH.md)和[界面契约](04-UI-SPEC.md)。表中接入点均来自 Git 已跟踪文件。

## File Classification

| 改动位置 | 角色与数据流 | 最近先例 |
| --- | --- | --- |
| `FlutterRunlet/FlutterRunletApp.swift` | App 场景与启动，系统事件、共享依赖 | 同文件 `liveSession`、`showMainWindow`、`MainWindowIdentity`、`PanelWindowAnchor`、`AppTermination` |
| `FlutterRunlet/SessionController.swift` | 状态控制器，项目、会话、偏好及恢复事件 | 同文件 `canRun`、`canStop`、`canHotOperate`、`retryRecovery`、`discoverRecovery`、SDK 请求标识 |
| `FlutterRunlet/MainWindowView.swift`、`FlutterRunlet/MenuBarPanelView.swift` | 原生界面，展示状态及派发操作 | `DebugControls`、`BrowserControls`、`PresentationField`、日志外恢复动作及 AppKit 悬停桥接 |
| `FlutterRunlet/AuxiliaryWindows.swift` | 原生设置及关于，偏好绑定、诊断请求、链接 | 同文件 `SettingsView.Page`、`flutterSettings`、`chooseSDK`、`AboutView` |
| 应用语言状态、翻译资源和诊断结果（拟增） | 可观察偏好、语义文案转换、有限进程输出 | `SessionController.swift` 的 `UserDefaults` 和请求身份；`FlutterToolchain.swift` 的探测、执行及解析 |
| `FlutterRunlet/Assets.xcassets`、`FlutterRunlet.xcodeproj/project.pbxproj` | 资源与目标配置，构建打包 | `BrandGlyph.imageset`、菜单栏模板资源和原生图像入口，`docs/design/assets` 的现有 Dock 导出 |
| `FlutterRunletTests/` | XCTest，偏好持久化、真实进程和会话副作用 | `SessionFixture`、`FlutterToolchainTests`、`ProjectRecoveryTests`、`FlutterDebugSessionTests` |

## Pattern Assignments

### 场景、启动和设置

- `FlutterRunlet/FlutterRunletApp.swift:20–88` 创建一次 `SessionController` 并将 `liveSession` 传入主窗、菜单栏和设置。语言状态与登录偏好接入同一 App 层，保留当前场景 ID 和预览／验收参数隔离。`showMainWindow` 会按 `mainWindowIdentifier` 复用、反最小化或打开主窗。`MainWindowIdentity` 和 `PanelWindowAnchor` 保留 G1 的 Dock 激活策略及菜单栏关闭行为。
- `FlutterRunlet/SessionController.swift:19–21,108–111,187–194` 保留已有偏好键及默认读取语义。初始化在最近项目尝试之后调用 `discoverRecovery()`，可据此决定启动是否显示主窗。使用 `recovery` 判定启动入口，项目是否自动打开及重试仍由原流程决定。

```swift
rememberRecentProject = preferences?.object(forKey: Self.rememberKey) as? Bool ?? true
if rememberRecentProject, let path = preferences?.string(forKey: Self.recentKey) {
    _ = loadProject(URL(fileURLWithPath: path, isDirectory: true), remember: false)
}
discoverRecovery()
```

- `FlutterRunlet/AuxiliaryWindows.swift:4–60` 的 `Page` 和现有 `Binding` 是通用设置入口。`flutterSettings`（61–119 行）沿用 `canEditFlutterSDK` 与 `canRefreshDevices` 所区分的能力。`AppTermination.applicationDidBecomeActive` 已重检无效 SDK，适合作为同步登录项实际状态的生命周期先例。系统注册及待批准的分支参考 [技术研究](04-RESEARCH.md#启动和登录项)。

### 共享操作、恢复和全名

- `FlutterRunlet/MainWindowView.swift:410–441` 的 `DebugControls` 将按钮接到 `canRun`、`canStop`、`canHotOperate`。`MenuBarPanelView.swift:26–49` 复用同一组件和 `SessionController`。在一个应用内分发位置重用这些条件与方法，验证主窗口和菜单栏面板同时存在时只消费一次。连接和热操作互斥沿用 `SessionController.swift:38–45`。
- `FlutterRunlet/MainWindowView.swift:182–202` 已在日志外显示原因、项目路径、任务及按钮。`FlutterRunlet/SessionController.swift:344–359` 是打开待恢复项目和重试的权威守卫。前者还验证项目身份，后者验证当前项目与持久记录一致。主窗与菜单栏共用这层规则；受管退出确认及执行原任务继续留在控制器。

```swift
guard !isBusy, !executionIsUnconfirmed, recoveryStoreIssue == nil, let expected = recovery,
      recoveryProjectIsOpen, let project, let store else { return }
```

- `FlutterRunlet/MainWindowView.swift:375–406` 提供非拦截鼠标的 `ProjectToolTip` 与 `PresentationField` 的 `.lineLimit(1)`、尾部省略及 `.help`。独立全名按钮位于选择器禁用范围外。对主窗原生选择器与菜单栏只读字段分别验证锁定时的悬停、点击及键盘行为。

### 应用级本地化

- 静态资源入口包括 `MainWindowView.swift:391–406` 和 `AuxiliaryWindows.swift:10–25,110–118` 的 `LocalizedStringKey`。动态文案须检查 `SessionController.swift:7–10,65–105,1069` 的 `SessionFeedback`、`status`、`displayMessage` 和恢复原因，以及 `FlutterToolchain.swift:4–9` 的 SDK 来源值。目前 `MainWindowView.swift:175–192,451–453` 与 `MenuBarPanelView.swift:40–41` 直接渲染格式化文本，语言改变时可能残留旧文本。让应用自有状态、提示和错误在展示时解析，并保留插值中的原始名称、路径、版本及原始 CLI 输出。
- `FlutterRunletApp.swift:46–85,143–150,227–252` 含场景标题、应用菜单和 AppKit 对话框。`MainWindowView.swift:148–157`、`AuxiliaryWindows.swift:121–132` 含自有文件面板标题。与 SwiftUI 共用应用语言选择，验证已经打开的场景、自有菜单、动态反馈和下一次 AppKit 提示。系统自带面板按钮和文案差异按界面契约记录。

### SDK 诊断

- `FlutterRunlet/FlutterToolchain.swift:79–136,257–288` 已建立可注入解析和探测，`FlutterSDK.executable` 指向实际使用的 SDK。doctor 复用绝对可执行路径及 `probeEnvironment`，沿用固定参数和独立工作目录。`readQuery`（324–370 行）提供非阻塞读取、超时和容量上限先例。该 JSON 探测丢弃 stderr，诊断需及时消费两路并保留原始输出。诊断退出与工具链逐项结果分别表达。
- `FlutterRunlet/SessionController.swift:480–501` 为异步 SDK 选择使用 UUID 及项目快照。诊断按请求、SDK 与项目拒绝过期结果，启动和恢复仍用现有锁定边界。`FlutterToolchainTests.swift:131–170` 已用 `PausedProbe` 验证迟到的 SDK 探测，适合扩展到诊断结果的归属验证。

```swift
let request = UUID()
let project = project
// 异步完成后核对请求与项目。
guard let self, self.sdkSelectionID == request, self.project == project else { return }
```

### 关于、图标和 Xcode 目标

- `FlutterRunlet/AuxiliaryWindows.swift:136–165` 已读取 `Bundle.main` 的真实版本和构建号，展示 `BrandGlyph`。用 D-07 地址及 [G1 上游审计](../01-upstream-audit-ui-shell/01-UPSTREAM-AUDIT.md)补齐关于窗口。`FlutterRunlet/SessionController.swift:128` 的 `openURL` 注入可作为链接打开验证先例。
- `FlutterRunletApp.swift:256` 的 `makeMenuBarTemplate` 已读取模板并标记 `isTemplate`。`FlutterRunlet.xcodeproj/project.pbxproj:292–300` 将品牌资源与菜单栏模板编入 App。应用图标从 `docs/design/assets` 的已验收 16–1024 px 导出填充 AppIcon 槽位。新 Swift 文件及翻译资源分别接入 App 的 Sources、Resources；测试文件接入 Tests Sources（327–338 行）。Debug 和 Release 的 App 设置都需检查。

## Shared Patterns

| 测试先例 | 可复用验证 |
| --- | --- |
| `FlutterRunletTests/ProjectSelectionTests.swift:80` | 隔离 `UserDefaults`，重新创建控制器验证保存的偏好，确认启动读取不执行项目任务。 |
| `FlutterRunletTests/ProjectRecoveryTests.swift:76` | 后置失败后重启，验证风险仍可见；显式重试原定义，确认恢复退出后才清除记录。 |
| `FlutterRunletTests/FlutterDebugSessionTests.swift:134`、`:201` | 热操作只作用于当前会话，等待连接时可停止。候选构建补测系统按键与可访问性。 |
| `FlutterRunletTests/FlutterToolchainTests.swift:79`、`:131` | 隔离 SDK 夹具、真实偏好持久化、恢复期间设置锁定、异步结果过期。 |
| `FlutterRunletTests/SessionLifecycleTests.swift:185`、`FlutterRunletTests/SessionLogTests.swift:25` | 临时独立项目和受管进程复用；应用翻译保留原始日志及 G2 连接令牌遮罩。 |

使用 `FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme:25–51` 的 Debug TestAction 与 `FlutterRunletTests`。按任务定向测试，按 [技术研究](04-RESEARCH.md#validation-architecture)运行完整测试与 Release 构建。原生窗口、菜单栏、两种外观和登录项的补充验证关联候选构建及实际证据。

## No Analog Found

- 仓库没有整应用即时切换语言、登录项注册或前台功能键分发的直接先例。采用技术研究中的原生机制，保留现有场景、系统快捷键和偏好语义。
- 仓库没有 doctor 文本协议解析、完整诊断输出展示或应用 Dock 图标资源集。沿用 SDK 探测和品牌打包的相邻模式，按各自实测数据验证。
