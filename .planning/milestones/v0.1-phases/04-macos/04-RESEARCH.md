# Phase 04 · macOS 界面与双语设置研究

**日期** 2026-11-13
**领域** SwiftUI、AppKit、macOS 启动和 Flutter 环境检测
**置信度** 高。快捷键和 CLI 在当前宿主实测，候选应用的原生界面与登录行为由本阶段验收。

## User Constraints

## 实施决定

### 启动偏好

- **D-01：** 登录时启动默认关闭，启动后显示主窗口默认开启，记住最近打开的项目默认开启。通用页提供对应的可用设置，保留用户已保存的偏好。
- **D-02：** 即使关闭「启动后显示主窗口」，启动检测到待恢复记录时也自动打开主窗口，显示对应项目和处理入口。项目是否自动打开仍按 Phase 02 D-08 处理。恢复须由用户触发。

### 调试快捷操作

- **D-03：** v0.1 通过现有按钮手动打开当前会话的 DevTools，通用页省略自动打开开关。此决定明确了技术契约 §7 中的可选项，以本轮确认和 UI 规格 §3 为准。
- **D-04：** 应用内快捷键为 F5 运行、Shift+F5 停止、Option+F5（Alt+F5）热重载、Shift+Command+F5 热重启。沿用按钮对应的共享会话操作及可用条件，保留原生 Tab 和 Shift-Tab 导航。

### 主窗口与菜单栏

- **D-05：** 主窗口和菜单栏均显示恢复失败原因及操作。菜单栏提供「重试恢复」，与主窗口共用恢复状态、操作和启用条件。主窗口的恢复提示与操作位于日志外。涉及待恢复项目的选择与打开，沿用 Phase 02 D-08。
- **D-06：** 主窗口与菜单栏的长项目名、配置名和设备名单行尾部省略，保留悬停提示。沿用 G0 的独立全名入口，支持点击及键盘操作。配置或设备选择锁定时，全名入口仍可使用。

### 关于窗口链接

- **D-07：** 项目主页采用 [GitHub 仓库](https://github.com/atypiape/flutter-runlet)，使用文档采用 [README](https://github.com/atypiape/flutter-runlet/blob/main/README.md)，项目许可证采用 [LICENSE](https://github.com/atypiape/flutter-runlet/blob/main/LICENSE)。这三个地址已确认，替代原有待配置占位。讨论时匿名访问均返回 404，公开可访问性留待发布验收复验。

## 后续阶段

Phase 05 继续处理异常恢复、压力、真实项目复验和发布准备，并复验关于窗口三个 GitHub 链接的公开可访问性。

## Project Constraints (from CLAUDE.md)

`CLAUDE.md` 指向 `AGENTS.md`。本阶段使用简体中文规划、复用原生布局和现有会话，按产品和技术契约实施，保留用户已有改动。Flutter 项目文件只读，原生设计差异保留验收记录。自动化证据完整覆盖的预期无需重复人工确认。[VERIFIED: CLAUDE.md:1-5；AGENTS.md]

## Summary

macOS 26.7.1 的前台 AppKit 探针确认 Command+F5 由系统接收。按用户随后确认的 D-04，热重载使用 Option+F5，前台探针已验证。应用层用共享语言偏好和可观察的展示状态，覆盖主窗、菜单栏、设置、关于及自有 AppKit 文案。首个切片验证已有共享会话在语言切换下的状态和动作，再扩展启动偏好、诊断与品牌资源。[VERIFIED: 下文 AppKit 探针；FlutterRunlet/FlutterRunletApp.swift:11-28；04-CONTEXT.md]

## Architectural Responsibility Map

| 能力 | 责任与接入点 |
| --- | --- |
| 状态和动作 | `SessionController` 保持状态和启用条件的唯一来源，主窗、菜单栏及键盘入口复用。 |
| 界面本地化 | 应用层共享可观察语言偏好，SwiftUI 和自有 AppKit 文案从同一套翻译资源解析。 |
| 启动 | 应用场景结合启动偏好与会话已读取的恢复记录决定是否打开主窗，登录项读取系统实际状态。 |
| 环境检测 | `FlutterToolchain` 负责已验证 SDK 的执行和诊断数据，Flutter 设置展示摘要、详细输出与重试。 |
| 关于、图标 | 关于窗口消费实际构建元数据和固定链接，应用 target 编译 Dock 图标并打包原菜单栏 template。 |

[VERIFIED: FlutterRunlet/FlutterRunletApp.swift:20-84；FlutterRunlet/FlutterToolchain.swift:73-136；FlutterRunlet/AuxiliaryWindows.swift:136-165；FlutterRunlet.xcodeproj/project.pbxproj:292-300]

## Standard Stack

| 现有技术 | 选用依据 |
| --- | --- |
| Swift 6、SwiftUI、AppKit、Foundation | 复用原生工程、控件和资源，macOS 部署目标为 `15.0`。 |
| ServiceManagement | `SMAppService.mainApp` 自 macOS 13 起支持将主应用注册为登录项。 |
| Flutter CLI | 本机 Flutter 3.47.4、Dart 3.13.3。运行以用户实际选择并验证的 SDK 为准。 |
| Xcode 测试与构建 | 本机 Xcode 27.1，复用 `FlutterRunlet` scheme 和 `FlutterRunletTests`。 |

[VERIFIED: FlutterRunlet.xcodeproj/project.pbxproj:372-374,452-454；xcodebuild -version、-list；本机 doctor 探针] [CITED: developer.apple.com/documentation/servicemanagement/smappservice/mainapp]

### Package Legitimacy Audit

沿用系统框架与已选 Flutter SDK，本阶段无需新增依赖包。

## Architecture Patterns

### 应用级语言选择

- SwiftUI 静态标题可用 String Catalog 与 locale 注入。应用动态状态、错误、反馈及 AppKit 自有提示到展示时才解析。保留语义键和结构化插值，用显式 locale 的 `LocalizedStringResource` 或选中的资源 bundle 生成 AppKit 字符串。当前 `SessionFeedback` 保存 `let title: String`、`let detail: String?`，会话持有 `status = "无调试会话"`。仅翻译视图会遗漏已出现的动态提示。[VERIFIED: FlutterRunlet/SessionController.swift:7-10,62-105] [CITED: developer.apple.com/documentation/swiftui/text-input-and-output；developer.apple.com/documentation/foundation/localizedstringresource/locale]
- 已打开的主窗、菜单栏面板、设置和关于分别验证可见字符串，包括场景标题、应用菜单与可访问名称。保留窗口、当前选项及会话身份。应用自定义 AppKit 文件面板标题、说明和按钮随应用语言，系统提供的文案按 macOS 原生偏差记录。跟随系统时从系统偏好选受支持的中英文，明确回退。插值中的路径、名称、版本和 CLI 原文保留，沿用 G2 日志遮罩。[VERIFIED: FlutterRunlet/FlutterRunletApp.swift:30-88,210-252；FlutterRunlet/MainWindowView.swift:148-167；FlutterRunlet/AuxiliaryWindows.swift:121-132；docs/02-TECHNICAL.md §4、§7]

### 启动和登录项

- 初始化先按最近项目偏好尝试加载，再调用 `discoverRecovery()`。主窗启动判定使用其已加载恢复信息，测试有无记录和最近项目偏好组合，保留原恢复任务的主动触发规则。[VERIFIED: FlutterRunlet/SessionController.swift:187-194,322-359；04-CONTEXT.md D-01、D-02]
- `defaultLaunchBehavior` 和 `restorationBehavior` 在本机 SDK 均声明 macOS 15 可用。区分默认启动和系统场景恢复，验证存在上次保存窗口时关闭主窗启动偏好仍有效，以及正常重开、菜单栏调出只打开一个主窗。[VERIFIED: macOS SDK SwiftUI.swiftinterface:277-279,11536-11546] [CITED: developer.apple.com/documentation/swiftui/scene/defaultlaunchbehavior(_:)]
- 用 `SMAppService.mainApp.status` 反映可用、未注册、待系统批准和不可用。注册、取消和应用重新激活后同步实际状态。默认关闭意味着新安装未发起注册，已有状态以系统为准。注入窄接口覆盖失败和权限分支，原生验收用可回退的隔离构建核对登录项。[CITED: developer.apple.com/documentation/servicemanagement/smappservice；developer.apple.com/documentation/servicemanagement/smappservice/status-swift.property]

### 快捷键实测

宿主 macOS 26.7.1（25G241）。经 Launch Services 启动临时 AppKit 前台窗口，由另一个有事件投递权限的临时 Swift 进程向 HID 事件 tap 投递按键。用 AppKit `sendEvent`、local monitor 和 `NSWorkspace.isVoiceOverEnabled` 观察应用与系统。首轮验证 F5 对照及 VoiceOver 反应，第二轮加入独立修饰键按下和释放，第三轮以 F5 为对照复验用户选定的 Option+F5。测试前后 VoiceOver 关闭，系统快捷键设置保持原值。[VERIFIED: 本机 AppKit/CGEvent 运行探针；sw_vers]

| 按键 | 前台 AppKit 观察 | 系统观察 |
| --- | --- | --- |
| F5 | 收到 keyDown，键码 96、修饰位 0 | VoiceOver 保持关闭 |
| Shift+F5 | 收到 keyDown，键码 96、修饰位 131072 | VoiceOver 保持关闭 |
| Shift+Command+F5 | 收到 keyDown，键码 96、修饰位 1179648 | VoiceOver 保持关闭 |
| Command+F5 | 只收到 Command 修饰键变化，无 F5 keyDown | VoiceOver 由关闭变为开启 |
| Option+F5 | 收到 keyDown，键码 96、修饰位 524288 | VoiceOver 保持关闭 |

用户确认热重载用 `Option+F5`（Alt+F5），前台探针复验通过。正式应用仍验证前台主窗、菜单栏面板和日志焦点、后台无动作、两窗同次按键最多一次，以及按钮与键盘共用启用条件和原生 Tab／Shift-Tab。Apple 记录 Command+F5 用于 VoiceOver，Option+Command+F5 用于系统辅助功能面板。[CITED: support.apple.com/guide/voiceover/turn-voiceover-on-or-off-vo2682/mac；support.apple.com/guide/mac-help/mchlp2975/mac] [VERIFIED: FlutterRunlet/MainWindowView.swift:410-441；04-CONTEXT.md D-04]

### SDK 和环境检测

- 诊断用绝对路径的已解析 `FlutterSDK.executable`。沿用 `probeEnvironment` 安全 PATH 和独立于工作区的诊断目录，避免项目任务或 `osx.env` 覆盖。保留 `canEditFlutterSDK` 启用条件。绑定 SDK／项目及请求身份，过时诊断结果不得覆盖当前设置。[VERIFIED: FlutterRunlet/FlutterToolchain.swift:11-16,167-200,257-288,324-370；FlutterRunlet/SessionController.swift:46-54,473-523]
- 本机 SDK 在临时空目录运行 `flutter --no-version-check doctor -v`，Flutter 工具计时约 7.8 秒，stdout 98,799 字节、stderr 0、exit 0。Flutter 和 Xcode 为 `[✓]`，Android Toolchain 为 `[!]`，Chrome 为 `[✗]`。日志可见 `[  +21 ms] [✓] Flutter …` 形态的计时前缀。逐项状态来自诊断标题，exit 0 仍可有问题。缺失或不识别的标题显示未知，保留完整文本。非零、启动异常、取消、超时和超限应报告相应检测异常并保留已捕获的内容。[VERIFIED: 本机 Flutter 3.47.4 运行探针；SDK commit 9584c6713b324636289d067944a46fd6b49df14b] [CITED: github.com/flutter/flutter/blob/stable/packages/flutter_tools/lib/src/commands/doctor.dart；docs.flutter.dev/resources/bug-reports]
- 现有探测使用非阻塞 stdout、`standardError = FileHandle.nullDevice`、25 秒和 1 MiB 限制。doctor 及时消费 stdout 和 stderr，限制时间与总输出，截断需告知，失败时回收进程。复用底层实现时保留已有 JSON 探测语义。原文留在当前设置，沿用会话日志隔离。[VERIFIED: FlutterRunlet/FlutterToolchain.swift:324-370；docs/02-TECHNICAL.md §4、§7]

### 关于与图标

- AboutView 现有 `CFBundleShortVersionString`、`CFBundleVersion` 和 `BrandGlyph`。三条 HTTPS 链接走系统默认浏览器，呈现真实上游归属和版权。G1 审计记录 `Copyright (c) 2026 huseyiniriss`、MIT 及实际导入情况。链接点击委派在 P4 验证，公开匿名访问在 P5 复验。[VERIFIED: FlutterRunlet/AuxiliaryWindows.swift:136-165；01-UPSTREAM-AUDIT.md:25-29；04-CONTEXT.md D-07]
- 沿用已验收的 16／32／64／128／256／512／1024 px PNG 建立 macOS `AppIcon.appiconset`，对应 16、32、128、256、512 pt 的 1x／2x 槽。应用 target 的 Debug、Release 指定 `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`。检查实际 bundle 图标声明和资产。工程已有 `flutterrunlet-menubar-template@1x.png` 和 `flutterrunlet-menubar-template@2x.png`，沿用原模板，两种外观分别观察。[VERIFIED: FlutterRunlet.xcodeproj/project.pbxproj:292-300；docs/design/assets；docs/design/DESIGN-SYSTEM.md §6] [CITED: developer.apple.com/documentation/xcode/configuring-your-app-icon]

## Common Pitfalls

- 主窗恢复按钮在日志外，按 `recoveryProjectIsOpen` 判断「重试恢复」和「打开待恢复项目」。菜单栏目前只显示原因。复用同一恢复动作和条件。名称全名入口独立于锁定选择控件，避免父级禁用同时禁用全名操作。[VERIFIED: FlutterRunlet/MainWindowView.swift:182-203,391-405；FlutterRunlet/MenuBarPanelView.swift:26-47]
- 已格式化的文案会在运行中改语言时保留旧文本。测试活动会话和已经显示的错误。诊断可能带本机路径和设备名，验收记录采用隔离样例及可复验命令。

## Environment Availability

| 项目 | 观察 |
| --- | --- |
| macOS / Xcode | 26.7.1（25G241）／27.1（27A9275），项目 scheme 已确认 |
| 前台 AppKit 分发 | 有交互桌面，命令宿主已有事件投递权限，探针完成 |
| Flutter / Dart | 3.47.4／3.13.3，本机绝对 SDK 完成 doctor 探针 |
| macOS 15 与实际登录 | 本次核对 SDK API 可用性，实际登录和目标系统复验由适用验收环境完成 |

## Validation Architecture

### 测试入口

复用共享 scheme 与现有测试 target。任务级定向验证按涉及测试类传入 `-only-testing:FlutterRunletTests/类名`；波次和阶段门槛跑完整 Debug 测试与 Release 构建。DerivedData 使用本阶段独立临时目录。

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-04" -parallel-testing-enabled NO test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Release -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-04" build
```

| 需求 | 自动覆盖与失败信号 | 原生实测补充 |
| --- | --- | --- |
| UI-01 / A03、A05、A21 | 复用 `FlutterDebugSessionTests`、`ProjectRecoveryTests`。可用性差异、重复动作、误恢复项目或自动重试即失败。 | 前台按键、锁定字段点击和 Tab、菜单栏原因和重试、主窗关闭后会话联动。 |
| UI-02 / A05、A23 | 测试语言选择、回退、偏好持久化及含原始值的文案。缺键、旧语言残留、名称或 CLI 原文改变即失败。 | 已打开界面、自有菜单与 AppKit 提示即时更新，英文四按钮同排，两种外观。 |
| UI-03 / A04、A24 | 复用 `FlutterToolchainTests`、`ProjectSelectionTests`、`ProjectRecoveryTests`。覆盖启动组合、恢复优先、注册错误、授权及 SDK 锁定。 | 登录项实际状态，两类设置，启动仅菜单栏及恢复打开主窗。 |
| UI-04 / A25 | 固定实录与可控进程，覆盖选中 SDK、警告但 exit 0、计时前缀、未知标题、stderr、非零、超时及过时请求。 | 真实 SDK 检测，摘要和原始输出，用户可见异常和重试。 |
| UI-05 / A04、A26 | 三个固定 URL 的打开委派与 bundle 版本及构建号一致。 | 独立关于窗口、归属、版权与默认浏览器。 |
| UI-06 / A06 | Debug、Release 包检查实际图标声明和模板资产。 | Dock 与菜单栏深浅外观及必要原生偏差。 |

### Wave 0 Gaps

测试 target 与 G1/G2 实测路径已存在。各任务同期补缺失的关键断言，重点为启动和恢复优先级、登录项授权、动态文案与 doctor 失败。自动覆盖完整预期时直接记录通过；实测只补剩余部分。按 A03–A06、A21、A23–A26 关联候选构建和证据。

## Security Domain

| 边界 | 控制 |
| --- | --- |
| 诊断启动 | 绝对 SDK、固定参数、受控 PATH 与工作目录，用户主动触发。 |
| 诊断输出 | 两路输出及时消费，取消、期限、容量及过时结果受控，详细输出保留在当前界面。 |
| 登录项 | 用户主动切换，遵循系统授权，以实际注册状态显示。 |
| 恢复和键盘 | 复用 `SessionController` 状态与动作，维持项目锁、退出确认和原任务边界。 |
| 关于链接 | 系统打开固定 HTTPS 目标，版本和归属来自实际构建和审计记录。 |

## Sources

- Context7 `/websites/developer_apple_swiftui`、`/websites/developer_apple_servicemanagement`、`/websites/flutter_dev`。核对视图 locale、登录项及 doctor 输出。
- [Apple VoiceOver 指南](https://support.apple.com/guide/voiceover/turn-voiceover-on-or-off-vo2682/mac) · [Apple String Catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog) · [Apple SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice) · [Apple App Icon](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)。
- [Flutter macOS 设置](https://docs.flutter.dev/platform-integration/macos/setup) · [Flutter doctor 上游实现](https://github.com/flutter/flutter/blob/stable/packages/flutter_tools/lib/src/commands/doctor.dart)。
- [阶段上下文](04-CONTEXT.md) · [Phase 03 G2 验收](../03-flutter/03-G2-ACCEPTANCE.md) · [验收矩阵](../../../../docs/04-ACCEPTANCE.md)。

## Metadata

快捷键和 Flutter CLI 结果对应本次宿主及工具版本。正式应用的快捷键路由、包资源和系统登录仍须按计划验收。
