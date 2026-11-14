---
phase: "04"
slug: macos
status: verified
threats_open: 0
asvs_level: 1
created: "2026-11-13"
---

# Phase 04 · 安全复核

受测候选为 `97a6713d3a65d3d49fbad2012e26bff3c40266d3`。配置使用 ASVS L1，高危及以上未关闭威胁阻断阶段。五份计划预先登记的 13 项威胁和 1 项重复声明的依赖风险已逐项复核。五份摘要均无额外威胁标记。该候选的 Debug xcresult（宿主证据 `/tmp/runlet-wave5-review.UdXPxN/tests.xcresult`）为 75 项通过，0 项失败、0 项跳过。

下表所引的原生、Release 包及取证目录清理证据来自修复前候选 `988ac81`。本次检查 `97a6713` 相对该候选的源码变更，新增回归验证退出时清理仍在运行及已取消的环境诊断。诊断命令、输出隔离、登录项授权、恢复任务复验、关于链接和品牌资源的实现保持一致。 [阶段验收记录](04-P4-ACCEPTANCE.md)

## 信任边界

| 边界 | 越界数据与授权 |
|---|---|
| 主窗、菜单栏、按键和启动偏好 → 会话 | 前台操作、调试选择、恢复项目及任务。实际派发由同一控制器守卫与恢复租约决定。 |
| SDK 选择 → 环境诊断 → Flutter 设置 | 已验证的可执行路径与固定参数，两路原始诊断数据及其当前项目和 SDK 归属。 |
| 通用设置与关于 → macOS | 显式切换请求交给系统登录项服务。固定 HTTPS 目标交给默认浏览器。 |
| 会话、包资源与本机取证 → 阶段记录 | 可显示原值、日志遮罩、候选签名和资源哈希，以及独立样例的脱敏复验结论。 |

## 威胁登记

| 威胁 ID | STRIDE | 组件 | 严重度 | 处置 | 缓解与证据 | 状态 |
|---|---|---|---|---|---|---|
| T-04-01 | Information Disclosure | 语义文案、日志和剪贴板 | high | mitigate | 应用文本在展示时翻译，项目和设备等参数按原值渲染。会话原始输出先经 `FlutterLogRedaction.clean` 再写入可复制日志，机器调试连接仍由既有协议独立处理。候选 `SessionLogTests` 覆盖分片、嵌套令牌与整段复制。 [会话实现](../../../../FlutterRunlet/SessionController.swift) · [日志测试](../../../../FlutterRunletTests/SessionLogTests.swift) | closed |
| T-04-02 | Tampering | 两处恢复动作、持久记录和原任务 | high | mitigate | 两处调用 `performRecoveryAction`。重试在项目租约内核对项目身份和预期记录、原任务定义及执行，进入忙碌状态后拒绝再次派发。恢复与并发测试覆盖错项目、记录变更、重复操作。最终样例从面板重试同一任务，风险记录 1→0。 [控制器](../../../../FlutterRunlet/SessionController.swift#L452) · [恢复测试](../../../../FlutterRunletTests/ProjectRecoveryTests.swift) · [A03 证据](04-P4-ACCEPTANCE.md#验收矩阵) | closed |
| T-04-03 | Spoofing | AppKit 调试功能键 | high | mitigate | 仅 AppKit 本地事件进入单一监听，要求匹配已注册可见的键盘焦点窗口、非模态且无附加 sheet。映射检查精确修饰键并忽略重复事件，调用与按钮相同的会话启用条件。原生基线在面板和日志焦点下的热操作生效，Finder 前台下发送四键后会话状态及热操作输出一致。当前候选退出收尾期间禁止启动新调试，设置从菜单栏打开时直接激活应用，原调试键路由沿用同一窗口守卫。 [路由实现](../../../../FlutterRunlet/FlutterRunletApp.swift#L460) · [映射测试](../../../../FlutterRunletTests/FlutterDebugSessionTests.swift#L13) · [A21 证据](04-P4-ACCEPTANCE.md#验收矩阵) | closed |
| T-04-04 | Tampering | 翻译与配置、退出、恢复 | medium | mitigate | 错误采用结构化展示资源，原 JSONC 内容、任务参数、退出码和恢复记录验证走既有模型。候选配置、任务退出与恢复测试通过，独立样例配置字节前后相同。 [配置测试](../../../../FlutterRunletTests/ProjectConfigurationTests.swift) · [恢复测试](../../../../FlutterRunletTests/ProjectRecoveryTests.swift) · [A23 证据](04-P4-ACCEPTANCE.md#验收矩阵) | closed |
| T-04-05 | Tampering | 启动偏好、恢复项目与任务 | high | mitigate | 持久化偏好只决定启动窗口及是否加载最近项目。启动检查恢复记录只标记状态，加载恢复项目与重试为独立的显式动作；重试保持租约与原任务检查。候选重启打开待恢复主窗，主动打开项目后标记仍为 prod，明确重试后恢复 test。 [启动测试](../../../../FlutterRunletTests/LaunchPresentationTests.swift#L120) · [原生复验](04-P4-ACCEPTANCE.md#原生复验与差异) | closed |
| T-04-06 | Elevation of Privilege | 通用设置与 macOS 登录项 | medium | mitigate | `SMAppService.mainApp` 授权状态来自系统。初始化、设置页进入及 App 激活只查询，登记与移除仅由用户显式切换触发，异常后重新读取实际状态。窄接口测试覆盖批准变化、显式请求和失败。原生隔离候选实测 `notFound` 与禁用开关，系统登记、批准、下一次登录和取消登记仍属于 A04 环境阻塞。 [授权实现](../../../../FlutterRunlet/FlutterRunletApp.swift#L63) · [授权测试](../../../../FlutterRunletTests/LaunchPresentationTests.swift#L66) · [A04 剩余验收](04-P4-ACCEPTANCE.md#剩余验收) | closed |
| T-04-07 | Tampering | 已选 SDK 与本机诊断执行 | high | mitigate | 诊断仅使用当前已解析的绝对 SDK 可执行文件，固定参数 `--no-version-check doctor -v`，过滤项目内和相对 PATH，使用独立 0700 临时工作目录。当前候选测试断言实际可执行文件、参数、工作目录及 PATH。原生基线显示 FVM 与真实 Flutter Run 路径一致，无效 FVM 禁止运行。 [诊断实现](../../../../FlutterRunlet/FlutterToolchain.swift#L409) · [诊断测试](../../../../FlutterRunletTests/FlutterToolchainTests.swift#L16) · [A24 证据](04-P4-ACCEPTANCE.md#验收矩阵) | closed |
| T-04-08 | Denial of Service | doctor 子进程、双流与清理 | medium | mitigate | 后台轮转非阻塞读取两路，25 秒与合计 1 MiB 限额。超时、取消或超限时终止独立进程组并回收组长。审查发现退出可能早于诊断清理，`97a6713` 保留当前与已取消任务的句柄，AppKit 延迟退出应答，取消并等待全部诊断完成清理。收尾期间禁止启动新诊断。新增回归 `db71cc6` 在两种退出路径均确认组长已回收且临时目录不存在。原生基线复验了取消提示和重试。 [诊断进程](../../../../FlutterRunlet/FlutterToolchain.swift#L422) · [AppKit 退出](../../../../FlutterRunlet/FlutterRunletApp.swift#L498) · [清理回归](../../../../FlutterRunletTests/FlutterToolchainTests.swift#L126) · [A25 证据](04-P4-ACCEPTANCE.md#验收矩阵) | closed |
| T-04-09 | Information Disclosure | 诊断结果、设置和会话日志 | medium | mitigate | `doctorResult` 仅在当前请求、项目和 SDK 都匹配时接收，仅供 Flutter 设置摘要和双流输出窗口。项目切换清除旧结果。当前候选取消后暂存任务句柄供退出等待，结果发布仍经过原归属检查，未进入会话日志。项目切换取消及丢弃回归通过，仓库仅记录必要摘要。 [请求归属](../../../../FlutterRunlet/SessionController.swift#L632) · [过期请求测试](../../../../FlutterRunletTests/FlutterToolchainTests.swift#L80) · [A25 证据](04-P4-ACCEPTANCE.md#验收矩阵) | closed |
| T-04-10 | Tampering | 关于链接与默认浏览器 | medium | mitigate | 三条 HTTPS URL 为编译期常量，与用户项目无输入关系。XCTest 核对固定目标，最终候选默认浏览器地址栏确认项目、README 及 LICENSE。 [关于实现](../../../../FlutterRunlet/AuxiliaryWindows.swift#L267) · [A26 证据](04-P4-ACCEPTANCE.md#验收矩阵) | closed |
| T-04-11 | Spoofing | Dock 与菜单栏资源 | low | mitigate | Dock 七份源 PNG 与验收导出逐字节匹配，模板沿用既有资源。候选包清单中 Debug 与 Release 的 ICNS 和两份模板哈希一致，原始包严格签名验证通过，隔离标识在两种外观显示对应图标。 [资源核对](04-04-SUMMARY.md#验证) · [A06 证据](04-P4-ACCEPTANCE.md#验收矩阵) | closed |
| T-04-12 | Tampering | 独立验收样例、原工程与系统状态 | high | mitigate | 使用公开样例独立副本、隔离标识和临时恢复根。直接比对 `sample-before.txt` 与 `sample-after.txt` 完全一致，标记恢复 test，风险为 0，链接和外观复原，模拟器回到关机。隔离登录候选未产生登记操作；Release 历史夹具参数的存储与任务副作用检查通过。 [候选隔离与清理](04-P4-ACCEPTANCE.md#原生复验与差异) | closed |
| T-04-13 | Information Disclosure | 调试及 doctor 的验收归档 | high | mitigate | 检查纳入仓库的五份摘要和验收文档，未检出用户主目录、认证查询参数、私钥标记及 VM 令牌形态。原生基线的 56 份本机文本证据也未检出这些凭据或令牌形态，其中 8 份包含本机路径，保存在宿主 0700 临时目录，仓库只引用文件名及必要脱敏结果。新增清理回归使用独立夹具，xcresult 保留于宿主 0700 临时目录。 [候选证据位置与摘要](04-P4-ACCEPTANCE.md#受测构建) | closed |
| T-04-SC | Tampering | 系统框架、SDK、构建与资源 | low | accept | 依计划复用系统框架、既有 SDK、共享 scheme、现有签名 worker 和已验收资源。本阶段未增加第三方应用包依赖。 [阶段计划](04-03-PLAN.md#verification) · [签名和资源证据](04-P4-ACCEPTANCE.md#受测构建) | closed |

## 已接受风险

| 风险 ID | 关联威胁 | 依据 | 日期 |
|---|---|---|---|
| T-04-SC | T-04-SC | 五份计划已记录采用现有工具链与原生依赖。该风险条目沿用计划的低危接受决定。 | 2026-11-13 |

## Security Audit Trail

| 日期 | 登记数 | 已关闭 | 未关闭 | 审计 |
|---|---:|---:|---:|---|
| 2026-11-13 | 14 | 14 | 0 | Phase 04 verify:post，复核 `97a6713` 和退出清理回归 |

## 签核

- [x] 计划登记的威胁均有处置与证据。
- [x] 低危依赖风险按计划记录。
- [x] 高危及以上未关闭威胁为 0。
- [x] 安全复核状态为 verified。

A04 的真实系统登录项验收仍为环境阻塞。应用授权边界已按 T-04-06 核对。 [A04 补验步骤](04-P4-ACCEPTANCE.md#剩余验收)
