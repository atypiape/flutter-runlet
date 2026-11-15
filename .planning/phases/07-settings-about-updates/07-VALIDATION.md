---
phase: "07"
slug: settings-about-updates
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-15"
---

# 阶段 07 · 验证方案

现有 macOS scheme `FlutterRunlet` 与 `FlutterRunletTests` 即可运行单元和集成回归。各任务运行计划中的命令；每一实施波结束跑 Debug 全量；阶段验收构建 Release，记录构建版本、构建号、提交、macOS 版本、语言、外观、截图倍数及命令退出结果。新 XCTest 随首次实现对应行为的任务加入；不得把还不存在的套件用无执行量的绿灯代替。首轮执行记录实测耗时和测试数量。

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-07" -parallel-testing-enabled NO test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Release -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-07" build
```

执行失败标准：构建或测试退出非零、目标套件无测试执行、非预期跳过、已知负例没有失败或任一原生检查缺少有效证据，均不能标记相应行为通过。

规划时已在现有代码上运行 `LaunchPresentationTests` 和 `FlutterToolchainTests`：31 项通过，0 失败。此记录仅用于确认基线和命令可运行。

## 接入真实更新前的对照

| 案例组 | 原生窗口里的状态 | 基线 |
| --- | --- | --- |
| V01 通用 | 三个偏好的开/关，语言菜单/关闭及焦点返回，跟随系统/简中/英文切换，登录项不可配置和设置入口 | Figma 通用及选择语言；无直接原图的失败用角色与状态验收 |
| V02 Flutter | 自动、手动、可用 FVM、无 SDK、无效与正在验证手动路径、原生选择与取消；Doctor 空闲、运行、成功、取消、失败/重试、完整长输出、项目/SDK 改变清除过时结果 | Figma Flutter、SDK 目录示意及 Doctor 输出；依赖真实系统的面板独立截图 |
| V03 关于布局 | 设置关于与独立窗的标题、品牌、说明、MIT、署名、版本、三链接、侧栏底部版本；独立窗可见 MIT 和 Svame，设置许可证链接的本地提示与辅助功能说明可读出同源信息，真实目标仍是 LICENSE；各控件的禁用、焦点、文本溢出 | 两处 Figma 窗口及共用信息，提示与辅助功能单独实测 |
| V04 更新原型 | 两处分别记录 11 个画板变体（包括两组 4 帧）及连续旋转，开关窗口时状态同步 | Figma 静态图与实机录像或连续帧 |
| V05 更新扩展 | 两处分别记录已是最新、无发布、检查失败、阻塞等待（调试/待恢复/恢复失败/进程退出未知/记录不可读）、确认、稍后继续、下载失败、校验失败、替换失败、新版启动失败、旧版恢复后无法自动打开 | 用受控数据呈现；引用相同组件及语义样式，独立反馈窗口单列，不伪造画板 |

V01–V05 按简体中文/英文 × 系统深色/浅色的适用组合记录；对状态不适用的组合写具体原因。对照时冻结文案、示例版本、路径和进度帧。统一 sRGB、缩放和截取边界，保留原图、叠图与差异表。对应用可控项逐个检查布局、标题、间距、行高、配色、图形、开启/禁用/焦点状态、文本裁切；可用 1 pt 作为几何复测线，超过即先复核或修正。参考没有独立英文或浅色画板时，按 `07-FIGMA-EVIDENCE.md` 使用组件度量、现有本地化及浅色变量，保留实拍，不冒称像素叠图。系统绘制、原生目录选择、字形抗锯齿等差异必须标位置与原因，整图相似度只辅助定位。

门槛记录 `07-VISUAL-GATE.md` 必须列候选提交、证据索引、逐行状态和可控偏差、未通过或阻塞项、核对人及时间。每个实拍绑定用例 ID、窗口、状态、语言、外观和帧；同时锁定候选的视觉源码及资源。矩阵全部通过且无未解决的可控差异，才能记录 `PASS`。只完成构建、只看几张代表状态或只有计划/总结均不构成通过。所有波次顺序执行于同一工作区，复用私有原始证据。真实更新前校验硬前置，缺证据、串用截图或视觉源码变动时先修复和复测。

## 真实更新与最终联验

| 需求 | 自动化与必须保留的实拍证据 |
| --- | --- |
| UI-13、UI-14、UI-15 | `LaunchPresentationTests`、`FlutterToolchainTests`；原生窗口尺寸与复用行为、偏好跨重开保持、默认浏览器打开六个链接入口、实际 SDK 与运行一致、完整 Doctor 输出及取消/失败；记录 V01–V03。 |
| UPD-01 | 受控 HTTP 和实际 Bundle 比较；无自动请求；无 Release、未发布/预发布过滤、网络/解码/限流失败、最新/新版、两入口同步和防止并发请求。从公开仓库只读检查，资产不支持则展示既定提示。 |
| UPD-02 | 隔离两个真实 App 做验包、替换、重启与三处版本刷新；覆盖重复点击、窗口全关、稍后、确认前后竞态、失败路径；故障注入覆盖坏包、错身份、真实回退、新旧 App 均启动失败时的反馈。等待安装期间不破坏运行和恢复；安装点需重新核对守卫。 |
| UI-07 | 同一最终 Release 四处界面，必须包括设置三页与独立窗。中英文 × 深浅外观、键盘/辅助功能名称/角色/状态、无 Tab 焦点的主窗口与菜单栏、保留原生行为的设置与关于；同候选重跑真实 Flutter、SDK 选择、成功与失败恢复。 |

最终记录含候选 App 的 Bundle 实际值、安装前后与回退启动证据、各项通过/失败/阻塞。两份更新构建、签名凭据、Figma 原图及真实运行日志留在本机隔离位置；提交源、测试和脱敏记录。执行结果见下方任务验证索引和[最终验收](07-ACCEPTANCE.md)。

## 规划复核（2026-11-15）

独立复核通过：六份计划、17 个任务覆盖 6 项需求和 12 条决定。修订后逐条验证 35 组校验命令的语法及失败条件；计划 04、05 在缺少真实视觉记录时均返回失败，最终签核的校验拒绝缺项、重复和 `BLOCKED`。复核收敛到同工作区证据、逐例绑定和视觉源码变动、首次替换前的回退、旧进程门禁、签名版本匹配、同源署名及全项通过判定。这些是对计划与现有测试基线的复核，实际视觉门槛和安装验收待执行。

## 逐任务验证索引

| 任务 | 需求或验收范围 | 已运行的验证 | 结果 |
| --- | --- | --- | --- |
| 07-01-01 | 视觉来源与资产 | 节点、导出索引、必需字体、图标及变量复核 | [07-01](07-01-SUMMARY.md) |
| 07-01-02 | 中英文及深浅矩阵 | 矩阵适用性、状态与 1×/2× 原图绑定 | [07-01](07-01-SUMMARY.md) |
| 07-02-01 | UI-13 | `LaunchPresentationTests` 及原生偏好、设置窗口复用 | [07-02](07-02-SUMMARY.md) |
| 07-02-02 | UI-14 | `FlutterToolchainTests` 及原生 SDK、Doctor 取证 | [07-02](07-02-SUMMARY.md) |
| 07-02-03 | UI-15、UPD-01 | `LaunchPresentationTests`、两处布局及普通 Release 负例 | [07-02](07-02-SUMMARY.md) |
| 07-03-01 | UI-13、UI-14、UI-15 | 固定产物、V01–V03 原生矩阵、辅助功能与键盘 | [逐状态签核](07-VISUAL-GATE.md) |
| 07-03-02 | UI-15、UPD-01、UPD-02 | 两处 V04–V05 原生矩阵、状态与帧 | [逐状态签核](07-VISUAL-GATE.md) |
| 07-03-03 | 真实接线前置 | 视觉验证器和伪 PASS、错身份、缺原图等负例自测 | [07-03](07-03-SUMMARY.md) |
| 07-04-01 | 真实接线前置 | 接线之前的实物验证，接线后 88 对原生复拍 | [07-04](07-04-SUMMARY.md) |
| 07-04-02 | UPD-01 | `ReleaseUpdatesTests`、同源双入口普通联网及无自动请求 | [07-04](07-04-SUMMARY.md) |
| 07-04-03 | UPD-02 | `UpdatePackageTests`、实际签名 DMG、回环传输和只读预检 | [07-04](07-04-SUMMARY.md) |
| 07-05-01 | UPD-02 | `UpdateTransactionTests`、`bootstrap-safety` 与 `success` | [安装实测](07-UPDATE-EVIDENCE.md) |
| 07-05-02 | UPD-02 | `UpdateInstallGateTests`、现行与旧版跨实例 `gate` | [安装实测](07-UPDATE-EVIDENCE.md) |
| 07-05-03 | UPD-02 | `UpdateTransactionTests`、`rollback`、双语原生恢复动作 | [安装实测](07-UPDATE-EVIDENCE.md) |
| 07-06-01 | UI-07、UI-13、UI-14、UI-15 | 最终普通 Release 四处界面、四组合、AX/HID 和六个实链 | [最终验收](07-ACCEPTANCE.md) |
| 07-06-02 | UI-07、UI-13、UI-14 | 同候选与真实设备、Flutter 热操作、DevTools、Doctor、失败和暂停恢复 | [最终验收](07-ACCEPTANCE.md) |
| 07-06-03 | UI-07、UI-13、UI-14、UI-15、UPD-01、UPD-02 | 同源码普通/隔离候选及最终六项唯一判定 | [最终验收](07-ACCEPTANCE.md) |

## 原生验证

Figma 节点、键盘、浏览器、系统登录项、Flutter 设备及回退助手使用本机实物和动作记录。应用源码与受控输入的自动化验证通过，正式 Developer ID 签发、公证及 macOS 15 和 Intel 实机仍待覆盖。完整截图和日志在项目私有证据目录。

## 签核

- [x] 17 个任务均关联已执行的证据。
- [x] 六项需求的最终判定和查重校验通过。
- [x] 普通 Release 构建、最终 133 项全量宿主测试、首轮 53 项定向宿主测试及视觉脚本均通过。
- [x] 同源码隔离安装、跨实例门禁与回退均有原生记录。

## Validation Audit 2026-11-15

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

同源码最终回归覆盖前序八个宿主测试套件，共 93 项，均包含在 133 项全量结果中。审阅新增故障、持续运行机制、进程标记过期策略及视觉像素校验的证据见[审阅处置](07-REVIEW-DISPOSITION.md)。
