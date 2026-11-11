---
phase: 01-upstream-audit-ui-shell
verified: 2026-11-11T19:42:42Z
status: human_needed
score: 12/13 必验项已有验证证据
behavior_unverified: 0
overrides_applied: 0
decision_coverage: {honored: 9, total: 9, not_honored: []}
covered_files:
  - .gitignore
  - .planning/phases/01-upstream-audit-ui-shell/01-01-PLAN.md
  - .planning/phases/01-upstream-audit-ui-shell/01-01-SUMMARY.md
  - .planning/phases/01-upstream-audit-ui-shell/01-02-PLAN.md
  - .planning/phases/01-upstream-audit-ui-shell/01-02-SUMMARY.md
  - .planning/phases/01-upstream-audit-ui-shell/01-03-PLAN.md
  - .planning/phases/01-upstream-audit-ui-shell/01-03-SUMMARY.md
  - .planning/phases/01-upstream-audit-ui-shell/01-CONTEXT.md
  - .planning/phases/01-upstream-audit-ui-shell/01-G1-ACCEPTANCE.md
  - .planning/phases/01-upstream-audit-ui-shell/01-REVIEW-DISPOSITION.md
  - .planning/phases/01-upstream-audit-ui-shell/01-SECURITY.md
  - .planning/phases/01-upstream-audit-ui-shell/01-UI-REVIEW.md
  - .planning/phases/01-upstream-audit-ui-shell/01-UI-SPEC.md
  - .planning/phases/01-upstream-audit-ui-shell/01-UPSTREAM-AUDIT.md
  - .planning/phases/01-upstream-audit-ui-shell/01-VALIDATION.md
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
  - docs/design/assets/flutterrunlet-glyph.svg
  - docs/design/assets/flutterrunlet-menubar-template@1x.png
  - docs/design/assets/flutterrunlet-menubar-template@2x.png
covered_digest: "v3:sha256:67a48b462133ba790262e3f77272a8223209007a672492d52e224d74bcb3b8d6"
human_verification:
  - test: >-
      核对三种启动状态、两处运行提示及浅深外观。分别用验收记录的命令启动普通 Debug、带 --g1-ready 的 Debug 和带同一参数的 Release。检查主窗与面板的字段及动作，在两处 Ready 点击运行并关闭提示，对照四张主窗和面板截图，重点辨认浅色主窗的禁用按钮标签。
    expected: >-
      普通 Debug 和带参数的 Release 两处均为 Empty。只有带参数的 Debug 进入 Ready，且主窗与面板显示同一组固定脱敏数据。主窗外框 640 × 580 pt，面板宽 404 pt，四个调试按钮同排，日志默认展开且空。两处运行只弹出标题、正文及关闭按钮完整可见的原生提示，关闭后保持 Ready。禁用标签仍可辨认。
    why_human: >-
      本轮有三种启动与两处提示的执行者实测。最终的原生材质、浅色禁用标签可辨认度和无真实 Flutter 行为的场景确认需要用户验收。
  - test: >-
      核对菜单栏面板的外侧关闭及主窗重开。用状态项打开面板，分别点击状态项和面板外侧关闭。关闭 Ready 主窗，再从面板打开主窗两次。
    expected: >-
      两种方式都能关闭面板。关闭主窗后 App 和状态项保持运行，面板入口重开并聚焦同一扇主窗，Ready 数据仍在。
    why_human: >-
      实测已记录状态项切换、同一进程及窗口编号。远程控制未执行面板外侧点击。
  - test: >-
      核对主窗和面板的完整 Tab 焦点顺序、禁用动作及主窗工具栏文件夹图标的悬停文字。在系统键盘导航可用的情况下依序遍历，用键盘尝试触发禁用的调试和浏览器动作，再将指针停在「打开项目」图标上。
    expected: >-
      可交互控件按界面阅读顺序获得焦点，禁用动作无法由键盘触发。「打开项目」保持禁用并显示可读悬停提示。
    why_human: >-
      AX 已记录重开后的焦点和禁用语义，两次 Tab 均停在主窗。审查修复已添加显式 help，AX 仍读到禁用按钮名称，原生悬停表现和完整键盘路径尚待确认。
  - test: >-
      核对设置和独立关于窗口。分别从主窗与菜单栏打开设置，切换「通用」「Flutter」并返回。打开关于，对照设置及关于截图和实际 bundle。
    expected: >-
      两个入口聚焦同一设置窗口，首次显示通用，两项导航可用且清晰。独立关于显示品牌、FlutterRunlet、版本 0.1.0 和构建号 1，与运行 bundle 一致。
    why_human: >-
      本轮执行者已核对窗口身份、两页往返、截图和版本。可读性及原生窗口外观属于 G1 用户验收。
  - test: >-
      核对长字段与平台证据。在两份 Debug Live Canvas 预览逐项悬停项目、配置、设备，核对六张归档图、原生尺寸与差异说明，并核对 A31 和 D-09 的记录。
    expected: >-
      两处长字段单行省略，原生提示显示全文及对应尾段，主窗会话字段可换行。六图和原生差异可追溯。当前系统实测与两个配置的 macOS 15.0 部署证据分别记录，macOS 15 实机明确列为未执行。
    why_human: >-
      本轮已有六个 Help Tag 与六张原生界面的实测证据。最终的提示可读性、截图与证据范围由用户确认。
---

# Phase 1 · 上游审计与原生 UI 骨架验证

**阶段目标** 完成上游审计，交付可启动的原生 App 骨架并通过 G1。

**结论** 三份计划的交付物已就绪。当前源码、构建和原生取证支持阶段目标的技术部分，G1 用户验收待完成。浅色主窗禁用标签的实际可辨认度仍需确认。六张正式截图来自首次原生取证的构建基线，审查修复 `281cafa` 另有重新构建和运行记录。 [G1 验收记录](01-G1-ACCEPTANCE.md) · [审查复验](01-REVIEW-DISPOSITION.md)

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
| 两处动作与禁用标签可辨认 | 待人工确认 | 标签完整。浅色主窗的禁用文字对比偏低，保留实际可辨认度的用户确认。 [界面审查](01-UI-REVIEW.md#3-颜色--34) |
| 长字段省略、全文与换行 | 已验证 | 两处共享 `PresentationField` 的单行尾部省略及原生 help。两份 Live Canvas 实测六个 Help Tag，项目、配置、设备均显示各自尾段。会话字段换行，生产面板仅约束宽度。 [长字段复验](01-G1-ACCEPTANCE.md#长字段复验) |
| D-06，设置默认通用与双入口 | 已验证 | 原生 Settings scene。执行者实际通用 → Flutter → 通用，两入口均聚焦窗口 6655。截图显示通用默认页及两项导航。 [设置与关于](01-G1-ACCEPTANCE.md#设置与关于) · [设置截图](g1/settings-general.png) |
| D-07，独立关于与实际版本 | 已验证 | 独立 `about` 窗口 6673 和主窗、设置同时存在。截图中的标志及 0.1.0 (1) 与实际两个 bundle 的版本键一致。 [关于截图](g1/about.png) · [关于实现](../../../FlutterRunlet/AuxiliaryWindows.swift) |
| 路线图 2、D-05，四窗口尺寸及六图 | 已验证 | 实测主窗外框 640 × 580 pt、面板 404 × 278 pt、设置 672 × 520 pt、关于 440 × 480 pt。内容区、逻辑点与截图像素分别记录。独立查看全部六张 PNG，并核对 G0 参考尺寸与实际原生控件差异。 [G1 验收记录](01-G1-ACCEPTANCE.md) |
| 路线图 3、D-08，最低部署版本和 API | 已验证 | 当前有效设置为 Swift 6.0、macOS 15.0。独立读取 Debug arm64、Release x86_64 与 arm64 的 Mach-O，三者 `minos 15.0`、`sdk 27.0`。本轮实际 API 及替代路径有出处。 [A31](01-G1-ACCEPTANCE.md#a31--macos-15-部署目标与-api) |
| D-09，实际运行系统与实机例外 | 已验证 | 原生记录来自 macOS 26.7.1。macOS 15 实机未执行，范围按已确认的 D-09 记录。 [D-09](01-G1-ACCEPTANCE.md#d-09--macos-15-实机) |

## 工件与接线

计划声明的 8 项工件通过 GSD 工件检查，均存在且有实际内容。工程和共享 scheme 产出了 App 与 XCTest，场景和窗口内容进入实际 App，验收工件的源链接及截图链接均可读取。

| 计划 | 接线核对 |
| --- | --- |
| 01-01 | `FlutterRunletApp.presentation` 从进程参数求值一次，传入 `MainWindowView` 与 `MenuBarPanelView`。面板把环境 `openWindow` 交给 `showMainWindow`，后者先聚焦已显示的主窗，再按固定 ID 和路由值重开。 [App 场景](../../../FlutterRunlet/FlutterRunletApp.swift) · [面板实现](../../../FlutterRunlet/MenuBarPanelView.swift) |
| 01-02 | 主窗与面板接同一 `showSettings`。`SettingsView` 挂在 Settings scene。关于入口接独立 `Window`，其中 `BrandGlyph` 来自资产目录，版本与构建号来自 `Bundle.main`。 [App 场景](../../../FlutterRunlet/FlutterRunletApp.swift) · [窗口内容](../../../FlutterRunlet/AuxiliaryWindows.swift) |
| 01-03 | 验收记录引用固定上游审计和六张实际截图，各文件能打开。 [验收记录](01-G1-ACCEPTANCE.md) · [上游审计](01-UPSTREAM-AUDIT.md) |

GSD 文本检查对六条链接返回 `Target not referenced in source`。计划中的 `via` 为自然语言。核对实际 Swift 同模块调用、闭包参数及 Markdown 相对路径后，六条均已确认连通。

## 行为与测试质量

| 核对 | 结果 |
| --- | --- |
| 固定上游对象 | `git cat-file -e` 确认提交、依赖清单和 LICENSE 均在本地审计克隆中。该克隆在 Git 忽略范围内。 |
| 参数行为 | 将当前 `LaunchPresentation.swift` 与断言送入 `swift -D DEBUG -` 和 `swift -`。两次均退出 0。实际 XCTest 分别断言普通、精确及相似参数，三项通过，没有跳过或用被测输出生成预期值。 |
| 已构建 App | 两份 App 可执行。当前 `xcodebuild -showBuildSettings -json` 与 `xcrun vtool -show-build` 的有效部署目标、编译条件及 Mach-O 记录一致。 |
| 原生取证 | `sips` 读取六张 PNG 的格式及像素尺寸。核对本机实际记录中的主窗、面板、设置和关于窗口，以及长字段提示。 |
| 审查修复复验 | `g1-review-debug-tests.log` 记录 3 项测试、0 项失败。 `g1-review-release-build.log` 记录 `BUILD SUCCEEDED`。修复后的 AX 保留禁用图标的名称，悬停由用户确认。 [处置记录](01-REVIEW-DISPOSITION.md) |

计划未声明独立探针脚本。复核了计划指定的原生实测记录、构建结果及验收证据。

## 需求与阶段决定

| 需求 | 来源 | 覆盖 |
| --- | --- | --- |
| BASE-01 | 01-01、01-03 | 固定上游审计、复用边界、许可与实际采用核对齐备。 |
| BASE-02 | 01-01、01-02、01-03 | 四个原生界面、实测尺寸、原生差异及截图齐备，G1 用户验收待完成。 |
| BASE-03 | 01-01、01-03 | 两种实际构建、各架构最低版本与 API 可用性齐备。 |

GSD 决定覆盖检查核对 D-01 至 D-09，结果 9/9。两项判断型禁止行为均已检查其支持证据，留待端到端确认。实际 Run 只打开原生 `NSAlert`，固定样例来自 `LaunchPresentation`。macOS 15.0 目标产物与 macOS 26.7.1 实测分别记录，macOS 15 实机保留未执行状态。 [阶段决定](01-CONTEXT.md) · [G1 取证](01-G1-ACCEPTANCE.md)

固定演示样例和空日志均符合本阶段约定。禁用动作有意保留原生控件位置，实际项目配置和调试能力对应后续路线。安全验证记录 0 项未关闭威胁。 [UI 规格](01-UI-SPEC.md) · [安全验证](01-SECURITY.md) · [路线图](../../ROADMAP.md)

## 人工验收

按报告前置元数据中的五项步骤完成用户验收。重点核对完整 Tab 顺序、禁用动作的键盘触发、面板外关闭、浅色禁用标签可辨认度与「打开项目」的实际悬停提示。 [G1 验收步骤](01-G1-ACCEPTANCE.md)
