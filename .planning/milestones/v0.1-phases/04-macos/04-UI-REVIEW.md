# Phase 04 · macOS 界面审查

**审查日期** 2026-11-13

**受测候选** `988ac81`（完整原生审查）、`97a6713`（修正复验），macOS 26.7.1，Xcode 27.1

**基线** [Phase 04 UI 契约](04-UI-SPEC.md) · [已确认决定](04-CONTEXT.md) · [原生控件与设计偏差](../../../../docs/design/DESIGN-SYSTEM.md)

**截图** 复核 `988ac81` 的 16 张原生窗口截图与四张图标截图，以及同候选的按键、辅助功能和真实模拟器证据，目录为 `/tmp/runlet-04-05.VMZlFG`。用 `97a6713` 补验诊断完整输出 sheet、设置激活和主窗重开，目录为 `/tmp/runlet-04-review-final.9Zc6wM`。 [最终候选验收](04-P4-ACCEPTANCE.md)

## Pillar Scores

| 维度 | 评分 | 发现 |
| --- | --- | --- |
| 文案 | 4/4 | 两处共用动作和错误文案，设置页往返保持应用语言，系统面板的自有标题和系统控件文字按各自语言来源显示。 |
| 视觉层级 | 4/4 | 主窗、菜单栏和设置保持既有层级，关于独立呈现品牌与元数据。两处全名图标有可访问名称。 |
| 颜色 | 4/4 | 深浅外观使用系统表面和语义色，运行中禁用 Run 采用普通原生禁用样式。两种外观中的品牌与状态可辨。 |
| 排版 | 4/4 | 两语言的调试动作完整同排。主窗日志及修正后的 doctor 完整输出均为 12 pt 系统等宽。 |
| 间距 | 4/4 | 默认外框和面板宽度符合规格，按钮高度及设置分隔线位置记录为原生尺寸。 |
| 体验 | 4/4 | 同一会话、原任务恢复、键盘和诊断流程有实测。系统登录项通过真实登录复验。 |

**Overall: 24/24**

## Detailed Findings

### 1. 文案 · 4/4

运行按钮的可见标签简短，两个界面均提供完整的「运行当前调试配置」及英文辅助名称。FVM 链接缺失时说明原因并给出 Flutter 设置入口。恢复失败提示含实际任务名和退出码，随语言切换重渲染。设置从通用切换到 Flutter 再返回时标题保持当前语言。英文项目与 SDK 选择面板使用应用自有英文标题，系统绘制的「打开」「取消」保留宿主简体中文。 [共享调试动作](../../../../FlutterRunlet/MainWindowView.swift#L503) · [设置标题](../../../../FlutterRunlet/AuxiliaryWindows.swift#L76) · [A23 证据](04-P4-ACCEPTANCE.md#验收矩阵)

### 2. 视觉层级 · 4/4

主窗延续项目、双列配置、调试动作、会话和日志的顺序。菜单栏在顶部显示当前状态，底部保留窗口和设置入口。关于窗中的标志、应用名、版本、归属和链接分组可辨。运行态的两个选择器锁定时，字段外的全名按钮仍可达。 [主窗与全名入口](../../../../FlutterRunlet/MainWindowView.swift#L14) · [菜单栏分组](../../../../FlutterRunlet/MenuBarPanelView.swift#L15) · [关于](../../../../FlutterRunlet/AuxiliaryWindows.swift#L300)

### 3. 颜色 · 4/4

深浅模式均能区分窗口、日志及辅助内容。Run 只在可执行状态使用系统强调按钮，禁用态的运行截图与其他原生控件一致。恢复及诊断状态同时使用文字。菜单栏模板由系统着色，测试宿主在两种模式下使用同样的菜单栏背景。Dock 和关于仍显示同源青蓝标志。 [共享按钮样式](../../../../FlutterRunlet/MainWindowView.swift#L508) · [状态栏模板](../../../../FlutterRunlet/FlutterRunletApp.swift#L536) · [A06 证据](04-P4-ACCEPTANCE.md#验收矩阵)

### 4. 排版 · 4/4

主窗和菜单栏采用 13 pt 系统字体。AX 坐标与原生截图共同确认，四个调试动作在 640 pt 主窗和 404 pt 面板内都保持同排且文字完整。长项目名在面板尾部省略，辅助功能帮助与原生全名弹出层保留原值。主窗日志是 12 pt 系统等宽。审查发现 `988ac81` 的 doctor 详细输出字号继承系统正文，`97a6713` 已统一为 12 pt。新候选原生截图核对了 stdout 和 stderr 两组等宽原文，字号由源码显式指定。 [主窗日志字体](../../../../FlutterRunlet/MainWindowView.swift#L293) · [诊断详情字体](../../../../FlutterRunlet/AuxiliaryWindows.swift#L216) · [修正复验](04-P4-ACCEPTANCE.md#审查修正复验)

### 5. 间距 · 4/4

AX 外框为主窗 640 × 580 pt、设置 672 × 520 pt、关于 440 × 480 pt。原生面板宽 404 pt，运行态高 278 pt，恢复及反馈展开时高度随内容增长。调试动作间距为 8 pt，原生按钮高 24 pt，设计参考高 26 pt。设置侧栏滚动区为 142 pt，分隔线距窗口左边 150 pt。主窗、设置和关于的外框与内容尺寸已在验收记录列明。 [原生尺寸与差异](04-P4-ACCEPTANCE.md#原生复验与差异)

### 6. 体验 · 4/4

从空白、就绪到等待、运行、停止与恢复失败，主窗和菜单栏共享状态。关闭主窗后可在面板用功能键控制同一 Flutter 进程。日志焦点内的热操作和后台无动作有按键探针。主窗的 Tab、Shift-Tab 与 Space 可到达并打开锁定字段的全名。恢复失败后折叠日志仍可操作，原任务重试后风险归零。新候选从菜单栏打开设置只显示设置窗，明确打开主窗后维持唯一窗口，诊断进行中从菜单栏退出会清理进程和工作目录。用户已确认实际登录启动、主窗行为及撤销后不再启动。 [A04 用户验收](04-UAT.md) [A03、A04、A05、A21、A25](04-P4-ACCEPTANCE.md#验收矩阵) · [修正复验](04-P4-ACCEPTANCE.md#审查修正复验)

## Files Audited

- [阶段 UI 契约](04-UI-SPEC.md) · [阶段决定](04-CONTEXT.md) · [验收记录](04-P4-ACCEPTANCE.md)
- [主窗与共享控件](../../../../FlutterRunlet/MainWindowView.swift) · [菜单栏](../../../../FlutterRunlet/MenuBarPanelView.swift) · [设置及关于](../../../../FlutterRunlet/AuxiliaryWindows.swift) · [窗口和应用菜单](../../../../FlutterRunlet/FlutterRunletApp.swift) · [本地化资源](../../../../FlutterRunlet/Localizable.xcstrings)
- 原生窗口截图 `final-{light,dark}-{zh,en}-*.png`、图标截图 `final-{light,dark}-{dock,menu-icon}.png` 与验收所列的辅助功能及按键记录。
