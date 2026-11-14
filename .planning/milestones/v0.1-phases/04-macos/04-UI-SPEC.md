---
phase: "04"
slug: "macos"
status: approved
shadcn_initialized: false
preset: none
created: "2026-11-13"
reviewed_at: "2026-11-13"
---

# Phase 04 · macOS 界面与双语设置 UI 契约

基于已通过验收的 G0 设计、G1 原生窗口和 G2 共享会话，交付 UI-01–UI-06。本阶段实施以用户决定 D-01–D-07 为准，验证 A03–A06、A21、A23–A26。

[阶段决定](04-CONTEXT.md) · [技术研究](04-RESEARCH.md) · [验收矩阵](../../../../docs/04-ACCEPTANCE.md) · [G0 画板清单](../../../../docs/design/FIGMA-HANDOFF.md#画板清单) · [G2 会话操作矩阵](../03-flutter/03-UI-SPEC.md#会话操作矩阵)

## Design System

| 项目 | 约定 |
| --- | --- |
| Tool | none |
| Preset | 不适用 |
| 组件 | SwiftUI 优先，AppKit 按需补充。沿用原生窗口、菜单、选择器、开关、按钮、焦点和提示。 |
| 图标 | 系统符号、已验收的 Dock PNG 及同源标志和菜单栏 template。 |
| 字体 | macOS 系统 SF Pro，CLI 原文采用系统等宽字体。 |

[设计系统](../../../../docs/design/DESIGN-SYSTEM.md) · [界面与交互规格](../../../../docs/design/UI-SPEC.md) · [G1 原生复验](../01-upstream-audit-ui-shell/01-G1-RETEST.md)

## 界面与信息层级

| 区域 | 布局与行为 |
| --- | --- |
| 主窗口 | 默认外框 **640 × 580 pt**，无侧栏。沿用项目、配置与设备双列、调试按钮、会话与浏览器入口、日志及底部项目状态的顺序。四个调试按钮在默认宽度同排且标签完整。恢复提示和操作位于日志外。SDK 信息集中在 Flutter 设置，按产品 P-11 与 A04 执行。 |
| 菜单栏 | **404 pt** 原生面板，高度随内容。按状态、项目、配置与设备、调试操作、浏览器、窗口入口的顺序呈现。菜单栏直接显示恢复失败原因和对应操作。关闭主窗后会话继续，面板可控制同一会话。 |
| 通用设置 | 设置默认外框 **672 × 520 pt**，保留 **142 pt** 左导航，仅「通用」和「Flutter」。通用页含语言及三项启动偏好。登录时启动默认关闭，启动后显示主窗口和记住最近打开的项目默认开启，已保存偏好继续生效。登录项显示系统实际状态及所需用户操作。DevTools 由现有按钮手动打开。（D-01、D-03） |
| Flutter 设置 | SDK 来源、路径、实测 Flutter/Dart 版本、可用性、FVM 优先及项目版本。编辑沿用会话与恢复期间的锁定条件。环境检测按 Flutter、Xcode、Android Toolchain 显示摘要，提供完整原始输出和可理解的检测失败状态。 |
| 关于 | 约 **440 × 480 pt** 独立原生窗口。用现有品牌标志、真实版本和构建号，显示上游 Flutter GUI Runner 归属、版权和 MIT 许可。三个链接采用 D-07 已确认地址，通过系统默认浏览器打开。匿名访问在 Phase 05 复验。 |
| 应用与菜单栏图标 | Dock 使用已验收的各尺寸导出，外框无多余透明或黑色边；菜单栏使用现有 1x、2x 单色 template，由系统着色。两种系统外观均检查辨识度。 |

按 G0 主窗、菜单栏、设置、关于、长名称和 prod 恢复画板核对。记录必要的原生差异、所在窗口或控件、成因及验证结果。外框和内容尺寸分别测量，标题栏与控件尺寸以系统行为为准。[Figma 交接](../../../../docs/design/FIGMA-HANDOFF.md)

## Spacing Scale

| 间距 | 用途 |
| --- | --- |
| 4 pt | 字段标题和值之间 |
| 8 pt | 同排按钮、会话内容和日志区内间隔 |
| 12 pt | 菜单栏分组间隔 |
| 16 pt | 主窗区块、配置与设备双列间隔、菜单栏内边距 |
| 20 pt | 主窗两侧边距 |
| 24 pt | 设置内容内边距 |

G0 的 52 pt 标题栏及工具栏、26 pt 调试按钮高度为画板参考。使用原生控件尺寸和焦点反馈。

## Typography

| 用途 | 字号 | 字重与行高 |
| --- | --- | --- |
| 正文、字段、动作和状态 | SF Pro 13 pt | 常规，系统行高 |
| CLI 日志和详细输出 | 系统等宽 12 pt | 常规，系统行高 |
| 原生窗口和设置页标题 | 沿用系统标题角色 | 常规或半粗体，系统行高 |

## Color

| 角色 | 取值与用途 |
| --- | --- |
| 主表面 | 系统窗口背景 |
| 次表面 | 原生菜单栏面板、设置导航和日志的辅助表面 |
| 强调 | 系统强调色用于可执行的 Run 主动作，原生选中和焦点沿用系统反馈 |
| 品牌与告警 | 青蓝用于已确认的品牌标志。文字与状态使用系统语义色，运行和错误状态同时给出文字。 |

两种外观共用布局和层级，跟随系统。菜单栏模板采用系统着色，Dock 图标沿用现有导出配色。

## Copywriting Contract

同一时刻使用当前应用语言。语言选项保留语言自称。项目、配置、设备、路径、版本、Flutter 等技术名、命令和 CLI 原文保留原值，G2 规定的连接令牌遮罩继续生效。已显示的状态和反馈随语言切换更新，应用自有菜单、窗口标题、辅助名称、工具提示及 AppKit 提示一并覆盖。系统提供的面板文案遵循 macOS 语言并记录原生差异。

| 元素 | 简体中文 | English |
| --- | --- | --- |
| 无项目 | 未选择项目 · 打开项目 | No project selected · Open Project |
| 调试动作 | 运行 · 停止 · 热重载 · 热重启 | Run · Stop · Hot Reload · Hot Restart |
| 共享状态 | 就绪 · 正在启动 Flutter · 等待 VM Service 连接 · 运行中 · 正在停止 · 正在恢复环境 | Ready · Starting Flutter · Waiting for VM Service · Running · Stopping · Restoring Environment |
| 恢复失败及操作 | 环境恢复失败：{原因}。· 重试恢复 · 打开待恢复项目 | Environment recovery failed: {reason}. · Retry Recovery · Open Project for Recovery |
| 全名入口 | 查看项目全名 · 查看配置全名 · 查看设备全名 | Show Full Project Name · Show Full Configuration Name · Show Full Device Name |
| 退出确认 | 停止会话并退出 FlutterRunlet？· 停止并退出 · 取消 | Stop the session and quit FlutterRunlet? · Stop and Quit · Cancel |
| 设置与语言 | 通用 · Flutter · 语言 · 跟随系统 · 简体中文 · English | General · Flutter · Language · Follow System · 简体中文 · English |
| 启动偏好 | 登录时启动 · 启动后显示主窗口 · 记住最近打开的项目 | Launch at Login · Show Main Window on Launch · Remember Last Opened Project |
| 登录项待批准 | 请在系统设置中允许 FlutterRunlet 登录时启动。 | Allow FlutterRunlet to launch at login in System Settings. |
| SDK 无效 | 当前 Flutter SDK 不可用：{原因}。请检查 SDK 路径。· 打开 Flutter 设置 | The current Flutter SDK is unavailable: {reason}. Check the SDK path. · Open Flutter Settings |
| 环境检测 | 检查环境 · 正在检查环境 · 查看完整输出 · 重试 | Check Environment · Checking Environment · View Full Output · Retry |
| 检测异常 | 无法完成环境检测：{原因}。请检查 Flutter SDK 后重试。 | Environment check could not complete: {reason}. Check the Flutter SDK and try again. |
| 关于 | 关于 FlutterRunlet · 版本 {version} · 构建号 {build} · 项目主页 · 使用文档 · 项目许可证 | About FlutterRunlet · Version {version} · Build {build} · Project Home · Documentation · Project License |

保留 G2 文案中更具体的故障原因和操作指引。诊断发现工具链警告时在相应条目显示问题，检测本身异常时说明原因。系统登录项被拒绝或不可用时说明实际结果及可采取的操作。[G2 操作反馈与文案](../03-flutter/03-UI-SPEC.md#copywriting-contract)

## 键盘与恢复

F5 运行，Shift+F5 停止，Option+F5（Alt+F5）热重载，Shift+Command+F5 热重启。四个快捷键只在应用内工作，复用对应按钮的操作和可用条件。主窗和菜单栏面板使用同一个会话，同一次按键最多执行一次。保留原生 Tab、Shift-Tab 导航及系统 VoiceOver 快捷键。正式构建验证日志获得焦点、主窗关闭后在菜单栏面板操作及应用在后台的情形。（D-04）[本机探针](04-RESEARCH.md#快捷键实测)

项目、配置和设备字段长值单行尾部省略并提供悬停提示。可点击且可用键盘操作的独立全名入口位于字段外层，选择器锁定时仍可达。图标按钮具备可访问名称和提示。恢复原因允许换行。两处窗口共用同一重试条件，当前项目与待恢复记录不一致时按 Phase 02 D-08 打开对应项目。启动发现待恢复记录时打开主窗，恢复由用户触发。（D-02、D-05、D-06）

## UI Considerations

| 类别 | 界面或元素 | 状态 | 验收条件 |
| --- | --- | --- | --- |
| empty、loading、populated、error | 主窗与菜单栏 · A03、A21 | ✅ covered | 两处呈现同一会话的空白、就绪、启动、等待 VM Service、运行、停止、恢复和错误。运行中 Run 禁用、Stop 可用，等待连接时热操作和浏览器入口禁用。关闭主窗后可从菜单栏控制同一会话。 |
| loading、error、long-text | 恢复 · A03、A21 | ✅ covered | 恢复失败时两处显示原因和相同条件下的恢复操作，主窗折叠日志后仍能查看并操作。按既有恢复规则匹配项目和原任务。 |
| overflow、long-text | 四个调试按钮与长名称 · A05 | 🧪 backstop | 以默认主窗和 404 pt 菜单栏宽度分别检查中文和英文的四个完整同排按钮，验证锁定字段仍可用悬停、点击和键盘查看完整原名。 |
| populated、partial、error | 快捷键与原生焦点 · A03、A05、A21 | 🧪 backstop | 在候选构建操作前台主窗、日志焦点和菜单栏，验证四个键位、禁用和重复触发、后台无动作、Tab 与 Shift-Tab 的原生焦点顺序。 |
| populated、long-text | 应用语言与系统外观 · A05、A23 | 🧪 backstop | 打开四个界面，在中文、English、跟随系统间切换，验证即时文案、既有错误和自有提示、原值与偏好持久化。深浅外观检查层级、可访问标签和控件。 |
| populated、partial、error | 通用偏好 · A04 | ✅ covered | 设置只有两类。保留已保存的启动偏好。关闭启动后显示主窗口时可仅启动菜单栏，发现待恢复记录时打开主窗并等待用户操作。登录项显示实际注册、待批准或失败状态。 |
| loading、partial、error | SDK/FVM · A24 | ✅ covered | 检查时显示进度，展示与会话实际执行的 SDK 和版本一致。无效项目 FVM 时说明原因并阻止启动，锁定期间显示实际 SDK 和修改条件。 |
| empty、loading、populated、partial、error、overflow | 环境检测 · A25 | ✅ covered | 用户主动启动检测，显示进度。三类摘要逐项反映诊断结果，完整输出保留原始内容并可查看长行。检测失败有原因和重试入口，SDK 或项目已变化时不展示过期结果。 |
| populated、long-text | 关于及品牌 · A04、A06、A26 | 🧪 backstop | 检查独立窗口、真实构建信息、上游版权、三个链接的打开动作，以及 Dock 和单色菜单栏模板在两种外观下的辨识度。 |

自动化完整覆盖的预期直接记录通过。对剩余原生界面行为关联候选构建、截图或实测步骤。Phase 05 继续发布验收及目标系统复验。[验收方法](../../../../docs/04-ACCEPTANCE.md#如何使用)

## Registry Safety

| 注册表 | 使用情况 | 安全门槛 |
| --- | --- | --- |
| 不适用 | 使用系统原生控件和仓库内已验收的设计资产 | 不适用 |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: FLAG，沿用既有原生窗口的信息层级和 Run 主操作。
- [x] Dimension 3 Color: FLAG，沿用系统语义色及既有主、次表面与强调角色。
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval** · 2026-11-13，独立审查通过。
