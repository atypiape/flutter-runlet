# Phase 1 · 上游审计与原生 UI 骨架

**讨论日期** 2026-11-12  
**状态** 待规划

<domain>
## 阶段范围

审计 Flutter GUI Runner 的实现、依赖与许可，按审计结论复用适合的部分。交付可启动的 macOS 原生骨架，能打开主窗口、菜单栏面板、设置与独立关于窗口。验证 BASE-01 至 BASE-03 和 G1 对应的 A01、A02、A31，保留构建证据、截图与原生控件差异记录。配置与任务内核在 Phase 2 接入，真实调试会话在 Phase 3 接入，完整双语、设置功能及视觉验收按后续阶段推进。

</domain>

<decisions>
## 实施决定

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

</decisions>

<canonical_refs>
## 规划与实施依据

### 阶段与产品契约

- `AGENTS.md` · 仓库协作约束、文档优先级和阶段验收要求。
- `.planning/PROJECT.md` · 项目约束与已确认决定。
- `.planning/ROADMAP.md` · Phase 1 目标、范围和完成条件。
- `.planning/REQUIREMENTS.md` · BASE-01 至 BASE-03 及后续需求映射。
- `docs/01-PRODUCT.md` · v0.1 产品范围和已确认决策。
- `docs/02-TECHNICAL.md` §1、§7 · 原生架构、共享会话、上游许可和窗口职责。
- `docs/03-ROADMAP.md` §3–§4 · G1 门槛和各阶段操作顺序。
- `docs/04-ACCEPTANCE.md` · A01、A02、A31；参照 A04、A21、A26 的后续完整验收范围。

### 视觉与演示数据

- `docs/design/UI-SPEC.md` §1–§5 · Empty、Ready、主窗、菜单栏、设置与关于规格。
- `docs/design/DESIGN-SYSTEM.md` §2、§4、§6–§7 · 原生结构、控件、品牌资源与 G1 验收。
- `docs/design/FIGMA-HANDOFF.md` · 已验收视觉基线、原生实验及偏差记录要求。
- `docs/design/assets/flutterrunlet-glyph.svg` · 关于窗口可复用的已验收品牌标志。
- `docs/examples/sample-flutter-app/README.md` 和 `docs/examples/sample-flutter-app/launch.jsonc` · 脱敏示例及 dev 配置的原始显示名。

</canonical_refs>

<code_context>
## 仓库现状

- 仓库已有产品与设计文档、品牌导出和脱敏样例。当前没有 macOS 应用源码或上游导入，需先审计候选实现及其许可证。
- 原生界面遵循 SwiftUI 优先、AppKit 按需补充。主窗口和菜单栏使用共享状态，Phase 1 提供 Empty 与 Ready 示例。正式配置及会话能力由后续阶段接入。
- 设计交接记录了 macOS 26.7.1 上的原生窗口、菜单栏面板和 Picker 实验。用于指导骨架验证，macOS 15 API 可用性须按 A31 核查。

</code_context>

<specifics>
## G1 手工验收要点

- 普通启动核对 Empty，再使用专用参数启动 Debug Ready。核对主窗与菜单栏数据一致、Run 弹出原生演示提示。
- 从菜单栏重新打开已关闭的主窗，核对唯一主窗与 Ready 示例。打开设置并往返两页，打开独立关于窗口核对品牌与实际构建信息。

</specifics>

<deferred>
## 延后事项

完整设置功能、项目链接、双语及外观验收按 Phase 4 推进。真实调试与菜单栏的会话联动按 Phase 3 验收。

</deferred>
