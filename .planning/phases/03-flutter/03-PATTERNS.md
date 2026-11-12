# Phase 03 · 代码复用图

**日期** 2026-11-12

**范围** 已跟踪的 App、worker、Xcode 工程和现有 XCTest。文件路径均相对于仓库根目录。

## 文件分类

| 改动位置 | 角色与数据流 | 现有接入点 |
| --- | --- | --- |
| `FlutterRunlet/SessionController.swift` | 状态控制器，项目与进程事件 | `loadProject`、`run`、`stop`、`execute`、`restore` |
| `FlutterRunlet/SessionProcess.swift` | 父进程适配，命令、输出流与退出报告 | `SessionProcessRunner.start`、`SessionProcess.wait` |
| `FlutterRunletSessionWorker/main.swift` | 子进程监督，文件描述符及进程组 | `run(_:lease:directory:)`、`main()` |
| SDK 与设备解析（拟增） | 只读配置、子进程请求及结果解析 | `ProjectConfiguration.prepare`、`executablePath`、`SessionController.loadProject` |
| `FlutterRunlet/FlutterRunletApp.swift`、`MainWindowView.swift`、`MenuBarPanelView.swift`、`AuxiliaryWindows.swift`（均在 `FlutterRunlet/`） | 原生界面，观察共享状态与发出操作 | `liveSession`、`SettingsView`、`DebugControls`、`BrowserControls`、`logs` |
| `FlutterRunlet.xcodeproj/project.pbxproj` | 工程配置，文件归属与打包 | 三个 `PBXSourcesBuildPhase`，以及 App 对 worker 的依赖和复制阶段 |
| `FlutterRunletTests/` | XCTest，命令、任务顺序及持久副作用 | `SessionFixture`、生命周期、项目选择、并发与恢复测试 |

## 接入依据

- **启动与恢复**：`SessionController.swift:303` 的 `run` 先验证项目、获取租约、查询待恢复记录，再加载配置，使用 `executionMatches` 比对已选配置。真实 SDK 与设备预检在前置任务启动前完成。保留 `execute`（361 行）的恢复记录、前置成功后才调试、确认退出后才 `restore`（423 行）的顺序。`finishForTermination`（355 行）已经沿用 `stop` 和 `waitUntilIdle`。
- **管道与退出**：`SessionProcess.swift:157` 启动 worker 时分别建立 `control`、`input`、`output`、`errors`、`report`。现有控制片段是 `func stop() { try? control.close() }`（237 行）。`main.swift:4` 检查控制 stdin、给子进程绑定 `/dev/null`、等待主进程和进程组，最后通过报告管道传递 `SessionExit`。增设仅 Debug 使用的输入通道，沿用现有 EOF、租约和退出报告。配置读取、停止和热操作命令的管道各有明确归属。
- **输出与日志**：`SessionProcess.swift:215` 分流读取 stdout 和 stderr，`drain`（245 行）保留有界尾部。当前 `SessionController.swift:458` 等待进程结束才汇入文本。流式适配器复用分流读取，在内存区分机器帧和可见日志，避免退出后重复追加。主窗 `MainWindowView.swift:150` 将折叠状态与 `session.logs` 分开，并通过 `textSelection(.enabled)` 支持选取。
- **SDK 与设备**：`ProjectConfiguration.swift:103` 的 `PreparedLaunch` 持有已解析配置，`prepare`（172 行）读取 `deviceId`、目录、参数和环境。现有 `executablePath`（362 行）提供可执行性检查和从环境 PATH 查找的参照。用单个已验证 SDK 决定发现和执行，项目切换复用 `SessionController.loadProject`（158 行）的成功提交点。SDK 偏好可参照同文件 `rememberRecentProject` 的偏好访问方式，设备选择按项目在 App 内存中记住。
- **共享界面**：`FlutterRunletApp.swift:17` 创建 App 级 `@State` 控制器，`liveSession`（27 行）传给窗口、菜单栏和设置。主窗 `DebugControls`（205 行）与 `BrowserControls`（229 行）也是菜单栏所用组件。沿用共享操作和原生布局，Flutter 设置接入 `AuxiliaryWindows.swift:4` 的 `SettingsView`。App 激活重检 SDK 接入 App 层，窗口关闭仍沿用共享控制器。
- **工程成员**：`project.pbxproj:289` 起显式列出 App、测试、worker 的 Sources。当前 `SessionProcess.swift` 同时登记在 App（298 行）和 worker（324 行）。新增 Swift 文件按各自使用者登记引用和 Sources，App 专用的设备、浏览器或界面依赖留在 App 目标。

## 测试复用

| 现有测试 | 本阶段优先沿用的验证 |
| --- | --- |
| `SessionLifecycleTests.swift:7`、`:185` | `SessionFixture` 的独立临时项目、可注入调试脚本、真实 worker、任务顺序和源配置字节不变 |
| `ProjectConcurrencyTests.swift:8`、`:52`、`:102` | 后代进程仍在时保留租约，父控制管道关闭，停止早于派发 |
| `ProjectRecoveryTests.swift:7`、`:76` | 自动后置使用快照，恢复失败后按原任务显式重试 |
| `ProjectSelectionTests.swift:54`、`ProjectConfigurationTests.swift:7` | 配置变化要求二次运行确认，公开样例的参数与环境传递 |

## 缺少直接先例

- Flutter 机器协议、VM Service 重连、DevTools 地址和令牌遮罩由 `03-RESEARCH.md` 指定验证边界。现有进程监督可作为传输和退出先例，协议处理需要对应的隔离测试。
- SDK 实际版本探测、设备发现与启动当前没有实现。现有配置解析、设置外壳和临时进程夹具可复用，真实 iOS Simulator 与 Inspector 由 G2 证明。
