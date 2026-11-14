# Phase 1 · 上游审计与原生 UI 骨架研究

**研究日期** 2026-11-12  
**置信度** 高。核查了固定上游提交、Apple API 文档和本机 SDK。窗口行为由 G1 实测确认。

<user_constraints>
## User Constraints

### Ready 演示入口

- **D-01** 普通启动显示 Empty。专用启动参数仅在 Debug 构建可用，用于打开实际 App 的 Ready 演示。G1 验收记录包含可复验的启动命令。Release 正常启动显示 Empty。
- **D-02** Ready 固定展示脱敏项目 `sample-flutter-app`、启动配置 `sample-flutter-app(dev)` 和一个 iOS 模拟器示例。主窗口和菜单栏共享同一组状态与数据。演示数据固定在 App 内，不依赖读取项目文件或扫描设备。
- **D-03** Ready 的 Run 按 G0 规格显示可用，点击时弹出原生提示，说明当前为演示。Stop、Hot Reload、Hot Restart、DevTools 和 Inspector 按 Ready 规格禁用。点击演示 Run 不触发 Flutter 或任务执行。

### 窗口交互与截图

- **D-04** G1 在 Debug Ready 下关闭主窗口，确认 App 仍运行且菜单栏面板可打开。从面板重新打开主窗口，确认仅有一个主窗且 Ready 示例仍在。Phase 3 使用真实会话验收 A21。
- **D-05** G1 共留六张结构截图。Ready 主窗与菜单栏面板各留浅色、深色两张，设置和关于各留一张。记录主窗口外框 640 × 580 pt、菜单栏面板宽 404 pt 的核对结果及必要的原生差异。

### 设置与关于

- **D-06** 设置首次打开「通用」，G1 截图保留这一页。人工验收切到「Flutter」再返回，核对两项导航。表单控件随对应功能实现后显示。
- **D-07** G1 的独立关于窗口展示现有品牌标志、应用名和来自实际构建的版本及构建号。项目链接按 Phase 4 的 A26 验收。上游许可和版权按 Phase 1 审计与导入要求保留。

### macOS 兼容性证据

- **D-08** G1 验证 macOS 15 部署目标，记录所用 API 的可用性和必要替代路径。在当前 macOS 26.7.1 上实测四个原生界面，记录测试系统版本。
- **D-09** 用户确认没有可用的 macOS 15 环境，省略 Phase 5 的 macOS 15 实机复验。这是对 A31、REL-03 和 Phase 5 路线中实机部分的例外。后续验收记录将该部分标为未执行并注明原因。Phase 1 的构建与 API 核查以及 Phase 5 的其他验证仍按既定要求执行。

### 延后事项

完整设置功能、项目链接、双语及外观验收按 Phase 4 推进。真实调试与菜单栏的会话联动按 Phase 3 验收。

</user_constraints>

## Project Constraints (from AGENTS.md)

- 使用精炼简体中文。按用户指令、产品需求、技术契约、UI 规格与设计系统、最终 Figma 的顺序处理冲突，并记录差异。
- 优先复用现有实现，避免无关重构和过度设计。保持用户 Flutter 项目文件原样。已验收布局、视觉或交互的调整由用户确认。
- 保留工作区已有改动。Conventional Commits 用简体中文，推送与合并需授权。通过本机 GSD 更新运行态文件。
- 关键行为优先验证。保留相关自动验证、必要构建、人工验收与截图，真实记录失败及未验证事项。开发技术文档先查 Context7 CLI。 [协作约束](../../../../AGENTS.md)

<phase_requirements>
## Phase Requirements

| ID | 要求 | 研究支持 |
| --- | --- | --- |
| BASE-01 | 审查 Flutter GUI Runner 的源码、依赖与许可证，记录复用边界，导入的代码保留必要许可及版权 | 固定提交、依赖来源、模块审计与归属处理 |
| BASE-02 | 原生 App 可启动并打开主窗口、菜单栏面板、设置及独立关于窗口。主窗默认 640 × 580 pt，菜单栏面板宽 404 pt，记录原生控件差异。（A01、A02） | 原生场景、单主窗路由、共享演示状态、G1 手工验收 |
| BASE-03 | 审查所用原生 API 在暂定最低目标 macOS 15 的可用性和替代路径，验证目标构建。（A31） | SDK 类型检查、构建设置、产物最低系统版本、当前系统实测 |

</phase_requirements>

## Summary

用原生 Xcode macOS App target、共享 scheme 和 Swift 6 建立可启动的 `.app`。先验证主窗与菜单栏消费同一份演示状态及唯一主窗的关闭重开路径，再补齐设置、关于和验收证据。建议 G1 沿用上游的双场景共享状态结构，原生界面按已批准的阶段 UI 契约实现。阶段实施仍须交付独立审计记录，写明导入清单及取舍。 [技术契约](../../../../docs/02-TECHNICAL.md) · [Phase 1 UI 契约](01-UI-SPEC.md)

## 上游源码、依赖与许可证

`git ls-remote`、临时 Git 对象与归档均指向 `1c8468f54f1c7785aca31cfea0a5207feca30c06`。核对了固定提交的 Swift 源码、`Package.swift`、`LICENSE`、打包脚本和发布工作流。上游清单使用 `// swift-tools-version:6.0`、`platforms: [.macOS(.v14)]` 和单个 `.executableTarget`，未声明第三方 SwiftPM 包。源码导入系统框架 Foundation、SwiftUI 和 AppKit。构建脚本由 SwiftPM 生成可执行文件后手工组装应用包并尝试 ad-hoc 签名。发布工作流的 GitHub Actions 和外部 Flutter CLI 属于各自的运行边界，不应列为 G1 App 的 SwiftPM 依赖。 [VERIFIED: 固定提交 Git 对象及归档] [清单](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Package.swift#L1-L13) · [打包](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/build-app.sh#L1-L37) · [发布工作流](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/.github/workflows/release.yml#L14-L38)

| 上游区域 | 源码观察及建议 |
| --- | --- |
| 场景入口与菜单栏 | `WindowGroup(id: "main")` 和 `MenuBarExtra` 使用同一模型。主窗启动执行 `model.bootstrap()`，后者发现项目、SDK 并查询 Flutter。菜单栏的重开逻辑挑选第一个可成为主窗的窗口，多种窗口存在时无法通过该条件确认窗口身份。保留共享结构，按 G1 使用固定路由和无扫描的演示状态。 [VERIFIED: FlutterRunnerApp.swift:11-36、AppModel.swift:146-167、ContentView.swift:334-341] [场景](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/FlutterRunnerApp.swift#L11-L36) · [路由](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/ContentView.swift#L334-L341) |
| 上游控件和超范围入口 | 主窗使用 `NavigationSplitView`，导航含 Run、Emulators、Build、Packages、Commands、Git、SDK、Doctor、Settings。菜单栏带构建、工具、Git 和自定义参数入口。G1 按已批准的无侧栏主窗与独立设置布局交付，审计记录列出省略的入口。 [VERIFIED: MainWindow.swift:5-49、ContentView.swift:285-330] [主窗](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/MainWindow.swift#L5-L49) · [菜单栏](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/ContentView.swift#L285-L330) |
| 设备与运行 | `refreshDevices` 以 `devices --machine` 解码设备，`run()` 拼装运行参数及 `--pid-file`，热操作发送 `SIGUSR1`、`SIGUSR2`。可在后续阶段提取设备解码与进程控制候选。上游还允许 Profile、Release 和独立保存的参数，不能直接承接本仓库的 Debug、任务、恢复和配置权威契约。 [VERIFIED: AppModel.swift:505-522、661-716、Device.swift:30-42] [设备](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/AppModel.swift#L505-L522) · [运行](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/AppModel.swift#L661-L716) |
| 日志及浏览器 | 上游有批次刷新、截流、只读 AppKit 日志视图，以及从日志片段提取 DevTools URL 后调用 `NSWorkspace.shared.open(url)` 的路径。可保留为 Phase 3 候选。进入真实会话时需按技术契约处理 VM Service 作用域、日志清空和敏感 URL。 [VERIFIED: AppModel.swift:1054-1089、1134-1143、LogTextView.swift:7-38] [日志与提取](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/AppModel.swift#L1054-L1089) · [日志控件](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/LogTextView.swift#L7-L38) |

**许可处理建议** 上游根许可为 MIT，版权为 `Copyright (c) 2026 huseyiniriss`。建议 G1 自建骨架并沿用上游架构思路，代码与资源导入清单可为空。实施时如确有适配代码导入，先记录提交和源路径，再随纳入的代码保留上游版权及完整许可文本，并核查分发包保留该文本。保留正式审计产物，记录实际导入结论及隐藏的入口。上游打包脚本复制图标和可执行文件且生成 plist，验收不能由该脚本推断许可已经入包。 [VERIFIED: LICENSE:1-13、build-app.sh:9-37] [上游许可](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/LICENSE) · [技术契约](../../../../docs/02-TECHNICAL.md#1-架构原则)

## Standard Stack

| 层 | 建议 | 依据 |
| --- | --- | --- |
| 构建 | 用原生 `.xcodeproj` 与共享 scheme，Debug 和 Release 的 App target 部署目标均为 `15.0`。提交共享工程配置，派生数据留在构建目录 | 本机 `xcodebuild` 可用，仓库当前未跟踪 App 工程或自动测试。 [VERIFIED: xcodebuild -version、git ls-files] |
| 界面 | SwiftUI 场景、系统按钮与语义色。需要窗口外框度量时使用 AppKit 的公开接口 | 已批准契约明确该结构。 [Phase 1 UI 契约](01-UI-SPEC.md) |
| 品牌与元数据 | 使用仓库现有单色 1x/2x 模板和矢量主标志。关于读取 bundle 的 `CFBundleShortVersionString` 和 `CFBundleVersion`，不用 Flutter 示例项目的版本 | 菜单栏模板为 18 × 18 与 36 × 36 PNG。 [VERIFIED: file、品牌资产] [版本键](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleshortversionstring) · [构建号键](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleversion) |
| 验证 | Xcode 内建测试、Debug/Release 构建与人工原生窗口验收 | 只对启动策略等关键逻辑加小范围回归测试。 [协作约束](../../../../AGENTS.md) |

G1 无需新增包、第三方脚手架或外部服务。Context7 的 `SwiftUI` 索引查询异常。改用 Apple Developer Documentation 成功解析 `/websites/developer_apple_de`，文档调用返回 `fetch failed`，所以可用性结论以 Apple 一手资料和本机 SDK 类型检查为依据。 [VERIFIED: Context7 CLI 调用结果]

## Architecture Patterns

- **主窗口** 用首个 data-driven `WindowGroup` 作为主场景，初始绑定值固定。菜单栏的主窗入口用相同 scene ID 和同一值调用 `openWindow(id:value:)`，以相同值聚焦已开窗口。通过 `CommandGroup(replacing: .newItem)` 去掉创建额外主窗的命令。Apple 记录了单 `Window` 作为主场景时关闭会退出 App 的行为。首启、关闭重开、连续点击重开和前台聚焦均在当前系统实测。 [CITED: developer.apple.com] [WindowGroup](https://developer.apple.com/documentation/swiftui/windowgroup) · [Window](https://developer.apple.com/documentation/swiftui/window)
- **共享状态和演示入口** App 层从本进程参数求出一个不可变的初始演示状态，传给主窗口和菜单栏。建议用精确参数匹配与 `#if DEBUG`，在 Release 不启用演示路径。原生提示在触发按钮所属界面呈现，关闭后共享状态仍是 Ready。启动、演示按钮和窗口重开均避免调用上游扫描、Shell 或 Flutter。 [已锁定 D-01 至 D-04](01-CONTEXT.md) · [Apple Swift Active Compilation Conditions](https://developer.apple.com/documentation/xcode/build-settings-reference#Active-Compilation-Conditions)
- **菜单栏、设置和关于** 用 `MenuBarExtra` 的 `.window` 样式承载 404 pt 面板，用 `Settings` 搭配原生侧栏并通过 `openSettings` 打开。关于为独立 `Window`，用专属 ID 打开。验证从主窗和菜单栏进入设置及在后台拉起窗口，发现原生前台激活问题时再使用 AppKit 的公开激活或窗口接口。 [CITED: developer.apple.com] [菜单栏样式](https://developer.apple.com/documentation/swiftui/menubarextrastyle/window) · [Settings](https://developer.apple.com/documentation/swiftui/settings) · [OpenSettingsAction](https://developer.apple.com/documentation/swiftui/opensettingsaction)
- **尺寸与恢复** `defaultSize(width:height:)` 提供首次打开的尺寸，SwiftUI 可能恢复上次大小。验收用首次打开状态测量 `NSWindow.frame`，并将尺寸与内容视图大小分开记录。标题栏高度由系统决定。若 SwiftUI 默认值不符合外框契约，可对明确识别的目标窗口用 `contentRect(forFrameRect:)` 或 `setFrame(_:display:)` 校准首次尺寸，避免每次渲染时强制恢复。菜单栏记录 404 pt 内容宽度和系统边缘材质产生的差异。 [CITED: developer.apple.com] [默认尺寸](https://developer.apple.com/documentation/swiftui/scene/defaultsize(width:height:)) · [窗口换算](https://developer.apple.com/documentation/appkit/nswindow/contentrect(forframerect:)) · [设计交接](../../../../docs/design/FIGMA-HANDOFF.md)

### macOS 15 API 可用性与替代路径

| 所用路径 | 核查结果 | 适用替代 |
| --- | --- | --- |
| 数据型 `WindowGroup`、`openWindow(id:value:)`、`Window` | 所列签名以 macOS 15.0 目标通过独立类型检查。Apple 标记 `Window` 自 macOS 13 可用 | 若平台交互实测发现主窗无法保持唯一，由显式标识的 AppKit `NSWindowController` 管理该窗 |
| `MenuBarExtra`、`.menuBarExtraStyle(.window)` | Apple 标记 macOS 13 起可用，macOS 15.0 目标类型检查通过 | 保留系统面板和素材。若实测遇到系统布局限制，先记录差异并核对窗口行为 |
| `Settings`、`openSettings`、`NavigationSplitView` | `Settings` 自 macOS 11，`openSettings` 动作自 macOS 14，组合通过 macOS 15.0 目标类型检查 | 保留系统设置菜单，若侧栏度量确有冲突，用原生列表与详情区保持批准的两项结构 |
| `defaultSize(width:height:)`、`NSWindow.frame` 与内容尺寸换算 | Apple 标记 SwiftUI 尺寸修饰器自 macOS 13 可用，AppKit 调用经 macOS 15.0 目标类型检查 | 仅在默认外框实测不合格时校准首开尺寸 |

独立 SDK 探针使用 `xcrun --sdk macosx swiftc -typecheck -parse-as-library -swift-version 6 -target arm64-apple-macos15.0 -sdk "$(xcrun --sdk macosx --show-sdk-path)"`。以同样参数静态检查了固定提交的全部 Swift 源文件，两次均返回 0。另用临时可执行文件确认 `xcrun vtool -show-build` 可读取 `platform MACOS`、`minos 15.0` 和 `sdk 27.0`。这些证据用于规划。实际 App 构建、原生交互和截图由执行阶段验收。 [VERIFIED: 本机 SDK 与固定提交源码] [Window](https://developer.apple.com/documentation/swiftui/window) · [MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra) · [OpenSettingsAction](https://developer.apple.com/documentation/swiftui/opensettingsaction)

## Common Pitfalls

- 把模板设为自定义渲染、直接使用上游品牌或重绘原生窗口会偏离契约。对系统控件优先使用系统语义，尺寸与截图证据分别测量。 [设计系统](../../../../docs/design/DESIGN-SYSTEM.md) · [UI 契约](01-UI-SPEC.md)
- 测试时通过 `MACOSX_DEPLOYMENT_TARGET=15.0` 临时覆盖工程可能掩盖工程配置错误。以 `-showBuildSettings` 核对真实配置，再用实际 Debug、Release 产物的 Mach-O `minos` 补证。 [VERIFIED: 本机 xcodebuild 与 vtool 命令]
- `open -n` 启动新 App 进程，连续验证 Debug 与 Release 时先退出上一份实例，确保观察到指定产物。G1 验收记录写入最终采用的 Debug 参数与实际产物位置。 [VERIFIED: 本机 open 用法] [D-01](01-CONTEXT.md)

## Environment Availability

| 工具或环境 | 本次实测 | 用途 |
| --- | --- | --- |
| macOS / Apple Silicon | 26.7.1，25G241，arm64 | G1 当前系统窗口实测 |
| Xcode、macOS SDK、Swift | Xcode 27.1（27A9275）、SDK 27.0、Swift 6.4 | Swift 6 目标构建和测试 |
| `xcodebuild`、`xcrun vtool`、`plutil` | 已定位。命令帮助已核查，临时产物已由 vtool 读出最低系统版本 | 自动构建证据和 bundle 元数据 |
| macOS 15 实机 | 当前环境不可用，D-09 已确认后续例外 | A31 仍保留目标构建和 API 核查 |

[VERIFIED: sw_vers、xcodebuild -version、xcrun --sdk macosx --show-sdk-version、swift --version、xcrun vtool] [D-08、D-09](01-CONTEXT.md)

## Validation Architecture

建议使用 `FlutterRunlet.xcodeproj` 和共享 `FlutterRunlet` scheme 作为统一入口，以下是计划创建工程后运行的命令形态。实际名称由计划同步固定。命令及选项经本机帮助核查。目标 App 尚未创建。

| ID | 可验证行为 | 自动命令与验收 |
| --- | --- | --- |
| BASE-01 | 可复现的上游审计、依赖及许可证归属 | 在临时 Git 对象中 `git cat-file -e '1c8468f54f1c7785aca31cfea0a5207feca30c06^{commit}'`，用 `git show <SHA>:Package.swift` 和 `git show <SHA>:LICENSE` 对照审计记录。人工确认范围和实际导入清单，实际导入时核对随代码及产物保留的许可。 |
| BASE-02 / D-01–D-03 | 无参数进入 Empty、Debug 指定参数进入固定 Ready、无效参数不触发演示 | Xcode 自带 XCTest。工程和测试目标就绪后执行 `xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath .build/phase-01 test`。覆盖最小启动策略，Release 另行手工用同一参数确认仍为 Empty。 |
| BASE-02 / A01、A02、D-04–D-07 | 四个原生界面、唯一主窗重开、两种外观、设置路由和关于信息 | Debug 构建与测试命令提供基础自动证据。当前系统按契约人工测量主窗 640 × 580 pt、菜单栏 404 pt，核对 Ready 按钮与提示、设置两页、关于版本、长字段及六张截图。 |
| BASE-03 / A31、D-08–D-09 | 两种配置的最低部署目标与当前系统实测环境 | 使用 `xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -showBuildSettings` 与对应 Release 调用核对 `MACOSX_DEPLOYMENT_TARGET = 15.0`。Release 使用同一工程和 scheme，`-configuration Release -destination 'platform=macOS' -derivedDataPath .build/phase-01 build`。运行 `xcrun vtool -show-build <App二进制>` 核对每个产物的 `minos 15.0`，用 `plutil -p <App的Info.plist>` 对照关于页。macOS 15 实机记录为未执行并注明原因。 |

### Sampling Rate

- 审计任务先验证固定提交与文档证据。工程具备共享 scheme 后，每个代码任务运行对应 Debug build 或测试，首个可用的主窗至菜单栏切片合并前实测关闭、重开及重复打开。
- 阶段最终运行 Debug 测试和 Release 构建，保留关键命令、退出状态、SDK、目标系统、系统实测版本和六张脱敏截图。编译缓存与机器状态影响用时，执行时记录实际反馈时长。
- 窗口度量、焦点、外观、菜单栏交互以及截图由人工检查。证据分列编译与运行环境。

### Wave 0 Gaps

仓库没有现成 App 工程或测试 target。将共享 scheme、App target 与一个小范围 XCTest target 纳入最早的原生工程任务，在实现启动策略时加入回归测试。工具链已在本机可用，无需单独安装框架或引入自动化 UI 驱动。 [VERIFIED: git ls-files、xcodebuild -version]

## Security Domain

ASVS L1 与 high 阻断门槛按当前 GSD 配置。G1 的风险集中在本地输入边界、误接执行路径、上游来源及分发许可。启动参数仅选择固定演示状态，Release 隔离演示入口，运行按钮限于本地原生提示。App 进入阶段不接认证、网络会话、凭据或持久项目配置。审计证据用固定提交复核，执行时不继承上游自动扫描或 Shell 入口。验收截图使用脱敏固定数据。 [VERIFIED: .planning/config.json、01-CONTEXT.md:18-35] [技术契约](../../../../docs/02-TECHNICAL.md)

## Open Questions

G1 验收中的标题栏及工具栏实际高度、后台弹出面板的前台切换、键盘导航和浅深外观，以当前系统实测和偏差记录收口。规划阶段未运行项目 App，也没有 macOS 15 实机结果。
