# 阶段 07 · 视觉与取证基线

2026-11-15 从 v0.2 批准稿只读复测。前次桌面读数见 [07-FIGMA-EVIDENCE](07-FIGMA-EVIDENCE.md)，状态范围按 [07-VALIDATION](07-VALIDATION.md#接入真实更新前的对照)、[07-UI-SPEC](07-UI-SPEC.md) 和 [D-09～D-12](07-CONTEXT.md#沿用的界面与运行行为)。当同名图层的既有记录与批准实例有差异时，采用下列实例读数。源稿入口留在本地私有交接。

## 原始参考与截图边界

所有 P07-F/P07-U 为中文深色批准稿导出。证据 ID 对应本机 `.private/phase-07/figma-originals/` 内同名 2× PNG，保留原始字节。`figma-1x/` 有 18 张同节点 1× PNG，当前 1× 显示器截图优先与它配对。两套均使用 Figma 节点边界、sRGB IEC61966-2.1 和 RGBA。私有 `exports.tsv` 记录节点、尺寸、档名和 SHA-256。若必须从 2× 生成 1×，在 sRGB 按 2:1 等比降采样、记录滤镜和派生 ID，并保留 2× 原图与 1× 原始 App 截图。

坐标用逻辑 pt，原点为导出节点左上，x 向右、y 向下。`(x,y,w,h)` 为布局框，矢量范围不含居中描边。比较前先对齐外框或指定部件的原点，再看内容框、标题栏及局部。窗口外系统阴影、圆角抗锯齿、原生交通灯、窗口边缘和系统弹层锚点单独留区域证据。应用可控几何相差超过 1 pt 时先复核或修正，配色、线形、字重、裁切和状态逐项记录。原图叠图匹配语言、外观、数据及帧，叠图区域限于原图确实覆盖的范围。

| 证据 ID | 节点与实例 | 逻辑尺寸 | 原图内容与冻结数据 |
| --- | --- | --- | --- |
| P07-F01 | 总框 `117:238`，标题栏 `165:476`，侧栏 `165:482`，正文 `165:499` | 520 × 520 | 通用整窗。跟随系统，登录关、显示主窗开、记住项目开，侧栏 `v0.2.0 (build 256)`。 |
| P07-F02 | 总框 `117:260`，标题栏 `165:537`，侧栏 `165:543`，正文 `165:560` | 520 × 520 | Flutter 整窗。`当前：自动`、`~/Developer/flutter`、`Flutter 3.x  ·  Dart 3.x`、`可用`，FVM 开，Doctor 空闲。 |
| P07-F03 | 总框 `145:230`，标题栏 `165:609`，侧栏 `165:615`，正文 `165:632` | 520 × 520 | 设置关于整窗。`FlutterRunlet`、`v0.2.0 (build 256)`、`检查更新`、`检查 FlutterRunlet 是否有新版本`、`Github`／`使用文档`／`项目许可证`。 |
| P07-F04 | 总框 `174:428`，内容 `174:433`，按钮 `174:445` | 400 × 412 | 独立关于整窗。同名、初始版本、更新按钮、反馈和三个链接。另有 `轻量 Flutter 运行与调试工具`、`MIT 许可证`、`Copyright (c) 2026 Svame`。 |
| P07-F05 | 总框 `117:365`，实例 `165:662` | 310 × 148 | 「选择语言」独立弹层，`跟随系统`／`简体中文`／`English`。叠图限弹层内容。 |
| P07-F06 | 总框 `117:373`，实例 `165:670` | 310 × 160 | 「Flutter Doctor 输出 · 示例」独立弹层，`[✓] Flutter`、`[✓] Xcode`、`[✓] Android toolchain` 和「关闭」。真实完整输出独立取证。 |
| P07-F07 | 总框 `117:380`，实例 `165:677` | 310 × 108 | 「选择 Flutter SDK 文件夹 · 示意」，`~/Developer/flutter` 和「完成」。真实 `NSOpenPanel` 以系统实拍验收。 |
| P07-U01～P07-U11 | 组件集 `153:285`，下方逐帧表 | 各 116 × 30 | 两处复用的按钮及图标。对动态状态的 Figma 原图叠图只覆盖按钮，整窗背景、反馈和数据按对应实例及变量核查。 |

两处「关于」的初始反馈绑定同一字符串变量，品牌版本同绑 `显示的应用版本`。原型在检查完成写入 `检测到新版本：v1.5.0`，演示更新结束写入 `v1.5.0` 与 `已是最新版本`。检查和更新中，反馈各写入与按钮相同的 `检查中...`／`更新中...`。侧栏也绑定演示版本变量。受控对照采用这些演示文字和变量，实际版本与构建号始终读运行 App 的 Bundle。对启用应用真实数据的实拍，按实例核查版本角色与空间，并记录文字差异。

## 三张设置画板

| 区域 | 实例和几何 | 属性 |
| --- | --- | --- |
| 窗口外框 | 三窗 `(0,0,520,520)` | 圆角 13，`background/window`，1 pt 内描边 `border/divider`。 |
| 设置标题栏 | `165:476`／`165:537`／`165:609` 均 `(1,1,518,47)`。标题 `(76,13,28,23)`，交通灯组 `(17,19,47,11)`，分隔线 `(1,48,518,1)`。 | `surface/toolbar`，横 16、纵 12、组间 12；三个 11 × 11 圆点间隔 7，固定 `#FF6159`／`#FFBF33`／`#29CC47` 为 Figma 系统示意。 |
| 主体与侧栏 | 主体 `(1,49,518,470)`；三侧栏 `165:482`／`165:543`／`165:615` 都 `(1,49,116,470)`。竖分隔 `(117,49,1,470)`。 | `surface/toolbar`，横 10、纵 14，导航和底部版本撑开。导航组 `(11,63,96,111)`；版本框 `(11,489,93,16)`。 |
| 导航行 | 通用、Flutter、关于依次为 `(11,63,96,33)`、`(11,100,96,33)`、`(11,137,96,37)`。 | 行距 4，横 9、纵 7，图标到文本间距 8。选中行圆角 6、`surface/selected`，选中文字 `text/primary`，通常图标 `action/accent`。设置关于的未选通用保留蓝齿轮及 Medium 字重，行本身无选中色，见 `I165:615;164:317`。 |
| 内容实例 | `165:499`／`165:560`／`165:632` 都 `(118,49,401,470)`。正文标题依次 `(133,63,34,23)`、`(133,63,56,23)`、`(133,63,34,23)`。 | 横 15、纵 14、纵向间隔 7；内区宽 371。 |
| 通用卡片 | 语言标题 `(133,93,24,19)`，卡片 `(133,119,371,47)`。启动与项目标题 `(133,173,60,19)`，卡片 `(133,199,371,126)`。 | 卡片圆角 8，`surface/field`，内描边 1 `border/divider`。内容行横 12、纵 8，说明间距 1，左右组间 8。登录／显示／记住三行高 52／35／35，分隔线 y=252、288。 |
| 通用语言与开关 | 语言选择框 `I165:499;164:339` 为 `(402,128,89,29)`。三个开关 x=459，y=217／261.5／297.5。 | 选择框圆角 5，横 8、纵 4、图文距 8；`surface/raised`，1 pt 内描边 `border/divider`。 |
| Flutter SDK | 分组标题 `(133,93,68,19)`、卡片 `(133,119,371,116)`。来源／路径／版本行高 42／35／35。来源操作组 `(344,128,147,26)`、路径文字 `(384,171,107,19)`，版本与「可用」框为 `(341,207,120,19)`／`(469,208.5,22,16)`。 | 同卡片样式与行内边距；自动、手动各 42 × 26、组间 4、圆角 5。按钮横 9、纵 4，`surface/raised` 加 1 pt `border/divider`。来源是独立状态文字，原稿两按钮同色。 |
| Flutter 手动路径 | `I165:560;164:388` 为条件显示的「选路径」，53 × 26，圆角 5。`164:389` 文字框在按钮内 `(10,5,33,16)`。 | `surface/raised` 加 1 pt `border/divider`，文字 Noto Sans SC Medium 11/16。显示受「手动 SDK」变量驱动，连接 `117:380`。隐藏图层保存的 x=418 是未重排局部值，显示时按路径行内布局预留其宽度。 |
| Flutter FVM 与 Doctor | FVM 标题 `(133,242,27,19)`、卡片 `(133,268,371,54)`、开关 `(459,286,32,18)`。Doctor 标题 `(133,329,48,19)`、卡片 `(133,355,371,44)`、检查按钮 `(427,364,64,26)`。 | 卡片样式同上，检查按钮圆角 5、`action/accent` 配 `text/on-accent`、1 pt `border/divider`。 |
| Flutter 检测结果 | `I165:560;164:410` 受「检测结果」变量控制，隐藏存储框 483 × 100。`164:411` 成功说明 11/16，`164:412`「完整输出」64 × 26、圆角 5、横 9、纵 4。 | 成功说明为 Noto Sans SC Regular、`status/success`，完整输出按钮 Noto Sans SC Medium 11/16、`surface/raised`、1 pt `border/divider`。隐藏存储宽 483 超出可见 371 pt 卡片，实际结果按卡片可用宽度排版，长原文在独立面板可滚动与选中。 |
| 设置关于卡片 | `I165:632;164:420` 为 `(133,93,371,154)`，圆角 8。品牌区 `(134,94,369,65)`，反馈 `(134,160,369,37)`，三链接 `(134,198,369,48)`。 | 段间 1 pt 线在 y=159／197。品牌横纵 12，项目间距 10；反馈横 12、纵 9；链接横 12、纵 10，间隔 8。 |
| 设置关于品牌与按钮 | 标志 `(146,112.325,28.35,28.35)`；名称 `(184.35,106,91,23)`，版本 `(184.35,131,93,16)`；按钮 `(375,111.5,116,30)`；反馈文字 `(146,169,176,19)`。 | 品牌及按钮垂直居中。名称、版本间距 2，反馈 `text/primary`。 |
| 设置关于链接 | 依次 `(146,207.5,74,29)`／`(228,207.5,83,29)`／`(319,207.5,94,29)`。 | 三段结构中的第三段保留三个链接原位，MIT 与 Svame 由许可证帮助文字及辅助功能说明提供。 |

## 独立关于与辅助画板

| 区域 | 实例与边界 | 属性 |
| --- | --- | --- |
| 独立窗与标题栏 | `174:428` 外框 400 × 412，标题栏 `(1,1,398,35)`、标题 `(148.5,10,103,18)`、关闭按钮 `(17,13,11,11)`，分隔线 `(1,36,398,1)`。 | 圆角 14、1 pt `border/default`。标题栏 `surface/toolbar`，标题居中，关闭按钮固定红为原型示意。 |
| 独立窗内容 | `174:433` 为 `(1,37,398,374)`，应用组 `(21,55,358,153)`，更新组 `(21,223,358,54)`。 | 横 20、纵 18、顶层组距 15。应用组间距 6，更新组间距 7，均水平居中。 |
| 独立窗品牌 | `174:435` 品牌底座 `(167,55,66,66)`，`182:485` 标志 `(177.95,65.95,44.1,44.1)`。名称 `(124.5,127,151,32)`、版本 `(149.5,165,101,18)`、简介 `(118,189,164,19)`。 | 底座圆角 17，`surface/raised`、1 pt `border/divider`。版本、简介为 `text/secondary`。 |
| 独立窗更新与链接 | 按钮 `(142,223,116,30)`，反馈文字 `(119.5,260,161,17)`，分隔 `(21,292,358,1)`，链接组 `(21,308,358,29)`。 | 链接依次 `(66.5,308,74,29)`／`(148.5,308,83,29)`／`(239.5,308,94,29)`。反馈 `text/secondary`。 |
| 独立窗许可与署名 | `174:465` 为 `(21,352,358,37)`，两行相隔 3。`174:466`「MIT 许可证」`(172.5,352,55,17)`；`174:468`「Copyright (c) 2026 Svame」`(131.5,372,137,17)`。 | 第一行 Noto Sans SC Regular 11/17、`text/secondary`、基线 y=364.90；第二行 SF Pro Regular 11/17、`text/muted`、基线 y=384.41。 |
| 语言面板 | `165:662`。标题 `(13,13,56,23)`；三行均为 284 × 26、x=13，y=43／76／109，文字各在行内 `(10,5)`。 | 310 × 148，圆角 8，内边距 12、间隔 7 和 1 pt 内描边；菜单行圆角 5、`surface/raised`。 |
| Doctor 示例面板 | `165:670`。标题 `(13,13,173,23)`，三条状态 x=13、y=43／69／95、高 19；「关闭」`(13,121,42,26)`。 | 310 × 160，同弹层样式；三条输出为 `status/success`。 |
| SDK 示意面板 | `165:677`。标题 `(13,13,201,23)`；路径 `(13,43,107,19)`；「完成」`(13,69,42,26)`。 | 310 × 108，同弹层样式，路径为 `text/secondary`。原生目录选择器的布局、按钮和取消回焦按实机记录。 |

三个辅助面板均用 `surface/toolbar` 与 1 pt `border/divider`，面板可控按钮使用 `surface/raised`、1 pt 描边、圆角 5、横 9／纵 4。系统弹层边界单列。

设置「关于」与独立窗的六个链接实例均读到原型点击目的地，与 `AboutInformation.Destination` 一致。项目、README 与 LICENSE 实际请求均返回 HTTP 200，公开 LICENSE 原文与仓库文件 SHA-256 一致。画板的 Svame 应用内署名、许可证文件的 Atypiape 版权和仓库保留的上游归属分别核对。设置许可证提示、辅助功能说明以及真实点击各需实拍证据。 [项目](https://github.com/atypiape/flutter-runlet) · [README](https://github.com/atypiape/flutter-runlet/blob/main/README.md) · [LICENSE](https://github.com/atypiape/flutter-runlet/blob/main/LICENSE)

## 字体、图标与颜色

表内字号/行高均为 pt。Noto Regular/Medium 的实例字重为 400/500；Figma 读到 SF Pro Regular/Semibold 为 400/590。颜色未单列的层用 `text/primary`（主标题、行标题、主动作标签）或已列明的实际角色。文字基线按同一文本层绝对边界的可编辑 SVG `tspan y` 复测，局部基线加文字框 y 即为该画板坐标。

| 实例或角色 | 批准实例字体 |
| --- | --- |
| 设置标题及正文标题 | 三窗标题栏「设置」Noto Sans SC Medium 14/23；通用、设置关于页标题 Noto Sans SC Medium 17/23，基线局部 18.30（绝对 y=81.30）；Flutter 页标题 SF Pro Semibold 17/23，基线局部 17.54（y=80.54）。 |
| 侧栏导航与版本 | 通用、关于 Noto Sans SC 13/19（选中 Medium，未选 Regular，设置关于的通用实例例外）；Flutter SF Pro 13/19（选中 Semibold，未选 Regular）；底部版本 SF Pro Regular 11/16、`text/secondary`。 |
| 通用表单 | 语言、启动与项目 Noto Sans SC Medium 12/19、`text/secondary`；界面语言及三个偏好标题 Noto Sans SC Regular 13/19；当前语言 Noto Sans SC Regular 12/19；登录说明 Noto Sans SC Regular 11/16、`text/secondary`。 |
| Flutter 表单 | Flutter SDK 和 FVM 标题 SF Pro Semibold 12/19，环境检测标题 Noto Sans SC Medium 12/19，均 `text/secondary`；SDK 来源、路径、版本与状态、FVM 标题均 Noto Sans SC Regular 13/19；路径、Flutter/Dart 版本 SF Pro Regular 12/19、`text/secondary`。 |
| Flutter 表单操作与反馈 | 自动、手动、选路径、检查环境、完整输出 Noto Sans SC Medium 11/16；当前来源、FVM 说明及成功说明 Noto Sans SC Regular 11/16；「可用」Noto Sans SC Medium 11/16、`status/success`；Flutter Doctor 行标题 SF Pro Regular 13/19。 |
| 三个辅助面板 | 三标题 Noto Sans SC Medium 14/23；菜单中文行与关闭／完成 Noto Sans SC Medium 11/16；English 行 SF Pro Semibold 11/16、实际基线局部 11.91；Doctor 三条示例 SF Pro Regular 12/19（Flutter 条目基线局部 13.77）；SDK 路径 SF Pro Regular 12/19。 |
| 设置关于文字 | 品牌 SF Pro Semibold 14/23、基线局部 16.48（y=122.48）；版本 SF Pro Regular 11/16；反馈 Noto Sans SC Regular 12/19。 |
| 独立关于文字 | 窗口标题 Noto Sans SC Medium 12/18；品牌 SF Pro Semibold 26/32、基线局部 25.24（y=152.24）；版本 SF Pro Regular 12/18；简介 Noto Sans SC Regular 13/19；反馈 Noto Sans SC Regular 11/17；许可与署名见上表。 |
| 两处链接及更新 | Github 链接 SF Pro Regular 11/17，中文两链接 Noto Sans SC Regular 11/17。两个实例的更新按钮与全部变体均用 Noto Sans SC Medium 11/16、`text/on-accent`。 |

批准稿将混排的「SDK 来源」「登录 macOS 后自动启动 FlutterRunlet」「检查 FlutterRunlet 是否有新版本」「关于 FlutterRunlet」「轻量 Flutter 运行与调试工具」「MIT 许可证」存成各自单一 Noto 字体段。纯拉丁品牌、版本、Flutter/FVM、路径等按各自 SF Pro 角色保留。英文保留对应角色与行高，纯拉丁采用该角色的批准字体，中文回落到已打包 Noto Sans SC 并核对混排基线。Figma 读数中所抽取的字体层未报告缺字，实际 macOS 回退和字体栅格在候选中核对，原始 Doctor CLI 输出按现有等宽样式保留可读、可选、可滚动。

| 部件 | 形状、边界与对齐 |
| --- | --- |
| 导航齿轮 | 容器 `(20,72,15,15)`，外矢量在容器内 `(1.875,1.875,11.25,11.25)`、中心孔 `(5.8125,5.8125,3.375,3.375)`，均 1.0625 pt 居中，颜色见各行实例。图标中心 y=79.5，通用选中文本基线 y=84.70。 |
| 导航代码与关于 | 代码容器 `(20,109,15,15)`，矢量 `(1.25,1.875,12.5,11.25)`，1.0625 pt 居中，中心 y=116.5；Flutter 选中文本基线 y=121.12。关于为 `ⓘ` 字层 `(20,144,14,23)`、SF Pro Regular 14/23，基线 y=160.48；同排文字盒 `(42,146,26,19)`。 |
| 语言向下箭头 | 容器 `(467,135,15,15)`，矢量局部 `(4.375,6.25,6.25,3.125)`，1.0625 pt 居中、`text/secondary`；选择文字基线 y=147.30。 |
| 通用与 FVM 开关 | `164:259` 的四个分类实例均为 32 × 18、圆角 9。关闭底色固定 `#616673`，开时覆以 `action/accent`。白滑块固定 `#FFFFFF`、12 × 12，关在 `(3,3)`、开在 `(17,3)`。布局中心按各行复测，隐藏开层和登录开关的可见性绑定可查。 |
| 品牌标志 | 两实例同源，设置 `182:690` 标志框 28.35 × 28.35，四矢量合围局部 `(0.3635,5.9971,27.4414,16.9010)`；独立 `182:485` 为 44.1 × 44.1，四矢量合围 `(0.5654,9.3288,42.6865,26.2904)`。四片固定色依次 `#19CFE6`／`#147BE8`／`#1B57D1`／`#18AEEB`，无描边。设置标志框中心 y=126.5 对齐品牌版本组，独立标志居中于 66 × 66 底座。 |
| 三个项目链接 | 两组图标均 13 × 13、各图形轮廓 0.92083 pt 居中、`text/secondary`。GitHub、文档、天平在容器内矢量范围分别 `(2.1667,1.95,8.6667,8.8833)`、`(2.7083,1.625,7.5833,9.75)`、`(1.625,1.625,9.75,9.2083)`。链接圆角 6，横 9、纵 5、图文距 6、`surface/field` 和 1 pt `border/default`。容器局部 `(10,8,13,13)`、文字局部 `(29,6)`，对应基线距按钮顶部 18.41（Github）／18.90（两中文）。 |
| 更新按钮与操作图标 | 两处默认实例 `I165:632;164:430`、`174:445` 和 11 变体皆 116 × 30、圆角 6、无描边、`action/accent`。图标 14 × 14，图文距 5，组水平居中。循环矢量 9.3333 × 9.3333、局部 `(2.3333,2.3333)`；下载箭头 9.3333 × 10.5、局部 `(2.3333,1.75)`。两种均 1.16667 pt 居中、`text/on-accent`。图标中心 y=15，文字盒 y=7、高 16，检查中字层实际基线 y=19.40。 |

批准页范围内无独立焦点、悬停或禁用样式图层。原型检查中与更新中按钮仍为强调蓝且无额外点击反应。受控状态沿用原图的活动外观，按 AX 和输入两条路径验证不可重复触发。真正不可用的 Doctor 或锁定登录项有 `surface/disabled`、`text/disabled` 等语义变量可对照，焦点显隐、回焦、键盘和系统设置入口按真实系统行为取证。全量向量路径、变量绑定、图层位置、字体段及条件层读数留在私有 `measurements/`。

| 语义变量 | 深色 | 浅色 |
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

## 共用更新变体

| 私有证据 ID | 变体根／符号／文字 | 文案 | 帧 | 操作图标与文字框的局部 x |
| --- | --- | --- | --- | --- |
| P07-U01 | `153:230`／`153:232`／`153:234` | 检查更新 | static | 26.5／45.5 |
| P07-U02 | `153:235`／`153:237`／`153:239` | 检查中... | f01，0° | 27／46 |
| P07-U03 | `153:240`／`153:242`／`153:244` | 检查中... | f02，90° | 27／46 |
| P07-U04 | `153:245`／`153:247`／`153:249` | 检查中... | f03，180° | 27／46 |
| P07-U05 | `153:250`／`153:252`／`153:254` | 检查中... | f04，−90° | 27／46 |
| P07-U06 | `153:255`／`153:257`／`153:259` | 更新到 v1.5.0 | static | 15／34 |
| P07-U07 | `153:260`／`153:262`／`153:264` | 更新中... | f01，0° | 27／46 |
| P07-U08 | `153:265`／`153:267`／`153:269` | 更新中... | f02，90° | 27／46 |
| P07-U09 | `153:270`／`153:272`／`153:274` | 更新中... | f03，180° | 27／46 |
| P07-U10 | `153:275`／`153:277`／`153:279` | 更新中... | f04，−90° | 27／46 |
| P07-U11 | `153:280`／`153:282`／`153:284` | 检查更新 | static | 26.5／45.5 |

角度按 Figma 属性的正负号记录。旋转只作用于符号组，外框与文字不动。两组均由 200 ms 触发下一关键帧，帧间采用 180 ms 线性 Smart Animate，末帧按原型转换结果。连续实拍要能读出位相顺序和无跳帧的循环，状态持续时间随实际操作。P07-U11 的按钮返回初始轮廓，完成态以反馈和版本变更共同判定。

## 参考类型和适配

- **原图** 使用 P07-F/P07-U，限定相同语言、外观、示例数据和帧。部件级原图只检查对应部件。动态更新状态的整窗用同窗 F03/F04 的布局锚点，加对应的变量状态与当前实拍。
- **组件/变量** 使用对应画板的角色、颜色变量、原有数据和已记录度量。两批准页和公用组件未找到独立英文或浅色画板。英文依据 `FlutterRunlet/Localizable.xcstrings` 的 `General`、`Follow System`、`Launch at Login`、`Show Main Window on Launch`、`Remember Last Opened Project`、`Prefer Project FVM`、`Environment Check Output`、`About FlutterRunlet`、`Documentation`、`Project License` 等现有长标签，新增状态使用规格语义补译。实测英文长标签、说明、多位版本与真实长路径；字宽变化时记录可控布局适配。浅色以同角色变量替换配色，品牌四色、白滑块和关闭灰保持固定。若制作本地派生图，记录节点、所用模式、固定色、导出倍数及派生 ID。
- **系统/实测** 使用当次真实窗口、原生区域截图、键盘录像／连续帧、AX 树、链接落地或等价行为记录。适用例都留下自身同语言同外观的实拍。截图绑定候选提交、App 版本与构建号、macOS 版本、显示比例、用例 ID 和帧；脱敏记录保存差异及具体位置。锁定登录、原生目录、键盘和系统窗口边缘按 [阶段 06 的原生复核](../06-main-window-menu-bar/06-UI-REVIEW.md) 的区域留证做法执行。

## V01–V05 逐状态矩阵

语言和外观是主证据截图的最终状态。语言切换的前置窗口按各行指定的起始语言另拍；英文和浅色始终检查各自截图。`general`、`flutter`、`settings-about` 分别指设置三页。`about` 指独立关于，`install-confirm` 和 `recovery-feedback` 指升级流程产生的独立窗口。静态帧记为 `static`，旋转位相记为 `f01`–`f04`，连续序列记为 `sequence`。四个关键帧的 ID 在状态名后加入帧号。每行的截图、录像或区域索引以用例 ID 命名，关联本次操作前后及所用输入；候选视觉签核按行登记结果。`N/A` 保留具体原因，`REQUIRED` 按证据列复拍。

冻结原型输入采用 P07-F01～F07 的示例文字、路径和 `v0.2.0 (build 256)`，新版 `v1.5.0`。实机专用长版本统一使用 `v12.34.567 (build 123456)`，手动长路径用隔离夹具内含空格的 `Flutter SDK Fixtures/2026 channel beta/flutter`，实际完整路径只在本地证据中保留。Doctor 长输出夹具保留成功标记、实测行数及首尾标识并传给真实视图，故障夹具固定退出状态和可用原文。正式更新前的检查、等待、安装与回退使用受控状态和故障输入；真实网络、安装与进程回退证据在相应验收项另取。旋转静态取图固定相位，连续录像解除相位固定并延长对应状态。截图机的语言、外观、缩放倍率、实际 Bundle 和候选提交在每轮采集前记录。

| 组 | REQUIRED | N/A | 合计 |
| --- | ---: | ---: | ---: |
| V01 | 76 | 4 | 80 |
| V02 | 92 | 0 | 92 |
| V03 | 76 | 16 | 92 |
| V04 | 136 | 0 | 136 |
| V05 | 136 | 8 | 144 |
| 合计 | 516 | 28 | 544 |

### V01 通用偏好与语言

| 用例 ID | 适用 | 窗口 | 状态 | 语言 | 外观 | 帧 | 操作起点 | 选择或故障输入 | 参考 ID 和类型 | 检查项或不适用原因 | 所需证据 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| V01-general-default-zh-Hans-dark | REQUIRED | general | default | zh-Hans | dark | static | 设置 → 通用 | 系统跟随、登录关、主窗开、记住开 | Figma 原图 P07-F01（匹配区域） | 检查三组设置行、版本、开关与应用标题栏 | 窗口+原生标题栏局部 |
| V01-general-default-zh-Hans-light | REQUIRED | general | default | zh-Hans | light | static | 设置 → 通用 | 系统跟随、登录关、主窗开、记住开 | 组件/变量 P07-F01（浅色变量） | 检查三组设置行、版本、开关与应用标题栏 | 窗口+原生标题栏局部 |
| V01-general-default-en-dark | REQUIRED | general | default | en | dark | static | 设置 → 通用 | 系统跟随、登录关、主窗开、记住开 | 组件/变量 P07-F01（英文译文） | 检查三组设置行、版本、开关与应用标题栏 | 窗口+原生标题栏局部 |
| V01-general-default-en-light | REQUIRED | general | default | en | light | static | 设置 → 通用 | 系统跟随、登录关、主窗开、记住开 | 组件/变量 P07-F01（英文译文与浅色变量） | 检查三组设置行、版本、开关与应用标题栏 | 窗口+原生标题栏局部 |
| V01-general-entry-main-zh-Hans-dark | REQUIRED | general | entry-main | zh-Hans | dark | static | 隔离主窗口可见 | 点击主窗口右上齿轮 | 组件/变量 P07-F01（无同状态原图） | 打开同一个设置窗口，原窗口可继续操作 | 窗口+入口录像+AX |
| V01-general-entry-main-zh-Hans-light | REQUIRED | general | entry-main | zh-Hans | light | static | 隔离主窗口可见 | 点击主窗口右上齿轮 | 组件/变量 P07-F01（无同状态原图，浅色变量） | 打开同一个设置窗口，原窗口可继续操作 | 窗口+入口录像+AX |
| V01-general-entry-main-en-dark | REQUIRED | general | entry-main | en | dark | static | 隔离主窗口可见 | 点击主窗口右上齿轮 | 组件/变量 P07-F01（无同状态原图，英文译文） | 打开同一个设置窗口，原窗口可继续操作 | 窗口+入口录像+AX |
| V01-general-entry-main-en-light | REQUIRED | general | entry-main | en | light | static | 隔离主窗口可见 | 点击主窗口右上齿轮 | 组件/变量 P07-F01（无同状态原图，英文译文与浅色变量） | 打开同一个设置窗口，原窗口可继续操作 | 窗口+入口录像+AX |
| V01-general-entry-menu-zh-Hans-dark | REQUIRED | general | entry-menu | zh-Hans | dark | static | 设置窗口已开；隔离菜单栏可用 | 点击菜单栏面板齿轮 | 组件/变量 P07-F01（无同状态原图） | 同一设置窗口置前，不增加第二个窗口 | 窗口+入口录像+AX窗口标识 |
| V01-general-entry-menu-zh-Hans-light | REQUIRED | general | entry-menu | zh-Hans | light | static | 设置窗口已开；隔离菜单栏可用 | 点击菜单栏面板齿轮 | 组件/变量 P07-F01（无同状态原图，浅色变量） | 同一设置窗口置前，不增加第二个窗口 | 窗口+入口录像+AX窗口标识 |
| V01-general-entry-menu-en-dark | REQUIRED | general | entry-menu | en | dark | static | 设置窗口已开；隔离菜单栏可用 | 点击菜单栏面板齿轮 | 组件/变量 P07-F01（无同状态原图，英文译文） | 同一设置窗口置前，不增加第二个窗口 | 窗口+入口录像+AX窗口标识 |
| V01-general-entry-menu-en-light | REQUIRED | general | entry-menu | en | light | static | 设置窗口已开；隔离菜单栏可用 | 点击菜单栏面板齿轮 | 组件/变量 P07-F01（无同状态原图，英文译文与浅色变量） | 同一设置窗口置前，不增加第二个窗口 | 窗口+入口录像+AX窗口标识 |
| V01-general-login-on-zh-Hans-dark | REQUIRED | general | login-on | zh-Hans | dark | static | 通用，相应偏好先置反值 | 切换登录时自动启动为开，其他偏好回到原稿默认 | 组件/变量 P07-F01（无同状态原图） | 滑块、轨道、AX 值为开。设置关闭再打开时仍为开；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-login-on-zh-Hans-light | REQUIRED | general | login-on | zh-Hans | light | static | 通用，相应偏好先置反值 | 切换登录时自动启动为开，其他偏好回到原稿默认 | 组件/变量 P07-F01（无同状态原图，浅色变量） | 滑块、轨道、AX 值为开。设置关闭再打开时仍为开；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-login-on-en-dark | REQUIRED | general | login-on | en | dark | static | 通用，相应偏好先置反值 | 切换登录时自动启动为开，其他偏好回到原稿默认 | 组件/变量 P07-F01（无同状态原图，英文译文） | 滑块、轨道、AX 值为开。设置关闭再打开时仍为开；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-login-on-en-light | REQUIRED | general | login-on | en | light | static | 通用，相应偏好先置反值 | 切换登录时自动启动为开，其他偏好回到原稿默认 | 组件/变量 P07-F01（无同状态原图，英文译文与浅色变量） | 滑块、轨道、AX 值为开。设置关闭再打开时仍为开；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-login-off-zh-Hans-dark | REQUIRED | general | login-off | zh-Hans | dark | static | 通用，相应偏好先置反值 | 切换登录时自动启动为关，其他偏好回到原稿默认 | Figma 原图 P07-F01（匹配区域） | 滑块、轨道、AX 值为关。设置关闭再打开时仍为关；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-login-off-zh-Hans-light | REQUIRED | general | login-off | zh-Hans | light | static | 通用，相应偏好先置反值 | 切换登录时自动启动为关，其他偏好回到原稿默认 | 组件/变量 P07-F01（浅色变量） | 滑块、轨道、AX 值为关。设置关闭再打开时仍为关；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-login-off-en-dark | REQUIRED | general | login-off | en | dark | static | 通用，相应偏好先置反值 | 切换登录时自动启动为关，其他偏好回到原稿默认 | 组件/变量 P07-F01（英文译文） | 滑块、轨道、AX 值为关。设置关闭再打开时仍为关；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-login-off-en-light | REQUIRED | general | login-off | en | light | static | 通用，相应偏好先置反值 | 切换登录时自动启动为关，其他偏好回到原稿默认 | 组件/变量 P07-F01（英文译文与浅色变量） | 滑块、轨道、AX 值为关。设置关闭再打开时仍为关；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-show-main-on-zh-Hans-dark | REQUIRED | general | show-main-on | zh-Hans | dark | static | 通用，相应偏好先置反值 | 切换启动后显示主窗口为开，其他偏好回到原稿默认 | Figma 原图 P07-F01（匹配区域） | 滑块、轨道、AX 值为开。设置关闭再打开时仍为开；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-show-main-on-zh-Hans-light | REQUIRED | general | show-main-on | zh-Hans | light | static | 通用，相应偏好先置反值 | 切换启动后显示主窗口为开，其他偏好回到原稿默认 | 组件/变量 P07-F01（浅色变量） | 滑块、轨道、AX 值为开。设置关闭再打开时仍为开；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-show-main-on-en-dark | REQUIRED | general | show-main-on | en | dark | static | 通用，相应偏好先置反值 | 切换启动后显示主窗口为开，其他偏好回到原稿默认 | 组件/变量 P07-F01（英文译文） | 滑块、轨道、AX 值为开。设置关闭再打开时仍为开；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-show-main-on-en-light | REQUIRED | general | show-main-on | en | light | static | 通用，相应偏好先置反值 | 切换启动后显示主窗口为开，其他偏好回到原稿默认 | 组件/变量 P07-F01（英文译文与浅色变量） | 滑块、轨道、AX 值为开。设置关闭再打开时仍为开；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-show-main-off-zh-Hans-dark | REQUIRED | general | show-main-off | zh-Hans | dark | static | 通用，相应偏好先置反值 | 切换启动后显示主窗口为关，其他偏好回到原稿默认 | 组件/变量 P07-F01（无同状态原图） | 滑块、轨道、AX 值为关。设置关闭再打开时仍为关；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-show-main-off-zh-Hans-light | REQUIRED | general | show-main-off | zh-Hans | light | static | 通用，相应偏好先置反值 | 切换启动后显示主窗口为关，其他偏好回到原稿默认 | 组件/变量 P07-F01（无同状态原图，浅色变量） | 滑块、轨道、AX 值为关。设置关闭再打开时仍为关；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-show-main-off-en-dark | REQUIRED | general | show-main-off | en | dark | static | 通用，相应偏好先置反值 | 切换启动后显示主窗口为关，其他偏好回到原稿默认 | 组件/变量 P07-F01（无同状态原图，英文译文） | 滑块、轨道、AX 值为关。设置关闭再打开时仍为关；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-show-main-off-en-light | REQUIRED | general | show-main-off | en | light | static | 通用，相应偏好先置反值 | 切换启动后显示主窗口为关，其他偏好回到原稿默认 | 组件/变量 P07-F01（无同状态原图，英文译文与浅色变量） | 滑块、轨道、AX 值为关。设置关闭再打开时仍为关；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-remember-on-zh-Hans-dark | REQUIRED | general | remember-on | zh-Hans | dark | static | 通用，相应偏好先置反值 | 切换记住最近打开的项目为开，其他偏好回到原稿默认 | Figma 原图 P07-F01（匹配区域） | 滑块、轨道、AX 值为开。设置关闭再打开时仍为开；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-remember-on-zh-Hans-light | REQUIRED | general | remember-on | zh-Hans | light | static | 通用，相应偏好先置反值 | 切换记住最近打开的项目为开，其他偏好回到原稿默认 | 组件/变量 P07-F01（浅色变量） | 滑块、轨道、AX 值为开。设置关闭再打开时仍为开；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-remember-on-en-dark | REQUIRED | general | remember-on | en | dark | static | 通用，相应偏好先置反值 | 切换记住最近打开的项目为开，其他偏好回到原稿默认 | 组件/变量 P07-F01（英文译文） | 滑块、轨道、AX 值为开。设置关闭再打开时仍为开；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-remember-on-en-light | REQUIRED | general | remember-on | en | light | static | 通用，相应偏好先置反值 | 切换记住最近打开的项目为开，其他偏好回到原稿默认 | 组件/变量 P07-F01（英文译文与浅色变量） | 滑块、轨道、AX 值为开。设置关闭再打开时仍为开；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-remember-off-zh-Hans-dark | REQUIRED | general | remember-off | zh-Hans | dark | static | 通用，相应偏好先置反值 | 切换记住最近打开的项目为关，其他偏好回到原稿默认 | 组件/变量 P07-F01（无同状态原图） | 滑块、轨道、AX 值为关。设置关闭再打开时仍为关；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-remember-off-zh-Hans-light | REQUIRED | general | remember-off | zh-Hans | light | static | 通用，相应偏好先置反值 | 切换记住最近打开的项目为关，其他偏好回到原稿默认 | 组件/变量 P07-F01（无同状态原图，浅色变量） | 滑块、轨道、AX 值为关。设置关闭再打开时仍为关；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-remember-off-en-dark | REQUIRED | general | remember-off | en | dark | static | 通用，相应偏好先置反值 | 切换记住最近打开的项目为关，其他偏好回到原稿默认 | 组件/变量 P07-F01（无同状态原图，英文译文） | 滑块、轨道、AX 值为关。设置关闭再打开时仍为关；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-remember-off-en-light | REQUIRED | general | remember-off | en | light | static | 通用，相应偏好先置反值 | 切换记住最近打开的项目为关，其他偏好回到原稿默认 | 组件/变量 P07-F01（无同状态原图，英文译文与浅色变量） | 滑块、轨道、AX 值为关。设置关闭再打开时仍为关；隔离重启后验证该偏好效果 | 窗口+回开前后+启动或登录状态记录 |
| V01-general-language-menu-open-zh-Hans-dark | REQUIRED | general | language-menu-open | zh-Hans | dark | static | 通用，跟随系统 | 打开界面语言选框 | Figma 原图 P07-F05（弹层），组件 P07-F01（宿主） | 核对 310 × 148 面板的标题、三项、间距和对齐，记录系统锚点 | 窗口+弹层裁区+AX |
| V01-general-language-menu-open-zh-Hans-light | REQUIRED | general | language-menu-open | zh-Hans | light | static | 通用，跟随系统 | 打开界面语言选框 | 组件/变量 P07-F05、P07-F01（浅色变量） | 核对 310 × 148 面板的标题、三项、间距和对齐，记录系统锚点 | 窗口+弹层裁区+AX |
| V01-general-language-menu-open-en-dark | REQUIRED | general | language-menu-open | en | dark | static | 通用，跟随系统 | 打开界面语言选框 | 组件/变量 P07-F05、P07-F01（英文译文） | 核对 310 × 148 面板的标题、三项、间距和对齐，记录系统锚点 | 窗口+弹层裁区+AX |
| V01-general-language-menu-open-en-light | REQUIRED | general | language-menu-open | en | light | static | 通用，跟随系统 | 打开界面语言选框 | 组件/变量 P07-F05、P07-F01（英文译文与浅色变量） | 核对 310 × 148 面板的标题、三项、间距和对齐，记录系统锚点 | 窗口+弹层裁区+AX |
| V01-general-language-dismiss-escape-zh-Hans-dark | REQUIRED | general | language-dismiss-escape | zh-Hans | dark | static | 语言菜单已开且焦点在菜单 | 按 Escape | 组件/变量 P07-F05;P07-F01（无同状态原图） | 弹层闭合、恢复选框焦点、原语言不变 | 闭合前后+键盘录像+焦点AX |
| V01-general-language-dismiss-escape-zh-Hans-light | REQUIRED | general | language-dismiss-escape | zh-Hans | light | static | 语言菜单已开且焦点在菜单 | 按 Escape | 组件/变量 P07-F05;P07-F01（无同状态原图，浅色变量） | 弹层闭合、恢复选框焦点、原语言不变 | 闭合前后+键盘录像+焦点AX |
| V01-general-language-dismiss-escape-en-dark | REQUIRED | general | language-dismiss-escape | en | dark | static | 语言菜单已开且焦点在菜单 | 按 Escape | 组件/变量 P07-F05;P07-F01（无同状态原图，英文译文） | 弹层闭合、恢复选框焦点、原语言不变 | 闭合前后+键盘录像+焦点AX |
| V01-general-language-dismiss-escape-en-light | REQUIRED | general | language-dismiss-escape | en | light | static | 语言菜单已开且焦点在菜单 | 按 Escape | 组件/变量 P07-F05;P07-F01（无同状态原图，英文译文与浅色变量） | 弹层闭合、恢复选框焦点、原语言不变 | 闭合前后+键盘录像+焦点AX |
| V01-general-language-dismiss-outside-zh-Hans-dark | REQUIRED | general | language-dismiss-outside | zh-Hans | dark | static | 语言菜单已开 | 点出弹层、点通用页空白 | 组件/变量 P07-F05;P07-F01（无同状态原图） | 弹层闭合且配置不变，记录指针关闭时焦点位置 | 闭合前后+AX |
| V01-general-language-dismiss-outside-zh-Hans-light | REQUIRED | general | language-dismiss-outside | zh-Hans | light | static | 语言菜单已开 | 点出弹层、点通用页空白 | 组件/变量 P07-F05;P07-F01（无同状态原图，浅色变量） | 弹层闭合且配置不变，记录指针关闭时焦点位置 | 闭合前后+AX |
| V01-general-language-dismiss-outside-en-dark | REQUIRED | general | language-dismiss-outside | en | dark | static | 语言菜单已开 | 点出弹层、点通用页空白 | 组件/变量 P07-F05;P07-F01（无同状态原图，英文译文） | 弹层闭合且配置不变，记录指针关闭时焦点位置 | 闭合前后+AX |
| V01-general-language-dismiss-outside-en-light | REQUIRED | general | language-dismiss-outside | en | light | static | 语言菜单已开 | 点出弹层、点通用页空白 | 组件/变量 P07-F05;P07-F01（无同状态原图，英文译文与浅色变量） | 弹层闭合且配置不变，记录指针关闭时焦点位置 | 闭合前后+AX |
| V01-general-language-system-zh-Hans-dark | REQUIRED | general | language-system | zh-Hans | dark | static | 通用，显式语言与系统语言相反 | 选跟随系统；系统语言置本行语言 | 组件/变量 P07-F01;P07-F05（无同状态原图） | 界面按系统语言刷新，重开后跟随且表单不裁切 | 前后窗口+偏好记录 |
| V01-general-language-system-zh-Hans-light | REQUIRED | general | language-system | zh-Hans | light | static | 通用，显式语言与系统语言相反 | 选跟随系统；系统语言置本行语言 | 组件/变量 P07-F01;P07-F05（无同状态原图，浅色变量） | 界面按系统语言刷新，重开后跟随且表单不裁切 | 前后窗口+偏好记录 |
| V01-general-language-system-en-dark | REQUIRED | general | language-system | en | dark | static | 通用，显式语言与系统语言相反 | 选跟随系统；系统语言置本行语言 | 组件/变量 P07-F01;P07-F05（无同状态原图，英文译文） | 界面按系统语言刷新，重开后跟随且表单不裁切 | 前后窗口+偏好记录 |
| V01-general-language-system-en-light | REQUIRED | general | language-system | en | light | static | 通用，显式语言与系统语言相反 | 选跟随系统；系统语言置本行语言 | 组件/变量 P07-F01;P07-F05（无同状态原图，英文译文与浅色变量） | 界面按系统语言刷新，重开后跟随且表单不裁切 | 前后窗口+偏好记录 |
| V01-general-language-zh-zh-Hans-dark | REQUIRED | general | language-zh | zh-Hans | dark | static | 通用，英文界面 | 选简体中文，然后重新打开设置 | 组件/变量 P07-F01;P07-F05（无同状态原图） | 界面与 AX 进入简体中文，「简体中文」仍为当前选项 | 前后窗口+AX |
| V01-general-language-zh-zh-Hans-light | REQUIRED | general | language-zh | zh-Hans | light | static | 通用，英文界面 | 选简体中文，然后重新打开设置 | 组件/变量 P07-F01;P07-F05（无同状态原图，浅色变量） | 界面与 AX 进入简体中文，「简体中文」仍为当前选项 | 前后窗口+AX |
| V01-general-language-zh-en-dark | N/A | general | language-zh | en | dark | static | 通用，英文界面 | 选简体中文，然后重新打开设置 | —（P07-F01;P07-F05，范围说明） | 界面语言列记录操作后的语言；显式选择结果固定为 zh-Hans，本组合不能产生 en。起始语言在对应适用行一起留证。 | — |
| V01-general-language-zh-en-light | N/A | general | language-zh | en | light | static | 通用，英文界面 | 选简体中文，然后重新打开设置 | —（P07-F01;P07-F05，范围说明） | 界面语言列记录操作后的语言；显式选择结果固定为 zh-Hans，本组合不能产生 en。起始语言在对应适用行一起留证。 | — |
| V01-general-language-en-zh-Hans-dark | N/A | general | language-en | zh-Hans | dark | static | 通用，中文界面 | 选 English，然后重新打开设置 | —（P07-F01;P07-F05，范围说明） | 界面语言列记录操作后的语言；显式选择结果固定为 en，本组合不能产生 zh-Hans。起始语言在对应适用行一起留证。 | — |
| V01-general-language-en-zh-Hans-light | N/A | general | language-en | zh-Hans | light | static | 通用，中文界面 | 选 English，然后重新打开设置 | —（P07-F01;P07-F05，范围说明） | 界面语言列记录操作后的语言；显式选择结果固定为 en，本组合不能产生 zh-Hans。起始语言在对应适用行一起留证。 | — |
| V01-general-language-en-en-dark | REQUIRED | general | language-en | en | dark | static | 通用，中文界面 | 选 English，然后重新打开设置 | 组件/变量 P07-F01;P07-F05（无同状态原图，英文译文） | 界面与 AX 进入英文，选框不裁切，偏好保持 | 前后窗口+AX |
| V01-general-language-en-en-light | REQUIRED | general | language-en | en | light | static | 通用，中文界面 | 选 English，然后重新打开设置 | 组件/变量 P07-F01;P07-F05（无同状态原图，英文译文与浅色变量） | 界面与 AX 进入英文，选框不裁切，偏好保持 | 前后窗口+AX |
| V01-general-login-approval-zh-Hans-dark | REQUIRED | general | login-approval | zh-Hans | dark | static | 通用，隔离登录项等待系统批准 | 读取真实系统待批准；确认提示可读 | 组件/变量 P07-F01（无同状态原图） | 展示系统批准说明与适用入口，切换能力与当次系统状态一致 | 窗口+AX+系统状态 |
| V01-general-login-approval-zh-Hans-light | REQUIRED | general | login-approval | zh-Hans | light | static | 通用，隔离登录项等待系统批准 | 读取真实系统待批准；确认提示可读 | 组件/变量 P07-F01（无同状态原图，浅色变量） | 展示系统批准说明与适用入口，切换能力与当次系统状态一致 | 窗口+AX+系统状态 |
| V01-general-login-approval-en-dark | REQUIRED | general | login-approval | en | dark | static | 通用，隔离登录项等待系统批准 | 读取真实系统待批准；确认提示可读 | 组件/变量 P07-F01（无同状态原图，英文译文） | 展示系统批准说明与适用入口，切换能力与当次系统状态一致 | 窗口+AX+系统状态 |
| V01-general-login-approval-en-light | REQUIRED | general | login-approval | en | light | static | 通用，隔离登录项等待系统批准 | 读取真实系统待批准；确认提示可读 | 组件/变量 P07-F01（无同状态原图，英文译文与浅色变量） | 展示系统批准说明与适用入口，切换能力与当次系统状态一致 | 窗口+AX+系统状态 |
| V01-general-login-locked-zh-Hans-dark | REQUIRED | general | login-locked | zh-Hans | dark | static | 通用，登录项状态不可更改 | 受控锁定并以鼠标和键盘尝试；记录系统状态来源 | 组件/变量 P07-F01（无同状态原图） | 保留说明与可用系统入口，不修改注册状态；核对禁用角色和焦点 | 窗口+AX+拒绝动作记录 |
| V01-general-login-locked-zh-Hans-light | REQUIRED | general | login-locked | zh-Hans | light | static | 通用，登录项状态不可更改 | 受控锁定并以鼠标和键盘尝试；记录系统状态来源 | 组件/变量 P07-F01（无同状态原图，浅色变量） | 保留说明与可用系统入口，不修改注册状态；核对禁用角色和焦点 | 窗口+AX+拒绝动作记录 |
| V01-general-login-locked-en-dark | REQUIRED | general | login-locked | en | dark | static | 通用，登录项状态不可更改 | 受控锁定并以鼠标和键盘尝试；记录系统状态来源 | 组件/变量 P07-F01（无同状态原图，英文译文） | 保留说明与可用系统入口，不修改注册状态；核对禁用角色和焦点 | 窗口+AX+拒绝动作记录 |
| V01-general-login-locked-en-light | REQUIRED | general | login-locked | en | light | static | 通用，登录项状态不可更改 | 受控锁定并以鼠标和键盘尝试；记录系统状态来源 | 组件/变量 P07-F01（无同状态原图，英文译文与浅色变量） | 保留说明与可用系统入口，不修改注册状态；核对禁用角色和焦点 | 窗口+AX+拒绝动作记录 |
| V01-general-login-system-settings-zh-Hans-dark | REQUIRED | general | login-system-settings | zh-Hans | dark | static | 通用，登录项需系统处理 | 打开系统设置登录项入口；返回 App | 系统/实测；组件 P07-F01（入口或角色） | 系统落地为登录项页面；返回时反映实际状态 | 设置窗口+系统落地截图+返回AX |
| V01-general-login-system-settings-zh-Hans-light | REQUIRED | general | login-system-settings | zh-Hans | light | static | 通用，登录项需系统处理 | 打开系统设置登录项入口；返回 App | 系统/实测；组件 P07-F01（入口或角色，浅色变量） | 系统落地为登录项页面；返回时反映实际状态 | 设置窗口+系统落地截图+返回AX |
| V01-general-login-system-settings-en-dark | REQUIRED | general | login-system-settings | en | dark | static | 通用，登录项需系统处理 | 打开系统设置登录项入口；返回 App | 系统/实测；组件 P07-F01（入口或角色，英文译文） | 系统落地为登录项页面；返回时反映实际状态 | 设置窗口+系统落地截图+返回AX |
| V01-general-login-system-settings-en-light | REQUIRED | general | login-system-settings | en | light | static | 通用，登录项需系统处理 | 打开系统设置登录项入口；返回 App | 系统/实测；组件 P07-F01（入口或角色，英文译文与浅色变量） | 系统落地为登录项页面；返回时反映实际状态 | 设置窗口+系统落地截图+返回AX |
| V01-general-keyboard-order-zh-Hans-dark | REQUIRED | general | keyboard-order | zh-Hans | dark | static | 通用初始窗口 | Tab、Shift-Tab、Space、Return 操作选框和开关 | 组件/变量 P07-F01;P07-F05（无同状态原图） | 顺序、名称和值可读，焦点可见，完成菜单选择后回入口 | 窗口+焦点AX+键盘录像 |
| V01-general-keyboard-order-zh-Hans-light | REQUIRED | general | keyboard-order | zh-Hans | light | static | 通用初始窗口 | Tab、Shift-Tab、Space、Return 操作选框和开关 | 组件/变量 P07-F01;P07-F05（无同状态原图，浅色变量） | 顺序、名称和值可读，焦点可见，完成菜单选择后回入口 | 窗口+焦点AX+键盘录像 |
| V01-general-keyboard-order-en-dark | REQUIRED | general | keyboard-order | en | dark | static | 通用初始窗口 | Tab、Shift-Tab、Space、Return 操作选框和开关 | 组件/变量 P07-F01;P07-F05（无同状态原图，英文译文） | 顺序、名称和值可读，焦点可见，完成菜单选择后回入口 | 窗口+焦点AX+键盘录像 |
| V01-general-keyboard-order-en-light | REQUIRED | general | keyboard-order | en | light | static | 通用初始窗口 | Tab、Shift-Tab、Space、Return 操作选框和开关 | 组件/变量 P07-F01;P07-F05（无同状态原图，英文译文与浅色变量） | 顺序、名称和值可读，焦点可见，完成菜单选择后回入口 | 窗口+焦点AX+键盘录像 |
| V01-general-preferences-reopen-zh-Hans-dark | REQUIRED | general | preferences-reopen | zh-Hans | dark | static | 通用已变更语言以外的三个偏好 | 关闭设置，由另一齿轮复开，再重启隔离 App | 组件/变量 P07-F01（无同状态原图） | 窗口复用与三项实际持久化；启动行为读取真实偏好 | 窗口前后+偏好记录 |
| V01-general-preferences-reopen-zh-Hans-light | REQUIRED | general | preferences-reopen | zh-Hans | light | static | 通用已变更语言以外的三个偏好 | 关闭设置，由另一齿轮复开，再重启隔离 App | 组件/变量 P07-F01（无同状态原图，浅色变量） | 窗口复用与三项实际持久化；启动行为读取真实偏好 | 窗口前后+偏好记录 |
| V01-general-preferences-reopen-en-dark | REQUIRED | general | preferences-reopen | en | dark | static | 通用已变更语言以外的三个偏好 | 关闭设置，由另一齿轮复开，再重启隔离 App | 组件/变量 P07-F01（无同状态原图，英文译文） | 窗口复用与三项实际持久化；启动行为读取真实偏好 | 窗口前后+偏好记录 |
| V01-general-preferences-reopen-en-light | REQUIRED | general | preferences-reopen | en | light | static | 通用已变更语言以外的三个偏好 | 关闭设置，由另一齿轮复开，再重启隔离 App | 组件/变量 P07-F01（无同状态原图，英文译文与浅色变量） | 窗口复用与三项实际持久化；启动行为读取真实偏好 | 窗口前后+偏好记录 |

### V02 Flutter SDK 与环境检测

| 用例 ID | 适用 | 窗口 | 状态 | 语言 | 外观 | 帧 | 操作起点 | 选择或故障输入 | 参考 ID 和类型 | 检查项或不适用原因 | 所需证据 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| V02-flutter-sdk-auto-zh-Hans-dark | REQUIRED | flutter | sdk-auto | zh-Hans | dark | static | 设置 → Flutter，隔离 PATH 可用 | 选自动；FVM 按原图开但无项目 FVM 约束；使用原图 SDK 展示数据 | Figma 原图 P07-F02（匹配区域） | 自动来源、路径、Flutter/Dart 版本、状态及检查按钮 | 窗口+实际 SDK 来源记录 |
| V02-flutter-sdk-auto-zh-Hans-light | REQUIRED | flutter | sdk-auto | zh-Hans | light | static | 设置 → Flutter，隔离 PATH 可用 | 选自动；FVM 按原图开但无项目 FVM 约束；使用原图 SDK 展示数据 | 组件/变量 P07-F02（浅色变量） | 自动来源、路径、Flutter/Dart 版本、状态及检查按钮 | 窗口+实际 SDK 来源记录 |
| V02-flutter-sdk-auto-en-dark | REQUIRED | flutter | sdk-auto | en | dark | static | 设置 → Flutter，隔离 PATH 可用 | 选自动；FVM 按原图开但无项目 FVM 约束；使用原图 SDK 展示数据 | 组件/变量 P07-F02（英文译文） | 自动来源、路径、Flutter/Dart 版本、状态及检查按钮 | 窗口+实际 SDK 来源记录 |
| V02-flutter-sdk-auto-en-light | REQUIRED | flutter | sdk-auto | en | light | static | 设置 → Flutter，隔离 PATH 可用 | 选自动；FVM 按原图开但无项目 FVM 约束；使用原图 SDK 展示数据 | 组件/变量 P07-F02（英文译文与浅色变量） | 自动来源、路径、Flutter/Dart 版本、状态及检查按钮 | 窗口+实际 SDK 来源记录 |
| V02-flutter-sdk-manual-zh-Hans-dark | REQUIRED | flutter | sdk-manual | zh-Hans | dark | static | Flutter 页，已有有效手动 SDK | 选手动并指向有效 SDK，使用带空格的长路径 | 组件/变量 P07-F02;P07-F07（无同状态原图） | 手动来源、选择路径按钮、完整路径可取，显示 SDK 与执行 SDK 同源 | 窗口+AX+SDK解析记录 |
| V02-flutter-sdk-manual-zh-Hans-light | REQUIRED | flutter | sdk-manual | zh-Hans | light | static | Flutter 页，已有有效手动 SDK | 选手动并指向有效 SDK，使用带空格的长路径 | 组件/变量 P07-F02;P07-F07（无同状态原图，浅色变量） | 手动来源、选择路径按钮、完整路径可取，显示 SDK 与执行 SDK 同源 | 窗口+AX+SDK解析记录 |
| V02-flutter-sdk-manual-en-dark | REQUIRED | flutter | sdk-manual | en | dark | static | Flutter 页，已有有效手动 SDK | 选手动并指向有效 SDK，使用带空格的长路径 | 组件/变量 P07-F02;P07-F07（无同状态原图，英文译文） | 手动来源、选择路径按钮、完整路径可取，显示 SDK 与执行 SDK 同源 | 窗口+AX+SDK解析记录 |
| V02-flutter-sdk-manual-en-light | REQUIRED | flutter | sdk-manual | en | light | static | Flutter 页，已有有效手动 SDK | 选手动并指向有效 SDK，使用带空格的长路径 | 组件/变量 P07-F02;P07-F07（无同状态原图，英文译文与浅色变量） | 手动来源、选择路径按钮、完整路径可取，显示 SDK 与执行 SDK 同源 | 窗口+AX+SDK解析记录 |
| V02-flutter-sdk-fvm-zh-Hans-dark | REQUIRED | flutter | sdk-fvm | zh-Hans | dark | static | Flutter 页，打开有有效 SDK 的项目 | 配置有效项目 FVM；启用优先 FVM | 组件/变量 P07-F02（无同状态原图） | 来源切到项目 FVM，路径/版本与实际 Flutter 命令一致 | 窗口+实际 SDK 来源记录 |
| V02-flutter-sdk-fvm-zh-Hans-light | REQUIRED | flutter | sdk-fvm | zh-Hans | light | static | Flutter 页，打开有有效 SDK 的项目 | 配置有效项目 FVM；启用优先 FVM | 组件/变量 P07-F02（无同状态原图，浅色变量） | 来源切到项目 FVM，路径/版本与实际 Flutter 命令一致 | 窗口+实际 SDK 来源记录 |
| V02-flutter-sdk-fvm-en-dark | REQUIRED | flutter | sdk-fvm | en | dark | static | Flutter 页，打开有有效 SDK 的项目 | 配置有效项目 FVM；启用优先 FVM | 组件/变量 P07-F02（无同状态原图，英文译文） | 来源切到项目 FVM，路径/版本与实际 Flutter 命令一致 | 窗口+实际 SDK 来源记录 |
| V02-flutter-sdk-fvm-en-light | REQUIRED | flutter | sdk-fvm | en | light | static | Flutter 页，打开有有效 SDK 的项目 | 配置有效项目 FVM；启用优先 FVM | 组件/变量 P07-F02（无同状态原图，英文译文与浅色变量） | 来源切到项目 FVM，路径/版本与实际 Flutter 命令一致 | 窗口+实际 SDK 来源记录 |
| V02-flutter-sdk-fvm-off-zh-Hans-dark | REQUIRED | flutter | sdk-fvm-off | zh-Hans | dark | static | Flutter 页，FVM 有效且已启用 | 关闭优先 FVM，保留 PATH SDK | 组件/变量 P07-F02（无同状态原图） | 灰轨、白滑块及来源回退，无静默换到错误 SDK | 窗口+AX+实际 SDK 来源记录 |
| V02-flutter-sdk-fvm-off-zh-Hans-light | REQUIRED | flutter | sdk-fvm-off | zh-Hans | light | static | Flutter 页，FVM 有效且已启用 | 关闭优先 FVM，保留 PATH SDK | 组件/变量 P07-F02（无同状态原图，浅色变量） | 灰轨、白滑块及来源回退，无静默换到错误 SDK | 窗口+AX+实际 SDK 来源记录 |
| V02-flutter-sdk-fvm-off-en-dark | REQUIRED | flutter | sdk-fvm-off | en | dark | static | Flutter 页，FVM 有效且已启用 | 关闭优先 FVM，保留 PATH SDK | 组件/变量 P07-F02（无同状态原图，英文译文） | 灰轨、白滑块及来源回退，无静默换到错误 SDK | 窗口+AX+实际 SDK 来源记录 |
| V02-flutter-sdk-fvm-off-en-light | REQUIRED | flutter | sdk-fvm-off | en | light | static | Flutter 页，FVM 有效且已启用 | 关闭优先 FVM，保留 PATH SDK | 组件/变量 P07-F02（无同状态原图，英文译文与浅色变量） | 灰轨、白滑块及来源回退，无静默换到错误 SDK | 窗口+AX+实际 SDK 来源记录 |
| V02-flutter-sdk-fvm-missing-zh-Hans-dark | REQUIRED | flutter | sdk-fvm-missing | zh-Hans | dark | static | Flutter 页，有项目 FVM 约束 | 令项目要求的 FVM SDK 缺失；PATH 另有 SDK | 组件/变量 P07-F02（无同状态原图） | 明确缺失原因，按技术契约避免静默回退；检查不可用时截取禁用控件 | 窗口+AX+SDK解析记录 |
| V02-flutter-sdk-fvm-missing-zh-Hans-light | REQUIRED | flutter | sdk-fvm-missing | zh-Hans | light | static | Flutter 页，有项目 FVM 约束 | 令项目要求的 FVM SDK 缺失；PATH 另有 SDK | 组件/变量 P07-F02（无同状态原图，浅色变量） | 明确缺失原因，按技术契约避免静默回退；检查不可用时截取禁用控件 | 窗口+AX+SDK解析记录 |
| V02-flutter-sdk-fvm-missing-en-dark | REQUIRED | flutter | sdk-fvm-missing | en | dark | static | Flutter 页，有项目 FVM 约束 | 令项目要求的 FVM SDK 缺失；PATH 另有 SDK | 组件/变量 P07-F02（无同状态原图，英文译文） | 明确缺失原因，按技术契约避免静默回退；检查不可用时截取禁用控件 | 窗口+AX+SDK解析记录 |
| V02-flutter-sdk-fvm-missing-en-light | REQUIRED | flutter | sdk-fvm-missing | en | light | static | Flutter 页，有项目 FVM 约束 | 令项目要求的 FVM SDK 缺失；PATH 另有 SDK | 组件/变量 P07-F02（无同状态原图，英文译文与浅色变量） | 明确缺失原因，按技术契约避免静默回退；检查不可用时截取禁用控件 | 窗口+AX+SDK解析记录 |
| V02-flutter-sdk-missing-zh-Hans-dark | REQUIRED | flutter | sdk-missing | zh-Hans | dark | static | Flutter 页，未指定手动 SDK | 隔离 PATH 移除可用 Flutter，移除 FVM 来源 | 组件/变量 P07-F02（无同状态原图） | 显示无 SDK 原因和可修正入口，环境检查不可触发 | 窗口+禁用区域+AX |
| V02-flutter-sdk-missing-zh-Hans-light | REQUIRED | flutter | sdk-missing | zh-Hans | light | static | Flutter 页，未指定手动 SDK | 隔离 PATH 移除可用 Flutter，移除 FVM 来源 | 组件/变量 P07-F02（无同状态原图，浅色变量） | 显示无 SDK 原因和可修正入口，环境检查不可触发 | 窗口+禁用区域+AX |
| V02-flutter-sdk-missing-en-dark | REQUIRED | flutter | sdk-missing | en | dark | static | Flutter 页，未指定手动 SDK | 隔离 PATH 移除可用 Flutter，移除 FVM 来源 | 组件/变量 P07-F02（无同状态原图，英文译文） | 显示无 SDK 原因和可修正入口，环境检查不可触发 | 窗口+禁用区域+AX |
| V02-flutter-sdk-missing-en-light | REQUIRED | flutter | sdk-missing | en | light | static | Flutter 页，未指定手动 SDK | 隔离 PATH 移除可用 Flutter，移除 FVM 来源 | 组件/变量 P07-F02（无同状态原图，英文译文与浅色变量） | 显示无 SDK 原因和可修正入口，环境检查不可触发 | 窗口+禁用区域+AX |
| V02-flutter-sdk-invalid-zh-Hans-dark | REQUIRED | flutter | sdk-invalid | zh-Hans | dark | static | 手动 SDK 路径选择入口 | 选择无 Flutter 可执行文件的目录 | 组件/变量 P07-F02;P07-F07（无同状态原图） | 显示有意义的失败原因和重选，保留上次有效设置 | 窗口+文件夹选择结果+AX |
| V02-flutter-sdk-invalid-zh-Hans-light | REQUIRED | flutter | sdk-invalid | zh-Hans | light | static | 手动 SDK 路径选择入口 | 选择无 Flutter 可执行文件的目录 | 组件/变量 P07-F02;P07-F07（无同状态原图，浅色变量） | 显示有意义的失败原因和重选，保留上次有效设置 | 窗口+文件夹选择结果+AX |
| V02-flutter-sdk-invalid-en-dark | REQUIRED | flutter | sdk-invalid | en | dark | static | 手动 SDK 路径选择入口 | 选择无 Flutter 可执行文件的目录 | 组件/变量 P07-F02;P07-F07（无同状态原图，英文译文） | 显示有意义的失败原因和重选，保留上次有效设置 | 窗口+文件夹选择结果+AX |
| V02-flutter-sdk-invalid-en-light | REQUIRED | flutter | sdk-invalid | en | light | static | 手动 SDK 路径选择入口 | 选择无 Flutter 可执行文件的目录 | 组件/变量 P07-F02;P07-F07（无同状态原图，英文译文与浅色变量） | 显示有意义的失败原因和重选，保留上次有效设置 | 窗口+文件夹选择结果+AX |
| V02-flutter-sdk-validating-zh-Hans-dark | REQUIRED | flutter | sdk-validating | zh-Hans | dark | static | Flutter 页，尚未选定候选 SDK | 选择延迟返回的手动 SDK 验证输入 | 组件/变量 P07-F02;P07-F07（无同状态原图） | 捕获正在验证，结束前保持行为和交互状态一致 | 窗口+前后帧+AX |
| V02-flutter-sdk-validating-zh-Hans-light | REQUIRED | flutter | sdk-validating | zh-Hans | light | static | Flutter 页，尚未选定候选 SDK | 选择延迟返回的手动 SDK 验证输入 | 组件/变量 P07-F02;P07-F07（无同状态原图，浅色变量） | 捕获正在验证，结束前保持行为和交互状态一致 | 窗口+前后帧+AX |
| V02-flutter-sdk-validating-en-dark | REQUIRED | flutter | sdk-validating | en | dark | static | Flutter 页，尚未选定候选 SDK | 选择延迟返回的手动 SDK 验证输入 | 组件/变量 P07-F02;P07-F07（无同状态原图，英文译文） | 捕获正在验证，结束前保持行为和交互状态一致 | 窗口+前后帧+AX |
| V02-flutter-sdk-validating-en-light | REQUIRED | flutter | sdk-validating | en | light | static | Flutter 页，尚未选定候选 SDK | 选择延迟返回的手动 SDK 验证输入 | 组件/变量 P07-F02;P07-F07（无同状态原图，英文译文与浅色变量） | 捕获正在验证，结束前保持行为和交互状态一致 | 窗口+前后帧+AX |
| V02-flutter-sdk-locked-zh-Hans-dark | REQUIRED | flutter | sdk-locked | zh-Hans | dark | static | Flutter 页，运行或恢复期间 | 进入不允许修改 SDK 的会话状态；尝试来源、目录和 FVM 控件 | 组件/变量 P07-F02（无同状态原图） | 各控件按实际允许范围禁用，现有来源不变 | 窗口+AX+拒绝动作记录 |
| V02-flutter-sdk-locked-zh-Hans-light | REQUIRED | flutter | sdk-locked | zh-Hans | light | static | Flutter 页，运行或恢复期间 | 进入不允许修改 SDK 的会话状态；尝试来源、目录和 FVM 控件 | 组件/变量 P07-F02（无同状态原图，浅色变量） | 各控件按实际允许范围禁用，现有来源不变 | 窗口+AX+拒绝动作记录 |
| V02-flutter-sdk-locked-en-dark | REQUIRED | flutter | sdk-locked | en | dark | static | Flutter 页，运行或恢复期间 | 进入不允许修改 SDK 的会话状态；尝试来源、目录和 FVM 控件 | 组件/变量 P07-F02（无同状态原图，英文译文） | 各控件按实际允许范围禁用，现有来源不变 | 窗口+AX+拒绝动作记录 |
| V02-flutter-sdk-locked-en-light | REQUIRED | flutter | sdk-locked | en | light | static | Flutter 页，运行或恢复期间 | 进入不允许修改 SDK 的会话状态；尝试来源、目录和 FVM 控件 | 组件/变量 P07-F02（无同状态原图，英文译文与浅色变量） | 各控件按实际允许范围禁用，现有来源不变 | 窗口+AX+拒绝动作记录 |
| V02-flutter-sdk-panel-open-zh-Hans-dark | REQUIRED | flutter | sdk-panel-open | zh-Hans | dark | static | Flutter 页，已选手动且可编辑 | 从选路径按钮打开实际目录选择器，保留窗口截图 | 系统/实测；组件 P07-F07;P07-F02（入口或角色） | 实际原生面板、目录策略、入口位置、宿主边界 | 窗口+NSOpenPanel独立区域+AX |
| V02-flutter-sdk-panel-open-zh-Hans-light | REQUIRED | flutter | sdk-panel-open | zh-Hans | light | static | Flutter 页，已选手动且可编辑 | 从选路径按钮打开实际目录选择器，保留窗口截图 | 系统/实测；组件 P07-F07;P07-F02（入口或角色，浅色变量） | 实际原生面板、目录策略、入口位置、宿主边界 | 窗口+NSOpenPanel独立区域+AX |
| V02-flutter-sdk-panel-open-en-dark | REQUIRED | flutter | sdk-panel-open | en | dark | static | Flutter 页，已选手动且可编辑 | 从选路径按钮打开实际目录选择器，保留窗口截图 | 系统/实测；组件 P07-F07;P07-F02（入口或角色，英文译文） | 实际原生面板、目录策略、入口位置、宿主边界 | 窗口+NSOpenPanel独立区域+AX |
| V02-flutter-sdk-panel-open-en-light | REQUIRED | flutter | sdk-panel-open | en | light | static | Flutter 页，已选手动且可编辑 | 从选路径按钮打开实际目录选择器，保留窗口截图 | 系统/实测；组件 P07-F07;P07-F02（入口或角色，英文译文与浅色变量） | 实际原生面板、目录策略、入口位置、宿主边界 | 窗口+NSOpenPanel独立区域+AX |
| V02-flutter-sdk-panel-accept-zh-Hans-dark | REQUIRED | flutter | sdk-panel-accept | zh-Hans | dark | static | 原生目录选择器打开 | 选有效 Flutter SDK 并确认 | 系统/实测；组件 P07-F07;P07-F02（入口或角色） | 回入口，更新手动 SDK，检查可读路径和来源 | 系统区域+返回窗口+AX |
| V02-flutter-sdk-panel-accept-zh-Hans-light | REQUIRED | flutter | sdk-panel-accept | zh-Hans | light | static | 原生目录选择器打开 | 选有效 Flutter SDK 并确认 | 系统/实测；组件 P07-F07;P07-F02（入口或角色，浅色变量） | 回入口，更新手动 SDK，检查可读路径和来源 | 系统区域+返回窗口+AX |
| V02-flutter-sdk-panel-accept-en-dark | REQUIRED | flutter | sdk-panel-accept | en | dark | static | 原生目录选择器打开 | 选有效 Flutter SDK 并确认 | 系统/实测；组件 P07-F07;P07-F02（入口或角色，英文译文） | 回入口，更新手动 SDK，检查可读路径和来源 | 系统区域+返回窗口+AX |
| V02-flutter-sdk-panel-accept-en-light | REQUIRED | flutter | sdk-panel-accept | en | light | static | 原生目录选择器打开 | 选有效 Flutter SDK 并确认 | 系统/实测；组件 P07-F07;P07-F02（入口或角色，英文译文与浅色变量） | 回入口，更新手动 SDK，检查可读路径和来源 | 系统区域+返回窗口+AX |
| V02-flutter-sdk-panel-cancel-zh-Hans-dark | REQUIRED | flutter | sdk-panel-cancel | zh-Hans | dark | static | 原生目录选择器打开 | 换浏览目录但点系统取消 | 系统/实测；组件 P07-F07;P07-F02（入口或角色） | 面板关闭且路径未变，焦点回选路径 | 系统区域+返回窗口+焦点AX |
| V02-flutter-sdk-panel-cancel-zh-Hans-light | REQUIRED | flutter | sdk-panel-cancel | zh-Hans | light | static | 原生目录选择器打开 | 换浏览目录但点系统取消 | 系统/实测；组件 P07-F07;P07-F02（入口或角色，浅色变量） | 面板关闭且路径未变，焦点回选路径 | 系统区域+返回窗口+焦点AX |
| V02-flutter-sdk-panel-cancel-en-dark | REQUIRED | flutter | sdk-panel-cancel | en | dark | static | 原生目录选择器打开 | 换浏览目录但点系统取消 | 系统/实测；组件 P07-F07;P07-F02（入口或角色，英文译文） | 面板关闭且路径未变，焦点回选路径 | 系统区域+返回窗口+焦点AX |
| V02-flutter-sdk-panel-cancel-en-light | REQUIRED | flutter | sdk-panel-cancel | en | light | static | 原生目录选择器打开 | 换浏览目录但点系统取消 | 系统/实测；组件 P07-F07;P07-F02（入口或角色，英文译文与浅色变量） | 面板关闭且路径未变，焦点回选路径 | 系统区域+返回窗口+焦点AX |
| V02-flutter-sdk-panel-escape-zh-Hans-dark | REQUIRED | flutter | sdk-panel-escape | zh-Hans | dark | static | 原生目录选择器打开 | 浏览目录后按 Escape | 系统/实测；组件 P07-F07;P07-F02（入口或角色） | 与原生取消一致，保存选择不变 | 系统区域+键盘录像+返回焦点AX |
| V02-flutter-sdk-panel-escape-zh-Hans-light | REQUIRED | flutter | sdk-panel-escape | zh-Hans | light | static | 原生目录选择器打开 | 浏览目录后按 Escape | 系统/实测；组件 P07-F07;P07-F02（入口或角色，浅色变量） | 与原生取消一致，保存选择不变 | 系统区域+键盘录像+返回焦点AX |
| V02-flutter-sdk-panel-escape-en-dark | REQUIRED | flutter | sdk-panel-escape | en | dark | static | 原生目录选择器打开 | 浏览目录后按 Escape | 系统/实测；组件 P07-F07;P07-F02（入口或角色，英文译文） | 与原生取消一致，保存选择不变 | 系统区域+键盘录像+返回焦点AX |
| V02-flutter-sdk-panel-escape-en-light | REQUIRED | flutter | sdk-panel-escape | en | light | static | 原生目录选择器打开 | 浏览目录后按 Escape | 系统/实测；组件 P07-F07;P07-F02（入口或角色，英文译文与浅色变量） | 与原生取消一致，保存选择不变 | 系统区域+键盘录像+返回焦点AX |
| V02-flutter-doctor-idle-zh-Hans-dark | REQUIRED | flutter | doctor-idle | zh-Hans | dark | static | Flutter 页，原图默认 SDK 数据 | 清除旧检测，保持空闲且 SDK 可用 | Figma 原图 P07-F02（匹配区域） | 检查键存在且可用，无旧反馈 | 窗口+AX |
| V02-flutter-doctor-idle-zh-Hans-light | REQUIRED | flutter | doctor-idle | zh-Hans | light | static | Flutter 页，原图默认 SDK 数据 | 清除旧检测，保持空闲且 SDK 可用 | 组件/变量 P07-F02（浅色变量） | 检查键存在且可用，无旧反馈 | 窗口+AX |
| V02-flutter-doctor-idle-en-dark | REQUIRED | flutter | doctor-idle | en | dark | static | Flutter 页，原图默认 SDK 数据 | 清除旧检测，保持空闲且 SDK 可用 | 组件/变量 P07-F02（英文译文） | 检查键存在且可用，无旧反馈 | 窗口+AX |
| V02-flutter-doctor-idle-en-light | REQUIRED | flutter | doctor-idle | en | light | static | Flutter 页，原图默认 SDK 数据 | 清除旧检测，保持空闲且 SDK 可用 | 组件/变量 P07-F02（英文译文与浅色变量） | 检查键存在且可用，无旧反馈 | 窗口+AX |
| V02-flutter-doctor-running-zh-Hans-dark | REQUIRED | flutter | doctor-running | zh-Hans | dark | static | Flutter 页，SDK 可用 | 启动可延迟的 Doctor | 组件/变量 P07-F02（无同状态原图） | 运行反馈、取消可达，阻止重复启动 | 窗口+AX+输入行为 |
| V02-flutter-doctor-running-zh-Hans-light | REQUIRED | flutter | doctor-running | zh-Hans | light | static | Flutter 页，SDK 可用 | 启动可延迟的 Doctor | 组件/变量 P07-F02（无同状态原图，浅色变量） | 运行反馈、取消可达，阻止重复启动 | 窗口+AX+输入行为 |
| V02-flutter-doctor-running-en-dark | REQUIRED | flutter | doctor-running | en | dark | static | Flutter 页，SDK 可用 | 启动可延迟的 Doctor | 组件/变量 P07-F02（无同状态原图，英文译文） | 运行反馈、取消可达，阻止重复启动 | 窗口+AX+输入行为 |
| V02-flutter-doctor-running-en-light | REQUIRED | flutter | doctor-running | en | light | static | Flutter 页，SDK 可用 | 启动可延迟的 Doctor | 组件/变量 P07-F02（无同状态原图，英文译文与浅色变量） | 运行反馈、取消可达，阻止重复启动 | 窗口+AX+输入行为 |
| V02-flutter-doctor-success-zh-Hans-dark | REQUIRED | flutter | doctor-success | zh-Hans | dark | static | Flutter 页，Doctor 嵌入受控成功输出 | 返回成功及三项示例；打开完整输出 | 组件/变量 P07-F02;P07-F06（无同状态原图） | 成功摘要、完整输出入口；三例文字和布局角色供对照 | 窗口+输出面板+AX+原文 |
| V02-flutter-doctor-success-zh-Hans-light | REQUIRED | flutter | doctor-success | zh-Hans | light | static | Flutter 页，Doctor 嵌入受控成功输出 | 返回成功及三项示例；打开完整输出 | 组件/变量 P07-F02;P07-F06（无同状态原图，浅色变量） | 成功摘要、完整输出入口；三例文字和布局角色供对照 | 窗口+输出面板+AX+原文 |
| V02-flutter-doctor-success-en-dark | REQUIRED | flutter | doctor-success | en | dark | static | Flutter 页，Doctor 嵌入受控成功输出 | 返回成功及三项示例；打开完整输出 | 组件/变量 P07-F02;P07-F06（无同状态原图，英文译文） | 成功摘要、完整输出入口；三例文字和布局角色供对照 | 窗口+输出面板+AX+原文 |
| V02-flutter-doctor-success-en-light | REQUIRED | flutter | doctor-success | en | light | static | Flutter 页，Doctor 嵌入受控成功输出 | 返回成功及三项示例；打开完整输出 | 组件/变量 P07-F02;P07-F06（无同状态原图，英文译文与浅色变量） | 成功摘要、完整输出入口；三例文字和布局角色供对照 | 窗口+输出面板+AX+原文 |
| V02-flutter-doctor-cancel-zh-Hans-dark | REQUIRED | flutter | doctor-cancel | zh-Hans | dark | static | Doctor 延迟运行中 | 点取消，等待本次任务确认取消 | 组件/变量 P07-F02;P07-F06（无同状态原图） | 清除进行中状态，不把旧结果标成成功，重新可检查 | 窗口+前后帧+AX |
| V02-flutter-doctor-cancel-zh-Hans-light | REQUIRED | flutter | doctor-cancel | zh-Hans | light | static | Doctor 延迟运行中 | 点取消，等待本次任务确认取消 | 组件/变量 P07-F02;P07-F06（无同状态原图，浅色变量） | 清除进行中状态，不把旧结果标成成功，重新可检查 | 窗口+前后帧+AX |
| V02-flutter-doctor-cancel-en-dark | REQUIRED | flutter | doctor-cancel | en | dark | static | Doctor 延迟运行中 | 点取消，等待本次任务确认取消 | 组件/变量 P07-F02;P07-F06（无同状态原图，英文译文） | 清除进行中状态，不把旧结果标成成功，重新可检查 | 窗口+前后帧+AX |
| V02-flutter-doctor-cancel-en-light | REQUIRED | flutter | doctor-cancel | en | light | static | Doctor 延迟运行中 | 点取消，等待本次任务确认取消 | 组件/变量 P07-F02;P07-F06（无同状态原图，英文译文与浅色变量） | 清除进行中状态，不把旧结果标成成功，重新可检查 | 窗口+前后帧+AX |
| V02-flutter-doctor-failed-zh-Hans-dark | REQUIRED | flutter | doctor-failed | zh-Hans | dark | static | Flutter 页，SDK 可用 | Doctor 返回非零并带可用部分输出 | 组件/变量 P07-F02;P07-F06（无同状态原图） | 失败原因、重试、可访问已产出原文 | 窗口+AX+失败原文 |
| V02-flutter-doctor-failed-zh-Hans-light | REQUIRED | flutter | doctor-failed | zh-Hans | light | static | Flutter 页，SDK 可用 | Doctor 返回非零并带可用部分输出 | 组件/变量 P07-F02;P07-F06（无同状态原图，浅色变量） | 失败原因、重试、可访问已产出原文 | 窗口+AX+失败原文 |
| V02-flutter-doctor-failed-en-dark | REQUIRED | flutter | doctor-failed | en | dark | static | Flutter 页，SDK 可用 | Doctor 返回非零并带可用部分输出 | 组件/变量 P07-F02;P07-F06（无同状态原图，英文译文） | 失败原因、重试、可访问已产出原文 | 窗口+AX+失败原文 |
| V02-flutter-doctor-failed-en-light | REQUIRED | flutter | doctor-failed | en | light | static | Flutter 页，SDK 可用 | Doctor 返回非零并带可用部分输出 | 组件/变量 P07-F02;P07-F06（无同状态原图，英文译文与浅色变量） | 失败原因、重试、可访问已产出原文 | 窗口+AX+失败原文 |
| V02-flutter-doctor-retry-zh-Hans-dark | REQUIRED | flutter | doctor-retry | zh-Hans | dark | static | Flutter 页，已显示 Doctor 失败 | 改为成功输入并重试 | 组件/变量 P07-F02;P07-F06（无同状态原图） | 失败反馈被新运行和新结果替换 | 窗口+前后帧+AX |
| V02-flutter-doctor-retry-zh-Hans-light | REQUIRED | flutter | doctor-retry | zh-Hans | light | static | Flutter 页，已显示 Doctor 失败 | 改为成功输入并重试 | 组件/变量 P07-F02;P07-F06（无同状态原图，浅色变量） | 失败反馈被新运行和新结果替换 | 窗口+前后帧+AX |
| V02-flutter-doctor-retry-en-dark | REQUIRED | flutter | doctor-retry | en | dark | static | Flutter 页，已显示 Doctor 失败 | 改为成功输入并重试 | 组件/变量 P07-F02;P07-F06（无同状态原图，英文译文） | 失败反馈被新运行和新结果替换 | 窗口+前后帧+AX |
| V02-flutter-doctor-retry-en-light | REQUIRED | flutter | doctor-retry | en | light | static | Flutter 页，已显示 Doctor 失败 | 改为成功输入并重试 | 组件/变量 P07-F02;P07-F06（无同状态原图，英文译文与浅色变量） | 失败反馈被新运行和新结果替换 | 窗口+前后帧+AX |
| V02-flutter-doctor-long-output-zh-Hans-dark | REQUIRED | flutter | doctor-long-output | zh-Hans | dark | static | Flutter 页，Doctor 已产出长输出 | 打开完整输出，滚到末行，选中并复制原文 | 组件/变量 P07-F06;P07-F02（无同状态原图） | 不丢尾行，等宽字、选中、滚动、可读性与 Esc 返回 | 窗口+输出区域首尾+选中记录 |
| V02-flutter-doctor-long-output-zh-Hans-light | REQUIRED | flutter | doctor-long-output | zh-Hans | light | static | Flutter 页，Doctor 已产出长输出 | 打开完整输出，滚到末行，选中并复制原文 | 组件/变量 P07-F06;P07-F02（无同状态原图，浅色变量） | 不丢尾行，等宽字、选中、滚动、可读性与 Esc 返回 | 窗口+输出区域首尾+选中记录 |
| V02-flutter-doctor-long-output-en-dark | REQUIRED | flutter | doctor-long-output | en | dark | static | Flutter 页，Doctor 已产出长输出 | 打开完整输出，滚到末行，选中并复制原文 | 组件/变量 P07-F06;P07-F02（无同状态原图，英文译文） | 不丢尾行，等宽字、选中、滚动、可读性与 Esc 返回 | 窗口+输出区域首尾+选中记录 |
| V02-flutter-doctor-long-output-en-light | REQUIRED | flutter | doctor-long-output | en | light | static | Flutter 页，Doctor 已产出长输出 | 打开完整输出，滚到末行，选中并复制原文 | 组件/变量 P07-F06;P07-F02（无同状态原图，英文译文与浅色变量） | 不丢尾行，等宽字、选中、滚动、可读性与 Esc 返回 | 窗口+输出区域首尾+选中记录 |
| V02-flutter-doctor-project-change-zh-Hans-dark | REQUIRED | flutter | doctor-project-change | zh-Hans | dark | static | Flutter 页，项目 A 已有结果 | 切到不同 SDK 环境的项目 B | 组件/变量 P07-F02;P07-F06（无同状态原图） | A 的摘要和原文不会出现在 B，之后检查归属 B | 窗口前后+项目与输出归属记录 |
| V02-flutter-doctor-project-change-zh-Hans-light | REQUIRED | flutter | doctor-project-change | zh-Hans | light | static | Flutter 页，项目 A 已有结果 | 切到不同 SDK 环境的项目 B | 组件/变量 P07-F02;P07-F06（无同状态原图，浅色变量） | A 的摘要和原文不会出现在 B，之后检查归属 B | 窗口前后+项目与输出归属记录 |
| V02-flutter-doctor-project-change-en-dark | REQUIRED | flutter | doctor-project-change | en | dark | static | Flutter 页，项目 A 已有结果 | 切到不同 SDK 环境的项目 B | 组件/变量 P07-F02;P07-F06（无同状态原图，英文译文） | A 的摘要和原文不会出现在 B，之后检查归属 B | 窗口前后+项目与输出归属记录 |
| V02-flutter-doctor-project-change-en-light | REQUIRED | flutter | doctor-project-change | en | light | static | Flutter 页，项目 A 已有结果 | 切到不同 SDK 环境的项目 B | 组件/变量 P07-F02;P07-F06（无同状态原图，英文译文与浅色变量） | A 的摘要和原文不会出现在 B，之后检查归属 B | 窗口前后+项目与输出归属记录 |
| V02-flutter-doctor-sdk-change-zh-Hans-dark | REQUIRED | flutter | doctor-sdk-change | zh-Hans | dark | static | Flutter 页，SDK A 已有结果 | 切换到另一个有效 SDK B，保留项目 | 组件/变量 P07-F02;P07-F06（无同状态原图） | 旧结果即时失效，随后检查读取 SDK B | 窗口前后+SDK与输出归属记录 |
| V02-flutter-doctor-sdk-change-zh-Hans-light | REQUIRED | flutter | doctor-sdk-change | zh-Hans | light | static | Flutter 页，SDK A 已有结果 | 切换到另一个有效 SDK B，保留项目 | 组件/变量 P07-F02;P07-F06（无同状态原图，浅色变量） | 旧结果即时失效，随后检查读取 SDK B | 窗口前后+SDK与输出归属记录 |
| V02-flutter-doctor-sdk-change-en-dark | REQUIRED | flutter | doctor-sdk-change | en | dark | static | Flutter 页，SDK A 已有结果 | 切换到另一个有效 SDK B，保留项目 | 组件/变量 P07-F02;P07-F06（无同状态原图，英文译文） | 旧结果即时失效，随后检查读取 SDK B | 窗口前后+SDK与输出归属记录 |
| V02-flutter-doctor-sdk-change-en-light | REQUIRED | flutter | doctor-sdk-change | en | light | static | Flutter 页，SDK A 已有结果 | 切换到另一个有效 SDK B，保留项目 | 组件/变量 P07-F02;P07-F06（无同状态原图，英文译文与浅色变量） | 旧结果即时失效，随后检查读取 SDK B | 窗口前后+SDK与输出归属记录 |
| V02-flutter-keyboard-order-zh-Hans-dark | REQUIRED | flutter | keyboard-order | zh-Hans | dark | static | Flutter 页，选择有效手动 SDK | Tab／Shift-Tab 遍历来源、选路径、FVM、检查与输出动作；通过键盘进入目录选择器 | 组件/变量 P07-F02;P07-F07（无同状态原图） | 原生焦点顺序、可达控件和名称可读，开关状态正确，目录关闭后焦点回入口 | 窗口+键盘录像+焦点AX |
| V02-flutter-keyboard-order-zh-Hans-light | REQUIRED | flutter | keyboard-order | zh-Hans | light | static | Flutter 页，选择有效手动 SDK | Tab／Shift-Tab 遍历来源、选路径、FVM、检查与输出动作；通过键盘进入目录选择器 | 组件/变量 P07-F02;P07-F07（无同状态原图，浅色变量） | 原生焦点顺序、可达控件和名称可读，开关状态正确，目录关闭后焦点回入口 | 窗口+键盘录像+焦点AX |
| V02-flutter-keyboard-order-en-dark | REQUIRED | flutter | keyboard-order | en | dark | static | Flutter 页，选择有效手动 SDK | Tab／Shift-Tab 遍历来源、选路径、FVM、检查与输出动作；通过键盘进入目录选择器 | 组件/变量 P07-F02;P07-F07（无同状态原图，英文译文） | 原生焦点顺序、可达控件和名称可读，开关状态正确，目录关闭后焦点回入口 | 窗口+键盘录像+焦点AX |
| V02-flutter-keyboard-order-en-light | REQUIRED | flutter | keyboard-order | en | light | static | Flutter 页，选择有效手动 SDK | Tab／Shift-Tab 遍历来源、选路径、FVM、检查与输出动作；通过键盘进入目录选择器 | 组件/变量 P07-F02;P07-F07（无同状态原图，英文译文与浅色变量） | 原生焦点顺序、可达控件和名称可读，开关状态正确，目录关闭后焦点回入口 | 窗口+键盘录像+焦点AX |

### V03 关于布局、许可与操作

| 用例 ID | 适用 | 窗口 | 状态 | 语言 | 外观 | 帧 | 操作起点 | 选择或故障输入 | 参考 ID 和类型 | 检查项或不适用原因 | 所需证据 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| V03-settings-about-layout-zh-Hans-dark | REQUIRED | settings-about | layout | zh-Hans | dark | static | 设置 → 关于 | 待检查；使用原画板版本、构建号、文案 | Figma 原图 P07-F03（匹配区域） | 四角、标题、品牌、版本、反馈、三链接及该窗专属内容边界 | 窗口+原生标题栏局部 |
| V03-settings-about-layout-zh-Hans-light | REQUIRED | settings-about | layout | zh-Hans | light | static | 设置 → 关于 | 待检查；使用原画板版本、构建号、文案 | 组件/变量 P07-F03（浅色变量） | 四角、标题、品牌、版本、反馈、三链接及该窗专属内容边界 | 窗口+原生标题栏局部 |
| V03-settings-about-layout-en-dark | REQUIRED | settings-about | layout | en | dark | static | 设置 → 关于 | 待检查；使用原画板版本、构建号、文案 | 组件/变量 P07-F03（英文译文） | 四角、标题、品牌、版本、反馈、三链接及该窗专属内容边界 | 窗口+原生标题栏局部 |
| V03-settings-about-layout-en-light | REQUIRED | settings-about | layout | en | light | static | 设置 → 关于 | 待检查；使用原画板版本、构建号、文案 | 组件/变量 P07-F03（英文译文与浅色变量） | 四角、标题、品牌、版本、反馈、三链接及该窗专属内容边界 | 窗口+原生标题栏局部 |
| V03-settings-about-version-long-zh-Hans-dark | REQUIRED | settings-about | version-long | zh-Hans | dark | static | 设置 → 关于 | Bundle 使用多位版本和构建号；检查中英文链接与说明 | 组件/变量 P07-F03（无同状态原图） | 品牌、版本、链接及其长文案可读；设置侧栏也保留完整真实版本 | 窗口+文本局部+AX |
| V03-settings-about-version-long-zh-Hans-light | REQUIRED | settings-about | version-long | zh-Hans | light | static | 设置 → 关于 | Bundle 使用多位版本和构建号；检查中英文链接与说明 | 组件/变量 P07-F03（无同状态原图，浅色变量） | 品牌、版本、链接及其长文案可读；设置侧栏也保留完整真实版本 | 窗口+文本局部+AX |
| V03-settings-about-version-long-en-dark | REQUIRED | settings-about | version-long | en | dark | static | 设置 → 关于 | Bundle 使用多位版本和构建号；检查中英文链接与说明 | 组件/变量 P07-F03（无同状态原图，英文译文） | 品牌、版本、链接及其长文案可读；设置侧栏也保留完整真实版本 | 窗口+文本局部+AX |
| V03-settings-about-version-long-en-light | REQUIRED | settings-about | version-long | en | light | static | 设置 → 关于 | Bundle 使用多位版本和构建号；检查中英文链接与说明 | 组件/变量 P07-F03（无同状态原图，英文译文与浅色变量） | 品牌、版本、链接及其长文案可读；设置侧栏也保留完整真实版本 | 窗口+文本局部+AX |
| V03-settings-about-github-url-zh-Hans-dark | REQUIRED | settings-about | github-url | zh-Hans | dark | static | 设置 → 关于 | 点击 Github 链接或本地化的项目主页按钮 | 系统/实测；组件 P07-F03（入口或角色） | 由默认浏览器打开仓库首页 | 窗口+点击录像或目标URL |
| V03-settings-about-github-url-zh-Hans-light | REQUIRED | settings-about | github-url | zh-Hans | light | static | 设置 → 关于 | 点击 Github 链接或本地化的项目主页按钮 | 系统/实测；组件 P07-F03（入口或角色，浅色变量） | 由默认浏览器打开仓库首页 | 窗口+点击录像或目标URL |
| V03-settings-about-github-url-en-dark | REQUIRED | settings-about | github-url | en | dark | static | 设置 → 关于 | 点击 Github 链接或本地化的项目主页按钮 | 系统/实测；组件 P07-F03（入口或角色，英文译文） | 由默认浏览器打开仓库首页 | 窗口+点击录像或目标URL |
| V03-settings-about-github-url-en-light | REQUIRED | settings-about | github-url | en | light | static | 设置 → 关于 | 点击 Github 链接或本地化的项目主页按钮 | 系统/实测；组件 P07-F03（入口或角色，英文译文与浅色变量） | 由默认浏览器打开仓库首页 | 窗口+点击录像或目标URL |
| V03-settings-about-docs-url-zh-Hans-dark | REQUIRED | settings-about | docs-url | zh-Hans | dark | static | 设置 → 关于 | 点击使用文档／Documentation | 系统/实测；组件 P07-F03（入口或角色） | 由默认浏览器打开当前 README | 窗口+点击录像或目标URL |
| V03-settings-about-docs-url-zh-Hans-light | REQUIRED | settings-about | docs-url | zh-Hans | light | static | 设置 → 关于 | 点击使用文档／Documentation | 系统/实测；组件 P07-F03（入口或角色，浅色变量） | 由默认浏览器打开当前 README | 窗口+点击录像或目标URL |
| V03-settings-about-docs-url-en-dark | REQUIRED | settings-about | docs-url | en | dark | static | 设置 → 关于 | 点击使用文档／Documentation | 系统/实测；组件 P07-F03（入口或角色，英文译文） | 由默认浏览器打开当前 README | 窗口+点击录像或目标URL |
| V03-settings-about-docs-url-en-light | REQUIRED | settings-about | docs-url | en | light | static | 设置 → 关于 | 点击使用文档／Documentation | 系统/实测；组件 P07-F03（入口或角色，英文译文与浅色变量） | 由默认浏览器打开当前 README | 窗口+点击录像或目标URL |
| V03-settings-about-license-url-zh-Hans-dark | REQUIRED | settings-about | license-url | zh-Hans | dark | static | 设置 → 关于 | 点击项目许可证／Project License | 系统/实测；组件 P07-F03（入口或角色） | 由默认浏览器打开当前 LICENSE；校验许可和版权归属 | 窗口+点击录像或目标URL |
| V03-settings-about-license-url-zh-Hans-light | REQUIRED | settings-about | license-url | zh-Hans | light | static | 设置 → 关于 | 点击项目许可证／Project License | 系统/实测；组件 P07-F03（入口或角色，浅色变量） | 由默认浏览器打开当前 LICENSE；校验许可和版权归属 | 窗口+点击录像或目标URL |
| V03-settings-about-license-url-en-dark | REQUIRED | settings-about | license-url | en | dark | static | 设置 → 关于 | 点击项目许可证／Project License | 系统/实测；组件 P07-F03（入口或角色，英文译文） | 由默认浏览器打开当前 LICENSE；校验许可和版权归属 | 窗口+点击录像或目标URL |
| V03-settings-about-license-url-en-light | REQUIRED | settings-about | license-url | en | light | static | 设置 → 关于 | 点击项目许可证／Project License | 系统/实测；组件 P07-F03（入口或角色，英文译文与浅色变量） | 由默认浏览器打开当前 LICENSE；校验许可和版权归属 | 窗口+点击录像或目标URL |
| V03-settings-about-keyboard-focus-zh-Hans-dark | REQUIRED | settings-about | keyboard-focus | zh-Hans | dark | static | 设置 → 关于 | 用 Tab／Shift-Tab 聚焦更新和三链接；按 Return 或 Space 激活 | 组件/变量 P07-F03（无同状态原图） | 原生焦点顺序、名称、可达；窗口控制保持预期 | 窗口+焦点AX+键盘录像 |
| V03-settings-about-keyboard-focus-zh-Hans-light | REQUIRED | settings-about | keyboard-focus | zh-Hans | light | static | 设置 → 关于 | 用 Tab／Shift-Tab 聚焦更新和三链接；按 Return 或 Space 激活 | 组件/变量 P07-F03（无同状态原图，浅色变量） | 原生焦点顺序、名称、可达；窗口控制保持预期 | 窗口+焦点AX+键盘录像 |
| V03-settings-about-keyboard-focus-en-dark | REQUIRED | settings-about | keyboard-focus | en | dark | static | 设置 → 关于 | 用 Tab／Shift-Tab 聚焦更新和三链接；按 Return 或 Space 激活 | 组件/变量 P07-F03（无同状态原图，英文译文） | 原生焦点顺序、名称、可达；窗口控制保持预期 | 窗口+焦点AX+键盘录像 |
| V03-settings-about-keyboard-focus-en-light | REQUIRED | settings-about | keyboard-focus | en | light | static | 设置 → 关于 | 用 Tab／Shift-Tab 聚焦更新和三链接；按 Return 或 Space 激活 | 组件/变量 P07-F03（无同状态原图，英文译文与浅色变量） | 原生焦点顺序、名称、可达；窗口控制保持预期 | 窗口+焦点AX+键盘录像 |
| V03-settings-about-control-disabled-zh-Hans-dark | REQUIRED | settings-about | control-disabled | zh-Hans | dark | f01 | 设置 → 关于 | 固定检查中，尝试再次触发更新并检查三个链接 | Figma 原图 P07-U02（仅按钮），组件/变量 P07-F03（宿主） | 更新不可重复发起，链接仍可达，禁用/焦点以 AX 和动作核对 | 窗口+按钮局部+AX+操作计数 |
| V03-settings-about-control-disabled-zh-Hans-light | REQUIRED | settings-about | control-disabled | zh-Hans | light | f01 | 设置 → 关于 | 固定检查中，尝试再次触发更新并检查三个链接 | 组件/变量 P07-F03;P07-U02（浅色变量，无同帧原图） | 更新不可重复发起，链接仍可达，禁用/焦点以 AX 和动作核对 | 窗口+按钮局部+AX+操作计数 |
| V03-settings-about-control-disabled-en-dark | REQUIRED | settings-about | control-disabled | en | dark | f01 | 设置 → 关于 | 固定检查中，尝试再次触发更新并检查三个链接 | 组件/变量 P07-F03;P07-U02（英文译文，无同帧原图） | 更新不可重复发起，链接仍可达，禁用/焦点以 AX 和动作核对 | 窗口+按钮局部+AX+操作计数 |
| V03-settings-about-control-disabled-en-light | REQUIRED | settings-about | control-disabled | en | light | f01 | 设置 → 关于 | 固定检查中，尝试再次触发更新并检查三个链接 | 组件/变量 P07-F03;P07-U02（英文译文与浅色变量，无同帧原图） | 更新不可重复发起，链接仍可达，禁用/焦点以 AX 和动作核对 | 窗口+按钮局部+AX+操作计数 |
| V03-settings-about-sidebar-version-zh-Hans-dark | REQUIRED | settings-about | sidebar-version | zh-Hans | dark | static | 设置 → 关于 | 以同 Bundle 依次访问通用、Flutter、关于，截取侧栏架构 | 组件/变量 P07-F01;P07-F02;P07-F03（无同状态原图） | 三个设置页底部同版本与构建号，说明字号和位置一致 | 三个设置窗口+Bundle记录 |
| V03-settings-about-sidebar-version-zh-Hans-light | REQUIRED | settings-about | sidebar-version | zh-Hans | light | static | 设置 → 关于 | 以同 Bundle 依次访问通用、Flutter、关于，截取侧栏架构 | 组件/变量 P07-F01;P07-F02;P07-F03（无同状态原图，浅色变量） | 三个设置页底部同版本与构建号，说明字号和位置一致 | 三个设置窗口+Bundle记录 |
| V03-settings-about-sidebar-version-en-dark | REQUIRED | settings-about | sidebar-version | en | dark | static | 设置 → 关于 | 以同 Bundle 依次访问通用、Flutter、关于，截取侧栏架构 | 组件/变量 P07-F01;P07-F02;P07-F03（无同状态原图，英文译文） | 三个设置页底部同版本与构建号，说明字号和位置一致 | 三个设置窗口+Bundle记录 |
| V03-settings-about-sidebar-version-en-light | REQUIRED | settings-about | sidebar-version | en | light | static | 设置 → 关于 | 以同 Bundle 依次访问通用、Flutter、关于，截取侧栏架构 | 组件/变量 P07-F01;P07-F02;P07-F03（无同状态原图，英文译文与浅色变量） | 三个设置页底部同版本与构建号，说明字号和位置一致 | 三个设置窗口+Bundle记录 |
| V03-settings-about-license-help-zh-Hans-dark | REQUIRED | settings-about | license-help | zh-Hans | dark | static | 设置 → 关于 | 光标停留许可证链接，等待原生帮助文字 | 组件/变量 P07-F03（无同状态原图） | 帮助正文可读出 MIT 与 Svame，保留三段布局 | 窗口+提示局部 |
| V03-settings-about-license-help-zh-Hans-light | REQUIRED | settings-about | license-help | zh-Hans | light | static | 设置 → 关于 | 光标停留许可证链接，等待原生帮助文字 | 组件/变量 P07-F03（无同状态原图，浅色变量） | 帮助正文可读出 MIT 与 Svame，保留三段布局 | 窗口+提示局部 |
| V03-settings-about-license-help-en-dark | REQUIRED | settings-about | license-help | en | dark | static | 设置 → 关于 | 光标停留许可证链接，等待原生帮助文字 | 组件/变量 P07-F03（无同状态原图，英文译文） | 帮助正文可读出 MIT 与 Svame，保留三段布局 | 窗口+提示局部 |
| V03-settings-about-license-help-en-light | REQUIRED | settings-about | license-help | en | light | static | 设置 → 关于 | 光标停留许可证链接，等待原生帮助文字 | 组件/变量 P07-F03（无同状态原图，英文译文与浅色变量） | 帮助正文可读出 MIT 与 Svame，保留三段布局 | 窗口+提示局部 |
| V03-settings-about-license-ax-zh-Hans-dark | REQUIRED | settings-about | license-ax | zh-Hans | dark | static | 设置 → 关于 | 聚焦项目许可证链接并读取 AX 说明 | 组件/变量 P07-F03（无同状态原图） | AX 说明可读出 MIT 与 Svame，真实目标由 license-url 核对 | 窗口+AX帮助字段/朗读记录 |
| V03-settings-about-license-ax-zh-Hans-light | REQUIRED | settings-about | license-ax | zh-Hans | light | static | 设置 → 关于 | 聚焦项目许可证链接并读取 AX 说明 | 组件/变量 P07-F03（无同状态原图，浅色变量） | AX 说明可读出 MIT 与 Svame，真实目标由 license-url 核对 | 窗口+AX帮助字段/朗读记录 |
| V03-settings-about-license-ax-en-dark | REQUIRED | settings-about | license-ax | en | dark | static | 设置 → 关于 | 聚焦项目许可证链接并读取 AX 说明 | 组件/变量 P07-F03（无同状态原图，英文译文） | AX 说明可读出 MIT 与 Svame，真实目标由 license-url 核对 | 窗口+AX帮助字段/朗读记录 |
| V03-settings-about-license-ax-en-light | REQUIRED | settings-about | license-ax | en | light | static | 设置 → 关于 | 聚焦项目许可证链接并读取 AX 说明 | 组件/变量 P07-F03（无同状态原图，英文译文与浅色变量） | AX 说明可读出 MIT 与 Svame，真实目标由 license-url 核对 | 窗口+AX帮助字段/朗读记录 |
| V03-settings-about-license-visible-zh-Hans-dark | N/A | settings-about | license-visible | zh-Hans | dark | static | 设置 → 关于 | 保持设置卡片的三段布局 | —（P07-F03，范围说明） | D-09 将设置内许可与署名放在许可证链接帮助/AX，独立可见许可行只属于独立窗 | — |
| V03-settings-about-license-visible-zh-Hans-light | N/A | settings-about | license-visible | zh-Hans | light | static | 设置 → 关于 | 保持设置卡片的三段布局 | —（P07-F03，范围说明） | D-09 将设置内许可与署名放在许可证链接帮助/AX，独立可见许可行只属于独立窗 | — |
| V03-settings-about-license-visible-en-dark | N/A | settings-about | license-visible | en | dark | static | 设置 → 关于 | 保持设置卡片的三段布局 | —（P07-F03，范围说明） | D-09 将设置内许可与署名放在许可证链接帮助/AX，独立可见许可行只属于独立窗 | — |
| V03-settings-about-license-visible-en-light | N/A | settings-about | license-visible | en | light | static | 设置 → 关于 | 保持设置卡片的三段布局 | —（P07-F03，范围说明） | D-09 将设置内许可与署名放在许可证链接帮助/AX，独立可见许可行只属于独立窗 | — |
| V03-settings-about-attribution-visible-zh-Hans-dark | N/A | settings-about | attribution-visible | zh-Hans | dark | static | 设置 → 关于 | 保持设置卡片的三段布局 | —（P07-F03，范围说明） | D-09 将设置内许可与署名放在许可证链接帮助/AX，独立可见署名行只属于独立窗 | — |
| V03-settings-about-attribution-visible-zh-Hans-light | N/A | settings-about | attribution-visible | zh-Hans | light | static | 设置 → 关于 | 保持设置卡片的三段布局 | —（P07-F03，范围说明） | D-09 将设置内许可与署名放在许可证链接帮助/AX，独立可见署名行只属于独立窗 | — |
| V03-settings-about-attribution-visible-en-dark | N/A | settings-about | attribution-visible | en | dark | static | 设置 → 关于 | 保持设置卡片的三段布局 | —（P07-F03，范围说明） | D-09 将设置内许可与署名放在许可证链接帮助/AX，独立可见署名行只属于独立窗 | — |
| V03-settings-about-attribution-visible-en-light | N/A | settings-about | attribution-visible | en | light | static | 设置 → 关于 | 保持设置卡片的三段布局 | —（P07-F03，范围说明） | D-09 将设置内许可与署名放在许可证链接帮助/AX，独立可见署名行只属于独立窗 | — |
| V03-about-layout-zh-Hans-dark | REQUIRED | about | layout | zh-Hans | dark | static | 独立关于窗口 | 待检查；使用原画板版本、构建号、文案 | Figma 原图 P07-F04（匹配区域） | 四角、标题、品牌、版本、反馈、三链接及该窗专属内容边界 | 窗口+原生标题栏局部 |
| V03-about-layout-zh-Hans-light | REQUIRED | about | layout | zh-Hans | light | static | 独立关于窗口 | 待检查；使用原画板版本、构建号、文案 | 组件/变量 P07-F04（浅色变量） | 四角、标题、品牌、版本、反馈、三链接及该窗专属内容边界 | 窗口+原生标题栏局部 |
| V03-about-layout-en-dark | REQUIRED | about | layout | en | dark | static | 独立关于窗口 | 待检查；使用原画板版本、构建号、文案 | 组件/变量 P07-F04（英文译文） | 四角、标题、品牌、版本、反馈、三链接及该窗专属内容边界 | 窗口+原生标题栏局部 |
| V03-about-layout-en-light | REQUIRED | about | layout | en | light | static | 独立关于窗口 | 待检查；使用原画板版本、构建号、文案 | 组件/变量 P07-F04（英文译文与浅色变量） | 四角、标题、品牌、版本、反馈、三链接及该窗专属内容边界 | 窗口+原生标题栏局部 |
| V03-about-version-long-zh-Hans-dark | REQUIRED | about | version-long | zh-Hans | dark | static | 独立关于窗口 | Bundle 使用多位版本和构建号；检查中英文链接与说明 | 组件/变量 P07-F04（无同状态原图） | 品牌、版本、链接及其长文案可读；设置侧栏也保留完整真实版本 | 窗口+文本局部+AX |
| V03-about-version-long-zh-Hans-light | REQUIRED | about | version-long | zh-Hans | light | static | 独立关于窗口 | Bundle 使用多位版本和构建号；检查中英文链接与说明 | 组件/变量 P07-F04（无同状态原图，浅色变量） | 品牌、版本、链接及其长文案可读；设置侧栏也保留完整真实版本 | 窗口+文本局部+AX |
| V03-about-version-long-en-dark | REQUIRED | about | version-long | en | dark | static | 独立关于窗口 | Bundle 使用多位版本和构建号；检查中英文链接与说明 | 组件/变量 P07-F04（无同状态原图，英文译文） | 品牌、版本、链接及其长文案可读；设置侧栏也保留完整真实版本 | 窗口+文本局部+AX |
| V03-about-version-long-en-light | REQUIRED | about | version-long | en | light | static | 独立关于窗口 | Bundle 使用多位版本和构建号；检查中英文链接与说明 | 组件/变量 P07-F04（无同状态原图，英文译文与浅色变量） | 品牌、版本、链接及其长文案可读；设置侧栏也保留完整真实版本 | 窗口+文本局部+AX |
| V03-about-github-url-zh-Hans-dark | REQUIRED | about | github-url | zh-Hans | dark | static | 独立关于窗口 | 点击 Github 链接或本地化的项目主页按钮 | 系统/实测；组件 P07-F04（入口或角色） | 由默认浏览器打开仓库首页 | 窗口+点击录像或目标URL |
| V03-about-github-url-zh-Hans-light | REQUIRED | about | github-url | zh-Hans | light | static | 独立关于窗口 | 点击 Github 链接或本地化的项目主页按钮 | 系统/实测；组件 P07-F04（入口或角色，浅色变量） | 由默认浏览器打开仓库首页 | 窗口+点击录像或目标URL |
| V03-about-github-url-en-dark | REQUIRED | about | github-url | en | dark | static | 独立关于窗口 | 点击 Github 链接或本地化的项目主页按钮 | 系统/实测；组件 P07-F04（入口或角色，英文译文） | 由默认浏览器打开仓库首页 | 窗口+点击录像或目标URL |
| V03-about-github-url-en-light | REQUIRED | about | github-url | en | light | static | 独立关于窗口 | 点击 Github 链接或本地化的项目主页按钮 | 系统/实测；组件 P07-F04（入口或角色，英文译文与浅色变量） | 由默认浏览器打开仓库首页 | 窗口+点击录像或目标URL |
| V03-about-docs-url-zh-Hans-dark | REQUIRED | about | docs-url | zh-Hans | dark | static | 独立关于窗口 | 点击使用文档／Documentation | 系统/实测；组件 P07-F04（入口或角色） | 由默认浏览器打开当前 README | 窗口+点击录像或目标URL |
| V03-about-docs-url-zh-Hans-light | REQUIRED | about | docs-url | zh-Hans | light | static | 独立关于窗口 | 点击使用文档／Documentation | 系统/实测；组件 P07-F04（入口或角色，浅色变量） | 由默认浏览器打开当前 README | 窗口+点击录像或目标URL |
| V03-about-docs-url-en-dark | REQUIRED | about | docs-url | en | dark | static | 独立关于窗口 | 点击使用文档／Documentation | 系统/实测；组件 P07-F04（入口或角色，英文译文） | 由默认浏览器打开当前 README | 窗口+点击录像或目标URL |
| V03-about-docs-url-en-light | REQUIRED | about | docs-url | en | light | static | 独立关于窗口 | 点击使用文档／Documentation | 系统/实测；组件 P07-F04（入口或角色，英文译文与浅色变量） | 由默认浏览器打开当前 README | 窗口+点击录像或目标URL |
| V03-about-license-url-zh-Hans-dark | REQUIRED | about | license-url | zh-Hans | dark | static | 独立关于窗口 | 点击项目许可证／Project License | 系统/实测；组件 P07-F04（入口或角色） | 由默认浏览器打开当前 LICENSE；校验许可和版权归属 | 窗口+点击录像或目标URL |
| V03-about-license-url-zh-Hans-light | REQUIRED | about | license-url | zh-Hans | light | static | 独立关于窗口 | 点击项目许可证／Project License | 系统/实测；组件 P07-F04（入口或角色，浅色变量） | 由默认浏览器打开当前 LICENSE；校验许可和版权归属 | 窗口+点击录像或目标URL |
| V03-about-license-url-en-dark | REQUIRED | about | license-url | en | dark | static | 独立关于窗口 | 点击项目许可证／Project License | 系统/实测；组件 P07-F04（入口或角色，英文译文） | 由默认浏览器打开当前 LICENSE；校验许可和版权归属 | 窗口+点击录像或目标URL |
| V03-about-license-url-en-light | REQUIRED | about | license-url | en | light | static | 独立关于窗口 | 点击项目许可证／Project License | 系统/实测；组件 P07-F04（入口或角色，英文译文与浅色变量） | 由默认浏览器打开当前 LICENSE；校验许可和版权归属 | 窗口+点击录像或目标URL |
| V03-about-keyboard-focus-zh-Hans-dark | REQUIRED | about | keyboard-focus | zh-Hans | dark | static | 独立关于窗口 | 用 Tab／Shift-Tab 聚焦更新和三链接；按 Return 或 Space 激活 | 组件/变量 P07-F04（无同状态原图） | 原生焦点顺序、名称、可达；窗口控制保持预期 | 窗口+焦点AX+键盘录像 |
| V03-about-keyboard-focus-zh-Hans-light | REQUIRED | about | keyboard-focus | zh-Hans | light | static | 独立关于窗口 | 用 Tab／Shift-Tab 聚焦更新和三链接；按 Return 或 Space 激活 | 组件/变量 P07-F04（无同状态原图，浅色变量） | 原生焦点顺序、名称、可达；窗口控制保持预期 | 窗口+焦点AX+键盘录像 |
| V03-about-keyboard-focus-en-dark | REQUIRED | about | keyboard-focus | en | dark | static | 独立关于窗口 | 用 Tab／Shift-Tab 聚焦更新和三链接；按 Return 或 Space 激活 | 组件/变量 P07-F04（无同状态原图，英文译文） | 原生焦点顺序、名称、可达；窗口控制保持预期 | 窗口+焦点AX+键盘录像 |
| V03-about-keyboard-focus-en-light | REQUIRED | about | keyboard-focus | en | light | static | 独立关于窗口 | 用 Tab／Shift-Tab 聚焦更新和三链接；按 Return 或 Space 激活 | 组件/变量 P07-F04（无同状态原图，英文译文与浅色变量） | 原生焦点顺序、名称、可达；窗口控制保持预期 | 窗口+焦点AX+键盘录像 |
| V03-about-control-disabled-zh-Hans-dark | REQUIRED | about | control-disabled | zh-Hans | dark | f01 | 独立关于窗口 | 固定检查中，尝试再次触发更新并检查三个链接 | Figma 原图 P07-U02（仅按钮），组件/变量 P07-F04（宿主） | 更新不可重复发起，链接仍可达，禁用/焦点以 AX 和动作核对 | 窗口+按钮局部+AX+操作计数 |
| V03-about-control-disabled-zh-Hans-light | REQUIRED | about | control-disabled | zh-Hans | light | f01 | 独立关于窗口 | 固定检查中，尝试再次触发更新并检查三个链接 | 组件/变量 P07-F04;P07-U02（浅色变量，无同帧原图） | 更新不可重复发起，链接仍可达，禁用/焦点以 AX 和动作核对 | 窗口+按钮局部+AX+操作计数 |
| V03-about-control-disabled-en-dark | REQUIRED | about | control-disabled | en | dark | f01 | 独立关于窗口 | 固定检查中，尝试再次触发更新并检查三个链接 | 组件/变量 P07-F04;P07-U02（英文译文，无同帧原图） | 更新不可重复发起，链接仍可达，禁用/焦点以 AX 和动作核对 | 窗口+按钮局部+AX+操作计数 |
| V03-about-control-disabled-en-light | REQUIRED | about | control-disabled | en | light | f01 | 独立关于窗口 | 固定检查中，尝试再次触发更新并检查三个链接 | 组件/变量 P07-F04;P07-U02（英文译文与浅色变量，无同帧原图） | 更新不可重复发起，链接仍可达，禁用/焦点以 AX 和动作核对 | 窗口+按钮局部+AX+操作计数 |
| V03-about-license-visible-zh-Hans-dark | REQUIRED | about | license-visible | zh-Hans | dark | static | 独立关于窗口 | 查看更新链接下方独立许可行 | Figma 原图 P07-F04（匹配区域） | MIT 许可证单独可见，按原图检查字体、色和 y=352 | 窗口+许可行局部 |
| V03-about-license-visible-zh-Hans-light | REQUIRED | about | license-visible | zh-Hans | light | static | 独立关于窗口 | 查看更新链接下方独立许可行 | 组件/变量 P07-F04（浅色变量） | MIT 许可证单独可见，按原图检查字体、色和 y=352 | 窗口+许可行局部 |
| V03-about-license-visible-en-dark | REQUIRED | about | license-visible | en | dark | static | 独立关于窗口 | 查看更新链接下方独立许可行 | 组件/变量 P07-F04（英文译文） | MIT 许可证单独可见，按原图检查字体、色和 y=352 | 窗口+许可行局部 |
| V03-about-license-visible-en-light | REQUIRED | about | license-visible | en | light | static | 独立关于窗口 | 查看更新链接下方独立许可行 | 组件/变量 P07-F04（英文译文与浅色变量） | MIT 许可证单独可见，按原图检查字体、色和 y=352 | 窗口+许可行局部 |
| V03-about-attribution-visible-zh-Hans-dark | REQUIRED | about | attribution-visible | zh-Hans | dark | static | 独立关于窗口 | 查看许可下方独立署名行 | Figma 原图 P07-F04（匹配区域） | Copyright (c) 2026 Svame 单独可见，检查 y=372 与可读性 | 窗口+署名行局部 |
| V03-about-attribution-visible-zh-Hans-light | REQUIRED | about | attribution-visible | zh-Hans | light | static | 独立关于窗口 | 查看许可下方独立署名行 | 组件/变量 P07-F04（浅色变量） | Copyright (c) 2026 Svame 单独可见，检查 y=372 与可读性 | 窗口+署名行局部 |
| V03-about-attribution-visible-en-dark | REQUIRED | about | attribution-visible | en | dark | static | 独立关于窗口 | 查看许可下方独立署名行 | 组件/变量 P07-F04（英文译文） | Copyright (c) 2026 Svame 单独可见，检查 y=372 与可读性 | 窗口+署名行局部 |
| V03-about-attribution-visible-en-light | REQUIRED | about | attribution-visible | en | light | static | 独立关于窗口 | 查看许可下方独立署名行 | 组件/变量 P07-F04（英文译文与浅色变量） | Copyright (c) 2026 Svame 单独可见，检查 y=372 与可读性 | 窗口+署名行局部 |
| V03-about-license-help-zh-Hans-dark | N/A | about | license-help | zh-Hans | dark | static | 独立关于窗口 | 核对可见 MIT 与 Svame 位置 | —（P07-F04，范围说明） | 设置链接专用的帮助取证适用于设置关于；独立窗有可见许可和署名 | — |
| V03-about-license-help-zh-Hans-light | N/A | about | license-help | zh-Hans | light | static | 独立关于窗口 | 核对可见 MIT 与 Svame 位置 | —（P07-F04，范围说明） | 设置链接专用的帮助取证适用于设置关于；独立窗有可见许可和署名 | — |
| V03-about-license-help-en-dark | N/A | about | license-help | en | dark | static | 独立关于窗口 | 核对可见 MIT 与 Svame 位置 | —（P07-F04，范围说明） | 设置链接专用的帮助取证适用于设置关于；独立窗有可见许可和署名 | — |
| V03-about-license-help-en-light | N/A | about | license-help | en | light | static | 独立关于窗口 | 核对可见 MIT 与 Svame 位置 | —（P07-F04，范围说明） | 设置链接专用的帮助取证适用于设置关于；独立窗有可见许可和署名 | — |
| V03-about-license-ax-zh-Hans-dark | N/A | about | license-ax | zh-Hans | dark | static | 独立关于窗口 | 核对可见 MIT 与 Svame 位置 | —（P07-F04，范围说明） | 设置链接专用 AX 说明适用于设置关于；独立窗可见两行由独立用例核对 | — |
| V03-about-license-ax-zh-Hans-light | N/A | about | license-ax | zh-Hans | light | static | 独立关于窗口 | 核对可见 MIT 与 Svame 位置 | —（P07-F04，范围说明） | 设置链接专用 AX 说明适用于设置关于；独立窗可见两行由独立用例核对 | — |
| V03-about-license-ax-en-dark | N/A | about | license-ax | en | dark | static | 独立关于窗口 | 核对可见 MIT 与 Svame 位置 | —（P07-F04，范围说明） | 设置链接专用 AX 说明适用于设置关于；独立窗可见两行由独立用例核对 | — |
| V03-about-license-ax-en-light | N/A | about | license-ax | en | light | static | 独立关于窗口 | 核对可见 MIT 与 Svame 位置 | —（P07-F04，范围说明） | 设置链接专用 AX 说明适用于设置关于；独立窗可见两行由独立用例核对 | — |

### V04 原型 11 变体、连续旋转与窗口同步

| 用例 ID | 适用 | 窗口 | 状态 | 语言 | 外观 | 帧 | 操作起点 | 选择或故障输入 | 参考 ID 和类型 | 检查项或不适用原因 | 所需证据 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| V04-settings-about-idle-zh-Hans-dark | REQUIRED | settings-about | idle | zh-Hans | dark | static | 设置 → 关于 | 清除受控发布状态；开启窗口并等待 | Figma 原图 P07-F03;P07-U01（匹配区域） | 待检查及初始反馈；打开窗口不触发网络操作 | 窗口+116×30按钮局部+状态记录 |
| V04-settings-about-idle-zh-Hans-light | REQUIRED | settings-about | idle | zh-Hans | light | static | 设置 → 关于 | 清除受控发布状态；开启窗口并等待 | 组件/变量 P07-F03;P07-U01（浅色变量） | 待检查及初始反馈；打开窗口不触发网络操作 | 窗口+116×30按钮局部+状态记录 |
| V04-settings-about-idle-en-dark | REQUIRED | settings-about | idle | en | dark | static | 设置 → 关于 | 清除受控发布状态；开启窗口并等待 | 组件/变量 P07-F03;P07-U01（英文译文） | 待检查及初始反馈；打开窗口不触发网络操作 | 窗口+116×30按钮局部+状态记录 |
| V04-settings-about-idle-en-light | REQUIRED | settings-about | idle | en | light | static | 设置 → 关于 | 清除受控发布状态；开启窗口并等待 | 组件/变量 P07-F03;P07-U01（英文译文与浅色变量） | 待检查及初始反馈；打开窗口不触发网络操作 | 窗口+116×30按钮局部+状态记录 |
| V04-settings-about-new-zh-Hans-dark | REQUIRED | settings-about | new | zh-Hans | dark | static | 设置 → 关于 | 从本入口发起检查，受控结果给出 v1.5.0 | Figma 原图 P07-U06（仅按钮），组件/变量 P07-F03（宿主） | 显示发现版本和下载箭头，版本行保留原版 | 窗口+116×30按钮局部+状态记录 |
| V04-settings-about-new-zh-Hans-light | REQUIRED | settings-about | new | zh-Hans | light | static | 设置 → 关于 | 从本入口发起检查，受控结果给出 v1.5.0 | 组件/变量 P07-F03;P07-U06（浅色变量，无同帧原图） | 显示发现版本和下载箭头，版本行保留原版 | 窗口+116×30按钮局部+状态记录 |
| V04-settings-about-new-en-dark | REQUIRED | settings-about | new | en | dark | static | 设置 → 关于 | 从本入口发起检查，受控结果给出 v1.5.0 | 组件/变量 P07-F03;P07-U06（英文译文，无同帧原图） | 显示发现版本和下载箭头，版本行保留原版 | 窗口+116×30按钮局部+状态记录 |
| V04-settings-about-new-en-light | REQUIRED | settings-about | new | en | light | static | 设置 → 关于 | 从本入口发起检查，受控结果给出 v1.5.0 | 组件/变量 P07-F03;P07-U06（英文译文与浅色变量，无同帧原图） | 显示发现版本和下载箭头，版本行保留原版 | 窗口+116×30按钮局部+状态记录 |
| V04-settings-about-complete-zh-Hans-dark | REQUIRED | settings-about | complete | zh-Hans | dark | static | 设置 → 关于 | 受控完成更新，展示原型版本 v1.5.0；候选另验真实 Bundle | Figma 原图 P07-U11（仅按钮），组件/变量 P07-F03（宿主） | 按钮返回初始轮廓，反馈已是最新，设置侧栏及两窗口版本一致 | 窗口+116×30按钮局部+状态记录 |
| V04-settings-about-complete-zh-Hans-light | REQUIRED | settings-about | complete | zh-Hans | light | static | 设置 → 关于 | 受控完成更新，展示原型版本 v1.5.0；候选另验真实 Bundle | 组件/变量 P07-F03;P07-U11（浅色变量，无同帧原图） | 按钮返回初始轮廓，反馈已是最新，设置侧栏及两窗口版本一致 | 窗口+116×30按钮局部+状态记录 |
| V04-settings-about-complete-en-dark | REQUIRED | settings-about | complete | en | dark | static | 设置 → 关于 | 受控完成更新，展示原型版本 v1.5.0；候选另验真实 Bundle | 组件/变量 P07-F03;P07-U11（英文译文，无同帧原图） | 按钮返回初始轮廓，反馈已是最新，设置侧栏及两窗口版本一致 | 窗口+116×30按钮局部+状态记录 |
| V04-settings-about-complete-en-light | REQUIRED | settings-about | complete | en | light | static | 设置 → 关于 | 受控完成更新，展示原型版本 v1.5.0；候选另验真实 Bundle | 组件/变量 P07-F03;P07-U11（英文译文与浅色变量，无同帧原图） | 按钮返回初始轮廓，反馈已是最新，设置侧栏及两窗口版本一致 | 窗口+116×30按钮局部+状态记录 |
| V04-settings-about-check-f01-zh-Hans-dark | REQUIRED | settings-about | check | zh-Hans | dark | f01 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 1帧 | Figma 原图 P07-U02（仅按钮），组件/变量 P07-F03（宿主） | 检查按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f01-zh-Hans-light | REQUIRED | settings-about | check | zh-Hans | light | f01 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 1帧 | 组件/变量 P07-F03;P07-U02（浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f01-en-dark | REQUIRED | settings-about | check | en | dark | f01 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 1帧 | 组件/变量 P07-F03;P07-U02（英文译文，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f01-en-light | REQUIRED | settings-about | check | en | light | f01 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 1帧 | 组件/变量 P07-F03;P07-U02（英文译文与浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f02-zh-Hans-dark | REQUIRED | settings-about | check | zh-Hans | dark | f02 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 2帧 | Figma 原图 P07-U03（仅按钮），组件/变量 P07-F03（宿主） | 检查按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f02-zh-Hans-light | REQUIRED | settings-about | check | zh-Hans | light | f02 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 2帧 | 组件/变量 P07-F03;P07-U03（浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f02-en-dark | REQUIRED | settings-about | check | en | dark | f02 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 2帧 | 组件/变量 P07-F03;P07-U03（英文译文，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f02-en-light | REQUIRED | settings-about | check | en | light | f02 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 2帧 | 组件/变量 P07-F03;P07-U03（英文译文与浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f03-zh-Hans-dark | REQUIRED | settings-about | check | zh-Hans | dark | f03 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 3帧 | Figma 原图 P07-U04（仅按钮），组件/变量 P07-F03（宿主） | 检查按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f03-zh-Hans-light | REQUIRED | settings-about | check | zh-Hans | light | f03 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 3帧 | 组件/变量 P07-F03;P07-U04（浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f03-en-dark | REQUIRED | settings-about | check | en | dark | f03 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 3帧 | 组件/变量 P07-F03;P07-U04（英文译文，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f03-en-light | REQUIRED | settings-about | check | en | light | f03 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 3帧 | 组件/变量 P07-F03;P07-U04（英文译文与浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f04-zh-Hans-dark | REQUIRED | settings-about | check | zh-Hans | dark | f04 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 4帧 | Figma 原图 P07-U05（仅按钮），组件/变量 P07-F03（宿主） | 检查按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f04-zh-Hans-light | REQUIRED | settings-about | check | zh-Hans | light | f04 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 4帧 | 组件/变量 P07-F03;P07-U05（浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f04-en-dark | REQUIRED | settings-about | check | en | dark | f04 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 4帧 | 组件/变量 P07-F03;P07-U05（英文译文，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-f04-en-light | REQUIRED | settings-about | check | en | light | f04 | 设置 → 关于 | 从本入口检查；用受控相位停在检查 4帧 | 组件/变量 P07-F03;P07-U05（英文译文与浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-check-motion-zh-Hans-dark | REQUIRED | settings-about | check-motion | zh-Hans | dark | sequence | 设置 → 关于 | 释放固定帧，延长受控检查至少两周旋转 | 组件/变量 P07-F03;P07-U02/P07-U03/P07-U04/P07-U05（静态位相，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-settings-about-check-motion-zh-Hans-light | REQUIRED | settings-about | check-motion | zh-Hans | light | sequence | 设置 → 关于 | 释放固定帧，延长受控检查至少两周旋转 | 组件/变量 P07-F03;P07-U02/P07-U03/P07-U04/P07-U05（静态位相及浅色变量，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-settings-about-check-motion-en-dark | REQUIRED | settings-about | check-motion | en | dark | sequence | 设置 → 关于 | 释放固定帧，延长受控检查至少两周旋转 | 组件/变量 P07-F03;P07-U02/P07-U03/P07-U04/P07-U05（静态位相及英文译文，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-settings-about-check-motion-en-light | REQUIRED | settings-about | check-motion | en | light | sequence | 设置 → 关于 | 释放固定帧，延长受控检查至少两周旋转 | 组件/变量 P07-F03;P07-U02/P07-U03/P07-U04/P07-U05（静态位相及英文译文与浅色变量，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-settings-about-update-f01-zh-Hans-dark | REQUIRED | settings-about | update | zh-Hans | dark | f01 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 1帧 | Figma 原图 P07-U07（仅按钮），组件/变量 P07-F03（宿主） | 更新按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f01-zh-Hans-light | REQUIRED | settings-about | update | zh-Hans | light | f01 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 1帧 | 组件/变量 P07-F03;P07-U07（浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f01-en-dark | REQUIRED | settings-about | update | en | dark | f01 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 1帧 | 组件/变量 P07-F03;P07-U07（英文译文，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f01-en-light | REQUIRED | settings-about | update | en | light | f01 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 1帧 | 组件/变量 P07-F03;P07-U07（英文译文与浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f02-zh-Hans-dark | REQUIRED | settings-about | update | zh-Hans | dark | f02 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 2帧 | Figma 原图 P07-U08（仅按钮），组件/变量 P07-F03（宿主） | 更新按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f02-zh-Hans-light | REQUIRED | settings-about | update | zh-Hans | light | f02 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 2帧 | 组件/变量 P07-F03;P07-U08（浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f02-en-dark | REQUIRED | settings-about | update | en | dark | f02 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 2帧 | 组件/变量 P07-F03;P07-U08（英文译文，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f02-en-light | REQUIRED | settings-about | update | en | light | f02 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 2帧 | 组件/变量 P07-F03;P07-U08（英文译文与浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f03-zh-Hans-dark | REQUIRED | settings-about | update | zh-Hans | dark | f03 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 3帧 | Figma 原图 P07-U09（仅按钮），组件/变量 P07-F03（宿主） | 更新按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f03-zh-Hans-light | REQUIRED | settings-about | update | zh-Hans | light | f03 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 3帧 | 组件/变量 P07-F03;P07-U09（浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f03-en-dark | REQUIRED | settings-about | update | en | dark | f03 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 3帧 | 组件/变量 P07-F03;P07-U09（英文译文，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f03-en-light | REQUIRED | settings-about | update | en | light | f03 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 3帧 | 组件/变量 P07-F03;P07-U09（英文译文与浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f04-zh-Hans-dark | REQUIRED | settings-about | update | zh-Hans | dark | f04 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 4帧 | Figma 原图 P07-U10（仅按钮），组件/变量 P07-F03（宿主） | 更新按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f04-zh-Hans-light | REQUIRED | settings-about | update | zh-Hans | light | f04 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 4帧 | 组件/变量 P07-F03;P07-U10（浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f04-en-dark | REQUIRED | settings-about | update | en | dark | f04 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 4帧 | 组件/变量 P07-F03;P07-U10（英文译文，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-f04-en-light | REQUIRED | settings-about | update | en | light | f04 | 设置 → 关于 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 4帧 | 组件/变量 P07-F03;P07-U10（英文译文与浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-settings-about-update-motion-zh-Hans-dark | REQUIRED | settings-about | update-motion | zh-Hans | dark | sequence | 设置 → 关于 | 释放固定帧，延长受控更新至少两周旋转 | 组件/变量 P07-F03;P07-U07/P07-U08/P07-U09/P07-U10（静态位相，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-settings-about-update-motion-zh-Hans-light | REQUIRED | settings-about | update-motion | zh-Hans | light | sequence | 设置 → 关于 | 释放固定帧，延长受控更新至少两周旋转 | 组件/变量 P07-F03;P07-U07/P07-U08/P07-U09/P07-U10（静态位相及浅色变量，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-settings-about-update-motion-en-dark | REQUIRED | settings-about | update-motion | en | dark | sequence | 设置 → 关于 | 释放固定帧，延长受控更新至少两周旋转 | 组件/变量 P07-F03;P07-U07/P07-U08/P07-U09/P07-U10（静态位相及英文译文，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-settings-about-update-motion-en-light | REQUIRED | settings-about | update-motion | en | light | sequence | 设置 → 关于 | 释放固定帧，延长受控更新至少两周旋转 | 组件/变量 P07-F03;P07-U07/P07-U08/P07-U09/P07-U10（静态位相及英文译文与浅色变量，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-settings-about-check-reopen-zh-Hans-dark | REQUIRED | settings-about | check-reopen | zh-Hans | dark | f01 | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定检查中，关闭本窗口后重开；再关两窗并由本入口重开 | Figma 原图 P07-U02（仅按钮），组件/变量 P07-F03（宿主） | 同一检查中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-check-reopen-zh-Hans-light | REQUIRED | settings-about | check-reopen | zh-Hans | light | f01 | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定检查中，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F03;P07-U02（浅色变量，无同帧原图） | 同一检查中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-check-reopen-en-dark | REQUIRED | settings-about | check-reopen | en | dark | f01 | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定检查中，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F03;P07-U02（英文译文，无同帧原图） | 同一检查中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-check-reopen-en-light | REQUIRED | settings-about | check-reopen | en | light | f01 | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定检查中，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F03;P07-U02（英文译文与浅色变量，无同帧原图） | 同一检查中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-new-reopen-zh-Hans-dark | REQUIRED | settings-about | new-reopen | zh-Hans | dark | static | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定发现新版，关闭本窗口后重开；再关两窗并由本入口重开 | Figma 原图 P07-U06（仅按钮），组件/变量 P07-F03（宿主） | 同一发现新版状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-new-reopen-zh-Hans-light | REQUIRED | settings-about | new-reopen | zh-Hans | light | static | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定发现新版，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F03;P07-U06（浅色变量，无同帧原图） | 同一发现新版状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-new-reopen-en-dark | REQUIRED | settings-about | new-reopen | en | dark | static | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定发现新版，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F03;P07-U06（英文译文，无同帧原图） | 同一发现新版状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-new-reopen-en-light | REQUIRED | settings-about | new-reopen | en | light | static | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定发现新版，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F03;P07-U06（英文译文与浅色变量，无同帧原图） | 同一发现新版状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-update-reopen-zh-Hans-dark | REQUIRED | settings-about | update-reopen | zh-Hans | dark | f01 | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定更新中，关闭本窗口后重开；再关两窗并由本入口重开 | Figma 原图 P07-U07（仅按钮），组件/变量 P07-F03（宿主） | 同一更新中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-update-reopen-zh-Hans-light | REQUIRED | settings-about | update-reopen | zh-Hans | light | f01 | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定更新中，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F03;P07-U07（浅色变量，无同帧原图） | 同一更新中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-update-reopen-en-dark | REQUIRED | settings-about | update-reopen | en | dark | f01 | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定更新中，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F03;P07-U07（英文译文，无同帧原图） | 同一更新中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-update-reopen-en-light | REQUIRED | settings-about | update-reopen | en | light | f01 | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定更新中，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F03;P07-U07（英文译文与浅色变量，无同帧原图） | 同一更新中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-complete-reopen-zh-Hans-dark | REQUIRED | settings-about | complete-reopen | zh-Hans | dark | static | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定受控完成，关闭本窗口后重开；再关两窗并由本入口重开 | Figma 原图 P07-U11（仅按钮），组件/变量 P07-F03（宿主） | 同一受控完成状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-complete-reopen-zh-Hans-light | REQUIRED | settings-about | complete-reopen | zh-Hans | light | static | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定受控完成，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F03;P07-U11（浅色变量，无同帧原图） | 同一受控完成状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-complete-reopen-en-dark | REQUIRED | settings-about | complete-reopen | en | dark | static | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定受控完成，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F03;P07-U11（英文译文，无同帧原图） | 同一受控完成状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-settings-about-complete-reopen-en-light | REQUIRED | settings-about | complete-reopen | en | light | static | 设置 → 关于；另一关于入口可打开 | 由另一入口发起，固定受控完成，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F03;P07-U11（英文译文与浅色变量，无同帧原图） | 同一受控完成状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-idle-zh-Hans-dark | REQUIRED | about | idle | zh-Hans | dark | static | 独立关于窗口 | 清除受控发布状态；开启窗口并等待 | Figma 原图 P07-F04;P07-U01（匹配区域） | 待检查及初始反馈；打开窗口不触发网络操作 | 窗口+116×30按钮局部+状态记录 |
| V04-about-idle-zh-Hans-light | REQUIRED | about | idle | zh-Hans | light | static | 独立关于窗口 | 清除受控发布状态；开启窗口并等待 | 组件/变量 P07-F04;P07-U01（浅色变量） | 待检查及初始反馈；打开窗口不触发网络操作 | 窗口+116×30按钮局部+状态记录 |
| V04-about-idle-en-dark | REQUIRED | about | idle | en | dark | static | 独立关于窗口 | 清除受控发布状态；开启窗口并等待 | 组件/变量 P07-F04;P07-U01（英文译文） | 待检查及初始反馈；打开窗口不触发网络操作 | 窗口+116×30按钮局部+状态记录 |
| V04-about-idle-en-light | REQUIRED | about | idle | en | light | static | 独立关于窗口 | 清除受控发布状态；开启窗口并等待 | 组件/变量 P07-F04;P07-U01（英文译文与浅色变量） | 待检查及初始反馈；打开窗口不触发网络操作 | 窗口+116×30按钮局部+状态记录 |
| V04-about-new-zh-Hans-dark | REQUIRED | about | new | zh-Hans | dark | static | 独立关于窗口 | 从本入口发起检查，受控结果给出 v1.5.0 | Figma 原图 P07-U06（仅按钮），组件/变量 P07-F04（宿主） | 显示发现版本和下载箭头，版本行保留原版 | 窗口+116×30按钮局部+状态记录 |
| V04-about-new-zh-Hans-light | REQUIRED | about | new | zh-Hans | light | static | 独立关于窗口 | 从本入口发起检查，受控结果给出 v1.5.0 | 组件/变量 P07-F04;P07-U06（浅色变量，无同帧原图） | 显示发现版本和下载箭头，版本行保留原版 | 窗口+116×30按钮局部+状态记录 |
| V04-about-new-en-dark | REQUIRED | about | new | en | dark | static | 独立关于窗口 | 从本入口发起检查，受控结果给出 v1.5.0 | 组件/变量 P07-F04;P07-U06（英文译文，无同帧原图） | 显示发现版本和下载箭头，版本行保留原版 | 窗口+116×30按钮局部+状态记录 |
| V04-about-new-en-light | REQUIRED | about | new | en | light | static | 独立关于窗口 | 从本入口发起检查，受控结果给出 v1.5.0 | 组件/变量 P07-F04;P07-U06（英文译文与浅色变量，无同帧原图） | 显示发现版本和下载箭头，版本行保留原版 | 窗口+116×30按钮局部+状态记录 |
| V04-about-complete-zh-Hans-dark | REQUIRED | about | complete | zh-Hans | dark | static | 独立关于窗口 | 受控完成更新，展示原型版本 v1.5.0；候选另验真实 Bundle | Figma 原图 P07-U11（仅按钮），组件/变量 P07-F04（宿主） | 按钮返回初始轮廓，反馈已是最新，设置侧栏及两窗口版本一致 | 窗口+116×30按钮局部+状态记录 |
| V04-about-complete-zh-Hans-light | REQUIRED | about | complete | zh-Hans | light | static | 独立关于窗口 | 受控完成更新，展示原型版本 v1.5.0；候选另验真实 Bundle | 组件/变量 P07-F04;P07-U11（浅色变量，无同帧原图） | 按钮返回初始轮廓，反馈已是最新，设置侧栏及两窗口版本一致 | 窗口+116×30按钮局部+状态记录 |
| V04-about-complete-en-dark | REQUIRED | about | complete | en | dark | static | 独立关于窗口 | 受控完成更新，展示原型版本 v1.5.0；候选另验真实 Bundle | 组件/变量 P07-F04;P07-U11（英文译文，无同帧原图） | 按钮返回初始轮廓，反馈已是最新，设置侧栏及两窗口版本一致 | 窗口+116×30按钮局部+状态记录 |
| V04-about-complete-en-light | REQUIRED | about | complete | en | light | static | 独立关于窗口 | 受控完成更新，展示原型版本 v1.5.0；候选另验真实 Bundle | 组件/变量 P07-F04;P07-U11（英文译文与浅色变量，无同帧原图） | 按钮返回初始轮廓，反馈已是最新，设置侧栏及两窗口版本一致 | 窗口+116×30按钮局部+状态记录 |
| V04-about-check-f01-zh-Hans-dark | REQUIRED | about | check | zh-Hans | dark | f01 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 1帧 | Figma 原图 P07-U02（仅按钮），组件/变量 P07-F04（宿主） | 检查按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f01-zh-Hans-light | REQUIRED | about | check | zh-Hans | light | f01 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 1帧 | 组件/变量 P07-F04;P07-U02（浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f01-en-dark | REQUIRED | about | check | en | dark | f01 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 1帧 | 组件/变量 P07-F04;P07-U02（英文译文，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f01-en-light | REQUIRED | about | check | en | light | f01 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 1帧 | 组件/变量 P07-F04;P07-U02（英文译文与浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f02-zh-Hans-dark | REQUIRED | about | check | zh-Hans | dark | f02 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 2帧 | Figma 原图 P07-U03（仅按钮），组件/变量 P07-F04（宿主） | 检查按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f02-zh-Hans-light | REQUIRED | about | check | zh-Hans | light | f02 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 2帧 | 组件/变量 P07-F04;P07-U03（浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f02-en-dark | REQUIRED | about | check | en | dark | f02 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 2帧 | 组件/变量 P07-F04;P07-U03（英文译文，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f02-en-light | REQUIRED | about | check | en | light | f02 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 2帧 | 组件/变量 P07-F04;P07-U03（英文译文与浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f03-zh-Hans-dark | REQUIRED | about | check | zh-Hans | dark | f03 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 3帧 | Figma 原图 P07-U04（仅按钮），组件/变量 P07-F04（宿主） | 检查按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f03-zh-Hans-light | REQUIRED | about | check | zh-Hans | light | f03 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 3帧 | 组件/变量 P07-F04;P07-U04（浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f03-en-dark | REQUIRED | about | check | en | dark | f03 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 3帧 | 组件/变量 P07-F04;P07-U04（英文译文，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f03-en-light | REQUIRED | about | check | en | light | f03 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 3帧 | 组件/变量 P07-F04;P07-U04（英文译文与浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f04-zh-Hans-dark | REQUIRED | about | check | zh-Hans | dark | f04 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 4帧 | Figma 原图 P07-U05（仅按钮），组件/变量 P07-F04（宿主） | 检查按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f04-zh-Hans-light | REQUIRED | about | check | zh-Hans | light | f04 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 4帧 | 组件/变量 P07-F04;P07-U05（浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f04-en-dark | REQUIRED | about | check | en | dark | f04 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 4帧 | 组件/变量 P07-F04;P07-U05（英文译文，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-f04-en-light | REQUIRED | about | check | en | light | f04 | 独立关于窗口 | 从本入口检查；用受控相位停在检查 4帧 | 组件/变量 P07-F04;P07-U05（英文译文与浅色变量，无同帧原图） | 检查按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-check-motion-zh-Hans-dark | REQUIRED | about | check-motion | zh-Hans | dark | sequence | 独立关于窗口 | 释放固定帧，延长受控检查至少两周旋转 | 组件/变量 P07-F04;P07-U02/P07-U03/P07-U04/P07-U05（静态位相，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-about-check-motion-zh-Hans-light | REQUIRED | about | check-motion | zh-Hans | light | sequence | 独立关于窗口 | 释放固定帧，延长受控检查至少两周旋转 | 组件/变量 P07-F04;P07-U02/P07-U03/P07-U04/P07-U05（静态位相及浅色变量，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-about-check-motion-en-dark | REQUIRED | about | check-motion | en | dark | sequence | 独立关于窗口 | 释放固定帧，延长受控检查至少两周旋转 | 组件/变量 P07-F04;P07-U02/P07-U03/P07-U04/P07-U05（静态位相及英文译文，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-about-check-motion-en-light | REQUIRED | about | check-motion | en | light | sequence | 独立关于窗口 | 释放固定帧，延长受控检查至少两周旋转 | 组件/变量 P07-F04;P07-U02/P07-U03/P07-U04/P07-U05（静态位相及英文译文与浅色变量，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-about-update-f01-zh-Hans-dark | REQUIRED | about | update | zh-Hans | dark | f01 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 1帧 | Figma 原图 P07-U07（仅按钮），组件/变量 P07-F04（宿主） | 更新按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f01-zh-Hans-light | REQUIRED | about | update | zh-Hans | light | f01 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 1帧 | 组件/变量 P07-F04;P07-U07（浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f01-en-dark | REQUIRED | about | update | en | dark | f01 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 1帧 | 组件/变量 P07-F04;P07-U07（英文译文，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f01-en-light | REQUIRED | about | update | en | light | f01 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 1帧 | 组件/变量 P07-F04;P07-U07（英文译文与浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、0° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f02-zh-Hans-dark | REQUIRED | about | update | zh-Hans | dark | f02 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 2帧 | Figma 原图 P07-U08（仅按钮），组件/变量 P07-F04（宿主） | 更新按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f02-zh-Hans-light | REQUIRED | about | update | zh-Hans | light | f02 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 2帧 | 组件/变量 P07-F04;P07-U08（浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f02-en-dark | REQUIRED | about | update | en | dark | f02 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 2帧 | 组件/变量 P07-F04;P07-U08（英文译文，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f02-en-light | REQUIRED | about | update | en | light | f02 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 2帧 | 组件/变量 P07-F04;P07-U08（英文译文与浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f03-zh-Hans-dark | REQUIRED | about | update | zh-Hans | dark | f03 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 3帧 | Figma 原图 P07-U09（仅按钮），组件/变量 P07-F04（宿主） | 更新按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f03-zh-Hans-light | REQUIRED | about | update | zh-Hans | light | f03 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 3帧 | 组件/变量 P07-F04;P07-U09（浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f03-en-dark | REQUIRED | about | update | en | dark | f03 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 3帧 | 组件/变量 P07-F04;P07-U09（英文译文，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f03-en-light | REQUIRED | about | update | en | light | f03 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 3帧 | 组件/变量 P07-F04;P07-U09（英文译文与浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、180° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f04-zh-Hans-dark | REQUIRED | about | update | zh-Hans | dark | f04 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 4帧 | Figma 原图 P07-U10（仅按钮），组件/变量 P07-F04（宿主） | 更新按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f04-zh-Hans-light | REQUIRED | about | update | zh-Hans | light | f04 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 4帧 | 组件/变量 P07-F04;P07-U10（浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f04-en-dark | REQUIRED | about | update | en | dark | f04 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 4帧 | 组件/变量 P07-F04;P07-U10（英文译文，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-f04-en-light | REQUIRED | about | update | en | light | f04 | 独立关于窗口 | 从本入口选择更新到 v1.5.0；用受控相位停在更新 4帧 | 组件/变量 P07-F04;P07-U10（英文译文与浅色变量，无同帧原图） | 更新按钮色、文字、9.3333 pt 循环矢量、-90° 位相及共享反馈，重复操作无效 | 窗口+116×30按钮局部+帧状态 |
| V04-about-update-motion-zh-Hans-dark | REQUIRED | about | update-motion | zh-Hans | dark | sequence | 独立关于窗口 | 释放固定帧，延长受控更新至少两周旋转 | 组件/变量 P07-F04;P07-U07/P07-U08/P07-U09/P07-U10（静态位相，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-about-update-motion-zh-Hans-light | REQUIRED | about | update-motion | zh-Hans | light | sequence | 独立关于窗口 | 释放固定帧，延长受控更新至少两周旋转 | 组件/变量 P07-F04;P07-U07/P07-U08/P07-U09/P07-U10（静态位相及浅色变量，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-about-update-motion-en-dark | REQUIRED | about | update-motion | en | dark | sequence | 独立关于窗口 | 释放固定帧，延长受控更新至少两周旋转 | 组件/变量 P07-F04;P07-U07/P07-U08/P07-U09/P07-U10（静态位相及英文译文，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-about-update-motion-en-light | REQUIRED | about | update-motion | en | light | sequence | 独立关于窗口 | 释放固定帧，延长受控更新至少两周旋转 | 组件/变量 P07-F04;P07-U07/P07-U08/P07-U09/P07-U10（静态位相及英文译文与浅色变量，无连续原图） | 连续记录关键帧顺序、过零和布局稳定；检查无跳帧，记录帧率与相位 | 窗口+录像或连续帧 |
| V04-about-check-reopen-zh-Hans-dark | REQUIRED | about | check-reopen | zh-Hans | dark | f01 | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定检查中，关闭本窗口后重开；再关两窗并由本入口重开 | Figma 原图 P07-U02（仅按钮），组件/变量 P07-F04（宿主） | 同一检查中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-check-reopen-zh-Hans-light | REQUIRED | about | check-reopen | zh-Hans | light | f01 | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定检查中，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F04;P07-U02（浅色变量，无同帧原图） | 同一检查中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-check-reopen-en-dark | REQUIRED | about | check-reopen | en | dark | f01 | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定检查中，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F04;P07-U02（英文译文，无同帧原图） | 同一检查中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-check-reopen-en-light | REQUIRED | about | check-reopen | en | light | f01 | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定检查中，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F04;P07-U02（英文译文与浅色变量，无同帧原图） | 同一检查中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-new-reopen-zh-Hans-dark | REQUIRED | about | new-reopen | zh-Hans | dark | static | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定发现新版，关闭本窗口后重开；再关两窗并由本入口重开 | Figma 原图 P07-U06（仅按钮），组件/变量 P07-F04（宿主） | 同一发现新版状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-new-reopen-zh-Hans-light | REQUIRED | about | new-reopen | zh-Hans | light | static | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定发现新版，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F04;P07-U06（浅色变量，无同帧原图） | 同一发现新版状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-new-reopen-en-dark | REQUIRED | about | new-reopen | en | dark | static | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定发现新版，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F04;P07-U06（英文译文，无同帧原图） | 同一发现新版状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-new-reopen-en-light | REQUIRED | about | new-reopen | en | light | static | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定发现新版，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F04;P07-U06（英文译文与浅色变量，无同帧原图） | 同一发现新版状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-update-reopen-zh-Hans-dark | REQUIRED | about | update-reopen | zh-Hans | dark | f01 | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定更新中，关闭本窗口后重开；再关两窗并由本入口重开 | Figma 原图 P07-U07（仅按钮），组件/变量 P07-F04（宿主） | 同一更新中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-update-reopen-zh-Hans-light | REQUIRED | about | update-reopen | zh-Hans | light | f01 | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定更新中，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F04;P07-U07（浅色变量，无同帧原图） | 同一更新中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-update-reopen-en-dark | REQUIRED | about | update-reopen | en | dark | f01 | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定更新中，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F04;P07-U07（英文译文，无同帧原图） | 同一更新中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-update-reopen-en-light | REQUIRED | about | update-reopen | en | light | f01 | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定更新中，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F04;P07-U07（英文译文与浅色变量，无同帧原图） | 同一更新中状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-complete-reopen-zh-Hans-dark | REQUIRED | about | complete-reopen | zh-Hans | dark | static | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定受控完成，关闭本窗口后重开；再关两窗并由本入口重开 | Figma 原图 P07-U11（仅按钮），组件/变量 P07-F04（宿主） | 同一受控完成状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-complete-reopen-zh-Hans-light | REQUIRED | about | complete-reopen | zh-Hans | light | static | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定受控完成，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F04;P07-U11（浅色变量，无同帧原图） | 同一受控完成状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-complete-reopen-en-dark | REQUIRED | about | complete-reopen | en | dark | static | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定受控完成，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F04;P07-U11（英文译文，无同帧原图） | 同一受控完成状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |
| V04-about-complete-reopen-en-light | REQUIRED | about | complete-reopen | en | light | static | 独立关于窗口；另一关于入口可打开 | 由另一入口发起，固定受控完成，关闭本窗口后重开；再关两窗并由本入口重开 | 组件/变量 P07-F04;P07-U11（英文译文与浅色变量，无同帧原图） | 同一受控完成状态、共享版本、操作和相位可复拍，确认无重复查询或安装 | 窗口关闭/重开序列+双窗实拍+操作计数 |

### V05 更新扩展、安装确认与恢复反馈

| 用例 ID | 适用 | 窗口 | 状态 | 语言 | 外观 | 帧 | 操作起点 | 选择或故障输入 | 参考 ID 和类型 | 检查项或不适用原因 | 所需证据 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| V05-settings-about-latest-zh-Hans-dark | REQUIRED | settings-about | latest | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 从本入口检查，受控正式版本小于或等于运行版本 | 组件/变量 P07-F03;P07-U11（无同状态原图） | 已是最新版本，版本行来自 Bundle，检查可以再次主动触发 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-latest-zh-Hans-light | REQUIRED | settings-about | latest | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 从本入口检查，受控正式版本小于或等于运行版本 | 组件/变量 P07-F03;P07-U11（无同状态原图，浅色变量） | 已是最新版本，版本行来自 Bundle，检查可以再次主动触发 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-latest-en-dark | REQUIRED | settings-about | latest | en | dark | static | 设置 → 关于；两处共享受控状态 | 从本入口检查，受控正式版本小于或等于运行版本 | 组件/变量 P07-F03;P07-U11（无同状态原图，英文译文） | 已是最新版本，版本行来自 Bundle，检查可以再次主动触发 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-latest-en-light | REQUIRED | settings-about | latest | en | light | static | 设置 → 关于；两处共享受控状态 | 从本入口检查，受控正式版本小于或等于运行版本 | 组件/变量 P07-F03;P07-U11（无同状态原图，英文译文与浅色变量） | 已是最新版本，版本行来自 Bundle，检查可以再次主动触发 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-no-release-zh-Hans-dark | REQUIRED | settings-about | no-release | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 从本入口检查，返回无正式发布或只有草稿／预发布候选 | 组件/变量 P07-F03;P07-U01（无同状态原图） | 显示暂无正式版本，检查入口保留，记录过滤后的结果 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-no-release-zh-Hans-light | REQUIRED | settings-about | no-release | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 从本入口检查，返回无正式发布或只有草稿／预发布候选 | 组件/变量 P07-F03;P07-U01（无同状态原图，浅色变量） | 显示暂无正式版本，检查入口保留，记录过滤后的结果 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-no-release-en-dark | REQUIRED | settings-about | no-release | en | dark | static | 设置 → 关于；两处共享受控状态 | 从本入口检查，返回无正式发布或只有草稿／预发布候选 | 组件/变量 P07-F03;P07-U01（无同状态原图，英文译文） | 显示暂无正式版本，检查入口保留，记录过滤后的结果 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-no-release-en-light | REQUIRED | settings-about | no-release | en | light | static | 设置 → 关于；两处共享受控状态 | 从本入口检查，返回无正式发布或只有草稿／预发布候选 | 组件/变量 P07-F03;P07-U01（无同状态原图，英文译文与浅色变量） | 显示暂无正式版本，检查入口保留，记录过滤后的结果 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-check-failed-zh-Hans-dark | REQUIRED | settings-about | check-failed | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 从本入口检查，受控网络、解码或限流故障 | 组件/变量 P07-F03;P07-U01（无同状态原图） | 失败原因可读，重试能重新发起 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-check-failed-zh-Hans-light | REQUIRED | settings-about | check-failed | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 从本入口检查，受控网络、解码或限流故障 | 组件/变量 P07-F03;P07-U01（无同状态原图，浅色变量） | 失败原因可读，重试能重新发起 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-check-failed-en-dark | REQUIRED | settings-about | check-failed | en | dark | static | 设置 → 关于；两处共享受控状态 | 从本入口检查，受控网络、解码或限流故障 | 组件/变量 P07-F03;P07-U01（无同状态原图，英文译文） | 失败原因可读，重试能重新发起 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-check-failed-en-light | REQUIRED | settings-about | check-failed | en | light | static | 设置 → 关于；两处共享受控状态 | 从本入口检查，受控网络、解码或限流故障 | 组件/变量 P07-F03;P07-U01（无同状态原图，英文译文与浅色变量） | 失败原因可读，重试能重新发起 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-debug-zh-Hans-dark | REQUIRED | settings-about | blocked-debug | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 调试会话在运行时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图） | 等待理由为调试中，包保留；安全前无替换 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-debug-zh-Hans-light | REQUIRED | settings-about | blocked-debug | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 调试会话在运行时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，浅色变量） | 等待理由为调试中，包保留；安全前无替换 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-debug-en-dark | REQUIRED | settings-about | blocked-debug | en | dark | static | 设置 → 关于；两处共享受控状态 | 调试会话在运行时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，英文译文） | 等待理由为调试中，包保留；安全前无替换 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-debug-en-light | REQUIRED | settings-about | blocked-debug | en | light | static | 设置 → 关于；两处共享受控状态 | 调试会话在运行时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，英文译文与浅色变量） | 等待理由为调试中，包保留；安全前无替换 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-pending-zh-Hans-dark | REQUIRED | settings-about | blocked-pending | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 存在待恢复记录时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图） | 显示待恢复原因，可下载，替换守卫维持 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-pending-zh-Hans-light | REQUIRED | settings-about | blocked-pending | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 存在待恢复记录时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，浅色变量） | 显示待恢复原因，可下载，替换守卫维持 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-pending-en-dark | REQUIRED | settings-about | blocked-pending | en | dark | static | 设置 → 关于；两处共享受控状态 | 存在待恢复记录时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，英文译文） | 显示待恢复原因，可下载，替换守卫维持 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-pending-en-light | REQUIRED | settings-about | blocked-pending | en | light | static | 设置 → 关于；两处共享受控状态 | 存在待恢复记录时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，英文译文与浅色变量） | 显示待恢复原因，可下载，替换守卫维持 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-recovery-failed-zh-Hans-dark | REQUIRED | settings-about | blocked-recovery-failed | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 恢复返回失败时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图） | 显示恢复失败原因，包保留且不安装 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-recovery-failed-zh-Hans-light | REQUIRED | settings-about | blocked-recovery-failed | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 恢复返回失败时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，浅色变量） | 显示恢复失败原因，包保留且不安装 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-recovery-failed-en-dark | REQUIRED | settings-about | blocked-recovery-failed | en | dark | static | 设置 → 关于；两处共享受控状态 | 恢复返回失败时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，英文译文） | 显示恢复失败原因，包保留且不安装 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-recovery-failed-en-light | REQUIRED | settings-about | blocked-recovery-failed | en | light | static | 设置 → 关于；两处共享受控状态 | 恢复返回失败时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，英文译文与浅色变量） | 显示恢复失败原因，包保留且不安装 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-exit-unknown-zh-Hans-dark | REQUIRED | settings-about | blocked-exit-unknown | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 受管进程已请求退出但无法确认时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图） | 显示进程退出未知原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-exit-unknown-zh-Hans-light | REQUIRED | settings-about | blocked-exit-unknown | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 受管进程已请求退出但无法确认时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，浅色变量） | 显示进程退出未知原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-exit-unknown-en-dark | REQUIRED | settings-about | blocked-exit-unknown | en | dark | static | 设置 → 关于；两处共享受控状态 | 受管进程已请求退出但无法确认时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，英文译文） | 显示进程退出未知原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-exit-unknown-en-light | REQUIRED | settings-about | blocked-exit-unknown | en | light | static | 设置 → 关于；两处共享受控状态 | 受管进程已请求退出但无法确认时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，英文译文与浅色变量） | 显示进程退出未知原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-record-unreadable-zh-Hans-dark | REQUIRED | settings-about | blocked-record-unreadable | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 恢复记录不能读取时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图） | 显示记录不可读原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-record-unreadable-zh-Hans-light | REQUIRED | settings-about | blocked-record-unreadable | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 恢复记录不能读取时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，浅色变量） | 显示记录不可读原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-record-unreadable-en-dark | REQUIRED | settings-about | blocked-record-unreadable | en | dark | static | 设置 → 关于；两处共享受控状态 | 恢复记录不能读取时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，英文译文） | 显示记录不可读原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-blocked-record-unreadable-en-light | REQUIRED | settings-about | blocked-record-unreadable | en | light | static | 设置 → 关于；两处共享受控状态 | 恢复记录不能读取时完成下载及验证 | 组件/变量 P07-F03;P07-U07（无同状态原图，英文译文与浅色变量） | 显示记录不可读原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-waiting-reopen-zh-Hans-dark | REQUIRED | settings-about | waiting-reopen | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 固定下载完成且有阻塞，关本窗口、经另一入口核对，再由本入口重开 | 组件/变量 P07-F03;P07-U07（无同状态原图） | 等待理由、版本、已下载包一致；无重复下载或提前确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-waiting-reopen-zh-Hans-light | REQUIRED | settings-about | waiting-reopen | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 固定下载完成且有阻塞，关本窗口、经另一入口核对，再由本入口重开 | 组件/变量 P07-F03;P07-U07（无同状态原图，浅色变量） | 等待理由、版本、已下载包一致；无重复下载或提前确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-waiting-reopen-en-dark | REQUIRED | settings-about | waiting-reopen | en | dark | static | 设置 → 关于；两处共享受控状态 | 固定下载完成且有阻塞，关本窗口、经另一入口核对，再由本入口重开 | 组件/变量 P07-F03;P07-U07（无同状态原图，英文译文） | 等待理由、版本、已下载包一致；无重复下载或提前确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-waiting-reopen-en-light | REQUIRED | settings-about | waiting-reopen | en | light | static | 设置 → 关于；两处共享受控状态 | 固定下载完成且有阻塞，关本窗口、经另一入口核对，再由本入口重开 | 组件/变量 P07-F03;P07-U07（无同状态原图，英文译文与浅色变量） | 等待理由、版本、已下载包一致；无重复下载或提前确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-install-confirm-zh-Hans-dark | REQUIRED | settings-about | install-confirm | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 从本入口发起，令下载验证完成且守卫允许；出现确认后用受控确认动作 | 组件/变量 P07-F03;P07-U06（无同状态原图） | 安装并重启确认可见，明确版本与操作；一次下载只主动提示一次 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-install-confirm-zh-Hans-light | REQUIRED | settings-about | install-confirm | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 从本入口发起，令下载验证完成且守卫允许；出现确认后用受控确认动作 | 组件/变量 P07-F03;P07-U06（无同状态原图，浅色变量） | 安装并重启确认可见，明确版本与操作；一次下载只主动提示一次 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-install-confirm-en-dark | REQUIRED | settings-about | install-confirm | en | dark | static | 设置 → 关于；两处共享受控状态 | 从本入口发起，令下载验证完成且守卫允许；出现确认后用受控确认动作 | 组件/变量 P07-F03;P07-U06（无同状态原图，英文译文） | 安装并重启确认可见，明确版本与操作；一次下载只主动提示一次 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-install-confirm-en-light | REQUIRED | settings-about | install-confirm | en | light | static | 设置 → 关于；两处共享受控状态 | 从本入口发起，令下载验证完成且守卫允许；出现确认后用受控确认动作 | 组件/变量 P07-F03;P07-U06（无同状态原图，英文译文与浅色变量） | 安装并重启确认可见，明确版本与操作；一次下载只主动提示一次 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-install-later-zh-Hans-dark | REQUIRED | settings-about | install-later | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 选择稍后；从本入口重新进入并选择手动继续 | 组件/变量 P07-F03;P07-U06（无同状态原图） | 包保留且无重复主动弹窗，从本入口继续可再次进入确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-install-later-zh-Hans-light | REQUIRED | settings-about | install-later | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 选择稍后；从本入口重新进入并选择手动继续 | 组件/变量 P07-F03;P07-U06（无同状态原图，浅色变量） | 包保留且无重复主动弹窗，从本入口继续可再次进入确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-install-later-en-dark | REQUIRED | settings-about | install-later | en | dark | static | 设置 → 关于；两处共享受控状态 | 选择稍后；从本入口重新进入并选择手动继续 | 组件/变量 P07-F03;P07-U06（无同状态原图，英文译文） | 包保留且无重复主动弹窗，从本入口继续可再次进入确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-install-later-en-light | REQUIRED | settings-about | install-later | en | light | static | 设置 → 关于；两处共享受控状态 | 选择稍后；从本入口重新进入并选择手动继续 | 组件/变量 P07-F03;P07-U06（无同状态原图，英文译文与浅色变量） | 包保留且无重复主动弹窗，从本入口继续可再次进入确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-confirm-race-zh-Hans-dark | REQUIRED | settings-about | confirm-race | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 确认已显示后施加新调试或恢复阻塞，再点击确认 | 组件/变量 P07-F03;P07-U07（无同状态原图） | 确认动作重新核对守卫，回等待状态；无替换且包可继续使用 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-confirm-race-zh-Hans-light | REQUIRED | settings-about | confirm-race | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 确认已显示后施加新调试或恢复阻塞，再点击确认 | 组件/变量 P07-F03;P07-U07（无同状态原图，浅色变量） | 确认动作重新核对守卫，回等待状态；无替换且包可继续使用 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-confirm-race-en-dark | REQUIRED | settings-about | confirm-race | en | dark | static | 设置 → 关于；两处共享受控状态 | 确认已显示后施加新调试或恢复阻塞，再点击确认 | 组件/变量 P07-F03;P07-U07（无同状态原图，英文译文） | 确认动作重新核对守卫，回等待状态；无替换且包可继续使用 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-confirm-race-en-light | REQUIRED | settings-about | confirm-race | en | light | static | 设置 → 关于；两处共享受控状态 | 确认已显示后施加新调试或恢复阻塞，再点击确认 | 组件/变量 P07-F03;P07-U07（无同状态原图，英文译文与浅色变量） | 确认动作重新核对守卫，回等待状态；无替换且包可继续使用 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-settings-about-download-failed-zh-Hans-dark | REQUIRED | settings-about | download-failed | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 点击更新，注入下载错误 | 组件/变量 P07-F03;P07-U06（无同状态原图） | 保留运行版本，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-download-failed-zh-Hans-light | REQUIRED | settings-about | download-failed | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 点击更新，注入下载错误 | 组件/变量 P07-F03;P07-U06（无同状态原图，浅色变量） | 保留运行版本，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-download-failed-en-dark | REQUIRED | settings-about | download-failed | en | dark | static | 设置 → 关于；两处共享受控状态 | 点击更新，注入下载错误 | 组件/变量 P07-F03;P07-U06（无同状态原图，英文译文） | 保留运行版本，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-download-failed-en-light | REQUIRED | settings-about | download-failed | en | light | static | 设置 → 关于；两处共享受控状态 | 点击更新，注入下载错误 | 组件/变量 P07-F03;P07-U06（无同状态原图，英文译文与浅色变量） | 保留运行版本，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-verify-failed-zh-Hans-dark | REQUIRED | settings-about | verify-failed | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 下载成功后注入校验失败 | 组件/变量 P07-F03;P07-U06（无同状态原图） | 无替换，运行版本不变，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-verify-failed-zh-Hans-light | REQUIRED | settings-about | verify-failed | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 下载成功后注入校验失败 | 组件/变量 P07-F03;P07-U06（无同状态原图，浅色变量） | 无替换，运行版本不变，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-verify-failed-en-dark | REQUIRED | settings-about | verify-failed | en | dark | static | 设置 → 关于；两处共享受控状态 | 下载成功后注入校验失败 | 组件/变量 P07-F03;P07-U06（无同状态原图，英文译文） | 无替换，运行版本不变，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-verify-failed-en-light | REQUIRED | settings-about | verify-failed | en | light | static | 设置 → 关于；两处共享受控状态 | 下载成功后注入校验失败 | 组件/变量 P07-F03;P07-U06（无同状态原图，英文译文与浅色变量） | 无替换，运行版本不变，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-replace-failed-zh-Hans-dark | REQUIRED | settings-about | replace-failed | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 受控确认后模拟替换失败并令旧版恢复可打开 | 组件/变量 P07-F03;P07-U06（无同状态原图） | 报告替换阶段原因及旧版本，重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-replace-failed-zh-Hans-light | REQUIRED | settings-about | replace-failed | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 受控确认后模拟替换失败并令旧版恢复可打开 | 组件/变量 P07-F03;P07-U06（无同状态原图，浅色变量） | 报告替换阶段原因及旧版本，重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-replace-failed-en-dark | REQUIRED | settings-about | replace-failed | en | dark | static | 设置 → 关于；两处共享受控状态 | 受控确认后模拟替换失败并令旧版恢复可打开 | 组件/变量 P07-F03;P07-U06（无同状态原图，英文译文） | 报告替换阶段原因及旧版本，重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-replace-failed-en-light | REQUIRED | settings-about | replace-failed | en | light | static | 设置 → 关于；两处共享受控状态 | 受控确认后模拟替换失败并令旧版恢复可打开 | 组件/变量 P07-F03;P07-U06（无同状态原图，英文译文与浅色变量） | 报告替换阶段原因及旧版本，重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-new-launch-failed-zh-Hans-dark | REQUIRED | settings-about | new-launch-failed | zh-Hans | dark | static | 设置 → 关于；两处共享受控状态 | 模拟替换成功但新版启动失败，恢复并打开旧版 | 组件/变量 P07-F03;P07-U06（无同状态原图） | 报告新版启动失败、旧版已恢复，重试与发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-new-launch-failed-zh-Hans-light | REQUIRED | settings-about | new-launch-failed | zh-Hans | light | static | 设置 → 关于；两处共享受控状态 | 模拟替换成功但新版启动失败，恢复并打开旧版 | 组件/变量 P07-F03;P07-U06（无同状态原图，浅色变量） | 报告新版启动失败、旧版已恢复，重试与发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-new-launch-failed-en-dark | REQUIRED | settings-about | new-launch-failed | en | dark | static | 设置 → 关于；两处共享受控状态 | 模拟替换成功但新版启动失败，恢复并打开旧版 | 组件/变量 P07-F03;P07-U06（无同状态原图，英文译文） | 报告新版启动失败、旧版已恢复，重试与发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-new-launch-failed-en-light | REQUIRED | settings-about | new-launch-failed | en | light | static | 设置 → 关于；两处共享受控状态 | 模拟替换成功但新版启动失败，恢复并打开旧版 | 组件/变量 P07-F03;P07-U06（无同状态原图，英文译文与浅色变量） | 报告新版启动失败、旧版已恢复，重试与发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-settings-about-old-reopen-failed-zh-Hans-dark | N/A | settings-about | old-reopen-failed | zh-Hans | dark | static | 设置 → 关于 | 模拟恢复旧 App 后无法自动打开 | —（P07-F03，范围说明） | 旧进程未能重开，常规关于宿主无从承载反馈；适用的是 recovery-feedback 独立窗口 | — |
| V05-settings-about-old-reopen-failed-zh-Hans-light | N/A | settings-about | old-reopen-failed | zh-Hans | light | static | 设置 → 关于 | 模拟恢复旧 App 后无法自动打开 | —（P07-F03，范围说明） | 旧进程未能重开，常规关于宿主无从承载反馈；适用的是 recovery-feedback 独立窗口 | — |
| V05-settings-about-old-reopen-failed-en-dark | N/A | settings-about | old-reopen-failed | en | dark | static | 设置 → 关于 | 模拟恢复旧 App 后无法自动打开 | —（P07-F03，范围说明） | 旧进程未能重开，常规关于宿主无从承载反馈；适用的是 recovery-feedback 独立窗口 | — |
| V05-settings-about-old-reopen-failed-en-light | N/A | settings-about | old-reopen-failed | en | light | static | 设置 → 关于 | 模拟恢复旧 App 后无法自动打开 | —（P07-F03，范围说明） | 旧进程未能重开，常规关于宿主无从承载反馈；适用的是 recovery-feedback 独立窗口 | — |
| V05-about-latest-zh-Hans-dark | REQUIRED | about | latest | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 从本入口检查，受控正式版本小于或等于运行版本 | 组件/变量 P07-F04;P07-U11（无同状态原图） | 已是最新版本，版本行来自 Bundle，检查可以再次主动触发 | 窗口+反馈裁区+动作记录 |
| V05-about-latest-zh-Hans-light | REQUIRED | about | latest | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 从本入口检查，受控正式版本小于或等于运行版本 | 组件/变量 P07-F04;P07-U11（无同状态原图，浅色变量） | 已是最新版本，版本行来自 Bundle，检查可以再次主动触发 | 窗口+反馈裁区+动作记录 |
| V05-about-latest-en-dark | REQUIRED | about | latest | en | dark | static | 独立关于窗口；两处共享受控状态 | 从本入口检查，受控正式版本小于或等于运行版本 | 组件/变量 P07-F04;P07-U11（无同状态原图，英文译文） | 已是最新版本，版本行来自 Bundle，检查可以再次主动触发 | 窗口+反馈裁区+动作记录 |
| V05-about-latest-en-light | REQUIRED | about | latest | en | light | static | 独立关于窗口；两处共享受控状态 | 从本入口检查，受控正式版本小于或等于运行版本 | 组件/变量 P07-F04;P07-U11（无同状态原图，英文译文与浅色变量） | 已是最新版本，版本行来自 Bundle，检查可以再次主动触发 | 窗口+反馈裁区+动作记录 |
| V05-about-no-release-zh-Hans-dark | REQUIRED | about | no-release | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 从本入口检查，返回无正式发布或只有草稿／预发布候选 | 组件/变量 P07-F04;P07-U01（无同状态原图） | 显示暂无正式版本，检查入口保留，记录过滤后的结果 | 窗口+反馈裁区+动作记录 |
| V05-about-no-release-zh-Hans-light | REQUIRED | about | no-release | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 从本入口检查，返回无正式发布或只有草稿／预发布候选 | 组件/变量 P07-F04;P07-U01（无同状态原图，浅色变量） | 显示暂无正式版本，检查入口保留，记录过滤后的结果 | 窗口+反馈裁区+动作记录 |
| V05-about-no-release-en-dark | REQUIRED | about | no-release | en | dark | static | 独立关于窗口；两处共享受控状态 | 从本入口检查，返回无正式发布或只有草稿／预发布候选 | 组件/变量 P07-F04;P07-U01（无同状态原图，英文译文） | 显示暂无正式版本，检查入口保留，记录过滤后的结果 | 窗口+反馈裁区+动作记录 |
| V05-about-no-release-en-light | REQUIRED | about | no-release | en | light | static | 独立关于窗口；两处共享受控状态 | 从本入口检查，返回无正式发布或只有草稿／预发布候选 | 组件/变量 P07-F04;P07-U01（无同状态原图，英文译文与浅色变量） | 显示暂无正式版本，检查入口保留，记录过滤后的结果 | 窗口+反馈裁区+动作记录 |
| V05-about-check-failed-zh-Hans-dark | REQUIRED | about | check-failed | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 从本入口检查，受控网络、解码或限流故障 | 组件/变量 P07-F04;P07-U01（无同状态原图） | 失败原因可读，重试能重新发起 | 窗口+反馈裁区+动作记录 |
| V05-about-check-failed-zh-Hans-light | REQUIRED | about | check-failed | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 从本入口检查，受控网络、解码或限流故障 | 组件/变量 P07-F04;P07-U01（无同状态原图，浅色变量） | 失败原因可读，重试能重新发起 | 窗口+反馈裁区+动作记录 |
| V05-about-check-failed-en-dark | REQUIRED | about | check-failed | en | dark | static | 独立关于窗口；两处共享受控状态 | 从本入口检查，受控网络、解码或限流故障 | 组件/变量 P07-F04;P07-U01（无同状态原图，英文译文） | 失败原因可读，重试能重新发起 | 窗口+反馈裁区+动作记录 |
| V05-about-check-failed-en-light | REQUIRED | about | check-failed | en | light | static | 独立关于窗口；两处共享受控状态 | 从本入口检查，受控网络、解码或限流故障 | 组件/变量 P07-F04;P07-U01（无同状态原图，英文译文与浅色变量） | 失败原因可读，重试能重新发起 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-debug-zh-Hans-dark | REQUIRED | about | blocked-debug | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 调试会话在运行时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图） | 等待理由为调试中，包保留；安全前无替换 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-debug-zh-Hans-light | REQUIRED | about | blocked-debug | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 调试会话在运行时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，浅色变量） | 等待理由为调试中，包保留；安全前无替换 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-debug-en-dark | REQUIRED | about | blocked-debug | en | dark | static | 独立关于窗口；两处共享受控状态 | 调试会话在运行时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，英文译文） | 等待理由为调试中，包保留；安全前无替换 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-debug-en-light | REQUIRED | about | blocked-debug | en | light | static | 独立关于窗口；两处共享受控状态 | 调试会话在运行时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，英文译文与浅色变量） | 等待理由为调试中，包保留；安全前无替换 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-pending-zh-Hans-dark | REQUIRED | about | blocked-pending | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 存在待恢复记录时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图） | 显示待恢复原因，可下载，替换守卫维持 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-pending-zh-Hans-light | REQUIRED | about | blocked-pending | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 存在待恢复记录时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，浅色变量） | 显示待恢复原因，可下载，替换守卫维持 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-pending-en-dark | REQUIRED | about | blocked-pending | en | dark | static | 独立关于窗口；两处共享受控状态 | 存在待恢复记录时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，英文译文） | 显示待恢复原因，可下载，替换守卫维持 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-pending-en-light | REQUIRED | about | blocked-pending | en | light | static | 独立关于窗口；两处共享受控状态 | 存在待恢复记录时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，英文译文与浅色变量） | 显示待恢复原因，可下载，替换守卫维持 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-recovery-failed-zh-Hans-dark | REQUIRED | about | blocked-recovery-failed | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 恢复返回失败时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图） | 显示恢复失败原因，包保留且不安装 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-recovery-failed-zh-Hans-light | REQUIRED | about | blocked-recovery-failed | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 恢复返回失败时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，浅色变量） | 显示恢复失败原因，包保留且不安装 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-recovery-failed-en-dark | REQUIRED | about | blocked-recovery-failed | en | dark | static | 独立关于窗口；两处共享受控状态 | 恢复返回失败时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，英文译文） | 显示恢复失败原因，包保留且不安装 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-recovery-failed-en-light | REQUIRED | about | blocked-recovery-failed | en | light | static | 独立关于窗口；两处共享受控状态 | 恢复返回失败时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，英文译文与浅色变量） | 显示恢复失败原因，包保留且不安装 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-exit-unknown-zh-Hans-dark | REQUIRED | about | blocked-exit-unknown | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 受管进程已请求退出但无法确认时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图） | 显示进程退出未知原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-exit-unknown-zh-Hans-light | REQUIRED | about | blocked-exit-unknown | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 受管进程已请求退出但无法确认时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，浅色变量） | 显示进程退出未知原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-exit-unknown-en-dark | REQUIRED | about | blocked-exit-unknown | en | dark | static | 独立关于窗口；两处共享受控状态 | 受管进程已请求退出但无法确认时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，英文译文） | 显示进程退出未知原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-exit-unknown-en-light | REQUIRED | about | blocked-exit-unknown | en | light | static | 独立关于窗口；两处共享受控状态 | 受管进程已请求退出但无法确认时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，英文译文与浅色变量） | 显示进程退出未知原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-record-unreadable-zh-Hans-dark | REQUIRED | about | blocked-record-unreadable | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 恢复记录不能读取时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图） | 显示记录不可读原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-record-unreadable-zh-Hans-light | REQUIRED | about | blocked-record-unreadable | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 恢复记录不能读取时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，浅色变量） | 显示记录不可读原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-record-unreadable-en-dark | REQUIRED | about | blocked-record-unreadable | en | dark | static | 独立关于窗口；两处共享受控状态 | 恢复记录不能读取时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，英文译文） | 显示记录不可读原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-about-blocked-record-unreadable-en-light | REQUIRED | about | blocked-record-unreadable | en | light | static | 独立关于窗口；两处共享受控状态 | 恢复记录不能读取时完成下载及验证 | 组件/变量 P07-F04;P07-U07（无同状态原图，英文译文与浅色变量） | 显示记录不可读原因，不启动替换 | 窗口+反馈裁区+动作记录 |
| V05-about-waiting-reopen-zh-Hans-dark | REQUIRED | about | waiting-reopen | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 固定下载完成且有阻塞，关本窗口、经另一入口核对，再由本入口重开 | 组件/变量 P07-F04;P07-U07（无同状态原图） | 等待理由、版本、已下载包一致；无重复下载或提前确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-waiting-reopen-zh-Hans-light | REQUIRED | about | waiting-reopen | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 固定下载完成且有阻塞，关本窗口、经另一入口核对，再由本入口重开 | 组件/变量 P07-F04;P07-U07（无同状态原图，浅色变量） | 等待理由、版本、已下载包一致；无重复下载或提前确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-waiting-reopen-en-dark | REQUIRED | about | waiting-reopen | en | dark | static | 独立关于窗口；两处共享受控状态 | 固定下载完成且有阻塞，关本窗口、经另一入口核对，再由本入口重开 | 组件/变量 P07-F04;P07-U07（无同状态原图，英文译文） | 等待理由、版本、已下载包一致；无重复下载或提前确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-waiting-reopen-en-light | REQUIRED | about | waiting-reopen | en | light | static | 独立关于窗口；两处共享受控状态 | 固定下载完成且有阻塞，关本窗口、经另一入口核对，再由本入口重开 | 组件/变量 P07-F04;P07-U07（无同状态原图，英文译文与浅色变量） | 等待理由、版本、已下载包一致；无重复下载或提前确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-install-confirm-zh-Hans-dark | REQUIRED | about | install-confirm | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 从本入口发起，令下载验证完成且守卫允许；出现确认后用受控确认动作 | 组件/变量 P07-F04;P07-U06（无同状态原图） | 安装并重启确认可见，明确版本与操作；一次下载只主动提示一次 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-install-confirm-zh-Hans-light | REQUIRED | about | install-confirm | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 从本入口发起，令下载验证完成且守卫允许；出现确认后用受控确认动作 | 组件/变量 P07-F04;P07-U06（无同状态原图，浅色变量） | 安装并重启确认可见，明确版本与操作；一次下载只主动提示一次 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-install-confirm-en-dark | REQUIRED | about | install-confirm | en | dark | static | 独立关于窗口；两处共享受控状态 | 从本入口发起，令下载验证完成且守卫允许；出现确认后用受控确认动作 | 组件/变量 P07-F04;P07-U06（无同状态原图，英文译文） | 安装并重启确认可见，明确版本与操作；一次下载只主动提示一次 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-install-confirm-en-light | REQUIRED | about | install-confirm | en | light | static | 独立关于窗口；两处共享受控状态 | 从本入口发起，令下载验证完成且守卫允许；出现确认后用受控确认动作 | 组件/变量 P07-F04;P07-U06（无同状态原图，英文译文与浅色变量） | 安装并重启确认可见，明确版本与操作；一次下载只主动提示一次 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-install-later-zh-Hans-dark | REQUIRED | about | install-later | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 选择稍后；从本入口重新进入并选择手动继续 | 组件/变量 P07-F04;P07-U06（无同状态原图） | 包保留且无重复主动弹窗，从本入口继续可再次进入确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-install-later-zh-Hans-light | REQUIRED | about | install-later | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 选择稍后；从本入口重新进入并选择手动继续 | 组件/变量 P07-F04;P07-U06（无同状态原图，浅色变量） | 包保留且无重复主动弹窗，从本入口继续可再次进入确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-install-later-en-dark | REQUIRED | about | install-later | en | dark | static | 独立关于窗口；两处共享受控状态 | 选择稍后；从本入口重新进入并选择手动继续 | 组件/变量 P07-F04;P07-U06（无同状态原图，英文译文） | 包保留且无重复主动弹窗，从本入口继续可再次进入确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-install-later-en-light | REQUIRED | about | install-later | en | light | static | 独立关于窗口；两处共享受控状态 | 选择稍后；从本入口重新进入并选择手动继续 | 组件/变量 P07-F04;P07-U06（无同状态原图，英文译文与浅色变量） | 包保留且无重复主动弹窗，从本入口继续可再次进入确认 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-confirm-race-zh-Hans-dark | REQUIRED | about | confirm-race | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 确认已显示后施加新调试或恢复阻塞，再点击确认 | 组件/变量 P07-F04;P07-U07（无同状态原图） | 确认动作重新核对守卫，回等待状态；无替换且包可继续使用 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-confirm-race-zh-Hans-light | REQUIRED | about | confirm-race | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 确认已显示后施加新调试或恢复阻塞，再点击确认 | 组件/变量 P07-F04;P07-U07（无同状态原图，浅色变量） | 确认动作重新核对守卫，回等待状态；无替换且包可继续使用 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-confirm-race-en-dark | REQUIRED | about | confirm-race | en | dark | static | 独立关于窗口；两处共享受控状态 | 确认已显示后施加新调试或恢复阻塞，再点击确认 | 组件/变量 P07-F04;P07-U07（无同状态原图，英文译文） | 确认动作重新核对守卫，回等待状态；无替换且包可继续使用 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-confirm-race-en-light | REQUIRED | about | confirm-race | en | light | static | 独立关于窗口；两处共享受控状态 | 确认已显示后施加新调试或恢复阻塞，再点击确认 | 组件/变量 P07-F04;P07-U07（无同状态原图，英文译文与浅色变量） | 确认动作重新核对守卫，回等待状态；无替换且包可继续使用 | 窗口+含确认/重开序列的实录+操作记录 |
| V05-about-download-failed-zh-Hans-dark | REQUIRED | about | download-failed | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 点击更新，注入下载错误 | 组件/变量 P07-F04;P07-U06（无同状态原图） | 保留运行版本，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-download-failed-zh-Hans-light | REQUIRED | about | download-failed | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 点击更新，注入下载错误 | 组件/变量 P07-F04;P07-U06（无同状态原图，浅色变量） | 保留运行版本，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-download-failed-en-dark | REQUIRED | about | download-failed | en | dark | static | 独立关于窗口；两处共享受控状态 | 点击更新，注入下载错误 | 组件/变量 P07-F04;P07-U06（无同状态原图，英文译文） | 保留运行版本，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-download-failed-en-light | REQUIRED | about | download-failed | en | light | static | 独立关于窗口；两处共享受控状态 | 点击更新，注入下载错误 | 组件/变量 P07-F04;P07-U06（无同状态原图，英文译文与浅色变量） | 保留运行版本，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-verify-failed-zh-Hans-dark | REQUIRED | about | verify-failed | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 下载成功后注入校验失败 | 组件/变量 P07-F04;P07-U06（无同状态原图） | 无替换，运行版本不变，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-verify-failed-zh-Hans-light | REQUIRED | about | verify-failed | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 下载成功后注入校验失败 | 组件/变量 P07-F04;P07-U06（无同状态原图，浅色变量） | 无替换，运行版本不变，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-verify-failed-en-dark | REQUIRED | about | verify-failed | en | dark | static | 独立关于窗口；两处共享受控状态 | 下载成功后注入校验失败 | 组件/变量 P07-F04;P07-U06（无同状态原图，英文译文） | 无替换，运行版本不变，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-verify-failed-en-light | REQUIRED | about | verify-failed | en | light | static | 独立关于窗口；两处共享受控状态 | 下载成功后注入校验失败 | 组件/变量 P07-F04;P07-U06（无同状态原图，英文译文与浅色变量） | 无替换，运行版本不变，原因、重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-replace-failed-zh-Hans-dark | REQUIRED | about | replace-failed | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 受控确认后模拟替换失败并令旧版恢复可打开 | 组件/变量 P07-F04;P07-U06（无同状态原图） | 报告替换阶段原因及旧版本，重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-replace-failed-zh-Hans-light | REQUIRED | about | replace-failed | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 受控确认后模拟替换失败并令旧版恢复可打开 | 组件/变量 P07-F04;P07-U06（无同状态原图，浅色变量） | 报告替换阶段原因及旧版本，重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-replace-failed-en-dark | REQUIRED | about | replace-failed | en | dark | static | 独立关于窗口；两处共享受控状态 | 受控确认后模拟替换失败并令旧版恢复可打开 | 组件/变量 P07-F04;P07-U06（无同状态原图，英文译文） | 报告替换阶段原因及旧版本，重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-replace-failed-en-light | REQUIRED | about | replace-failed | en | light | static | 独立关于窗口；两处共享受控状态 | 受控确认后模拟替换失败并令旧版恢复可打开 | 组件/变量 P07-F04;P07-U06（无同状态原图，英文译文与浅色变量） | 报告替换阶段原因及旧版本，重试和发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-new-launch-failed-zh-Hans-dark | REQUIRED | about | new-launch-failed | zh-Hans | dark | static | 独立关于窗口；两处共享受控状态 | 模拟替换成功但新版启动失败，恢复并打开旧版 | 组件/变量 P07-F04;P07-U06（无同状态原图） | 报告新版启动失败、旧版已恢复，重试与发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-new-launch-failed-zh-Hans-light | REQUIRED | about | new-launch-failed | zh-Hans | light | static | 独立关于窗口；两处共享受控状态 | 模拟替换成功但新版启动失败，恢复并打开旧版 | 组件/变量 P07-F04;P07-U06（无同状态原图，浅色变量） | 报告新版启动失败、旧版已恢复，重试与发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-new-launch-failed-en-dark | REQUIRED | about | new-launch-failed | en | dark | static | 独立关于窗口；两处共享受控状态 | 模拟替换成功但新版启动失败，恢复并打开旧版 | 组件/变量 P07-F04;P07-U06（无同状态原图，英文译文） | 报告新版启动失败、旧版已恢复，重试与发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-new-launch-failed-en-light | REQUIRED | about | new-launch-failed | en | light | static | 独立关于窗口；两处共享受控状态 | 模拟替换成功但新版启动失败，恢复并打开旧版 | 组件/变量 P07-F04;P07-U06（无同状态原图，英文译文与浅色变量） | 报告新版启动失败、旧版已恢复，重试与发布页可达 | 窗口+反馈裁区+动作记录 |
| V05-about-old-reopen-failed-zh-Hans-dark | N/A | about | old-reopen-failed | zh-Hans | dark | static | 独立关于窗口 | 模拟恢复旧 App 后无法自动打开 | —（P07-F04，范围说明） | 旧进程未能重开，常规关于宿主无从承载反馈；适用的是 recovery-feedback 独立窗口 | — |
| V05-about-old-reopen-failed-zh-Hans-light | N/A | about | old-reopen-failed | zh-Hans | light | static | 独立关于窗口 | 模拟恢复旧 App 后无法自动打开 | —（P07-F04，范围说明） | 旧进程未能重开，常规关于宿主无从承载反馈；适用的是 recovery-feedback 独立窗口 | — |
| V05-about-old-reopen-failed-en-dark | N/A | about | old-reopen-failed | en | dark | static | 独立关于窗口 | 模拟恢复旧 App 后无法自动打开 | —（P07-F04，范围说明） | 旧进程未能重开，常规关于宿主无从承载反馈；适用的是 recovery-feedback 独立窗口 | — |
| V05-about-old-reopen-failed-en-light | N/A | about | old-reopen-failed | en | light | static | 独立关于窗口 | 模拟恢复旧 App 后无法自动打开 | —（P07-F04，范围说明） | 旧进程未能重开，常规关于宿主无从承载反馈；适用的是 recovery-feedback 独立窗口 | — |
| V05-install-confirm-both-closed-zh-Hans-dark | REQUIRED | install-confirm | both-closed | zh-Hans | dark | static | 两处关于均已关闭；更新由任一入口先启动 | 让下载就绪且守卫从等待转为允许，保持两处关闭 | 系统/实测；组件 P07-F03;P07-F04;P07-U06（入口或角色） | 独立确认出现一次，可读并可用键盘；记录确认前两处窗口确实关闭 | 独立确认原生窗口+AX+前后录像 |
| V05-install-confirm-both-closed-zh-Hans-light | REQUIRED | install-confirm | both-closed | zh-Hans | light | static | 两处关于均已关闭；更新由任一入口先启动 | 让下载就绪且守卫从等待转为允许，保持两处关闭 | 系统/实测；组件 P07-F03;P07-F04;P07-U06（入口或角色，浅色变量） | 独立确认出现一次，可读并可用键盘；记录确认前两处窗口确实关闭 | 独立确认原生窗口+AX+前后录像 |
| V05-install-confirm-both-closed-en-dark | REQUIRED | install-confirm | both-closed | en | dark | static | 两处关于均已关闭；更新由任一入口先启动 | 让下载就绪且守卫从等待转为允许，保持两处关闭 | 系统/实测；组件 P07-F03;P07-F04;P07-U06（入口或角色，英文译文） | 独立确认出现一次，可读并可用键盘；记录确认前两处窗口确实关闭 | 独立确认原生窗口+AX+前后录像 |
| V05-install-confirm-both-closed-en-light | REQUIRED | install-confirm | both-closed | en | light | static | 两处关于均已关闭；更新由任一入口先启动 | 让下载就绪且守卫从等待转为允许，保持两处关闭 | 系统/实测；组件 P07-F03;P07-F04;P07-U06（入口或角色，英文译文与浅色变量） | 独立确认出现一次，可读并可用键盘；记录确认前两处窗口确实关闭 | 独立确认原生窗口+AX+前后录像 |
| V05-recovery-feedback-old-reopen-failed-zh-Hans-dark | REQUIRED | recovery-feedback | old-reopen-failed | zh-Hans | dark | static | 独立反馈可用；旧版已恢复到原位置 | 模拟新版失败且旧版无法自动打开；依次验证两个操作 | 系统/实测；组件 P07-F03;P07-F04（入口或角色） | 反馈显示恢复的 App 路径，访达定位该 App，发布页打开预期版本 | 独立反馈窗口+AX+访达位置/发布页证据 |
| V05-recovery-feedback-old-reopen-failed-zh-Hans-light | REQUIRED | recovery-feedback | old-reopen-failed | zh-Hans | light | static | 独立反馈可用；旧版已恢复到原位置 | 模拟新版失败且旧版无法自动打开；依次验证两个操作 | 系统/实测；组件 P07-F03;P07-F04（入口或角色，浅色变量） | 反馈显示恢复的 App 路径，访达定位该 App，发布页打开预期版本 | 独立反馈窗口+AX+访达位置/发布页证据 |
| V05-recovery-feedback-old-reopen-failed-en-dark | REQUIRED | recovery-feedback | old-reopen-failed | en | dark | static | 独立反馈可用；旧版已恢复到原位置 | 模拟新版失败且旧版无法自动打开；依次验证两个操作 | 系统/实测；组件 P07-F03;P07-F04（入口或角色，英文译文） | 反馈显示恢复的 App 路径，访达定位该 App，发布页打开预期版本 | 独立反馈窗口+AX+访达位置/发布页证据 |
| V05-recovery-feedback-old-reopen-failed-en-light | REQUIRED | recovery-feedback | old-reopen-failed | en | light | static | 独立反馈可用；旧版已恢复到原位置 | 模拟新版失败且旧版无法自动打开；依次验证两个操作 | 系统/实测；组件 P07-F03;P07-F04（入口或角色，英文译文与浅色变量） | 反馈显示恢复的 App 路径，访达定位该 App，发布页打开预期版本 | 独立反馈窗口+AX+访达位置/发布页证据 |
