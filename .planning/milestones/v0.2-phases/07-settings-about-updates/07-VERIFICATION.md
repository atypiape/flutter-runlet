---
phase: 07-settings-about-updates
verified: 2026-11-15T15:08:43Z
status: passed
score: 16/16 must-haves verified
covered_files: [".planning/REQUIREMENTS.md",".planning/ROADMAP.md",".planning/phases/07-settings-about-updates/07-01-PLAN.md",".planning/phases/07-settings-about-updates/07-01-SUMMARY.md",".planning/phases/07-settings-about-updates/07-02-PLAN.md",".planning/phases/07-settings-about-updates/07-02-SUMMARY.md",".planning/phases/07-settings-about-updates/07-03-PLAN.md",".planning/phases/07-settings-about-updates/07-03-SUMMARY.md",".planning/phases/07-settings-about-updates/07-04-PLAN.md",".planning/phases/07-settings-about-updates/07-04-SUMMARY.md",".planning/phases/07-settings-about-updates/07-04-VISUAL-RECHECK.md",".planning/phases/07-settings-about-updates/07-05-PLAN.md",".planning/phases/07-settings-about-updates/07-05-SUMMARY.md",".planning/phases/07-settings-about-updates/07-06-PLAN.md",".planning/phases/07-settings-about-updates/07-06-SUMMARY.md",".planning/phases/07-settings-about-updates/07-ACCEPTANCE.md",".planning/phases/07-settings-about-updates/07-CONTEXT.md",".planning/phases/07-settings-about-updates/07-FIGMA-EVIDENCE.md",".planning/phases/07-settings-about-updates/07-REVIEW-DISPOSITION.md",".planning/phases/07-settings-about-updates/07-REVIEW.md",".planning/phases/07-settings-about-updates/07-SECURITY.md",".planning/phases/07-settings-about-updates/07-UI-REVIEW.md",".planning/phases/07-settings-about-updates/07-UI-SPEC.md",".planning/phases/07-settings-about-updates/07-UPDATE-EVIDENCE.md",".planning/phases/07-settings-about-updates/07-VALIDATION.md",".planning/phases/07-settings-about-updates/07-VISUAL-BASELINE.md",".planning/phases/07-settings-about-updates/07-VISUAL-GATE.md","FlutterRunlet.xcodeproj/project.pbxproj","FlutterRunlet/AppTermination.swift","FlutterRunlet/Assets.xcassets/RunletAboutDocumentation.imageset/Contents.json","FlutterRunlet/Assets.xcassets/RunletAboutDocumentation.imageset/image.svg","FlutterRunlet/Assets.xcassets/RunletAboutGitHub.imageset/Contents.json","FlutterRunlet/Assets.xcassets/RunletAboutGitHub.imageset/image.svg","FlutterRunlet/Assets.xcassets/RunletAboutLicense.imageset/Contents.json","FlutterRunlet/Assets.xcassets/RunletAboutLicense.imageset/image.svg","FlutterRunlet/Assets.xcassets/RunletUpdateCheck.imageset/Contents.json","FlutterRunlet/Assets.xcassets/RunletUpdateCheck.imageset/image.svg","FlutterRunlet/Assets.xcassets/RunletUpdateDownload.imageset/Contents.json","FlutterRunlet/Assets.xcassets/RunletUpdateDownload.imageset/image.svg","FlutterRunlet/Assets.xcassets/RunletUpdateSpinner.imageset/Contents.json","FlutterRunlet/Assets.xcassets/RunletUpdateSpinner.imageset/image.svg","FlutterRunlet/AuxiliaryWindows.swift","FlutterRunlet/FlutterRunletApp.swift","FlutterRunlet/FlutterToolchain.swift","FlutterRunlet/Fonts/NotoSansSC-Medium.ttf","FlutterRunlet/Fonts/NotoSansSC-Regular.ttf","FlutterRunlet/LaunchPresentation.swift","FlutterRunlet/Localizable.xcstrings","FlutterRunlet/MainWindowView.swift","FlutterRunlet/MenuBarPanelView.swift","FlutterRunlet/ProjectRecoveryStore.swift","FlutterRunlet/ReleaseUpdates.swift","FlutterRunlet/RunletAppearance.swift","FlutterRunlet/SessionController.swift","FlutterRunlet/SessionProcess.swift","FlutterRunlet/UpdateActivityLease.swift","FlutterRunlet/UpdateCoordinator.swift","FlutterRunlet/UpdatePackage.swift","FlutterRunlet/UpdatePresentationSource.swift","FlutterRunlet/UpdateTransaction.swift","FlutterRunletSessionWorker/main.swift","FlutterRunletTests/FlutterToolchainTests.swift","FlutterRunletTests/LaunchPresentationTests.swift","FlutterRunletTests/ReleaseUpdatesTests.swift","FlutterRunletTests/UpdateInstallGateTests.swift","FlutterRunletTests/UpdatePackageTests.swift","FlutterRunletTests/UpdateTransactionTests.swift","FlutterRunletUpdateHelper/Localizable.xcstrings","FlutterRunletUpdateHelper/main.swift","LICENSE","README.md","README.zh-CN.md","docs/02-TECHNICAL.md","docs/04-ACCEPTANCE.md","docs/DEVELOPMENT.md","docs/RELEASE-NOTES.md","docs/design/DESIGN-SYSTEM.md","docs/design/UI-SPEC.md","scripts/package-release.sh","scripts/phase-07-update-origin.py","scripts/verify-phase-07-update.py","scripts/verify-phase-07-update.sh","scripts/verify-phase-07-visual-gate.rb"]
covered_digest: "v3:sha256:3cf0abfc16d30f7fc5371c8cbc917ea9abf5daa6aa0254aa69ef04714aed5cda"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 16/16
  gaps_closed: []
  gaps_remaining: []
  regressions: []
decision_coverage:
  honored: 12
  total: 12
  not_honored: []
---

# Phase 07 · 设置、关于与更新 · 独立签核

**阶段目标**　交付设置、关于与更新体验，并完成四处界面的本地联验。

## README 与本机打包变更复核

**结论**　通过（`passed`）。16 项可观察结果、12 项决定和 6 项本地验收均有证据。本轮复核提交 `15a50a7dbb14b5f9c4af365104383b02ec4bc20b` 的 README、配套文档和打包脚本。GSD 此前仅将 `README.md` 和 `scripts/package-release.sh` 标为指纹变更。经 Git 比对，主 App、会话 worker、更新助手、Xcode 工程及测试与已签候选 `2fcb4a3` 一致。四处原生界面的完整矩阵及真实 Flutter 会话沿用原签核。本轮新增实测覆盖当前 DMG 的构建、解包启动和三处实际版本显示。

| 检查 | 结果与证据 |
| --- | --- |
| README、许可与配套文档 | 55 处本地引用及技术锚点有效。9 张 JPEG 在 HEAD 和工作树均完整解码，尺寸一致。中英文安装说明与本地验收范围相符，原许可与上游归属仍可追溯。增量代码审阅未发现阻塞项或警告。 [英文 README](../../../../README.md) · [简体中文说明](../../../../README.zh-CN.md) · [开发指南](../../../../docs/DEVELOPMENT.md) · [版本说明](../../../../docs/RELEASE-NOTES.md) · [许可](../../../../LICENSE) |
| 宿主回归 | `debug-recheck.xcresult` 退出 0，133 通过、0 失败、0 跳过。阶段 06 的八套件合计 93 项，本轮逐套从 `debug-tests.json` 复算。 |
| 打包、验包与签名 | `bash -n` 通过，无效版本与额外参数分别退出 2。`scripts/package-release.sh v0.2.0` 退出 0，输出构建 201，等于取证提交的 Git 提交数。DMG 的 SHA-256 为 `821eceb809b63117d5e4657539f62b6da221725e72c2591684013a63026d4f7f`，摘要及镜像完整性通过。只读挂载校验覆盖 App、会话 worker、更新助手的双架构、严格 ad hoc 签名及构建机路径。解包后复查双架构签名、最低部署目标 15.0，以及普通 Bundle 无隔离更新配置。 [打包脚本](../../../../scripts/package-release.sh) |
| 新包原生启动 | 从 DMG 复制到隔离目录，在 arm64 macOS 26.7.1 启动。设置 520 × 520、独立关于 400 × 412，AX 在设置侧栏、设置「关于」和独立「关于」均读到 `v0.2.0 (build 201)`。AppKit 请求正常退出，退出码 0。可执行 SHA-256 `5812a95c466f5d0c46e92e5001bb17c1d5097fb81fe3085ee8a64d6281df9fe5` 与实拍及 `runtime-smoke.json` 一致。 |
| 原签证据复核 | 视觉门槛实际校验 512 个适用用例，通过。五份已有 `success`、`gate`、`rollback`、`bootstrap-safety`、`handoff-boundaries` 实测清单重新校验，退出 0。本轮复核原始证据与产物身份，隔离事务、完整窗口矩阵和真实 Flutter 场景的运行证据来自原签批次。 [视觉签核](07-VISUAL-GATE.md) · [更新实测](07-UPDATE-EVIDENCE.md) |

本机复核原件在 `.private/phase-07/recheck-20261115T150132Z.bfva5oFd/`。两个早期探针结果保留。首轮在窗口就绪前请求激活，第二轮在独立关于置前时未匹配退出菜单标签。等待窗口后按 PID 与可执行路径定位 AppKit 退出请求，最终通过。

### 六项需求增量核对

| 需求 | 当前结论与证据 |
| --- | --- |
| UI-07 | 通过。四处界面的语言、深浅、可读控件和键盘行为由原候选原生证据覆盖。程序目录一致，512 项冻结证据复核通过，新包确认设置与独立关于可达。 |
| UI-13 | 通过。`SettingsView` 和两处齿轮到同一设置场景的接线与原候选一致，三页及开关由原验收覆盖。新包实测设置窗口和实际版本。 |
| UI-14 | 通过。偏好、SDK、FVM 与 Doctor 沿用原候选原生验收；当前 `FlutterToolchainTests` 17 项和 `LaunchPresentationTests` 25 项通过。 |
| UI-15 | 通过。共用关于组件读取 Bundle，原有 MIT、Svame 和上游归属，及两处共六次浏览器导航有已签证据。当前 README 链接检查与新包两处「关于」的版本显示均通过。 |
| UPD-01 | 通过。两处共用更新状态源，显式操作取实际运行版本，真实正式 Release 查询沿用原签录证，当前 `ReleaseUpdatesTests` 10 项通过。 |
| UPD-02 | 通过。22 项更新包、门禁及事务回归通过，五份隔离安装、恢复和重启证据重新校验通过。新包三处读出实际构建 201。 |

六份计划的 16 条必需产物声明均通过，原关键接线持续有效。GSD 决定覆盖为 12/12。阶段安全记录的开放项为 0，原代码审阅发现均有已关闭处置。本轮无新增验收缺口。Intel 与最低 macOS 15 实机运行、VoiceOver 实际朗读仍沿用原记录的覆盖边界。公开分发、Developer ID、公证、远端可用性和分享范围复核按发布决定暂缓。 [安全复核](07-SECURITY.md) · [审阅处置](07-REVIEW-DISPOSITION.md)

## 原始签核

**结论**　通过（`passed`）。16 项可观察结果、12 条决定和 6 项本地验收均通过。首次独立阶段签核。

## 候选与证据身份

- 最终程序提交 `2fcb4a3d4dbb3ee9b7acaf287582ea126dfcd2a7`，该提交的 Git 树为 `1d2b596aa5ae145f5ea094f7965b247819e6757e`。核对到 `f4fc1fe` 的差异均为阶段文档，程序、工程、脚本和测试与固定提交一致。最终普通 Release 为 `com.atypiape.FlutterRunlet` v0.1.0（构建 1），可执行 SHA-256 为 `2f1aec11c2ae39c30d99a0666903cf9c3895ed97e6950b23328d1f78cda50de7`。固定副本与 Release 构建原件重算的 Bundle 树 SHA-256 均为 `582f8252eb62f2eb0c8278ba76e9018da6822a71a228996634ae0cd36ca3b1f3`。
- 普通候选实物取自 `.private/phase-07/review-fixes/candidates/` 下的 `2fcb4a3` 候选。同期截图、AX、动作与网络取自同一证据根的 `ordinary/`，按实际可执行摘要及捕获进程核对。该目录顶层仍留有 `ad3e0eb` 的源标记、旧副本及旧摘要。动作及截图均按各自回执的最终摘要判定。最终宿主结果取自 `debug-final.xcresult`，构建取自 `release-final-build.log`，本机打包取自 `package-source-final.log`。
- `bfd53cc` 是 07-03 冻结视觉候选；`894422f` 绑定 07-04 的 88 对接线复证。07-06 的 `7752dab`、128 项全量、53 项定向及 `final/` 目录属于首轮候选。审阅修复中间版 `5a7f567` 的事务记录保留为修复过程证据。最终四处窗口、真实会话、网络、宿主回归及隔离事务采用下列最终实物和记录。 [最终验收](07-ACCEPTANCE.md) · [更新实测](07-UPDATE-EVIDENCE.md) · [接线视觉复证](07-04-VISUAL-RECHECK.md)

## 目标达成

### 可观察结果

前四项逐项采用 [ROADMAP Phase 07](../../v0.2-ROADMAP.md#phase-07-设置关于与更新) 的编号验收，其余合并六份计划中的补充条件。

| # | 可观察结果 | 判定 | 源码与行为证据 |
| --- | --- | --- | --- |
| 1 | 主窗和菜单栏打开同一设置，分类、开关、实际版本与 Flutter 检测可用 | VERIFIED | `FlutterRunletApp` 两入口汇入系统设置场景。四组合动作与 AX 显示同一设置窗口 ID；三页均 520 × 520 pt，实际开关和 Doctor 动作可见。 |
| 2 | 独立关于及设置关于符合批准稿，复用组件、署名与三个链接 | VERIFIED | `AboutInformation`、共用品牌／更新／链接视图和 Bundle 取值均已接线。独立关于 400 × 412 pt，MIT／Svame 有可见署名，设置许可证帮助和 AX 使用同源内容。两处各三次默认浏览器实际落地。 |
| 3 | 按状态完成冻结视觉对照，再接入实际查询、下载、校验、安装与回退，隔离重启后刷新版本 | VERIFIED | 门槛签核 `e0a6e15` 早于真实客户端与安装接入。512 条实物、88 对接线复证、最终普通查询与同源码隔离清单分别验证所对应的行为。 |
| 4 | 同一普通候选四处通过双语、深浅、AX 及键盘联验，并实测既有设置、真实运行和恢复 | VERIFIED | 28 张原图的 SHA-256、像素尺寸、唯一捕获 ID、PID 和 AX 与最终普通候选一致。主窗及菜单栏各有 6 次正向与 6 次反向 Tab，焦点未进入各自操作按钮。设置和关于有原生焦点记录。真实 Flutter 使用同一 SDK 和专用设备，正常停止、后置失败重试、暂停后的原任务继续与退出均有完成记录。 |
| 5 | 批准的中文深色来源和实测尺寸、字体、图标、色值可追溯，英文、浅色及系统反馈有对应依据 | VERIFIED | 18 个参考节点各有 1×／2× 原图及索引，共 36 张。三页、独立关于和 11 个按钮变体有实例标注。英文以本地化、浅色以已批准变量、系统界面以原生取证核对。 |
| 6 | V01–V05 所有适用窗口、状态、语言、外观与帧有唯一用例 | VERIFIED | 复核 544 个唯一行，512 项适用，32 项有 N/A 理由。最初 516 项适用中有四项因宿主系统未产生待批准登录项状态调整为 N/A。待批准状态、文案与操作另有宿主用例。 |
| 7 | 两处关于可联动演示，普通 Release 排除演示和回环配置 | VERIFIED | `#if DEBUG` 场景使用同一 `UpdatePresentationSource`，冻结实拍覆盖两窗、旋转、稍后和独立反馈。最终普通 Release 的 Bundle 无隔离配置，带演示参数及假端点的记录仍从固定公开源查询。 |
| 8 | 只有完整合格的视觉证据才允许接入真实更新 | VERIFIED | 门槛命令实际复验候选、原始证据和受保护源码。隔离自测对错误候选、证据损坏或串用、源码漂移及按钮区域静止等反例失败。07-04 和 07-05 都以有效门槛为第一道前置，07-05 同时以 07-04 下载预检为前置。 |
| 9 | 两处仅接受显式检查，合并在途请求并以运行 Bundle 比较正式版本 | VERIFIED | `UpdateCoordinator.check` 与 `ReleaseClient` 连通明确动作、在途任务和 Bundle。最终普通四次录证均为启动至开两窗零请求、点击后一次 HTTP 200、两窗状态同步。最终宿主覆盖当前版、无正式发布、过滤预发行、失败、限流及在途合并。 |
| 10 | 未配置公开发行信任时保留可查结果及发布页，公开安装保持关闭 | VERIFIED | 最终普通查询返回正式 `v0.1.1`，两处显示不可安全安装的原因。普通和回环信任由构建配置及固定身份限定。宿主用例验证未锁定或缺可信配置时不开始可安装包下载。 |
| 11 | 只有通过传输和实际包身份检查的下载进入待安装状态 | VERIFIED | `UpdatePackageService` 校验固定资产、摘要、大小、版本、只读 DMG 和签名身份。12 项验包宿主测试有真实 DMG 正负例，隔离坏包保持 A，两处有原因、发布页及重试，实际重试产生第二个资产请求。 |
| 12 | 确认后正常退出、同卷替换、健康握手与实际 B 版本刷新 | VERIFIED | 最终 `success` 记录 A 的 PID 58586，B 的健康应答、ACK 及实拍均为 PID 58649。原路径实物从 A 换为 B，旧 inode 随旧包保留。新 Bundle 的 v7.5.1（构建 751）出现在设置侧栏、设置关于及独立关于。 |
| 13 | 调试和恢复允许下载；安装经过活动、恢复与跨实例门禁，双窗关后仍可确认一次并稍后继续 | VERIFIED | 最终 `gate` 记录真 Flutter 在 prod 完成下载，并逐次阻止调试、恢复失败及在途、不可读记录、旧实例、旧 worker 和同版跨项目活动。解除阻塞后，两处都关闭仍有确认；稍后后两处均可以继续。该轮目标签名、摘要、inode 保持相同。 |
| 14 | 失败与中断按实物恢复，无法打开旧版时给出实际位置和下一步 | VERIFIED | 最终 `rollback` 13 组，`bootstrap-safety` 4 组。验证坏包、错误应答、早退、超时、交换／启动中断及对象变化。已恢复且重开的旧版两处显示回执与恢复动作。独立助手两类反馈共八种实拍，含恢复路径、访达定位及发布页动作。 |
| 15 | 准备故障与放行中断可继续接手，重复中断保留已提交结果 | VERIFIED | 最终 `handoff-boundaries` 7 组覆盖迟到待定写入、重命名后同步失败、A/B 放行前后和连续中断。核对准备失败后 A 可重开，B 连续中断仍为 `committed`，最终 ACK 与实际启动进程一致。 |
| 16 | 六项验收结论唯一且能追溯到最终证据，UI-07 覆盖四处 | VERIFIED | 已执行六行唯一 PASS 校验。逐项从需求、计划、最终源码与原始运行记录完成下方交叉核对。 |

### 六份计划及总结

| 计划与总结 | 任务 | 独立核对 |
| --- | ---: | --- |
| [07-01 计划](07-01-PLAN.md) · [总结](07-01-SUMMARY.md) | 2 | 批准节点、36 图、实例读数、参考类型及 544 行取证基线可对应到实际校验输入。 |
| [07-02 计划](07-02-PLAN.md) · [总结](07-02-SUMMARY.md) | 3 | 两入口、通用偏好、真实 SDK／Doctor、两处关于共享模型与 Debug 演示均有运行调用点；最终两种候选的可达路径由实物复验。 |
| [07-03 计划](07-03-PLAN.md) · [总结](07-03-SUMMARY.md) | 3 | 冻结原生候选的逐例证据、系统弹层和动画复证通过；门槛和自测均亲自复跑。 |
| [07-04 计划](07-04-PLAN.md) · [总结](07-04-SUMMARY.md) | 3 | 查证实际签核先于接线提交，核对固定 Release 查询和验包调用、88 对接线复证，以及最终普通联网与宿主结果。 |
| [07-05 计划](07-05-PLAN.md) · [总结](07-05-SUMMARY.md) | 3 | 对照实际签名预检、预约、正常退出、助手交接及恢复代码，严格复核五份最终清单与助手反馈。 |
| [07-06 计划](07-06-PLAN.md) · [总结](07-06-SUMMARY.md) | 3 | 总结前置的 `coverage` 路径仍指首轮，审阅后复验段指向最终验收。最终普通复拍、登录项、Doctor、真 Flutter、查询、回归和最终 A/B 均按实际候选复核。 |

### 必需产物

六份计划共 16 条产物声明均通过 `verify.artifacts`，其中视觉门槛被两份计划引用。人工追踪如下。

| 产物 | 判定 | 实际职责 |
| --- | --- | --- |
| [视觉基线](07-VISUAL-BASELINE.md)、[视觉门槛](07-VISUAL-GATE.md)、[视觉验证器](../../../../scripts/verify-phase-07-visual-gate.rb) | VERIFIED | 固定参考来源、候选与原始证据，按用例、候选、源码及真实像素校验。 |
| [主 App](../../../../FlutterRunlet/FlutterRunletApp.swift)、[设置及关于](../../../../FlutterRunlet/AuxiliaryWindows.swift)、[启动演示](../../../../FlutterRunlet/LaunchPresentation.swift) | VERIFIED | 两处设置入口、设置三页及关于场景；受控演示与真正运行数据经共用展示源接入。 |
| [Release 客户端](../../../../FlutterRunlet/ReleaseUpdates.swift)、[更新协调器](../../../../FlutterRunlet/UpdateCoordinator.swift)、[更新包](../../../../FlutterRunlet/UpdatePackage.swift) | VERIFIED | 匿名发行版读取、共享检查状态、严格准备候选和安装预约。 |
| [更新事务](../../../../FlutterRunlet/UpdateTransaction.swift)、[活动租约](../../../../FlutterRunlet/UpdateActivityLease.swift)、[原生助手](../../../../FlutterRunletUpdateHelper/main.swift) | VERIFIED | 退出确认、同卷身份核对、健康握手、持久提交及回退，跨实例互斥。 |
| [更新校验入口](../../../../scripts/verify-phase-07-update.sh)、[更新实测](07-UPDATE-EVIDENCE.md)、[最终验收](07-ACCEPTANCE.md) | VERIFIED | 可信场景表与实物绑定，普通、隔离和历史候选可从记录复查。 |

### 关键连接

`verify.key-links` 自动识别 2/15 条字面引用。其余路径以相对文档链接、命令参数、Swift 同目标符号或运行时嵌入助手连接，沿真实调用和行为证据核对后，15 条均成立。

| 从 | 到 | 判定依据 |
| --- | --- | --- |
| 视觉基线 | FIGMA-EVIDENCE、VALIDATION | 基线首段相对链接直达 Figma 取证与 V01–V05 验证方案。 |
| App、AuxiliaryWindows | 设置／关于场景、LaunchPresentation | `showSettings` 承接主窗、菜单栏和系统设置菜单。App 从 `Phase07UpdateDemo.source` 或生产 `UpdatePresentationSource` 向两处传入同一个实例。 |
| 视觉门槛、Ruby 验证器 | 视觉基线、门槛与私有清单 | 文档标出基线。CLI 实际消费三份实物，并核对受保护实现、Git 中的候选及原始截图。 |
| UpdateCoordinator | ReleaseUpdates、UpdatePackage | 显式检查使用 `RunningUpdateApp.version`，生产操作经 `UpdatePackageService` 进入 `ReleaseClient`、资产可用性和 `PreparedUpdate` 预检。 |
| UpdateCoordinator、UpdateTransaction、UpdateActivityLease | 事务交接、嵌入助手及 SessionController | 用户确认走 `reserveUpdate`、`UpdateHandoff.prepare`、正常退出。握手及签名实物由嵌入助手核对，控制器和 worker 保持受管活动的租约及退出证明。 |
| UPDATE-EVIDENCE | 隔离场景入口 | 文档场景名与脚本可信清单一致，最终五份实物可通过相同校验入口。 |
| ACCEPTANCE | VISUAL-GATE、UPDATE-EVIDENCE、阶段要求 | 具有相对链接及唯一需求判定行，最终候选的界面、A/B 和回归可逐条定位。 |

### 数据来源

| 展示或状态 | 实际来源与路径 | 判定 |
| --- | --- | --- |
| 设置开关、语言和启动行为 | 持久偏好／`SMAppService` → `AppLanguageSettings`、`LoginItemSettings`、`SessionController` → 设置和启动行为。 | FLOWING |
| SDK、FVM、Doctor、运行及恢复 | SDK 真实探测与 Doctor 输出 → `FlutterToolchain`、`SessionController`；会话 worker 与恢复库状态 → 两个运行界面和安装门禁。 | FLOWING |
| 三处版本、许可及外链 | `Bundle.main` → `AboutInformation` 及应用展示；MIT／Svame 同源，固定三个目标交给默认浏览器。 | FLOWING |
| 更新和恢复提示 | 正式 Release／签名隔离包 → 共享更新状态；事务、握手、进程身份及回执 → 界面或独立助手。 | FLOWING |

## 独立复核执行

| 检查 | 命令或记录 | 结果 |
| --- | --- | --- |
| 冻结视觉与拒绝路径 | `verify-phase-07-visual-gate.rb --gate … --baseline … --manifest …`（绝对路径），另执行 `--self-test` | 退出 0，512 项，隔离自测通过。 |
| 六项判定、矩阵和决定 | 07-06 Ruby 唯一 PASS 检查、V01–V05 行去重及适用性检查、GSD 决定覆盖 | 6/6 PASS，544 行唯一，12/12 决定命中。 |
| 普通实物及原生记录 | 重算普通 Bundle 树、可执行 SHA-256、28 张图的 SHA-256、尺寸、捕获 ID、PID 和 AX。核对两次齿轮的窗口 ID、六次导航和四次网络记录 | 全部通过。四组最终主窗均为 640 × 520，菜单栏 348 × 372，三页均为 520 × 520，独立关于 400 × 412。 |
| 普通设置、Flutter、Doctor | 核对同摘要的 7 份已完成动作记录以及关联实拍。正常轮与暂停轮以 `flutter-normal-retry`、`flutter-pause-retry` 的完整复跑为准 | 通过。保留首次 AX 超时／未确认选择 prod 的日志。最终记录覆盖热重载、热重启、DevTools、正常恢复、失败后只重试原任务、暂停后的退出。Doctor 失败与取消使用受控退出码／延迟，命令经正常应用入口。 |
| 最终宿主结果 | `xcrun xcresulttool get test-results summary` 及 `tests` 查询 `debug-final.xcresult` | 133 通过、0 失败、0 跳过。依据 06-04 的两组定向清单从同一结果复算 8 个前序套件共 93 项。 |
| 最终构建及包签名 | Release 与 Debug build-for-testing 日志；`lipo -archs`、`plutil`、`codesign --verify --deep --strict --all-architectures`、`shasum -a 256 -c` | 两次构建成功。App、worker、助手均有 arm64／x86_64，ad hoc 严格签名通过。普通程序最低部署目标 15.0。独立本机 v0.1.0（构建 192）DMG 已打包并校验摘要。 |
| 宿主状态 | 只读比对复验前后 plist，核对登录项和模拟器收尾记录 | 11 个偏好键值与类型等值；已记录登录项和专用模拟器恢复各自初始状态。 |

本次直接执行的事务探针为 `bash scripts/verify-phase-07-update.sh --scenario <场景> --workspace .private/phase-07/update --verify-manifest <清单>`。逐份核对退出码均为 0，场景目录相对 `.private/phase-07/update/`。

| 场景 | 最终清单 | 数量 |
| --- | --- | ---: |
| success | `success-20261115T115844363046Z/manifest.json` | 1 |
| gate | `gate-20261115T120103084468Z/manifest.json` | 1 |
| rollback | `rollback-20261115T120735379352Z/manifest.json` | 13 |
| bootstrap-safety | `bootstrap-safety-20261115T120610968740Z/manifest.json` | 4 |
| handoff-boundaries | `handoff-boundaries-20261115T115920109673Z/manifest.json` | 7 |

补充清单 `recovery-appearance-2026-11-15T122229.911940_0000/appearance-manifest.json` 中的 `d7e6449` 与 `2fcb4a3` 的程序输入一致。独立核对八种原生助手状态与坏包两次请求，PNG 摘要、尺寸及 AX 与各自进程的 App／助手二进制相符。此轮通过已有原始记录进行只读复核，沿用已执行的原生桌面动作、实机 Flutter、系统偏好操作和宿主测试；本轮执行的检查如上表。

## 需求覆盖

| 需求 | 计划 | 判定 | 对应验收 |
| --- | --- | --- | --- |
| UI-07 | 07-06 | SATISFIED | 四处同候选、语言／外观、语义色、可读名称、AX 状态、两类键盘行为及真实恢复。可观察结果 4、6。 |
| UI-13 | 07-01、02、03、06 | SATISFIED | 同一设置窗口、三个分类、520 pt、说明样式的实际版本、白色滑块与蓝开灰关。可观察结果 1、4、5。 |
| UI-14 | 07-01、02、03、06 | SATISFIED | 语言和登录项、启动偏好、最近项目，Auto／手动／FVM、实际 SDK 与运行一致，Doctor 摘要及完整输出。可观察结果 1、4。 |
| UI-15 | 07-01、02、03、06 | SATISFIED | 400 × 412 pt、品牌、说明、实际版本、MIT／Svame、三链接与六次落地，仓库原许可和上游归属保持。可观察结果 2、5。 |
| UPD-01 | 07-01～06 | SATISFIED | 点击才查正式 Release，两处共用检查中、当前／新版、无正式发布、失败或不可用；实际 Bundle 比较。可观察结果 3、7、9、10。 |
| UPD-02 | 07-01～06 | SATISFIED | 两处更新进度、验包、安装许可、真实重启后三处读 B、失败恢复与独立反馈。可观察结果 3、11～15。 |

六项均有计划归属。ROADMAP 中 07-06 的待勾选标记和 REQUIREMENTS 的复选框属于主控维护。验收状态由本报告记录。

## 决定覆盖

GSD 决定覆盖返回 12/12。每条决定按最终源码和观测证据核对如下。

| 决定 | 判定 | 核对结果 |
| --- | --- | --- |
| D-01 | PASS | 两个显式入口共享固定正式源，普通四回合启动零请求。检查本身不读安装门禁，活跃 Flutter 的隔离轮实际完成查询与下载。 |
| D-02 | PASS | 最终普通版两处同步显示检查及新版不可安装，宿主实测数字比较、已是最新、无正式发布、失败和预发布过滤，冻结取证覆盖各反馈。 |
| D-03 | PASS | 调试和恢复阶段可验包，安装在确认和预约时受进程、恢复库和跨实例租约约束；最终门禁场景逐级阻止。 |
| D-04 | PASS | 两处关闭后的自动确认、稍后一次、两处继续，均由最终门禁场景记录。 |
| D-05 | PASS | 最终隔离 A/B 在同一路径正常交接，三处实际显示 B 的版本与构建号。 |
| D-06 | PASS | 两处同报摘要失败，保有重试与发布页，第二次实际请求不改 A；有界传输和下载错误另有宿主覆盖。 |
| D-07 | PASS | 旧包先保留，实际失败后恢复且尝试重启 A，回执供两处显示原因及重试／发布页。 |
| D-08 | PASS | 新版启动失败和旧版无法重开均已复验；独立助手有位置、真实访达定位及浏览器目标。 |
| D-09 | PASS | 设置及独立关于尺寸、侧栏及两处实际身份、MIT／Svame 与六次真实导航已核。 |
| D-10 | PASS | 设置共窗、通用偏好、真实 SDK／FVM 与 Doctor、原有恢复，主窗／菜单栏和设置／关于两类原生焦点均有最终证据。 |
| D-11 | PASS | 以冻结批准稿和最终普通复拍对照应用外观；macOS 交通灯、系统焦点环和目录选择器按原生表现核对。 |
| D-12 | PASS | 受控 512 项、接线后 88 对实拍及最终实际更新分别有证据；最终实际显示复核已绑定普通候选与隔离 B。 |

## 审阅处置

| 审阅发现 | 最终处置和验证 |
| --- | --- |
| CR-01 · critical | 已修复。取消握手并确认助手退出后，在独占预约中按事务身份清理。最终 `prepare-delay`、`prepare-post-rename-sync` 可在 A 尚在原处时重新打开 A，宿主覆盖已落盘待定记录与无法安全清除两种分支。 |
| CR-02 · critical | 已修复。持久化终态、释放初始化锁、放行与 ACK 的顺序在最终 `handoff-boundaries` 实证。连续提交中断保存终态，最终助手按期限核验内核进程身份；`rollback` 和 `bootstrap-safety` 均已用最终源码复跑。 |
| WR-01 · warning | 已修复。跨系统启动清理只在独占且恢复记录可读并已清理时执行。同次启动和无法确定状态的分支继续阻止安装，最终宿主用例覆盖。 |
| WR-02 · warning | 已修复。Shell 入口清除优化环境变量，隔离目标及清单使用显式失败分支。原始负例在普通和优化环境均被拒绝。 |
| WR-03 · warning | 已修复。严格清单按可信场景定义核对事务、实物、进程、可见版本和 PNG。已核对缺事务、结论冲突及伪造截图负例记录，并复跑最终五份清单。 |
| WR-04 · warning | 已修复。视觉门槛重算原始按钮区域像素。自测拒绝按钮静止但窗口其他区域变化的反例，最终 512 项实物仍全部通过。 |
| IN-01 · info | 已修复。试运行在加载实际偏好后确定激活策略，晚注册的主窗处理器也读取同一偏好。主动关闭启动主窗的 `.accessory` 原生证据来自 `5a7f567`，相关 App 源码到 `2fcb4a3` 无改动；最终普通候选另完成真实偏好启动复验。 |

核对 [安全复核](07-SECURITY.md) 的 16 条本地威胁处置及最终负例，开放项为 0。源码审阅和处置 ID 可逐一对照。对阶段改动扫描后无未处置债务标记或占位路径。 [独立源码审阅](07-REVIEW.md) · [审阅处置](07-REVIEW-DISPOSITION.md)

### 测试质量

| 测试套件及取证 | 关联需求 | 最终执行 | 断言性质 |
| --- | --- | ---: | --- |
| LaunchPresentationTests | UI-07、UI-13、UI-15 | 25 | Bundle 版本、目标地址、双语、宿主开关、实际偏好重建、确认恢复流程；原生外观由截图与 AX 证明。 |
| FlutterToolchainTests | UI-14 | 17 | 真实路径与退出码、完整输出、取消及更改 SDK 后清除旧结果，和原生 Flutter／Doctor 运行相互核对。 |
| ReleaseUpdatesTests | UPD-01、UPD-02 | 10 | 显式动作计数、数字比较、发布身份、边界响应、同一状态源及重试动作。 |
| UpdatePackageTests、UpdateInstallGateTests、UpdateTransactionTests | UPD-02 | 22 | 实际签名 DMG、传输及拒绝条件、租约竞争、目录身份、终态接手与 ACK；最终 26 组隔离场景补足 macOS 行为。 |

验收关联套件在最终 Debug 实际执行，跳过数为 0。预期来自批准画板、固定验收场景、Bundle／磁盘／进程身份及实际操作结果。关联用例有值或行为断言，未发现循环取期望值或只断言产物存在的必要验收。 [验证方案](07-VALIDATION.md)

## 实测范围和非阻塞观察

- 三项 UI 观察仍记录在案。英文浅色 Flutter 版本长文本中间省略，AX 保留完整 Flutter／Dart 版本；菜单栏长 FVM 诊断的尾部省略，AX 和 Flutter 设置保留完整原因；一次鼠标打开 Doctor 完整输出后使用 Escape，关闭成功并回到设置侧栏「通用」。这些情形有可用的诊断及键盘路径。原生恢复警告外框随语言和内容变化，英文浅色样本的系统 AX 角色可沿用宿主语言。 [原生界面审查](07-UI-REVIEW.md)
- 原生运行实测为 macOS 26.7.1 arm64 和专用 iOS 模拟器。Intel 已查产物架构及签名，Intel 实机与最低 macOS 15 实机未覆盖。辅助功能实测覆盖 AX 和 HID，VoiceOver 实际朗读未覆盖。 [最终验收](07-ACCEPTANCE.md)
- 签名及 DMG 结论适用于本机 ad hoc 包。正式 Developer ID、公证、公开安装、公开可用性与分享范围复核仍属冻结的发布工作。阶段内真实公开查询与隔离安装两条验收均已达成。 [更新实测](07-UPDATE-EVIDENCE.md)

**缺口**　0。六项必需本地验收均有可追溯行为证据，无待补的人工验收或豁免。

_签核时间 2026-11-15T12:33:14Z_

_签核人 Codex（gsd-verifier）_
