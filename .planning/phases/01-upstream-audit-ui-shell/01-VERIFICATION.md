---
phase: 01-upstream-audit-ui-shell
verified: 2026-11-12T02:58:47Z
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
covered_files:
  - .gitignore
  - .planning/phases/01-upstream-audit-ui-shell/01-01-PLAN.md
  - .planning/phases/01-upstream-audit-ui-shell/01-01-SUMMARY.md
  - .planning/phases/01-upstream-audit-ui-shell/01-02-PLAN.md
  - .planning/phases/01-upstream-audit-ui-shell/01-02-SUMMARY.md
  - .planning/phases/01-upstream-audit-ui-shell/01-03-PLAN.md
  - .planning/phases/01-upstream-audit-ui-shell/01-03-SUMMARY.md
  - .planning/phases/01-upstream-audit-ui-shell/01-04-PLAN.md
  - .planning/phases/01-upstream-audit-ui-shell/01-04-SUMMARY.md
  - .planning/phases/01-upstream-audit-ui-shell/01-CONTEXT.md
  - .planning/phases/01-upstream-audit-ui-shell/01-G1-ACCEPTANCE.md
  - .planning/phases/01-upstream-audit-ui-shell/01-G1-RETEST.md
  - .planning/phases/01-upstream-audit-ui-shell/01-REVIEW-DISPOSITION.md
  - .planning/phases/01-upstream-audit-ui-shell/01-REVIEW.md
  - .planning/phases/01-upstream-audit-ui-shell/01-SECURITY.md
  - .planning/phases/01-upstream-audit-ui-shell/01-UAT.md
  - .planning/phases/01-upstream-audit-ui-shell/01-UI-REVIEW.md
  - .planning/phases/01-upstream-audit-ui-shell/01-UI-SPEC.md
  - .planning/phases/01-upstream-audit-ui-shell/01-UPSTREAM-AUDIT.md
  - .planning/phases/01-upstream-audit-ui-shell/01-VALIDATION.md
  - .planning/phases/01-upstream-audit-ui-shell/COVERAGE.md
  - .planning/phases/01-upstream-audit-ui-shell/g1/about.png
  - .planning/phases/01-upstream-audit-ui-shell/g1/ready-main-dark.png
  - .planning/phases/01-upstream-audit-ui-shell/g1/ready-main-light.png
  - .planning/phases/01-upstream-audit-ui-shell/g1/ready-menu-dark.png
  - .planning/phases/01-upstream-audit-ui-shell/g1/ready-menu-light.png
  - .planning/phases/01-upstream-audit-ui-shell/g1/settings-general.png
  - FlutterRunlet.xcodeproj/project.pbxproj
  - FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme
  - FlutterRunlet/Assets.xcassets/BrandGlyph.imageset/Contents.json
  - FlutterRunlet/Assets.xcassets/BrandGlyph.imageset/flutterrunlet-glyph.svg
  - FlutterRunlet/AuxiliaryWindows.swift
  - FlutterRunlet/FlutterRunletApp.swift
  - FlutterRunlet/LaunchPresentation.swift
  - FlutterRunlet/MainWindowView.swift
  - FlutterRunlet/MenuBarPanelView.swift
  - FlutterRunletTests/LaunchPresentationTests.swift
  - docs/04-ACCEPTANCE.md
  - docs/design/assets/flutterrunlet-glyph.svg
  - docs/design/assets/flutterrunlet-menubar-template@1x.png
  - docs/design/assets/flutterrunlet-menubar-template@2x.png
covered_digest: "v3:sha256:a801c674b61b8b9a74632814959e03679d00376681354902614ae5fa04946ceb"
---

# Phase 1 · 上游审计与原生 UI 骨架验证

**阶段目标** 完成上游审计，交付可启动的原生 App 骨架并通过 G1。

**结论** Phase 01 通过。四份计划的交付物和五项 G1 人工验收均有证据。G-01-2 与 G-01-3 在同一份最终 Debug Ready 构建上获用户确认。六张正式截图保留首次原生取证基线，最终构建另有主窗浅深外观和两处原生键盘焦点复验。 [G1 验收记录](01-G1-ACCEPTANCE.md) · [最终构建与用户复验](01-G1-RETEST.md)

## 可观察的必验项

路线图的三项成功条件与计划中重复的要求合并核对。运行结果来自实际记录，源码用于确认接线和数据边界。

| 必验项 | 结果 | 证据 |
| --- | --- | --- |
| 路线图 1、BASE-01、最终采用一致 | 已验证 | 独立核对固定 Git 提交、`Package.swift` 与完整 MIT 许可。已跟踪的 App、测试和工程对象与上游 blob 无交集。项目自有 SVG 和两种构建内的双比例 PNG 与项目资产一致。 [上游审计](01-UPSTREAM-AUDIT.md) · [最终采用](01-G1-ACCEPTANCE.md#base-01--上游来源与许可) |
| D-01、D-02，Empty 与共享 Ready | 已验证 | 三个 Debug XCTest 全通过。当前解析源码独立执行 Debug 及非 Debug 条件，精确参数仅 Debug 进入 Ready。主窗与面板的实际三种启动结果一致，Release 修复后启动仍为 Empty。 [启动策略](../../../FlutterRunlet/LaunchPresentation.swift) · [A01](01-G1-ACCEPTANCE.md#a01--主窗口) |
| D-03，两处原生 Run 提示 | 已验证 | 两处按钮共用 `showRunDemo`。实际打开两次原生提示，标题、正文与关闭按钮可见，回车关闭后保持 Ready。其余调试及浏览器动作禁用。 [原生取证](01-G1-ACCEPTANCE.md#a02--菜单栏快捷面板) |
| D-04，主窗关闭、重开与唯一聚焦 | 已验证 | 实测进程 PID 31979 在关闭主窗后存活，重开与第二次打开均为窗口 6651，AX 焦点回到主窗，Ready 状态保留。 [窗口记录](01-G1-ACCEPTANCE.md#a02--菜单栏快捷面板) |
| 日志默认展开且内容为空 | 已验证 | `isLogExpanded` 默认 `true`，滚动区为空。执行者记录 Empty 和 Ready 的实际表现，浅深主窗截图可复核。 [主窗实现](../../../FlutterRunlet/MainWindowView.swift) · [主窗浅色](g1/ready-main-light.png) |
| 主窗四个调试按钮同排 | 已验证 | 目检浅深两图，四项标签完整、同排。实际 AX 同一纵坐标。 [主窗浅色](g1/ready-main-light.png) · [主窗深色](g1/ready-main-dark.png) |
| 两处动作与禁用标签可辨认 | 已验证 | 原始人工验收第 1 项通过，包含浅色主窗禁用按钮的实际可辨认度。浅色对比偏低的原生观感仍有记录。 [人工验收](01-UAT.md) · [界面审查](01-UI-REVIEW.md#3-颜色--34) |
| 长字段省略、全文与换行 | 已验证 | 两处共享 `PresentationField` 的单行尾部省略及原生 help。两份 Live Canvas 实测六个 Help Tag，项目、配置、设备均显示各自尾段。会话字段换行，生产面板仅约束宽度。 [长字段复验](01-G1-ACCEPTANCE.md#长字段复验) |
| D-06，设置默认通用与双入口 | 已验证 | 原生 Settings scene。执行者实际通用 → Flutter → 通用，两入口均聚焦窗口 6655。截图显示通用默认页及两项导航。 [设置与关于](01-G1-ACCEPTANCE.md#设置与关于) · [设置截图](g1/settings-general.png) |
| D-07，独立关于与实际版本 | 已验证 | 独立 `about` 窗口 6673 和主窗、设置同时存在。截图中的标志及 0.1.0 (1) 与实际两个 bundle 的版本键一致。 [关于截图](g1/about.png) · [关于实现](../../../FlutterRunlet/AuxiliaryWindows.swift) |
| 路线图 2、D-05，四窗口尺寸及六图 | 已验证 | 实测主窗外框 640 × 580 pt、面板 404 × 278 pt、设置 672 × 520 pt、关于 440 × 480 pt。内容区、逻辑点与截图像素分别记录。独立查看全部六张 PNG，并核对 G0 参考尺寸与实际原生控件差异。 [G1 验收记录](01-G1-ACCEPTANCE.md) |
| 路线图 3、D-08，最低部署版本和 API | 已验证 | 当前有效设置为 Swift 6.0、macOS 15.0。独立读取 Debug arm64、Release x86_64 与 arm64 的 Mach-O，三者 `minos 15.0`、`sdk 27.0`。本轮实际 API 及替代路径有出处。 [A31](01-G1-ACCEPTANCE.md#a31--macos-15-部署目标与-api) |
| D-09，实际运行系统与实机例外 | 已验证 | 原生记录来自 macOS 26.7.1。缺少可用的 macOS 15 环境，实机复验按 D-09 未执行。 [D-09](01-G1-ACCEPTANCE.md#d-09--macos-15-实机) |
| G-01-2，面板打开主窗或设置时收起 | 已验证 | 两个入口先关闭当前面板，再执行窗口路由。用户在最终构建上确认缺口通过。 [App 场景](../../../FlutterRunlet/FlutterRunletApp.swift) · [最终复验](01-G1-RETEST.md) |
| G-01-2，主窗生命周期与 Dock | 已验证 | 实测关闭主窗前后为同一进程，激活策略转为 `.accessory`，设置和关于仍可操作。主窗最小化时保留 `.regular`。用户确认 Dock 指示和主窗恢复。 [最终复验](01-G1-RETEST.md) |
| G-01-3，正反向焦点及项目悬停 | 已验证 | 正反向键盘遍历截图覆盖主窗和面板，禁用控件被跳过，Space 可触发运行演示。用户确认两个窗口的 Tab 和 Shift-Tab 焦点可见，并确认「打开项目」提示。 [最终复验](01-G1-RETEST.md) |
| 同一构建复验与原始反馈可追溯 | 已验证 | 两次回复均关联记录中的最终 Debug 主程序及调试动态库，复核 SHA-256 一致。原始五项结果和两处问题均保留，GSD 判定五项通过且无阻塞项。 [最终复验](01-G1-RETEST.md) · [人工验收](01-UAT.md) |

## 工件与接线

四份计划声明的 13 项工件检查全部通过，按计划分别计数。工程和共享 scheme 产出了 App 与 XCTest，场景和窗口内容进入实际 App，验收工件的源链接及截图链接均可读取。

| 计划 | 接线核对 |
| --- | --- |
| 01-01 | `FlutterRunletApp.presentation` 从进程参数求值一次，传入 `MainWindowView` 与 `MenuBarPanelView`。面板把环境 `openWindow` 交给 `showMainWindow`，后者先聚焦已显示的主窗，再按固定 ID 和路由值重开。 [App 场景](../../../FlutterRunlet/FlutterRunletApp.swift) · [面板实现](../../../FlutterRunlet/MenuBarPanelView.swift) |
| 01-02 | 主窗与面板接同一 `showSettings`。`SettingsView` 挂在 Settings scene。关于入口接独立 `Window`，其中 `BrandGlyph` 来自资产目录，版本与构建号来自 `Bundle.main`。 [App 场景](../../../FlutterRunlet/FlutterRunletApp.swift) · [窗口内容](../../../FlutterRunlet/AuxiliaryWindows.swift) |
| 01-03 | 验收记录引用固定上游审计和六张实际截图，各文件能打开。 [验收记录](01-G1-ACCEPTANCE.md) · [上游审计](01-UPSTREAM-AUDIT.md) |
| 01-04 | `MenuBarPanelView` 的入口闭包传回 `FlutterRunletApp`，先关闭绑定的面板窗口，再执行主窗或设置路由。原生提示视图挂接在禁用项目按钮上。复验记录引用原 UAT 并保留两项用户反馈。 [App 场景](../../../FlutterRunlet/FlutterRunletApp.swift) · [主窗实现](../../../FlutterRunlet/MainWindowView.swift) · [复验记录](01-G1-RETEST.md) |

GSD 文本检查对八条链接返回 `Target not referenced in source`。核对 Swift 同模块类型、闭包调用及 Markdown 相对路径，八条接线均有实际证据。

## 行为与测试质量

| 核对 | 结果 |
| --- | --- |
| 固定上游对象 | `git cat-file -e` 确认提交、依赖清单和 LICENSE 均在本地审计克隆中。该克隆在 Git 忽略范围内。 |
| 参数行为 | 将当前 `LaunchPresentation.swift` 与断言送入 `swift -D DEBUG -` 和 `swift -`。两次均退出 0。实际 XCTest 分别断言普通、精确及相似参数，三项通过，没有跳过或用被测输出生成预期值。 |
| 已构建 App | 两份 App 可执行。当前 `xcodebuild -showBuildSettings -json` 与 `xcrun vtool -show-build` 的有效部署目标、编译条件及 Mach-O 记录一致。 |
| 原生取证 | `sips` 读取六张 PNG 的格式及像素尺寸。核对本机实际记录中的主窗、面板、设置和关于窗口，以及长字段提示。 |
| 最终构建 | `.build/phase-01-gaps/debug-tests.log` 记录 Debug XCTest 3 项通过且无跳过。Release 构建成功。三个文件的 SHA-256 均与复验记录一致。复查 Debug 动态库及 Release 的 arm64 和 x86_64，Mach-O 最低版本均为 15.0，SDK 为 27.0。 [最终构建](01-G1-RETEST.md#构建) |
| 原生 API 补查 | 最终实现使用 AppKit 窗口关闭、关闭通知、激活策略和提示属性。两种配置均以 macOS 15.0 为目标构建成功。复验覆盖的是 macOS 26.7.1 的运行行为。 [最终复验](01-G1-RETEST.md) · [A31](01-G1-ACCEPTANCE.md#a31--macos-15-部署目标与-api) |

Debug 启动测试以固定字面值断言普通、精确与相似参数，三项均有实际执行记录。原生交互以窗口实测、焦点截图及用户验收覆盖。 [验证策略](01-VALIDATION.md)

## 需求与阶段决定

| 需求 | 来源 | 覆盖 |
| --- | --- | --- |
| BASE-01 | 01-01、01-03 | 固定上游审计、复用边界、许可与实际采用核对齐备。 |
| BASE-02 | 01-01、01-02、01-03、01-04 | 四个原生界面、实测尺寸、原生差异及截图齐备，G1 用户验收通过。 |
| BASE-03 | 01-01、01-03、01-04 | 两种实际构建、各架构最低版本与 API 核查齐备。 |

GSD 决定覆盖检查核对 D-01 至 D-09，结果 9/9。用户验收与源码证实实际 Run 只打开原生 `NSAlert`，样例来自 `LaunchPresentation`。两种构建的 macOS 15.0 部署证据与 macOS 26.7.1 的运行实测分别记录。 [阶段决定](01-CONTEXT.md) · [G1 取证](01-G1-ACCEPTANCE.md)

固定演示样例和空日志均符合本阶段约定。禁用动作有意保留原生控件位置，实际项目配置和调试能力对应后续路线。安全验证记录 0 项未关闭威胁。 [UI 规格](01-UI-SPEC.md) · [安全验证](01-SECURITY.md) · [路线图](../../ROADMAP.md)

## 人工验收

GSD 核验五项人工验收均通过。原始两条问题保留在验收记录，缺口按 `01-04` 关闭。用户在同一构建确认面板与 Dock、原生悬停，以及主窗和面板的 Tab 和 Shift-Tab 焦点。 [人工验收](01-UAT.md) · [最终用户确认](01-G1-RETEST.md#2026-11-12-最终确认)

## 验证范围与警告

WR-03 保持待处理。主窗关闭通知回调缺少 Foundation 文档要求的 `Notification` 参数。当前验收构建在 macOS 26.7.1 上的激活策略切换及用户复验均通过。macOS 15 实机因缺少环境按 D-09 未执行。 [审查处置](01-REVIEW-DISPOSITION.md) · [实机范围](01-G1-ACCEPTANCE.md#d-09--macos-15-实机)
