---
phase: 01-upstream-audit-ui-shell
verified: 2026-11-13T19:18:44Z
status: passed
score: 17/17 必验项已验证
behavior_unverified: 0
overrides_applied: 0
decision_coverage: {honored: 9, total: 9, not_honored: []}
re_verification:
  previous_status: human_needed
  previous_score: 12/13
  gaps_closed: [G-01-2, G-01-3]
  gaps_remaining: []
  regressions: []
advisory:
  - finding: "WR-03 · 主窗关闭通知的选择器缺少 Notification 参数"
    category: other
    reason: "Foundation 文档要求选择器接收一个通知参数。验收构建在 macOS 26.7.1 上触发了关闭回调，同一进程的激活策略切换和 Dock 交互均有实测证据。"
    evidence_status: "文档契约差异，当前验收构建实测通过"
covered_files: [
  ".gitignore",
  ".planning/debug/resolved/g1-focus-help.md",
  ".planning/debug/resolved/g1-panel-dock.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-01-PLAN.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-01-SUMMARY.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-02-PLAN.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-02-SUMMARY.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-03-PLAN.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-03-SUMMARY.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-04-PLAN.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-04-SUMMARY.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-CONTEXT.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-G1-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-G1-RETEST.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-REVIEW-DISPOSITION.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-REVIEW.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-SECURITY.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-UAT.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-UI-REVIEW.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-UI-SPEC.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-UPSTREAM-AUDIT.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/01-VALIDATION.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/COVERAGE.md",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/g1/about.png",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/g1/ready-main-dark.png",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/g1/ready-main-light.png",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/g1/ready-menu-dark.png",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/g1/ready-menu-light.png",
  ".planning/milestones/v0.1-phases/01-upstream-audit-ui-shell/g1/settings-general.png",
  ".planning/milestones/v0.1-phases/03-flutter/03-G2-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/04-macos/04-P4-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/04-macos/04-UI-REVIEW.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-01-SUMMARY.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-ENVIRONMENT.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-G3-ACCEPTANCE.md",
  ".planning/milestones/v0.1-phases/05-stability-recovery-release/05-UI-REVIEW.md",
  "FlutterRunlet.xcodeproj/project.pbxproj",
  "FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme",
  "FlutterRunlet/Assets.xcassets/BrandGlyph.imageset/Contents.json",
  "FlutterRunlet/Assets.xcassets/BrandGlyph.imageset/flutterrunlet-glyph.svg",
  "FlutterRunlet/AuxiliaryWindows.swift",
  "FlutterRunlet/FlutterRunletApp.swift",
  "FlutterRunlet/LaunchPresentation.swift",
  "FlutterRunlet/Localizable.xcstrings",
  "FlutterRunlet/MainWindowView.swift",
  "FlutterRunlet/MenuBarPanelView.swift",
  "FlutterRunlet/SessionController.swift",
  "FlutterRunletSessionWorker/main.swift",
  "FlutterRunletTests/LaunchPresentationTests.swift",
  "LICENSE",
  "docs/04-ACCEPTANCE.md",
  "docs/design/assets/flutterrunlet-glyph.svg",
  "docs/design/assets/flutterrunlet-menubar-template@1x.png",
  "docs/design/assets/flutterrunlet-menubar-template@2x.png"
]
covered_digest: "v3:sha256:70101a65311295e50109b247dc9aef683536c991d02bb4805056a5be64679d46"
---

# Phase 1 · 上游审计与原生 UI 骨架验证

**阶段目标** 完成上游审计，交付可启动的原生 App 骨架并通过 G1。

**结论** Phase 01 通过。四份计划的交付物和五项 G1 人工验收均有证据。G-01-2 与 G-01-3 在同一份最终 Debug Ready 构建上获用户确认。六张正式截图保留首次原生取证基线，最终构建另有主窗浅深外观和两处原生键盘焦点复验。 [G1 验收记录](01-G1-ACCEPTANCE.md) · 最终构建与用户复验

## 最终候选复核

在 2026-11-14 对照冻结候选 `36916dd1f6a6f916a1c76ca93aa37ae84f8247f6`、四份 G1 计划与摘要及 G3 验收。应用源码、测试、worker 和 Xcode 工程与候选一致。BASE-01–03 及原 17 项均有对应证据。下方保留 G1 当时的原生构建、六张基线图和用户验收。

| 核对范围 | 最终候选及可沿用证据 |
| --- | --- |
| 路线 1、BASE-01 · 上游来源与许可 | 上游审计锁定提交、MIT 与版权，G1 采用共享场景思路，实际导入清单无上游源码、资源或依赖。品牌资源保持原样，G3 最终关于页及本地包继续提供上游归属和项目许可证据。[上游审计](01-UPSTREAM-AUDIT.md) · [原始导入核验](01-G1-ACCEPTANCE.md#base-01--上游来源与许可) · [G3 矩阵](../05-stability-recovery-release/05-G3-ACCEPTANCE.md) |
| D-01–D-03 · Empty、Debug Ready、原生提示及空日志 | 最终源码的启动解析分别以 `swiftc -D DEBUG FlutterRunlet/LaunchPresentation.swift "$probe/main.swift" -o "$probe/debug"` 与 `swiftc -O FlutterRunlet/LaunchPresentation.swift "$probe/main.swift" -o "$probe/release"` 编译并执行，两次退出码均为 0。普通、近似参数均为 Empty，精确 `--g1-ready` 仅在 Debug 返回完整示例。G2 的普通 Release 已实测历史参数隔离，G3 复验同源 Release 普通启动。当前隔离 Debug 实测主窗 640 × 580 pt、四按钮同排、完整示例和已展开的空日志。点击 Run 弹出原生「演示模式」「当前为运行演示。」「关闭」，关闭后回到 Ready。面板的演示沿用 G1 实测，本次源码核对两处共用 `showRunDemo(locale:)` 且 Debug Ready 不向视图传入实际会话。[启动测试](../../../../FlutterRunletTests/LaunchPresentationTests.swift#L241) · [场景接线](../../../../FlutterRunlet/FlutterRunletApp.swift#L180) · [G2 Release 隔离](../03-flutter/03-G2-ACCEPTANCE.md#release-历史参数隔离) · [原 G1 两处 Run](01-G1-ACCEPTANCE.md) |
| 路线 2、D-04–D-07、G-01-2 · 共有状态、窗口布局及开关 | G3 实测最终 Release 主窗 640 × 580 pt、双语控件和面板同会话。面板 404 pt、原生设置与独立关于尺寸和长名沿用 P4 原生基线，最终候选复验实际关于版本、版权及三个链接。用户在 G1 确认面板收起、关主窗同进程和 Dock、重开与焦点，P4 复验从面板打开设置和主窗、唯一窗口、状态栏驻留及共享会话。P4 登录候选至最终候选的场景与面板宿主保持一致。G1 用户复验 · [P4 修正复验](../04-macos/04-P4-ACCEPTANCE.md#审查修正复验) · [G3 原生审查](../05-stability-recovery-release/05-VERIFICATION.md) |
| G-01-3 · 键盘焦点、禁用语义和悬停 | 当前隔离 Debug 主窗的 Tab 与 Shift-Tab 在项目全名和配置全名之间可见往返，文件夹按钮的可访问名称和禁用状态可读，点击不执行。用户已在 G1 实测两处完整焦点链及「打开项目」悬停提示，Phase 04 与 G3 已复核生产原生焦点。本轮未直接操作菜单栏演示或悬停。禁用项目按钮仍使用原 AppKit 悬停视图且不参与命中，后续变更将原有标签改为按当前语言更新，中文仍为「打开项目」。原 G1 实测 · 调试记录 · [悬停实现](../../../../FlutterRunlet/MainWindowView.swift#L438) |
| 路线 3、D-08、D-09、BASE-03 · 实际部署目标 | 隔离 Debug 构建使用 Xcode 27.1，Bundle ID 为 `com.atypiape.FlutterRunlet.Reverify`。用 `xcrun vtool -show-build` 核对主程序、调试 dylib 和内嵌 worker 均为 `minos 15.0`、SDK 27.0。最终 G3 Release 的主程序和 worker 在 arm64／x86_64 上均为 15.0。原生复验宿主为 macOS 26.7.1。按用户确认，macOS 15 的运行兼容性未验证。[G1 API 及部署核查](01-G1-ACCEPTANCE.md#a31--macos-15-部署目标与-api) · [G3 A31](../05-stability-recovery-release/05-VERIFICATION.md) |

隔离 Debug 主程序 SHA-256 为 `a862d014350c28b7518ef8bfe8d31112f18a0a12f5c27b0d19d01ea4378afbd5`，调试 dylib 为 `78e5edf4fd0ad2ae846f83a4879b8272836f8ca2546d603a759a5f7d7a8bfb43`，内嵌 worker 为 `005ba0bfba89665a2403c71cdc20cbcdc5dd99f0a12f07d7ead6f9e9457eed82`。G1 两条原用户确认和原验收反馈可追溯。复核通过，原关闭通知签名差异仍有记录。 关闭通知审查 · 面板调试记录

## 可观察的必验项

路线图的三项成功条件与计划中重复的要求合并核对。运行结果来自实际记录，源码用于确认接线和数据边界。

| 必验项 | 结果 | 证据 |
| --- | --- | --- |
| 路线图 1、BASE-01、最终采用一致 | 已验证 | 独立核对固定 Git 提交、`Package.swift` 与完整 MIT 许可。已跟踪的 App、测试和工程对象与上游 blob 无交集。项目自有 SVG 和两种构建内的双比例 PNG 与项目资产一致。 [上游审计](01-UPSTREAM-AUDIT.md) · [最终采用](01-G1-ACCEPTANCE.md#base-01--上游来源与许可) |
| D-01、D-02，Empty 与共享 Ready | 已验证 | 三个 Debug XCTest 全通过。当前解析源码独立执行 Debug 及非 Debug 条件，精确参数仅 Debug 进入 Ready。主窗与面板的实际三种启动结果一致，Release 修复后启动仍为 Empty。 [启动策略](../../../../FlutterRunlet/LaunchPresentation.swift) · [A01](01-G1-ACCEPTANCE.md#a01--主窗口) |
| D-03，两处原生 Run 提示 | 已验证 | 两处按钮共用 `showRunDemo`。实际打开两次原生提示，标题、正文与关闭按钮可见，回车关闭后保持 Ready。其余调试及浏览器动作禁用。 [原生取证](01-G1-ACCEPTANCE.md#a02--菜单栏快捷面板) |
| D-04，主窗关闭、重开与唯一聚焦 | 已验证 | 实测进程 PID 31979 在关闭主窗后存活，重开与第二次打开均为窗口 6651，AX 焦点回到主窗，Ready 状态保留。 [窗口记录](01-G1-ACCEPTANCE.md#a02--菜单栏快捷面板) |
| 日志默认展开且内容为空 | 已验证 | `isLogExpanded` 默认 `true`，滚动区为空。执行者记录 Empty 和 Ready 的实际表现，浅深主窗截图可复核。 [主窗实现](../../../../FlutterRunlet/MainWindowView.swift) · 主窗浅色 |
| 主窗四个调试按钮同排 | 已验证 | 目检浅深两图，四项标签完整、同排。实际 AX 同一纵坐标。 主窗浅色 · 主窗深色 |
| 两处动作与禁用标签可辨认 | 已验证 | 原始人工验收第 1 项通过，包含浅色主窗禁用按钮的实际可辨认度。浅色对比偏低的原生观感仍有记录。 人工验收 · 界面审查 |
| 长字段省略、全文与换行 | 已验证 | 两处共享 `PresentationField` 的单行尾部省略及原生 help。两份 Live Canvas 实测六个 Help Tag，项目、配置、设备均显示各自尾段。会话字段换行，生产面板仅约束宽度。 [长字段复验](01-G1-ACCEPTANCE.md#长字段复验) |
| D-06，设置默认通用与双入口 | 已验证 | 原生 Settings scene。执行者实际通用 → Flutter → 通用，两入口均聚焦窗口 6655。截图显示通用默认页及两项导航。 [设置与关于](01-G1-ACCEPTANCE.md#设置与关于) · 设置截图 |
| D-07，独立关于与实际版本 | 已验证 | 独立 `about` 窗口 6673 和主窗、设置同时存在。截图中的标志及 0.1.0 (1) 与实际两个 bundle 的版本键一致。 关于截图 · [关于实现](../../../../FlutterRunlet/AuxiliaryWindows.swift) |
| 路线图 2、D-05，四窗口尺寸及六图 | 已验证 | 实测主窗外框 640 × 580 pt、面板 404 × 278 pt、设置 672 × 520 pt、关于 440 × 480 pt。内容区、逻辑点与截图像素分别记录。独立查看全部六张 PNG，并核对 G0 参考尺寸与实际原生控件差异。 [G1 验收记录](01-G1-ACCEPTANCE.md) |
| 路线图 3、D-08，最低部署版本和 API | 已验证 | 当前有效设置为 Swift 6.0、macOS 15.0。独立读取 Debug arm64、Release x86_64 与 arm64 的 Mach-O，三者 `minos 15.0`、`sdk 27.0`。本轮实际 API 及替代路径有出处。 [A31](01-G1-ACCEPTANCE.md#a31--macos-15-部署目标与-api) |
| D-09，实际运行系统与实机例外 | 已验证 | 原生记录来自 macOS 26.7.1。缺少可用的 macOS 15 环境，实机复验按 D-09 未执行。 [D-09](01-G1-ACCEPTANCE.md#d-09--macos-15-实机) |
| G-01-2，面板打开主窗或设置时收起 | 已验证 | 两个入口先关闭当前面板，再执行窗口路由。用户在最终构建上确认缺口通过。 [App 场景](../../../../FlutterRunlet/FlutterRunletApp.swift) · 最终复验 |
| G-01-2，主窗生命周期与 Dock | 已验证 | 实测关闭主窗前后为同一进程，激活策略转为 `.accessory`，设置和关于仍可操作。主窗最小化时保留 `.regular`。用户确认 Dock 指示和主窗恢复。 最终复验 |
| G-01-3，正反向焦点及项目悬停 | 已验证 | 正反向键盘遍历截图覆盖主窗和面板，禁用控件被跳过，Space 可触发运行演示。用户确认两个窗口的 Tab 和 Shift-Tab 焦点可见，并确认「打开项目」提示。 最终复验 |
| 同一构建复验与原始反馈可追溯 | 已验证 | 两次回复均关联记录中的最终 Debug 主程序及调试动态库，复核 SHA-256 一致。原始五项结果和两处问题均保留，GSD 判定五项通过且无阻塞项。 最终复验 · 人工验收 |

## 工件与接线

四份计划声明的 13 项工件检查全部通过，按计划分别计数。工程和共享 scheme 产出了 App 与 XCTest，场景和窗口内容进入实际 App，验收工件的源链接及截图链接均可读取。

| 计划 | 接线核对 |
| --- | --- |
| 01-01 | `FlutterRunletApp.presentation` 从进程参数求值一次，传入 `MainWindowView` 与 `MenuBarPanelView`。面板把环境 `openWindow` 交给 `showMainWindow`，后者先聚焦已显示的主窗，再按固定 ID 和路由值重开。 [App 场景](../../../../FlutterRunlet/FlutterRunletApp.swift) · [面板实现](../../../../FlutterRunlet/MenuBarPanelView.swift) |
| 01-02 | 主窗与面板接同一 `showSettings`。`SettingsView` 挂在 Settings scene。关于入口接独立 `Window`，其中 `BrandGlyph` 来自资产目录，版本与构建号来自 `Bundle.main`。 [App 场景](../../../../FlutterRunlet/FlutterRunletApp.swift) · [窗口内容](../../../../FlutterRunlet/AuxiliaryWindows.swift) |
| 01-03 | 验收记录引用固定上游审计和六张实际截图，各文件能打开。 [验收记录](01-G1-ACCEPTANCE.md) · [上游审计](01-UPSTREAM-AUDIT.md) |
| 01-04 | `MenuBarPanelView` 的入口闭包传回 `FlutterRunletApp`，先关闭绑定的面板窗口，再执行主窗或设置路由。原生提示视图挂接在禁用项目按钮上。复验记录引用原 UAT 并保留两项用户反馈。 [App 场景](../../../../FlutterRunlet/FlutterRunletApp.swift) · [主窗实现](../../../../FlutterRunlet/MainWindowView.swift) · 复验记录 |

GSD 文本检查对八条链接返回 `Target not referenced in source`。核对 Swift 同模块类型、闭包调用及 Markdown 相对路径，八条接线均有实际证据。

## 行为与测试质量

| 核对 | 结果 |
| --- | --- |
| 固定上游对象 | `git cat-file -e` 确认提交、依赖清单和 LICENSE 均在本地审计克隆中。该克隆在 Git 忽略范围内。 |
| 参数行为 | 将当前 `LaunchPresentation.swift` 与断言送入 `swift -D DEBUG -` 和 `swift -`。两次均退出 0。实际 XCTest 分别断言普通、精确及相似参数，三项通过，没有跳过或用被测输出生成预期值。 |
| 已构建 App | 两份 App 可执行。当前 `xcodebuild -showBuildSettings -json` 与 `xcrun vtool -show-build` 的有效部署目标、编译条件及 Mach-O 记录一致。 |
| 原生取证 | `sips` 读取六张 PNG 的格式及像素尺寸。核对本机实际记录中的主窗、面板、设置和关于窗口，以及长字段提示。 |
| 最终构建 | `.build/phase-01-gaps/debug-tests.log` 记录 Debug XCTest 3 项通过且无跳过。Release 构建成功。三个文件的 SHA-256 均与复验记录一致。复查 Debug 动态库及 Release 的 arm64 和 x86_64，Mach-O 最低版本均为 15.0，SDK 为 27.0。 最终构建 |
| 原生 API 补查 | 最终实现使用 AppKit 窗口关闭、关闭通知、激活策略和提示属性。两种配置均以 macOS 15.0 为目标构建成功。复验覆盖的是 macOS 26.7.1 的运行行为。 最终复验 · [A31](01-G1-ACCEPTANCE.md#a31--macos-15-部署目标与-api) |

Debug 启动测试以固定字面值断言普通、精确与相似参数，三项均有实际执行记录。原生交互以窗口实测、焦点截图及用户验收覆盖。 验证策略

## 需求与阶段决定

| 需求 | 来源 | 覆盖 |
| --- | --- | --- |
| BASE-01 | 01-01、01-03 | 固定上游审计、复用边界、许可与实际采用核对齐备。 |
| BASE-02 | 01-01、01-02、01-03、01-04 | 四个原生界面、实测尺寸、原生差异及截图齐备，G1 用户验收通过。 |
| BASE-03 | 01-01、01-03、01-04 | 两种实际构建、各架构最低版本与 API 核查齐备。 |

GSD 决定覆盖检查核对 D-01 至 D-09，结果 9/9。用户验收与源码证实实际 Run 只打开原生 `NSAlert`，样例来自 `LaunchPresentation`。两种构建的 macOS 15.0 部署证据与 macOS 26.7.1 的运行实测分别记录。 阶段决定 · [G1 取证](01-G1-ACCEPTANCE.md)

固定演示样例和空日志均符合本阶段约定。禁用动作有意保留原生控件位置，实际项目配置和调试能力对应后续路线。安全验证记录 0 项未关闭威胁。 UI 规格 · 安全验证 · [路线图](../../v0.1-ROADMAP.md)

## 人工验收

GSD 核验五项人工验收均通过。原始两条问题保留在验收记录，缺口按 `01-04` 关闭。用户在同一构建确认面板与 Dock、原生悬停，以及主窗和面板的 Tab 和 Shift-Tab 焦点。 人工验收 · 最终用户确认

## 验证范围与警告

WR-03 保持待处理。主窗关闭通知回调缺少 Foundation 文档要求的 `Notification` 参数。当前验收构建在 macOS 26.7.1 上的激活策略切换及用户复验均通过。macOS 15 实机因缺少环境按 D-09 未执行。 审查处置 · [实机范围](01-G1-ACCEPTANCE.md#d-09--macos-15-实机)
