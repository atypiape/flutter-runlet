# Phase 03 · Flutter 调试闭环界面审查

**审查日期** 2026-11-13

**受测候选** `9300b9c`，macOS 26.7.1

**基线** [Phase 03 UI 契约](03-UI-SPEC.md)

**截图** 复用 G2 的深色候选窗口与浅色隔离副本。浅色副本只调整外观属性并重新签名。截图和脱敏 AX 记录位于 `/tmp/flutter-runlet-phase03-fixture.TdrzUC/g2-proof`。

**交互证据** 复用 G2 真实设备、原生操作与 XCTest 记录。[G2 验收记录](03-G2-ACCEPTANCE.md)

## Pillar Scores

| 维度 | 评分 | 发现 |
| --- | --- | --- |
| 文案 | 3/4 | 设备冲突、FVM 修复和恢复失败均说明原因和下一步。共享运行按钮的 AX 名称少了「当前调试配置」。 |
| 视觉层级 | 4/4 | 主窗和菜单栏的配置、调试动作和窗口入口分组清楚，恢复入口在折叠日志后仍可见。 |
| 颜色 | 3/4 | 深浅外观保持相同主次层级。运行中和恢复失败时，禁用的「运行」仍有淡蓝底色。 |
| 排版 | 3/4 | 主窗和菜单栏四个调试标签完整。运行日志从中文空态切换到 ASCII 时沿用了比例字体。 |
| 间距 | 4/4 | 主窗为 640 × 580 pt，菜单栏宽 404 pt，两处四个调试动作同排，浅色长字段场景底部动作仍可达。 |
| 体验 | 4/4 | 同一进程跨主窗和菜单栏可控，默认浏览器和日志交互均有原生证据。 |

**Overall: 21/24**

三处警告均为界面规格偏差。已核对的九项 G2 验收结论维持通过，A18 真机分支按本机条件记为不适用。[G2 验收矩阵](03-G2-ACCEPTANCE.md#g2-验收矩阵)

**修正复验 · `0416505`**：原始评分保留以便追踪。最终候选的原生 AX 记录使用「运行当前调试配置」，窗口截图显示可用 Run 的系统强调色与禁用态的普通样式。实际日志从中文空态切到 ASCII 后仍使用 12 pt 系统等宽字体；AppKit 回归还验证了缓存裁剪时阅读位置、选区和字体。取证在 G2 目录的 `recheck-0416505` 子目录，见 `android-ready.ax`、`android-running.ax`、`native-android-active-ready.png`、`native-android-active-running.png`、`native-running-log.png` 和 `live-log-font.txt`。三处偏差均已关闭。

## Top 3 Priority Fixes

1. **WARNING · 日志字体在中文空态后发生变化。** 按原生日志视图的初始化和更新顺序，用无窗 `NSTextView` 先写入中文空态再写入 ASCII 行，字符属性仍是 `.PingFangUITextSC-Regular` 12 pt。截图中对应的 39 字符日志行也明显短于同字号的等宽文本。重复设置内容时明确应用 12 pt 系统等宽字体，保留现有选区和滚动位置。[日志视图](../../../../FlutterRunlet/MainWindowView.swift#L263) · [文本更新](../../../../FlutterRunlet/MainWindowView.swift#L293)
2. **WARNING · 运行按钮的可访问名称不完整。** 主窗和菜单栏的实际 AX 记录均为「运行」。在共享 `DebugControls` 给此动作设置规格约定的「运行当前调试配置」，保留可见标签「运行」。[共享按钮](../../../../FlutterRunlet/MainWindowView.swift#L365)
3. **WARNING · 禁用的运行按钮仍有强调底色。** `native-main-running.png`、`native-main-recovery-folded.png` 和 `native-menu-light-long-conflict.png` 中，禁用的「运行」仍以淡蓝色区别于其他按钮。仅可用时采用系统强调样式，其余状态沿用同排按钮的原生禁用样式。[共享按钮](../../../../FlutterRunlet/MainWindowView.swift#L365)

## Detailed Findings

### 1. 文案 · 3/4

`long-conflict.ax` 保留当前 Android 选择，说明配置要求 iPhone 17，并指向设备菜单。FVM 失效的 AX 记录含具体原因和「打开 Flutter 设置」，恢复失败截图中保留原任务名、退出码和「重试恢复」。`hot-reload.ax` 和 `menu-restart.ax` 有实际成功提示及「关闭」。运行按钮名称的差异由两处 AX 记录与共享组件源码共同证实。[设备阻断文案](../../../../FlutterRunlet/SessionController.swift#L81) · [状态与恢复区](../../../../FlutterRunlet/MainWindowView.swift#L160)

### 2. 视觉层级 · 4/4

`native-main-ready.png`、`native-main-running.png` 展示无侧栏主窗，项目与双列字段位于调试动作之上，当前会话信息集中在动作下方。就绪和长字段的菜单栏截图均可辨认顶部状态、调试动作、浏览器和窗口入口。恢复失败截图在折叠日志时仍显示恢复原因与按钮。刷新设备、设置和关于按钮在源码中配有可访问名称及悬停提示。[主窗与工具栏](../../../../FlutterRunlet/MainWindowView.swift#L14) · [菜单栏布局](../../../../FlutterRunlet/MenuBarPanelView.swift#L14)

### 3. 颜色 · 3/4

深色候选和浅色隔离副本通过系统窗口背景、原生分组和文本样式呈现层级。日志背景和边界分别采用 `textBackgroundColor` 与 `separatorColor`。恢复失败由文字表达。共享 Run 控件的 `.borderedProminent` 无条件生效，实际禁用态保留蓝色，与规格所限的可用状态不符。[日志颜色](../../../../FlutterRunlet/MainWindowView.swift#L215) · [共享按钮样式](../../../../FlutterRunlet/MainWindowView.swift#L365)

### 4. 排版 · 3/4

主窗和菜单栏采用 13 pt 系统字体。长配置在浅色主窗尾部省略，`long-conflict.ax` 与 `long-menu.ax` 均保存完整项目与配置名称。设备外层及菜单栏只读字段提供全文帮助，设置 SDK 路径可选取并附全文帮助。无窗复现与 `native-main-ready.png` 共同证实日志等宽字体在普通更新中丢失。[设备和配置字段](../../../../FlutterRunlet/MainWindowView.swift#L18) · [字段帮助](../../../../FlutterRunlet/MainWindowView.swift#L338) · [设置路径](../../../../FlutterRunlet/AuxiliaryWindows.swift#L110)

### 5. 间距 · 4/4

G2 原生截图复核主窗 640 × 580 pt，菜单栏宽 404 pt，两处调试控件都保持同排。主窗使用 16 pt 区块间距和已批准的 20 pt 水平留白，菜单栏沿用 12 pt 组间距并有 16 pt 内边距，设置正文保留 24 pt 内边距。浅色长字段冲突和深色恢复失败截图中的主要动作均完整可读。[主窗间距](../../../../FlutterRunlet/MainWindowView.swift#L14) · [菜单栏间距](../../../../FlutterRunlet/MenuBarPanelView.swift#L61) · [设置间距](../../../../FlutterRunlet/AuxiliaryWindows.swift#L52)

### 6. 体验 · 4/4

G2 原生操作覆盖启动模拟器、FVM 直达与运行期间锁定、设备冲突、同一 Flutter 进程的主窗重载和菜单栏重启，以及断线、恢复失败和重试。默认 Edge 两个入口随重跑更新连接，Inspector 实际选中样例 Widget。日志原生操作覆盖离开底部后保持阅读位置、回底继续跟随、清空后折叠与重开、整段和选区复制遮罩。启动计时和请求归属由 XCTest 补证。现有取证没有单独记录完整 Tab 顺序、原生退出确认框的焦点顺序和所有提示的双外观对照。[真实交互证据](03-G2-ACCEPTANCE.md#g2-验收矩阵)

## Files Audited

- [Phase 03 UI 契约](03-UI-SPEC.md) · [阶段决定](03-CONTEXT.md) · [G2 验收记录](03-G2-ACCEPTANCE.md)
- [主窗与共享控件](../../../../FlutterRunlet/MainWindowView.swift) · [菜单栏](../../../../FlutterRunlet/MenuBarPanelView.swift) · [设置](../../../../FlutterRunlet/AuxiliaryWindows.swift) · [窗口与退出](../../../../FlutterRunlet/FlutterRunletApp.swift) · [会话状态](../../../../FlutterRunlet/SessionController.swift)
- 原生截图 `native-main-ready.png`、`native-menu-ready.png`、`native-main-running.png`、`native-main-recovery-folded.png`、`native-main-light-long-conflict.png`、`native-menu-light-long-conflict.png`，以及验收矩阵所列的相关 AX 记录。
