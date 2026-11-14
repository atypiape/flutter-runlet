# Phase 02 · 配置和任务执行内核模式映射

**映射日期** 2026-11-12

## File Classification

| 文件或预期职责 | 角色 | 数据流 | 仓库依据 |
|---|---|---|---|
| `FlutterRunlet/FlutterRunletApp.swift` | 场景与状态所有者 | App 启动 → 共享项目与会话 → 原生场景 | 同一 `presentation` 和 Run 动作传入主窗与菜单栏。 [场景入口](../../../../FlutterRunlet/FlutterRunletApp.swift#L15-L57) |
| `FlutterRunlet/MainWindowView.swift` | 主窗组件 | 状态 → 项目、配置、会话与日志；工具栏 → 打开项目 | 项目字段、原工具栏按钮、会话区及日志折叠。 [主窗](../../../../FlutterRunlet/MainWindowView.swift#L12-L106) |
| `FlutterRunlet/MenuBarPanelView.swift` | 菜单栏组件 | 共享状态 → 摘要与会话操作 | 直接复用 `PresentationField`、`DebugControls` 和 `BrowserControls`。 [菜单栏](../../../../FlutterRunlet/MenuBarPanelView.swift#L20-L49) |
| `FlutterRunlet/AuxiliaryWindows.swift` | 设置组件 | 偏好 → 通用页控件与启动恢复 | `SettingsView.Page.general` 和既有 `NavigationSplitView` detail。 [设置](../../../../FlutterRunlet/AuxiliaryWindows.swift#L4-L43) |
| `FlutterRunlet/LaunchPresentation.swift` 与 Debug 验收入口 | 启动分派、模型 | 参数 → 精确 Debug 开关 → App 装配 | `#if DEBUG` 包围精确参数匹配。 [启动分派](../../../../FlutterRunlet/LaunchPresentation.swift#L24-L35) |
| `FlutterRunletTests/` 新增关键行为 XCTest | 测试 | 输入及运行结果 → 可观察断言 | 宿主 XCTest、`@testable import FlutterRunlet` 和正反用例。 [已有测试](../../../../FlutterRunletTests/LaunchPresentationTests.swift#L1-L25) |
| `FlutterRunlet.xcodeproj/project.pbxproj` | 构建配置 | 源文件与测试文件 → 各自 target | 显式 `PBXBuildFile`、`PBXFileReference`、组和 `PBXSourcesBuildPhase`。 [文件条目](../../../../FlutterRunlet.xcodeproj/project.pbxproj#L9-L45) [Sources](../../../../FlutterRunlet.xcodeproj/project.pbxproj#L225-L246) |

## Pattern Assignments

- 在 `FlutterRunletApp` 的状态装配处创建一个可观察的会话控制器，让两个场景使用同一实例和同一操作入口。保留 `mainSceneID`、`mainRoute`、AppKit 主窗标识以及关闭面板后重开主窗的路径。`windowWillClose` 目前只调整激活策略。退出菜单当前调用 `NSApp.terminate(nil)`，在 App 层将菜单退出和系统退出接入同一生命周期决策。 [场景装配](../../../../FlutterRunlet/FlutterRunletApp.swift#L5-L85) [窗口标识和关闭](../../../../FlutterRunlet/FlutterRunletApp.swift#L127-L169)
- 主窗沿用 `.primaryAction` 的「打开项目」位置及会话区。配置名称和项目字段沿用 `Text(verbatim:)`、尾部省略和悬停全名。通过 `DebugControls` 把 Run、Stop 的状态和动作共享给两处界面。恢复状态及重试放入日志之外的会话区，日志 `DisclosureGroup` 展开状态继续由视图持有。 [主窗操作](../../../../FlutterRunlet/MainWindowView.swift#L38-L105) [共享控件](../../../../FlutterRunlet/MainWindowView.swift#L126-L176) [设计系统](../../../../docs/design/DESIGN-SYSTEM.md#4-控件风格)
- Debug 验收开关沿用精确匹配及正反参数测试的模式，控制进程替身和测试存储注入。保留 G1 固定演示的现有回归检查。前后置任务及恢复使用正式组件，普通启动和 Release 不激活注入。 [Debug 分支](../../../../FlutterRunlet/LaunchPresentation.swift#L16-L35) [精确与近似参数测试](../../../../FlutterRunletTests/LaunchPresentationTests.swift#L5-L25)
- 隔离测试复制公开 JSONC 和脚本到带空格的临时项目，比较执行前后两个配置文件的原字节。样例中四个配置名、旧 `args`、`toolArgs`、prod PATH 及后置标签均有现成输入。故障标记覆盖前置写入前失败、后置失败和前置部分写入后失败。记录退出和恢复顺序时优先观察子进程、脚本状态文件与退出码。 [启动样例](../../../../docs/examples/sample-flutter-app/launch.jsonc#L5-L57) [任务样例](../../../../docs/examples/sample-flutter-app/tasks.jsonc#L5-L26) [故障矩阵](../../../../docs/examples/sample-flutter-app/README.md#L5-L16) [脚本写入位置](../../../../docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh#L12-L25)
- 新 Swift 源码和 XCTest 各加入正确的 `Sources` 阶段。共享 scheme 的 `TestAction` 已包含 `FlutterRunletTests`，App 和测试 target 均使用 Swift 6、macOS 15。验证产物写入临时目录或让 `.build/phase-02/` 使用限定的 Git 忽略规则，目前仓库只对 `/.build/phase-01/` 设置了对应规则。 [共享 scheme](../../../../FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme#L25-L51) [测试目标](../../../../FlutterRunlet.xcodeproj/project.pbxproj#L411-L439) [现有忽略规则](../../../../.gitignore#L24)

## Shared Patterns

- 两个界面消费同一会话状态，显示层的禁用与执行层复验各自生效。
- 主窗、菜单栏和设置沿用 G1 原生结构。复杂项目管理和恢复操作使用主窗，菜单栏展示共享的会话摘要和受控操作。
- App、测试和样例均保持原生项目的文件组织。通过现有宿主测试和公开样例验证用户可观察结果。

## No Analog Found

| 预期职责 | 角色与数据流 | 采用依据 |
|---|---|---|
| JSONC 配置加载与诊断、命令参数和环境解析 | 文件读取与纯转换 | 技术契约 §2–§3、公开 JSONC 与研究中源坐标、argv 及环境规则。 |
| 前后置任务执行、会话编排、退出协调与进程间项目锁 | 事件、子进程、并发资源 | 技术契约 §3–§4、阶段决定 D-05–D-10 和研究的进程边界。 |
| 版本化恢复记录与重试核对 | 私有文件 I/O 与确定性比较 | 技术契约 §4、阶段决定 D-05–D-09 和研究的原子写入及指纹约束。 |

上游现有进程和日志行为仅有独立审计记录。若后续实际纳入代码，先按审计结论核对来源和许可。 [G1 上游审计](../01-upstream-audit-ui-shell/01-UPSTREAM-AUDIT.md) [Phase 02 研究](02-RESEARCH.md)

## Metadata

扫描 `FlutterRunlet/`、`FlutterRunletTests/`、`FlutterRunlet.xcodeproj/` 及 `docs/examples/sample-flutter-app/`。表中仓库代码、工程及样例依据已用 `git ls-files` 核对。
