---
phase: "05"
slug: stability-recovery-release
status: approved
shadcn_initialized: false
preset: none
created: "2026-11-13"
reviewed_at: "2026-11-13"
---

# Phase 05 · G3 原生界面验收契约

沿用 G0 和 Phase 04 验收通过的布局、文案与交互。按 D-11 对最终 Release 候选重跑受影响界面的自动检查。涉及既有布局、视觉或交互的调整须经用户明确确认。[阶段决定](05-CONTEXT.md) · [Phase 04 界面契约](../04-macos/04-UI-SPEC.md) · [Phase 04 验收](../04-macos/04-P4-ACCEPTANCE.md) · [G0 画板](../../../../docs/design/FIGMA-HANDOFF.md#画板清单)

## Design System

| 项目 | 已验收基线 |
| --- | --- |
| Tool | none |
| Preset | 不适用 |
| 控件 | SwiftUI 优先，AppKit 按需补充，沿用系统窗口、选取器、开关、按钮、焦点和辅助功能名称。 |
| 图标 | 系统符号、已验收的 Dock PNG 和同源单色菜单栏 template。 |
| 字体 | macOS 系统 SF Pro，CLI 原文使用系统等宽字体。 |

主窗默认外框 640 × 580 pt，无侧栏。项目、配置与设备、同排四个调试按钮、会话和浏览器入口、可折叠日志及底部状态沿用现有顺序。菜单栏面板宽 404 pt，高度随内容，与主窗共享会话。设置外框 672 × 520 pt，142 pt 左导航仅有「通用」「Flutter」，SDK 信息位于 Flutter 页。关于约 440 × 480 pt，作为独立窗口显示。分别记录窗口外框和内容尺寸，系统标题栏、控件大小及焦点反馈以实际运行环境为准。 [界面规格](../../../../docs/design/UI-SPEC.md) · [设计系统](../../../../docs/design/DESIGN-SYSTEM.md)

菜单栏分组间距 12 pt，主窗两侧各留 20 pt。以 Phase 04 已验收的原生布局尺寸复验这两处。 [Phase 04 界面契约](../04-macos/04-UI-SPEC.md#spacing-scale)

## Spacing Scale

| 间距 | 用途 |
| --- | --- |
| 4 pt | 字段标题和值之间 |
| 8 pt | 同排按钮、会话内容和日志区内 |
| 16 pt | 主窗区块、配置与设备双列、菜单栏内边距 |
| 24 pt | 设置内容内边距 |

## Typography

| 角色 | 尺寸 | 字重和行高 |
| --- | --- | --- |
| 正文、标签、动作和状态 | SF Pro 13 pt | 常规，系统行高 |
| CLI 日志和详细输出 | 系统等宽 12 pt | 常规，系统行高 |
| 原生窗口和设置标题 | 系统标题角色 | 常规或半粗体，系统行高 |

## Color

| 角色 | 用途 |
| --- | --- |
| 主表面 | 系统窗口背景 |
| 次表面 | 原生菜单栏面板、设置导航和日志辅助表面 |
| 强调 | 系统强调色用于可执行的 Run，原生选中与焦点采用系统反馈 |
| 品牌与告警 | 青蓝用于已验收品牌标志。运行、错误和恢复失败采用语义色并配文字 |

外观随系统切换，深浅色使用相同布局和层级。菜单栏图标由系统着色。 [Phase 04 设计基线](../04-macos/04-UI-SPEC.md)

## Copywriting Contract

| 元素 | 简体中文 | English |
| --- | --- | --- |
| 无项目 | 未选择项目 · 打开项目 | No project selected · Open Project |
| 调试动作 | 运行 · 停止 · 热重载 · 热重启 | Run · Stop · Hot Reload · Hot Restart |
| 停止和恢复 | 正在停止 · 正在恢复环境 | Stopping · Restoring Environment |
| 恢复提示和入口 | 环境恢复失败 · 重试恢复 · 打开待恢复项目 | Environment Recovery Failed · Retry Recovery · Open Project for Recovery |
| 退出提示和动作 | 停止会话并退出 FlutterRunlet？· 停止并退出 · 取消 | Stop the session and quit FlutterRunlet? · Stop and Quit · Cancel |
| 启动偏好 | 启动后显示主窗口 · 记住最近打开的项目 | Show Main Window on Launch · Remember Last Opened Project |
| 日志操作 | 清空日志 | Clear Logs |
| 关于链接 | 项目主页 · 使用文档 · 项目许可证 | Project Home · Documentation · Project License |

错误提示保留当前失败原因及可执行入口。项目、配置、设备名称及 CLI 原文保持原值，沿用 VM Service 令牌遮罩。应用自有文案随当前语言更新，系统控件提供的文字遵循系统语言。 [本地化资源](../../../../FlutterRunlet/Localizable.xcstrings) · [Phase 04 文案基线](../04-macos/04-UI-SPEC.md#copywriting-contract)

## UI Considerations

| 类别 | 界面或元素 | 状态 | 验收条件 |
| --- | --- | --- | --- |
| empty、loading、error、long-text | 主窗和菜单栏的项目、会话与恢复入口 · A13–A16、A22、D-01–D-03 | ✅ covered | 主窗和菜单栏共享会话和可执行条件。等待 VM Service 时禁用热操作和浏览器入口，连接后 Run 禁用且 Stop 可用。启动失败或断线退出显示原因或恢复入口。后置失败的原因和操作可换行并置于日志外。最终 Release 运行中强退前关闭两项启动偏好，重启仍自动打开主窗并显示待恢复项目。打开该项目并手动执行原后置任务，确认恢复成功才清除风险。Debug 后置暂停点已写入 `test` 而未确认任务成功时，重启仍显示恢复风险。 |
| loading、error | 运行中退出确认 · A28 | ✅ covered | 取消保留当前会话。停止并退出等待受管进程退出及后置任务，恢复失败时保留应用、原因和重试入口。 |
| empty、loading、populated、overflow、zero-one-many | 日志区域与调试控制 · A27、A30、D-04–D-06 | ✅ covered | 最终 Release 在隔离样例的真实 Flutter 会话中运行 30 分钟。以带递增编号的中英文短行检查 64 KiB 裁剪后的 UTF-8、清空边界和新增输出。最后 5 分钟约 200 行/秒时实际触发清空、折叠、展开和停止，逐项测得 1 秒内反馈，停止以首次进入 `Stopping` 状态为准。重开日志仍无清空前的输出。采样主进程 RSS，低频最后 5 分钟中位数为基线，高频峰值增长不超过 50 MiB 且无持续上升。 |
| 最低部署目标 | 最终 Release 主程序及 worker · A31、D-08 | ✅ covered | 核对两个 Mach-O 各架构最低部署目标均为 15.0。按 2026-11-14 用户决定取消 macOS 15 运行验收，记录该系统的运行兼容性未验证。 |
| loading、error、long-text | 关于窗口、版本和浏览器入口 · A26、D-10 | 🧪 backstop | 核对独立原生窗口、实际构建信息和上游版权。点击项目主页、使用文档和项目许可证，观察系统默认浏览器分别接收已确认的仓库、README 和 LICENSE 目标。匿名可访问性在公开分发前复验。 |
| error、overflow、long-text | 受影响界面的语言、外观和控件 · G3、D-11 | 🧪 backstop | 结合 G0 画板及 Phase 04 已通过证据，复验最终 Release 中受影响的窗口和状态。核对双语可读性、深浅色语义层级、按钮标签完整及原生焦点。长项目、配置和设备名称单行省略，锁定时仍可用全名入口。自动证据完整覆盖的预期直接记录通过，人工复核只提交受影响界面中的新增或改变差异及其他自动化未覆盖的预期。 |

每条证据关联 A 编号、候选提交或构建、受测系统、可复现步骤与判定。原生差异记录位置、原因和验证结果。 [验收规则](../../../../docs/04-ACCEPTANCE.md#如何使用) · [技术调研](05-RESEARCH.md)

## Registry Safety

本阶段沿用系统原生控件、仓库内品牌资产和既有 UI，无外部组件注册表依赖。

## Checker Sign-Off

- [x] Dimension 1 Copywriting · PASS
- [x] Dimension 2 Visuals · PASS
- [x] Dimension 3 Color · FLAG，沿用已验收的 macOS 系统语义色
- [x] Dimension 4 Typography · PASS
- [x] Dimension 5 Spacing · PASS
- [x] Dimension 6 Registry Safety · PASS
- [x] Dimension 7 Inventory Provenance · PASS

**审批状态** 2026-11-13 独立校验通过。
