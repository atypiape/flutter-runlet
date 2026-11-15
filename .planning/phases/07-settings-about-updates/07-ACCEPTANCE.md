---
phase: 07-settings-about-updates
status: passed
date: 2026-11-15
---

# 阶段 07 · 最终本地验收

## 审阅修复后的最终候选

最终程序源码为 `2fcb4a3d4dbb3ee9b7acaf287582ea126dfcd2a7`。普通构建仍为 `com.atypiape.FlutterRunlet` v0.1.0（构建 1）。App、会话 worker 和助手均为双架构，严格校验 App 及嵌入签名通过。最终普通 App 可执行 SHA-256 为 `2f1aec11c2ae39c30d99a0666903cf9c3895ed97e6950b23328d1f78cda50de7`，Bundle 树 SHA-256 为 `582f8252eb62f2eb0c8278ba76e9018da6822a71a228996634ae0cd36ca3b1f3`。

| 复验 | 最终记录 |
| --- | --- |
| 冻结视觉 | 512 适用状态仍通过。原始 PNG 的按钮区域实际呈现至少四种像素状态，静止按钮/变化窗口反例被拒绝 |
| 四处普通窗口 | 同一可执行摘要的 28 张原生截图和同期 AX、HID 记录。四组合均覆盖主窗、菜单栏、设置三页及独立关于，两个齿轮仍复用设置窗 |
| 浏览器与真实查询 | 两处共六次实际导航。两入口分别在中英文和深浅下发起公开查询，回合各记录一个 HTTP 200 及两处同步状态。公开 `v0.1.1` 未锁定，显示原因及发布页 |
| 偏好和真实 Flutter | 重验语言、真实登录项、启动主窗、最近项目和自动/手动/FVM。真实设备覆盖 DevTools、热重载、热重启、正常恢复、后置失败重试及暂停后继续。Doctor 成功、失败、取消及完整输出均实拍 |
| 同源码真实隔离更新 | 成功 1 组、综合门禁 1 组、回退 13 组、助手安全 4 组、放行及重复中断 7 组。按实物重新核对五份清单。B 的版本、PID 和三处实际 Bundle 显示均已复核。另复拍独立助手的两种反馈 × 四组合，并核对坏包可从两处看到原因和重新请求 |
| 回归 | 全量 133 项通过、0 失败、0 跳过，其中覆盖前序 8 个套件的 93 项。焦点、旧版和故障记录已按审阅处置复核 |

界面及网络原始证据在 `.private/phase-07/review-fixes/ordinary/`，最终宿主结果为同层父目录的 `debug-final.xcresult`。同源码 A/B 的具体路径及审阅修复证据见[更新实测](07-UPDATE-EVIDENCE.md)和[审阅处置](07-REVIEW-DISPOSITION.md)。最终普通复拍结束后，宿主偏好快照等值，登录项和专用模拟器恢复各自初始状态。

## 首轮固定候选

构建前的 HEAD 为 `7752dab01be5721b50a6109e23393a36fbd4d199`，Git 树为 `59accafe68ddcf1a8f1ec1de7623e273389220e2`。与 07-05 的 `5da4fd43d346b9d8689a6b02002b36ca579a65e0` 相差两份规划文档。App、Xcode 工程、会话 worker、更新助手、测试及验证脚本目录的树对象完全一致。构建前核对了 Git 索引和已跟踪工作区。

| 观察 | 实测 |
| --- | --- |
| Bundle | `com.atypiape.FlutterRunlet` · `v0.1.0 (build 1)` · Release |
| 运行环境 | macOS 26.7.1（25G241），arm64，Xcode 27.1（27A9275），macOS SDK 27.0（26A425） |
| 架构与签名 | App、会话 worker 和更新助手均包含 arm64 与 x86_64。三者为临时签名，Team ID 缺省。双架构深度签名完整性检查通过 |
| App 可执行 SHA-256 | `4146e0a9c8a953029af725a55717f7a7013fdb0987699d278cca19995c1ed316` |
| Bundle 树 SHA-256 | `f834fcaecdfc422260bb7824e2b757ca1225955fa53042058769e5dd3dcf5564`，Xcode 原件与固定副本相同 |
| 编译配置 | 普通 Release 使用原有方案。构建日志无 `PHASE07_UPDATE` 编译条件，实际 Info.plist 无 `RunletIsolatedUpdate` |
| 本机证据 | `.private/phase-07/final/`。普通候选取证使用其下同一 `FlutterRunlet.app` |

## 07-06-01 · 四处原生界面

| 系统外观 / 应用语言 | 主窗口 | 菜单栏面板 | 设置三页 | 独立关于 | 证据 |
| --- | --- | --- | --- | --- | --- |
| 深色 / 简体中文 | 640 × 520 | 348 × 372 | 各 520 × 520 | 400 × 412 | `windows-isolated/zh-Hans-dark/` |
| 浅色 / 简体中文 | 640 × 520 | 348 × 372 | 各 520 × 520 | 400 × 412 | `windows-isolated/zh-Hans-light/` |
| 深色 / English | 640 × 520 | 348 × 372 | 各 520 × 520 | 400 × 412 | `windows-isolated/en-dark/` |
| 浅色 / English | 640 × 520 | 348 × 338 | 各 520 × 520 | 400 × 412 | `windows-isolated/en-light/` |

四组各 7 张 1× 原生截图，包含语言弹层。每份配套 AX 树及动作记录均绑定候选进程和可执行摘要。菜单栏按状态调整高度。两处齿轮分别操作后仍是同一设置窗 CG ID。主窗和菜单栏 6 次正向及 6 次反向 Tab 均未进入各自按钮。设置及独立关于实测 Tab/Shift-Tab。设置语言菜单经键盘打开、Escape 退出，焦点回到语言按钮。AX 核对齿轮、选中导航、开关角色及值、运行操作禁用状态、链接角色和说明。实际侧栏与两处关于显示当前 Bundle 的版本和构建号。

普通候选的原生像素按显示 ICC 归一到 sRGB，复核浅深底色、侧栏、卡片、分隔线及强调色；浅色强调蓝在当前显示器上呈现 `#226D98`，对应冻结基线记录的 `#006D98` 显示裁剪。中文深色沿冻结画板与相同组件核对。英文和浅色按相应角色及变量的原生证据核对。更换样例和实际版本引起的尺寸内位移属于实际内容。冻结门槛 512 项退出码 0，依据绝对路径的已签核文档、视觉基线和私有清单。07-04 对两处关于的 88 对复证继续适用。[冻结视觉签核](07-VISUAL-GATE.md) · [07-04 原生复证](07-04-VISUAL-RECHECK.md) · [06 原生复核](../06-main-window-menu-bar/06-UI-REVIEW.md)

英语深色 `links-isolated/en-dark/` 实点独立关于三条链接再实点设置关于三条，默认浏览器实际落在仓库首页、README 与 LICENSE。设置许可证原生提示及 AX Help 都带 MIT 与 Svame；独立窗显示独立的 MIT 许可和 Svame 署名行。`ordinary-window-audit.json` 复核截图摘要、尺寸、角色、选中、禁用、实际版本和六次导航。签核矩阵显式选用隔离 Flutter 样例，逐份比对未发现宿主最近项目路径。签核仅引用显式选用隔离样例的重拍矩阵。独立的 `Application Support` 持有实际恢复库，macOS 标准偏好使用宿主域，采用原值快照和按键回写验证。

## 07-06-02 · 普通候选的偏好和真实 Flutter

| 场景 | 原生与可观察结果 | 私有证据 |
| --- | --- | --- |
| 通用与登录项 | 经正常目录选择打开独立样例。手动中英文、系统语言跟随、主窗启动和最近项目在四次同 Bundle 的普通启动中生效。系统登录项先检查初始未注册，再实做注册、读取系统所在页、注销并核对空态 | `settings-preferences/actions.json` 和同目录截图及系统 AX |
| 正常运行 | 隔离样例起始 `test`。FVM 设置实际显示 Flutter 3.47.4 / Dart 3.13.3。选择专用 iOS 模拟器和 `prod`，F5 执行前置任务。隔离恢复库出现 1 条风险，命令和 worker/PID 证明实际使用相同 SDK。真实应用连上 VM，关闭主窗后菜单栏仍控制原会话，打开主窗保持同一 Flutter 进程。默认浏览器打开此会话的本机 DevTools，热重载和热重启完成。正常停止后 Flutter 与后置均结束，环境 `test`、风险 0 | `flutter-normal-final/actions.json` |
| 原后置失败与单独重试 | `fail-before-test` 触发原 `sample:select-test` 退出 1。主窗和菜单栏显示失败，Flutter 已退出，环境仍为 `prod`、风险 1。F5 没有拉起新 Flutter。取走标记，从原入口只重试，恢复 `test`、风险 0 | `flutter-failure-device-verified/actions.json` |
| 原后置暂停与退出 | `pause-after-test` 让原后置在写入 `test` 后继续在途。菜单栏和主窗显示恢复中，风险 1、Flutter 已退出。F5、运行与项目入口受限。Command-Q 后确认停止并退出，原任务释放前 App 仍在，释放后风险归零并退出 | `flutter-pause-device-verified/actions.json` |
| 重开后识别风险 | 实拍流程一轮中断后，同一候选在相同隔离恢复根重开，看到了持久风险。从重试执行原恢复任务，回到 `test`、风险 0 | `flutter-normal-retake/recovery-after-trial.json` |

样例使用仓库给出的 `test`、`prod` 环境标记脚本和故障契约，Flutter 使用真实 SDK、实际应用构建及设备。故障只施加于独立样例。[样例配置及复现说明](../../../docs/examples/sample-flutter-app/README.md)

设置页选择无效目录时说明原因并保留原设置，再通过原生目录选择实际 Flutter 3.47.4。原生目录动作实测 Escape 退出回焦和 Return 确认前往目录。Doctor 使用实际 SDK 生成摘要和标准输出／错误输出，500 × 360 的完整输出面板经 Escape 返回设置。切换手动 SDK 到 Auto 清除旧结果，再执行一次 Doctor，切换到 FVM 样例时再次清除。缺少 FVM 缓存链接的独立样例显示原因并禁用运行，恢复有效样例可重新识别固定 SDK。失败轮运行同一 Doctor 后由外部夹具返回 42，取消轮由外部夹具延迟 Doctor 以稳定实测取消动作。两者使用普通 Release 的正常 SDK 探测和环境检测入口。私有证据 `settings-doctor-auto-replay/`、`settings-doctor-failure-replay/`、`settings-doctor-cancel/`。

## 07-06-03 · 真实公开查询和隔离更新

### 普通候选的真实双入口

| 外观 / 语言 | 发起入口 | 启动与打开两窗的请求数 | 点击之后 | 双窗禁用 AX 样本 |
| --- | --- | ---: | --- | ---: |
| 深色 / English | 独立关于 | 0 | 1 次 HTTP 200，`v0.1.1` | 3 |
| 深色 / 简体中文 | 设置关于 | 0 | 1 次 HTTP 200，`v0.1.1` | 3 |
| 浅色 / English | 独立关于 | 0 | 1 次 HTTP 200，`v0.1.1` | 2 |
| 浅色 / 简体中文 | 设置关于 | 0 | 1 次 HTTP 200，`v0.1.1` | 3 |

实际匿名请求使用固定 GitHub 仓库的最新正式 Release。两窗同步检查及结果，关闭重开另一窗仍显示相同结果。响应的 Release 尚未锁定，普通候选显示不可安全安装及查看发布页。两种语言的设置窗只显示各自一个标题。版本判断使用普通 Bundle `v0.1.0 (build 1)`；当前版、无正式发布、预发布过滤、失败、限流和在途合并由本轮 `ReleaseUpdatesTests` 与冻结视觉记录覆盖。原生 `native-final-*` 和 `ordinary-update-audit.json` 记录请求、禁用、结果和重新打开。公开发行者信任继续冻结。

### 同源码隔离 A/B

`com.atypiape.FlutterRunlet.Phase07Update` 的 A 为 `v7.5.0 (build 750)`，B 为 `v7.5.1 (build 751)`。隔离构建在独立派生目录显式启用 `PHASE07_UPDATE`，逐轮用实际签名覆盖的 Info.plist 配置、临时签名、独立产品和回环端点生成 A/B。普通 Release 及隔离 A/B 的程序源码树一致，隔离每轮构建前后记录 Git HEAD、代码树与干净索引和程序路径。在 `.private/phase-07/final/` 下 `update-<scenario>.source-*`、`update-<scenario>.built-binary.sha256` 和 `update-<scenario>.bundle-tree.sha256` 绑定每轮实际 Xcode 产物及两份 Bundle，各 `candidates.json` 记录实际版本、可执行 SHA-256 和 DMG 校验摘要。原图、签名细节和事务私有记录位于 `.private/phase-07/update/`。历史轮次和门禁中故意引入的旧版本都有各自独立身份。

**实际替换与三处版本。** `success-20261115T110426766534Z/manifest.json` 重跑 1 组并校验清单。确认后 A 按 AppKit 正常退出，B 在同一 APFS 路径以不同 PID 完成健康握手与提交，旧 inode 保存在暂存区。设置侧栏、设置关于、独立关于均实见 `v7.5.1 (build 751)`。B DMG SHA-256 为 `60a2d3cab3f09d897ced3acf66831a1b419b3889b12e125da7013be72e48101e`。[场景行为及合同](07-UPDATE-EVIDENCE.md)

**门禁与确认。** `gate-20261115T110535670466Z/manifest.json` 重跑 1 组综合实测并校验清单。真实 Flutter 在 prod 期间下载完成，调试、失败恢复、在途恢复、不可读恢复记录、旧实例、旧版遗留 worker 和同源码第二实例逐次阻止安装。关闭两个关于窗后，恢复成功会自动弹出确认。选择稍后后确认只自动出现一次，两个关于入口都能继续。门禁轮目标 App 签名、摘要、inode 全程相同，只接收一次完整 B 资产。跨版本反例使用单独记录的历史旧版，另外运行一次本轮 A 的第二实例。

**回退与独立反馈。** `rollback-20261115T110701571277Z/manifest.json` 重跑 13 组并校验清单。包含坏包、新版早退／错误应答／提交前退出、交换前后及提交时中断、确认后旧版竞态、目录对象变更、旧版重开失败。目标目录以原签名和 inode 恢复时，两个关于窗口读到旧版回执；对象身份无法确认的场景保留实物。旧版不能自动打开时独立更新助手显示实际路径，以操作核对访达选中副本和浏览器收到发布页地址。



隔离执行文件逐轮 SHA-256 如下，Bundle 树及 DMG 摘要见前述核对记录与各轮 `candidates.json`。

| 场景 | A | B |
| --- | --- | --- |
| `success` | `a4db8f81524f5992e8400abf9cd59998a758e635384b4587c8482d159f9d8eab` | `9c58e45f824131d6bcc01c9d29e62b30efb99fb0b67e6653d601fcda8353b811` |
| `gate` | `71160f29f24ec7177a8d687e04e7413c87df13d03ab7f182c84cdf5600a86ba2` | `e59f2d98e46063459e8a40b17105eaa7d80cc5fe6764334657763b34d3734921` |
| `rollback` | `f3c8eb61c871daa447fa325a988fbda4e121a57e83c334b0e3090bafaa68412d` | `37bccd47c6c904c510a4ff1cd663719e2ec51ddafca6f5dc95455bca065b1131` |

补验 `recovery-appearance-2026-11-15T110943.611609_0000/appearance-manifest.json` 包含双窗校验失败与重试，以及独立助手的八个实际状态。两处显示同一校验失败，同时提供重试和查看发布页。从设置实际重试，回环资产请求增至 2 次，原 A 保持可用。旧版恢复但无法打开及无法确认恢复两类提示均由实际更新助手绘制，使用 AppKit 原生警告和路径正文。1× 实拍尺寸按系统实际结果登记，用以复核冻结演示对应状态。

| 语言／外观 | 旧版已恢复但无法打开 | 无法确认恢复 |
| --- | --- | --- |
| `en-dark` | 260 × 335 | 288 × 371 |
| `en-light` | 260 × 335 | 304 × 391 |
| `zh-Hans-dark` | 260 × 303 | 260 × 319 |
| `zh-Hans-light` | 260 × 303 | 266 × 327 |

## 命令及执行量

| 实际验证 | 退出码 | 执行量和结果 |
| --- | ---: | --- |
| `verify-phase-07-visual-gate.rb --gate … --baseline … --manifest …`，三参数均为绝对路径 | 0 | 512 项通过 |
| `xcodebuild … -configuration Release -destination 'platform=macOS' build` | 0 | 普通 Release 构建，复制前后 Bundle 树相同。`codesign --verify --deep --strict --all-architectures` 退出 0 |
| `xcodebuild … -configuration Debug -parallel-testing-enabled NO build-for-testing` 及 `test-without-building` | 0 / 0 | 全量 128 项通过，失败 0，跳过 0，`debug-all.xcresult` |
| 同派生目录 `test-without-building` 加五个 `-only-testing` | 0 | 定向 53 项通过，失败 0，跳过 0。FlutterToolchain 17、FlutterDebugSession 11、ProjectRecovery 10、ProjectConcurrency 5、SessionLifecycle 10。`debug-focused.xcresult` |
| 普通候选原生四组合及核对程序、实际六链接 | 0 | 28 张带 AX 的矩阵截图，另有许可证提示及六次真实落地 |
| 普通候选真实 Flutter 及 Doctor | 0 | 正常、失败恢复、暂停退出各 1 轮，额外 1 次真实重开恢复。Doctor 正常、失败与取消各一场景 |
| `bash scripts/verify-phase-07-update.sh --scenario success\|gate\|rollback --workspace .private/phase-07/update` | 0 / 0 / 0 | 1 / 1 / 13 组，逐轮 `--verify-manifest` 退出 0，逐轮复核候选签名、版本、可执行和包摘要 |

所有 Xcode 命令使用根目录 `FlutterRunlet.xcodeproj` 和 `FlutterRunlet` scheme。日志、退出码、产物身份、测试包和签名校验输出在私有证据根。需求判定表由 Ruby 检查六项唯一结论及全部 PASS。


## 需求判定

| 需求 | 判定 | 决定 | 最终证据 |
| --- | --- | --- | --- |
| UI-07 | PASS | D-10、D-11、D-12 | 同一复制件四处原生矩阵及键盘、AX 记录。主窗和菜单栏的真实运行与恢复见 07-06-02 |
| UI-13 | PASS | D-09、D-10、D-11 | 设置三页、520 pt、实际版本、说明角色与开关状态；两齿轮使用同一个窗口 |
| UI-14 | PASS | D-03、D-10 | 登录项、四次重启、Auto／手动／FVM、缺失 SDK、真实 Doctor 与清除旧结果 |
| UI-15 | PASS | D-09、D-11 | 独立关于尺寸及实际版本、MIT 与 Svame，两个入口共六次真实导航、原生许可证提示及 AX Help |
| UPD-01 | PASS | D-01、D-02、D-12 | 普通候选四轮匿名点击检查、同步及安装限制。实际 Bundle 和本次 128 项中的客户端负例 |
| UPD-02 | PASS | D-03、D-04、D-05、D-06、D-07、D-08、D-12 | 同源 A/B 的安装重启、确认门禁、坏包重试、回退、回执及独立助手实测 |

## 决定判定

| 决定 | 判定 | 已核对的结果 |
| --- | --- | --- |
| D-01 | PASS | 普通候选真实双入口、点击前零请求、点击后两处同步；在途活动由 A/B 门禁实测 |
| D-02 | PASS | 实际 Bundle 比较、真实新版不可安装提示，以及当前版、无发布、失败的客户端和冻结展示证据 |
| D-03 | PASS | 真实 Flutter 活动期间完成下载，随后调试、恢复及跨实例逐次阻止安装。持久风险和退出均有普通候选原生记录 |
| D-04 | PASS | 两处关闭后的确认、稍后及两处继续安装 |
| D-05 | PASS | 原路径新进程健康提交，三处实际 B 版本与构建号 |
| D-06 | PASS | 两处校验失败、查看发布页及实际重试下载，原版本签名保持；有界下载负例由 XCTest 执行 |
| D-07 | PASS | 替换或新版启动失败后旧版恢复，双窗回执、重试和发布页 |
| D-08 | PASS | 独立助手两种故障提示，实际恢复位置、访达选择和默认浏览器发布页 |
| D-09 | PASS | 两窗几何、三个设置页、实际版本、六条链接及 MIT／Svame 同源文字 |
| D-10 | PASS | 两入口设置、真实偏好和 SDK／Doctor，主窗／菜单栏与设置／关于各自的键盘行为 |
| D-11 | PASS | 四组普通 Release 的原生窗口与 AX，语义配色与已签核画板复核 |
| D-12 | PASS | 冻结门槛 512 项，本轮全部真实动作证据与各自产物身份绑定 |

## 宿主状态及平台限制

专用 iOS 模拟器恢复初始 `Shutdown`，宿主外观已恢复。登录项恢复原状态。候选退出后标准偏好工具按测试键恢复，明确删除测试新增的 `appLanguage`，宿主窗口位置恢复原值。与 18:42 快照重新导出的完整偏好树在 11 个键、值和类型上相等。原始截图、绝对路径、进程和恢复记录、签名细节留在本机。

运行覆盖 macOS 26.7.1 arm64 和专用 iOS 模拟器。最低部署目标 macOS 15，尚待实机验证。Intel 已核对产物架构和签名完整性，运行待验。Apple Developer ID 正式签发、公证、公开可用性与公开发布保持冻结。本地验收结果供主控执行独立阶段验证。
