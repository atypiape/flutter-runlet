# Phase 1 · 上游审计与原生 UI 骨架模式映射

**映射日期** 2026-11-12

**覆盖范围** 12 个预期文件职责，仓库内可复制的 Swift、工程或测试实现为 0 个。

检索了仓库跟踪文件，当前无 Swift 源码、Xcode 工程、共享 scheme 或 `.xcassets` 资源目录。表中的仓库依据是可复用的设计、资产、样例和验收约定。职责名称用于帮助划分任务，未确定的路径与文件拆分由实施计划固定。

## File Classification

| 预期文件或职责 | 角色 | 数据流 | 最近的仓库依据 |
| --- | --- | --- | --- |
| `FlutterRunlet.xcodeproj/project.pbxproj` | 构建配置 | 配置 → Debug 与 Release App 产物 | [研究 · Standard Stack](01-RESEARCH.md#standard-stack) |
| `FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme` | 构建与测试配置 | scheme → App target 与 XCTest target | [验证策略 · Test Infrastructure](01-VALIDATION.md#test-infrastructure) |
| App 场景入口 Swift 文件 | 入口、路由 | 启动参数 → 一次确定的演示状态 → 主窗与菜单栏；窗口动作 → 指定场景 | [技术契约 · 架构原则](../../../docs/02-TECHNICAL.md#1-架构原则) |
| 启动策略与固定 Ready 示例 | 模型、参数转换 | 进程参数与编译配置 → Empty 或 Ready → 只读字段 | [阶段决定](01-CONTEXT.md) · [示例配置第 5 行](../../../docs/examples/sample-flutter-app/launch.jsonc#L5) |
| 主窗口视图 | 界面组件 | 演示状态 → 项目、配置、设备及动作；Run 点击 → 原生演示提示 | [UI 契约 · 界面与交互](01-UI-SPEC.md#界面与交互) |
| 菜单栏面板视图 | 界面组件 | 同一演示状态 → 只读摘要与动作；打开主窗 → 聚焦或恢复唯一窗口 | [UI 契约 · 界面与交互](01-UI-SPEC.md#界面与交互) |
| 设置视图 | 导航组件 | 本地选中项 → 通用或 Flutter 页面 | [UI 契约 · 界面与交互](01-UI-SPEC.md#界面与交互) |
| 独立关于视图 | 界面组件 | 应用 bundle 元数据与品牌资源 → 名称、版本、构建号 | [研究 · Architecture Patterns](01-RESEARCH.md#architecture-patterns) · [UI 契约](01-UI-SPEC.md) |
| 品牌资产目录 | 本地资源 | 已验收的矢量图与模板位图 → 关于图标和菜单栏模板 | [设计系统 · Logo、Dock 与菜单栏图标](../../../docs/design/DESIGN-SYSTEM.md#6-logodock-与菜单栏图标) |
| 最小启动策略 XCTest | 测试 | 普通、专用及无效参数 → 断言对应的演示状态 | [研究 · Validation Architecture](01-RESEARCH.md#validation-architecture) |
| 上游审计记录 | 技术证据 | 固定提交、源码、清单和许可证 → 复用及实际导入结论 | [研究 · 上游源码、依赖与许可证](01-RESEARCH.md#上游源码依赖与许可证) |
| G1 验收记录与六张截图 | 运行证据 | 测试、构建、尺寸测量和窗口操作 → A01、A02、A31 | [UI 契约 · G1 验收](01-UI-SPEC.md#g1-验收) · [验收矩阵](../../../docs/04-ACCEPTANCE.md) |

## Pattern Assignments

### 场景入口与唯一主窗

- 上游把同一个 `model` 传入主场景和菜单栏场景。这是共享演示状态的外部结构参考。其主窗启动会调用 `model.bootstrap()`，重开路径按可成为主窗的条件找窗口，分别涉及 G1 无需触发的扫描与容易混淆多个窗口的选择。 [固定提交场景入口](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/FlutterRunnerApp.swift#L11-L34) · [固定提交重开路径](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Sources/FlutterRunner/ContentView.swift#L334-L341)
- G1 依据 D-01 至 D-04，从 App 入口给两个界面传同一份状态，用固定主窗标识重开。研究建议 data-driven `WindowGroup` 结合相同值的 `openWindow`，设置和关于按独立窗口角色打开。首启、关闭最后一个主窗、从菜单栏重开和重复重开在当前系统验证，必要时采用研究记录的 AppKit 替代路径。 [阶段决定](01-CONTEXT.md) · [研究 · Architecture Patterns](01-RESEARCH.md#architecture-patterns)

### 演示状态、动作与测试

- `sample-flutter-app(dev)` 复用脱敏样例中已跟踪的配置名。启动策略只选择固定演示状态，主窗与菜单栏按同一值展示项目、配置和设备。主窗及面板内的 Run 动作仅触发对应界面的原生提示，关闭提示后共享状态仍为 Ready。 [示例配置第 5 行](../../../docs/examples/sample-flutter-app/launch.jsonc#L5) · [UI 契约](01-UI-SPEC.md)
- XCTest 聚焦启动决策的普通参数、专用参数和无效参数。实际 Release 用同一专用参数核对仍为 Empty，实际窗口交互与状态保持使用 G1 手工证据。 [研究 · Validation Architecture](01-RESEARCH.md#validation-architecture)

### 视图与品牌

- 主窗布局、菜单栏宽度、设置页默认项、关于窗口内容都从已批准的阶段契约取值。使用系统语义色及原生控件，分别记录主窗外框、内容尺寸及面板系统边缘差异。长字段按契约省略并可悬停查全名。 [UI 契约](01-UI-SPEC.md) · [设计系统 · 窗口与信息层级](../../../docs/design/DESIGN-SYSTEM.md#2-窗口与信息层级)
- 关于可直接采用已跟踪的矢量主标志，菜单栏模板已有 18 × 18 与 36 × 36 PNG。保持两类资产的渲染职责，关于版本及构建号读取实际 App bundle。 [矢量主标志](../../../docs/design/assets/flutterrunlet-glyph.svg) · [菜单栏 1x 模板](../../../docs/design/assets/flutterrunlet-menubar-template@1x.png) · [菜单栏 2x 模板](../../../docs/design/assets/flutterrunlet-menubar-template@2x.png)

### 工程、审计与验收

- 研究中明确提出原生 macOS App target、共享 scheme 和 Debug、Release 两配置部署目标 15.0。上游 SwiftPM 清单用于依赖审计。它的可执行文件打包流程属于上游证据。 [研究 · Standard Stack](01-RESEARCH.md#standard-stack) · [固定提交 SwiftPM 清单](https://github.com/huseyiniriss/flutter-gui-runner/blob/1c8468f54f1c7785aca31cfea0a5207feca30c06/Package.swift#L1-L13)
- 现有 `.gitignore` 覆盖私有审计材料及示例运行产物。验证策略示例使用的 `.build/phase-01` 尚无匹配规则，计划应核对派生数据路径和相应的 Git 忽略或临时目录安排。 [仓库忽略规则](../../../.gitignore) · [验证策略](01-VALIDATION.md)
- 执行交付保留独立审计记录和 G1 证据。审计先确认源码及许可再决定是否导入，实际导入时保存完整许可及版权。G1 验证 macOS 15 构建与 API，在当前系统运行并留存六张脱敏截图。macOS 15 实机复验按 D-09 标记未执行。 [技术契约 · 架构原则](../../../docs/02-TECHNICAL.md#1-架构原则) · [阶段决定](01-CONTEXT.md) · [验收矩阵](../../../docs/04-ACCEPTANCE.md)

## Shared Patterns

- 数据所有权在 App 层，主窗与菜单栏消费同一状态。窗口身份独立于视图当前是否打开。
- 进程参数只选择 G1 固定演示，Release 使用正常 Empty 路径。项目配置解析、设备扫描、Flutter 运行和日志写入属于后续阶段。
- 审计固定提交与许可，记录取舍及实际导入。验收使用脱敏示例，分开记录部署目标和运行环境。

## No Analog Found

仓库当前没有可借用的 Swift 场景、组件、模型、测试或 Xcode 配置源码。上述角色使用阶段契约、现有资产和研究确认的原生方案，引用的上游文件保留为独立外部依据。

## Metadata

扫描范围为 42 个 Git 跟踪文件，包括项目约束、规划文档、设计规格与资产、示例和许可。映射反映 2026-11-12 的仓库状态。
