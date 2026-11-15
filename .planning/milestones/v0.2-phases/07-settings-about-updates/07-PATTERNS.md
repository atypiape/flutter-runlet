# 阶段 07 · 现有实现与复用点

| 区域 | 现有落点与复用方式 |
| --- | --- |
| 场景与偏好 | `FlutterRunlet/FlutterRunletApp.swift` 的 `Settings`、独立关于场景、`AppLanguageSettings` 和 `LoginItemSettings`。同一个 Settings 场景承接两处齿轮，保留系统设置入口、登录项状态刷新和启动时待恢复行为。 |
| 设置与关于 | `FlutterRunlet/AuxiliaryWindows.swift` 已有 `SettingsView`、`chooseSDK(for:)`、`environmentCheck(_:)`、`doctorOutput(_:text:)`、`AboutInformation` 和 `AboutView`。复用 Bundle 与链接来源、目录选择和 Doctor 数据流，独立设置三页与关于窗口的布局。 |
| 视觉与语言 | `FlutterRunlet/RunletAppearance.swift` 的 `RunletAppearance`、`RunletType`、`RunletIcon`、`RunletButtonStyle`、`RunletPopup`；按需补缺少的同源色值。复用 `FlutterRunlet/Assets.xcassets/BrandGlyph.imageset`、仓库字体与 `Localizable.xcstrings`。新增视觉样式作用于本阶段界面，避免改变已验收主窗口和菜单栏。 |
| SDK 与环境 | `FlutterRunlet/SessionController.swift` 的 `checkFlutterSDKIfNeeded()`、`checkEnvironment()`、`cancelEnvironmentCheck()`；配合 `FlutterToolchain.swift`。保留手动路径、项目 FVM、运行 SDK 一致性和取消/失败结果失效。`FlutterRunletTests/FlutterToolchainTests.swift` 复用。 |
| 演示隔离 | `LaunchPresentation.swift`、`SessionController.fixtureEnabled(arguments:)`、`fixture` 及 `FlutterRunletApp.swift` 现有演示与真实会话分流。更新画板状态通过仅本地调试可用的可控入口驱动真实 UI，两处视图共用数据；发行构建不能启用演示检查、端点或测试信任。`LaunchPresentationTests.swift` 已覆盖演示和实际版本基础。 |
| 退出与恢复 | `AppTermination.applicationShouldTerminate(_:)` 基于 `SessionController.canTerminate`、`hasPendingEnvironmentChecks`、`beginFinishingTermination()`、`finishForTermination()`。`canTerminate` 同时要求空闲、进程退出可确认、无未恢复记录、无恢复记录读取错误。更新沿用真值来源；需指定安装预约与普通退出的差异。现有 `SessionLifecycleTests`、`ProjectRecoveryTests`、`ProjectConcurrencyTests` 可回归。 |
| 构建与资产 | `FlutterRunlet.xcodeproj` 与 `scripts/package-release.sh` 已产出普适架构 DMG 及 SHA-256、校验 App 和现有会话 worker 的签名与架构。临时签名不代表发布者可信。沿用本地构建流程与独立命名空间，更新资产契约见研究。 |

`AppTermination.swift` 和 `UpdatePresentationSource.swift` 是 07-02 计划中新增的边界文件：前者移动现有退出委托并保留行为，后者在视觉验收前只提供展示数据和空操作。验收后从两处接入真实更新，窗口布局和资源无需随之修改。
