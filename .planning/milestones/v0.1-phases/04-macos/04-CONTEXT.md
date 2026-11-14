# Phase 04 · macOS 界面与双语设置

**讨论日期** 2026-11-13

**状态** 待规划

<domain>
## 阶段范围

沿用 G0 视觉基线、G1 原生窗口和 G2 共享会话，完成主窗口与菜单栏的状态呈现、简体中文与英文、系统深浅外观、通用与 Flutter 设置、环境检测、独立关于窗口和品牌图标。覆盖 UI-01 至 UI-06，以及 A03–A06、A21、A23–A26。

语言默认跟随系统，用户可切换为简体中文或 English，立即更新已打开的界面并记住偏好。项目、配置、设备名称及 Flutter/Dart 原始输出保留原文。Flutter 设置沿用实际 SDK/FVM 解析与会话期间的设置锁定规则。环境检测按 UI 规格呈现 Flutter、Xcode 和 Android Toolchain 摘要、完整输出及检测异常。

</domain>

<decisions>
## 实施决定

### 启动偏好

- **D-01:** 登录时启动默认关闭，启动后显示主窗口默认开启，记住最近打开的项目默认开启。通用页提供对应的可用设置，保留用户已保存的偏好。
- **D-02:** 即使关闭「启动后显示主窗口」，启动检测到待恢复记录时也自动打开主窗口，显示对应项目和处理入口。项目是否自动打开仍按 Phase 02 D-08 处理。恢复须由用户触发。

### 调试快捷操作

- **D-03:** v0.1 通过现有按钮手动打开当前会话的 DevTools，通用页省略自动打开开关。此决定明确了技术契约 §7 中的可选项，以本轮确认和 UI 规格 §3 为准。
- **D-04:** 应用内快捷键为 F5 运行、Shift+F5 停止、Option+F5（Alt+F5）热重载、Shift+Command+F5 热重启。沿用按钮对应的共享会话操作及可用条件，保留原生 Tab 和 Shift-Tab 导航。

### 主窗口与菜单栏

- **D-05:** 主窗口和菜单栏均显示恢复失败原因及操作。菜单栏提供「重试恢复」，与主窗口共用恢复状态、操作和启用条件。主窗口的恢复提示与操作位于日志外。涉及待恢复项目的选择与打开，沿用 Phase 02 D-08。
- **D-06:** 主窗口与菜单栏的长项目名、配置名和设备名单行尾部省略，保留悬停提示。沿用 G0 的独立全名入口，支持点击及键盘操作。配置或设备选择锁定时，全名入口仍可使用。

### 关于窗口链接

- **D-07:** 项目主页采用 [GitHub 仓库](https://github.com/atypiape/flutter-runlet)，使用文档采用 [README](https://github.com/atypiape/flutter-runlet/blob/main/README.md)，项目许可证采用 [LICENSE](https://github.com/atypiape/flutter-runlet/blob/main/LICENSE)。这三个地址已确认，替代原有待配置占位。讨论时匿名访问均返回 404，公开可访问性留待发布验收复验。

</decisions>

<canonical_refs>
## 规划与实施依据

规划和实施前读取相关章节。

### 范围、契约与验收

- `AGENTS.md` · 文档优先级、UI 改动范围及阶段验收。
- `.planning/PROJECT.md` · 产品约束和 G0–G2 结果。
- `.planning/milestones/v0.1-REQUIREMENTS.md` · UI-01 至 UI-06 与发布阶段分工。
- `.planning/milestones/v0.1-ROADMAP.md` · Phase 04 目标、依赖与完成条件。
- `docs/01-PRODUCT.md` §2–§7 · 产品范围、原生界面、语言和待确认项。
- `docs/02-TECHNICAL.md` §4–§8 · 生命周期、恢复、SDK/FVM、浏览器连接、本地化及测试。
- `docs/03-ROADMAP.md` §3–§4 · P4 范围与验收流程。
- `docs/04-ACCEPTANCE.md` · A03–A06、A21、A23–A26 与证据判定。

### 界面、前序决策与资源

- `docs/design/UI-SPEC.md` §1–§8 · 各窗口与状态、设置、环境检测、语言和键盘交互。
- `docs/design/DESIGN-SYSTEM.md` §2–§7 · 原生窗口、长名称、语言、图标及设计偏差。
- `docs/design/FIGMA-HANDOFF.md` · G0 视觉基线、长名称原型、品牌导出和原生实验。
- `docs/design/assets/flutterrunlet-dock-1024.png` 及同目录的各尺寸 Dock PNG · 已验收的应用图标导出。
- `docs/design/assets/flutterrunlet-glyph.svg`、`docs/design/assets/flutterrunlet-menubar-template@1x.png` 和 `docs/design/assets/flutterrunlet-menubar-template@2x.png` · 关于标志和菜单栏同源单色资源。
- `.planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-CONTEXT.md` 和 `.planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-G1-RETEST.md` · 原生窗口、Dock 行为、悬停与键盘导航基线。
- `.planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-UPSTREAM-AUDIT.md` · 上游归属、版权及导入情况。
- `.planning/milestones/v0.1-phases/02-config-task-execution-core/02-CONTEXT.md` · 记住最近项目、恢复入口、原任务及重试约束。
- `.planning/milestones/v0.1-phases/03-flutter/03-CONTEXT.md` 和 `.planning/milestones/v0.1-phases/03-flutter/03-G2-ACCEPTANCE.md` · 共享会话、实际 SDK、日志和原生界面回归依据。
- `README.md` 和 `LICENSE` · 关于窗口使用文档和项目 MIT 许可证对应文件。

</canonical_refs>

<code_context>
## 现有实现与接入点

- `FlutterRunlet/FlutterRunletApp.swift` 已注册四个界面，共享 `SessionController`，并处理主窗与菜单栏之间的窗口激活策略。应用菜单、自定义 AppKit 弹窗和文件选择面板也有待本地化的文案。
- `FlutterRunlet/MainWindowView.swift` 和 `FlutterRunlet/MenuBarPanelView.swift` 共用 `DebugControls`、`BrowserControls`、`PresentationField` 和会话反馈。主窗口已有日志外恢复操作，菜单栏已有失败原因。复用 `SessionController` 的恢复条件和调试操作。
- `FlutterRunlet/AuxiliaryWindows.swift` 已有两类设置导航、最近项目开关、SDK 选择、FVM 偏好和实际版本，以及读取真实构建信息的关于窗口。`FlutterRunlet/FlutterToolchain.swift` 已解析实际使用的 Flutter SDK，可为环境检测提供 SDK 来源。
- `FlutterRunlet/Assets.xcassets/BrandGlyph.imageset` 已提供关于窗口标志。Xcode 工程已打包 1x、2x 菜单栏模板，由应用设为 template image。Dock 图标的各尺寸导出已存于设计资产目录，待接入应用 target。

</code_context>

<specifics>
## 验收要点

- 主窗口与菜单栏复用 G2 状态和真实会话证据，重点核对英文四个按钮完整同排、锁定字段的全名入口、恢复失败时菜单栏直接重试，以及应用内快捷键与按钮启用条件一致。
- macOS 26.7.1 上实测 Command+F5 由系统接收并切换 VoiceOver。用户随后确认 Option+F5，前台 AppKit 探针已收到该组合键。正式构建验收四个键位、按钮启用条件及作用范围。 [实测记录](04-RESEARCH.md#快捷键实测)
- 验证语言切换立即更新各窗口、菜单、状态和应用提示，重启后记住偏好，并在两种系统外观下检查布局及图标。验证启动偏好和待恢复时打开主窗口的行为。环境检测核对实际 SDK、摘要、原始输出及失败提示。
- 关于窗口使用真实版本、构建号、上游归属与版权。Phase 04 核对三个链接配置和打开动作，发布验收复验匿名可访问性。原生差异按验收矩阵记录位置、原因及验证结果。

</specifics>

<deferred>
## 后续阶段

Phase 05 继续处理异常恢复、压力、真实项目复验和发布准备，并复验关于窗口三个 GitHub 链接的公开可访问性。

</deferred>

---

*Phase 04 · macOS 界面与双语设置*

*上下文确认于 2026-11-13*
