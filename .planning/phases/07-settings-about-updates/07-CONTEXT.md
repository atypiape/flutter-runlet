# 阶段 07 · 设置、关于与更新

**讨论日期** 2026-11-15

**状态** 可以进入规划

<domain>

## 阶段范围

按已确认的 v0.2 原型交付设置、独立关于窗口和用户主动触发的应用内更新。需求为 UI-13、UI-14、UI-15、UPD-01、UPD-02，并在同一候选上联验四处界面，完成 UI-07 的阶段 07 验收。保留通用设置、Flutter SDK、环境检测和调试恢复行为。

</domain>

<decisions>

## 已确认决定

### 检查更新

- **D-01** 检查只由用户点击独立关于窗口或设置「关于」页的「检查更新」发起，两处共用进度与结果。以公开仓库的 GitHub 最新正式 Release 为版本来源，忽略草稿与预发布版。调试或环境恢复期间仍可检查。
- **D-02** 两处呈现一致的检查中、有新版、已是最新以及检查失败或不可用反馈。确认没有正式 Release 时显示暂无正式版本可用。版本比较以已运行 App 的实际版本为基准。

### 下载与安装确认

- **D-03** 允许用户在调试运行或环境恢复期间点击「更新到 vX.Y.Z」下载并校验更新包。调试会话和环境恢复均结束后才允许安装并重启。安装入口需遵守现有运行与恢复安全条件，包括待恢复、恢复失败及无法确认进程已结束的情况。
- **D-04** 更新包就绪且允许安装时，主动弹出「安装并重启」确认。即使两处「关于」都已关闭，用户也能收到确认。安装需由用户确认。选择「稍后」时，本次 App 运行内保留已下载的更新包，两处「关于」都可继续安装，本次等待结束产生的确认框只自动显示一次。
- **D-05** 阶段 07 使用两份隔离的本地候选验证 App 内安装和重启。安装成功后，以新进程实际运行的 App 版本与构建号为准，更新独立关于窗口、设置「关于」页和设置侧栏。两处关于界面共享更新中反馈。

### 失败与恢复

- **D-06** 下载或校验失败时保留当前版本，两处「关于」显示失败原因，并同时提供「重试」和「查看发布页」。
- **D-07** 替换前保留旧版。安装失败或新版无法启动时，把旧版恢复到原位置并尝试重新打开。旧版重新打开后显示失败原因，并提供「重试」和「查看发布页」。
- **D-08** 旧版已恢复但无法自动打开时，显示恢复后的 App 位置，提供「在访达中显示」和「查看发布页」。验收覆盖新版无法启动及恢复后旧版无法自动打开。

### 沿用的界面与运行行为

- **D-09** 设置宽 520 pt，左栏包含「通用」「Flutter」「关于」，底部显示实际版本与构建号。独立关于窗口为 400 × 412 pt。设置「关于」页与独立窗口共享品牌、MIT 许可证与 Svame 署名、版本、更新状态和三个带图标的链接。三个链接继续打开已确认的仓库首页、README 和 LICENSE，保留现有许可和上游归属记录。v0.2 确认稿和当前需求适用于改动的尺寸与分类。
- **D-10** 两个齿轮打开同一设置窗口。通用设置立即生效，沿用已有持久化和启动逻辑。Flutter 页沿用实际 SDK／FVM 判定、运行一致性、环境检测摘要及完整原始输出。设置窗口和独立关于窗口保留原生键盘行为，主窗口与菜单栏沿用已完成的 Tab 焦点调整。

## 规划时确定

在上述决定内研究下载包的身份校验、安装与恢复方式、新版可用的确认条件、失败反馈传递和相关测试。验收覆盖检查与安装状态、调试期间先下载、恢复后确认、稍后安装，以及安装和启动失败后的恢复。更新闭环使用隔离候选与受控发布数据。四处界面的双语、深浅外观、可读控件名称、已有设置和真实运行恢复按同一候选复验。

</decisions>

<canonical_refs>

## 规划与验收依据

### 需求与契约

- `.planning/PROJECT.md`、`.planning/REQUIREMENTS.md`、`.planning/ROADMAP.md` 的 v0.2 范围与第 07 阶段验收。
- `docs/01-PRODUCT.md` 的历史产品范围。v0.2 的设置与关于采用当前需求。
- `docs/02-TECHNICAL.md` §4–§8 的会话、恢复、SDK、环境和设置规则。
- `docs/04-ACCEPTANCE.md` 的 A05、A21、A23–A26 和证据规则。尺寸与分类采用 v0.2 确认稿。

### 设计与前序验收

- `docs/design/FIGMA-HANDOFF.md` 的 v0.2 原型说明。私有设计入口见本地 `.private/FIGMA-HANDOFF.md`。
- `docs/design/UI-SPEC.md` §3–§7 与 `docs/design/DESIGN-SYSTEM.md` 的原生交互、语言和语义配色。两份文档记录的 v0.1 尺寸与分类已由 v0.2 需求更新。
- `.planning/phases/06-main-window-menu-bar/06-CONTEXT.md`、`.planning/phases/06-main-window-menu-bar/06-UAT.md`、`.planning/phases/06-main-window-menu-bar/06-UI-REVIEW.md` 的主窗口与菜单栏验收、原生差异及 Tab 调整。
- `.planning/milestones/v0.1-phases/04-macos/04-CONTEXT.md`、`.planning/milestones/v0.1-phases/05-stability-recovery-release/05-CONTEXT.md` 的既有偏好、关于链接和恢复验收。

### 发布与许可

- `README.md`、`LICENSE`、`scripts/package-release.sh` 的文档、许可和 macOS 打包入口。
- `docs/PUBLIC-RELEASE-AUDIT.md` 与本地 `.private/v0.1.0-PUBLIC-RELEASE-HANDOFF.md` 的签名、公证及复核历史。仓库与 Release 的可见状态见下方现场核查。

</canonical_refs>

<code_context>

## 可复用实现与接入点

- `FlutterRunlet/FlutterRunletApp.swift` 已用同一个 Settings 场景承接主窗口、菜单栏和系统菜单的设置入口，也已注册独立关于窗口。两处可共用应用级的更新状态和本地化环境。
- `FlutterRunlet/AuxiliaryWindows.swift` 已有通用和 Flutter 设置、SDK 原生目录选择、环境检测和完整输出。现有 `AboutInformation` 从运行 App 的 Bundle 读取版本与构建号，也集中维护三个链接和上游版权。关于标志来自 `FlutterRunlet/Assets.xcassets/BrandGlyph.imageset`。
- `FlutterRunlet/SessionController.swift` 管理调试与环境恢复、SDK 变更、环境检测和现有退出条件。`FlutterRunlet/FlutterRunletApp.swift` 中的 `AppTermination` 已防止普通退出绕过停止与恢复。更新也需要遵守这些状态约束。
- `FlutterRunletTests/FlutterToolchainTests.swift` 与 `FlutterRunletTests/LaunchPresentationTests.swift` 已有 SDK、环境检查及实际版本读取的回归基础。`scripts/package-release.sh` 已支持构建版本输入、通用架构 DMG 和 SHA-256。

</code_context>

<specifics>

## 现场核查

2026-11-15 用户确认已公开仓库，并将 `v0.1.1` 改为正式 Release。匿名 HTTP 请求验证仓库首页、README 和 LICENSE 均返回 200，GitHub 最新正式 Release 接口返回 `v0.1.1`，其预发布和草稿标记均为 false。此前发布说明仍写着「预发布版」并注明临时签名与未公证。阶段 07 继续通过隔离构建验证安装与重启。 [GitHub Release v0.1.1](https://github.com/atypiape/flutter-runlet/releases/tag/v0.1.1)

</specifics>

<deferred>

## 后续发布工作

v0.2 候选公开发布、正式签名、公证和 Figma 分享范围复核按原发布交接接续。

</deferred>
