# 阶段 07 · Figma 实施基线

2026-11-15 在 Figma 桌面端只读核查已确认的 v0.2 设计。文件入口见本地 `.private/FIGMA-HANDOFF.md`；下列尺寸和字体来自设计面板。画板例图和后续原始导出留在 `.private/phase-07/`，验收结论与差异说明可提交。此文是设计取证，不是 App 的对照通过记录。

| 页面或对象 | 直接依据 | 取证结论 |
| --- | --- | --- |
| `03 · 设置窗口` → `FlutterRunlet · 设置原型` | `设置 · 通用`（起始节点 `117:238`）、`设置 · Flutter`（`165:543`）、`设置 · 关于`（`165:609`）、选择语言（`165:662`）、Flutter Doctor 输出示例（`165:670`）、选择 SDK 文件夹示意 | 三页中文深色；外框 520 × 520 pt、圆角 13 pt；语言面板 310 × 148 pt、圆角 8 pt；Doctor 输出示例 310 × 160 pt、圆角 8 pt。SDK 文件夹画板辅助定位，交互以实际原生选择器验收。 |
| `04 · 关于窗口` | `关于 FlutterRunlet`（`174:428`）和 `关于 · 公用组件` | 一张独立中文深色窗口，400 × 412 pt，圆角 14 pt；品牌、版本、反馈和项目链接有公用组件。 |
| `设置 / 检查与更新` | `07-UI-SPEC.md` 的 11 个变体 | 待检查、检查 1–4、有新版、更新 1–4、完成。待恢复、稍后、最新、无 Release 和错误等分支按共用版式验收，不能当成 Figma 原图。 |
| 英文 | `选择语言` 实际列出「跟随系统」「简体中文」「English」；`设置 · 原型选项` 11 个变量，只有 `Value` 一列，语言字符串为「跟随系统」 | 所查两页及其公用组件未发现完整英文画板或中英文字模式。`English` 是选择项，`Flutter`、`FlutterRunlet`、`Github` 等是原组件中的拉丁文字。以中文画板的层级、尺寸、组件和实测字体角色为基准，用 `Localizable.xcstrings` 现有译文并补足缺项。长标签/真实版本导致的适配逐项记录；禁止把英文实拍说成 Figma 导出。 |
| 浅色 | `FlutterRunlet · 原型配色` 的「深色」「浅色」列 | 所查两页未发现独立浅色画板。按下列变量复用对应角色；未绑定变量的层按同角色处理，原型固定色（例如白色滑块）留原色并核实。需要浅色对照图时，在本地隔离副本套用既有模式，不改确认源稿；未生成参考图时用变量采样与实拍证明。 |

设置「关于」画板卡片为品牌和更新按钮、状态反馈、三个项目链接三段；MIT 与 Svame 的独立可见行在独立关于画板。D-09 的应用内署名以确认稿为依据，使用同一个本地信息模型。设置页用「项目许可证」现有链接的帮助文字及辅助功能说明提供同一 `MIT` 与 `Svame` 信息，初始画面仍保持三段结构。点击仍打开现有 `LICENSE`；该文件载有仓库的 Atypiape 版权，不能当作应用内 Svame 署名的证据。上游归属一并保留。

## 文字图层（字号 / 行高）

| 对象 | 从设计面板读到的值 |
| --- | --- |
| 设置关于 | 窗口标题 Noto Sans SC Medium 14/23；正文「关于」Medium 17/23；应用名 Medium 14/23；卡片版本 Medium 11/16；更新按钮 Medium 11/16；反馈 Medium 12/19；Github 链接 Medium 11/17；侧栏「关于」Medium 13/19。 |
| 设置通用 | Noto Sans SC Regular：界面语言、登录开关标题 13/19；当前语言和「启动与项目」分组标题 12/19；登录说明 11/16。 |
| 选择语言面板 | SF Pro Semibold：「选择语言」标题 14/23，「English」和「跟随系统」菜单项 11/16；English 行 284 × 26 pt、圆角 5 pt。 |
| 设置 Flutter | SF Pro Semibold：页标题 17/23，SDK 分组标题及路径值 12/19，当前来源、可用状态、检查环境及侧栏版本示例 11/16。Figma 显示 SF Pro 的混排图层仍需检查实际中文回退。 |
| 环境输出示例 | `[✓] Flutter` 为 SF Pro Regular 12/19。画板示例与可选择、滚动的实际原始 CLI 输出分开；实际原文保留现有等宽字体。 |
| 独立关于 | Noto Sans SC Medium：窗口标题 12/18，应用名 26/32，版本 12/18，简介 13/19，更新按钮 11/16，更新反馈 11/17；Noto Sans SC Regular：MIT 许可证与 Svame 署名 11/17。 |

测量是按实例选的图层，不能把一种字体套到全部角色：复用 `RunletType` 的已打包 Noto Sans SC／Roboto Mono 和系统 SF Pro；同名实例或变体的差异按实例抄录。英文没有原图时，保留对应层级、字重与行高，检查拉丁字形及中文回退。尚未逐项测量的变体及混合字体区段在 07-01 继续核对，禁止由默认 SwiftUI 字号推算。

英文有现行本地化依据：`General`、`Follow System`、`Launch at Login`、`Show Main Window on Launch`、`Remember Last Opened Project`、`Prefer Project FVM`、`Environment Check Output`、`About FlutterRunlet`、`Documentation`、`Project License`。用这些长标签做宽度检查；按画板角色为更新、说明及错误补译。SDK 路径和 Doctor 原始输出保留数据语言。

## 图标与控件

| 图标或控件 | 已核对 |
| --- | --- |
| 导航 | 齿轮、代码尖括号、圆形信息字样；Flutter 代码外框 15 × 15 pt，实选矢量描边 1.06 pt；关于图标是 SF Pro Regular 14/23 的文字图标层。按选中及未选值核对位置、色彩、基线。 |
| 检查更新 | 14 × 14 pt 操作图标外框，实选循环箭头矢量 9.33 × 9.33 pt、中心描边 1.17 pt、色 `text/on-accent`；各旋转关键帧按变体取原图。 |
| 三个项目链接 | GitHub 轮廓、文档页、天平。量到的设置文档及独立关于 GitHub、许可图标均为 13 × 13 pt 外框、描边 0.92 pt；以确认图层形状为准。 |
| 品牌、开关和菜单 | 两处均使用随 App 打包的品牌标志。通用开关轨道 32 × 18 pt、圆角 9 pt，关闭固定 `#616673`、开启 `action/accent`，滑块固定 `#FFFFFF`、12 × 12 pt。语言下拉箭头容器 15 × 15 pt、实选矢量描边 1.06 pt、色 `text/secondary`。验收前补录其余图标及品牌各实例的边界、固定色/绑定和基线。 |

## 批准稿的语义颜色（深色 / 浅色）

| 变量 | 深色 | 浅色 |
| --- | --- | --- |
| `background/desktop` | `#101822` | `#DCE7F1` |
| `background/window` | `#171E28` | `#F5F8FC` |
| `surface/toolbar` | `#1D2632` | `#EAF0F7` |
| `surface/raised` | `#222D3A` | `#FFFFFF` |
| `surface/field` | `#202A37` | `#FFFFFF` |
| `surface/disabled` | `#1B242F` | `#E8EEF5` |
| `surface/console` | `#111822` | `#EDF2F8` |
| `surface/selected` | `#223D50` | `#D7EAF5` |
| `border/default` | `#344252` | `#B9C8D9` |
| `border/divider` | `#2B3848` | `#D4DFEA` |
| `border/action` | `#4E6C81` | `#54778D` |
| `text/primary` | `#F0F5FB` | `#192638` |
| `text/secondary` | `#B0BDCD` | `#46576B` |
| `text/muted` | `#8594A7` | `#546579` |
| `text/disabled` | `#738194` | `#647388` |
| `text/on-accent` | `#0B2230` | `#FFFFFF` |
| `action/accent` | `#55CFFF` | `#006D98` |
| `status/success` | `#6DD6A6` | `#136548` |
| `status/success-surface` | `#1D3A35` | `#DDEFE7` |
| `status/warning` | `#F6CA80` | `#79510F` |
| `status/warning-surface` | `#342D24` | `#FFF2D8` |
| `status/error` | `#FFABA1` | `#963B35` |
| `status/error-surface` | `#3C292D` | `#FFE7E3` |
