---
phase: "06"
slug: main-window-menu-bar
status: verified
threats_open: 0
asvs_level: 1
register_authored_at_plan_time: true
created: "2026-11-14"
---

# 阶段 06 · 安全复核

按 ASVS L1 核对四份计划登记的 9 项威胁，阻断门槛为 high。生产代码复核至提交 `97865d3`，对应本地 Release 候选。XCTest 与本地交互的执行记录见联验文档。下文分别注明代码、XCTest 和 Release 实测证据。 [第三波回归记录](06-03-SUMMARY.md) · [本地联验](06-ACCEPTANCE.md)

## 信任边界

| 边界 | 数据与约束 |
|---|---|
| 两处操作入口与项目控制器 | 目录和历史共用打开守卫及规范路径。原恢复工程通过独立的身份核验入口打开。 |
| 下次设备与当前调试进程 | 下次设备 ID 是偏好。实际启动的设备与配置、进程、设备监测和 VM Service 绑定当前会话。 |
| 项目任务与恢复库 | 由项目租约串行执行，恢复从认证过的原记录核对项目、原任务定义及执行参数。风险清除需持久确认。 |
| 进程输出与界面、剪贴板 | 输出发布前进行 VM Service 令牌遮罩。浏览器入口只接收与当前 VM Service 相符的环回地址。 |
| 联验样例和日常工作区 | Release 验收使用独立项目、偏好域及恢复库。提交只保留脱敏结论与证据索引。 |

## 威胁登记

| 威胁 ID | STRIDE | 范围 | 严重度 | 处置 | 缓解与证据 | 状态 |
|---|---|---|---|---|---|---|
| T-06-01 | Tampering | 目录与历史绕过切换守卫 | high | mitigate | 两处目录和历史最终调用 `open`，在规范化和加载前重新检查项目切换条件。历史删除只更新偏好，不触碰已打开工程、会话或恢复记录。运行、恢复失败、路径别名和第二实例的边界均有自动化覆盖。 [打开守卫](../../../../FlutterRunlet/SessionController.swift#L469) · [历史和切换测试](../../../../FlutterRunletTests/ProjectSelectionTests.swift#L101) · [租约测试](../../../../FlutterRunletTests/ProjectConcurrencyTests.swift#L8) | closed |
| T-06-02 | Information Disclosure | 历史项目路径 | low | mitigate | 历史默认显示末级目录名，路径仅用于本机悬停辨认同名目录。移除按钮的可读名称只含项目名。 [历史列表](../../../../FlutterRunlet/MainWindowView.swift#L702) | closed |
| T-06-03 | Tampering | 下次设备误改当前进程或绕过预检 | high | mitigate | 下次偏好与启动快照各自独立。当前调试实例和监测读取实际启动设备。新启动先重查 SDK 和所选设备，校验配置及固定设备 ID 后才执行前置任务。回归验证从 A 改选 B、B 离线时 A 的监测与热操作、命令 ID、离线和扫描错误无新前置及风险。 [启动预检](../../../../FlutterRunlet/SessionController.swift#L1008) · [A/B 回归](../../../../FlutterRunletTests/FlutterDebugSessionTests.swift#L552) · [预检回归](../../../../FlutterRunletTests/FlutterDebugSessionTests.swift#L97) | closed |
| T-06-04 | Information Disclosure | 浏览器错误连接历史会话 | high | mitigate | 当前 `FlutterDebugSession` 以已验证的 VM Service、当前 app ID 和对应环回 URL 提供浏览器地址。结束时清除连接及浏览器可用性。回归覆盖过期地址拒绝、断线、重连、换会话和 Inspector 回退。Release 在 A 上验证 DevTools 和 Inspector 均连接当前 iOS 会话。 [入口](../../../../FlutterRunlet/SessionController.swift#L1139) · [绑定实现](../../../../FlutterRunlet/FlutterDebugSession.swift#L190) · [浏览器回归](../../../../FlutterRunletTests/FlutterDebugSessionTests.swift#L465) · [Release 联验](06-ACCEPTANCE.md#实机记录) | closed |
| T-06-05 | Tampering | 恢复期替换任务定义或项目 | high | mitigate | 同一项目租约下读取并核对预期记录，认证原定义和执行值，恢复时再次验证工程身份。完成后仍按当前配置重新准备新启动。回归覆盖更换工作目录、修改任务、改名工程第二实例及等待时更改新启动配置。 [恢复入口](../../../../FlutterRunlet/SessionController.swift#L587) · [原任务和身份](../../../../FlutterRunletTests/ProjectRecoveryTests.swift#L27) · [改名租约](../../../../FlutterRunletTests/ProjectConcurrencyTests.swift#L116) · [配置重查](../../../../FlutterRunletTests/FlutterDebugSessionTests.swift#L154) | closed |
| T-06-06 | Tampering | 持久风险未解除、重入或退出时接续启动 | high | mitigate | 单个受管操作持有同一租约。离开恢复和异步预检两个边界时都重新检查风险、项目、退出及所选目标。只有恢复退出 0 且完成回执持久化后才允许接续。回归覆盖持久化失败、风险库不可读、二次恢复失败、只重试、恢复和预检期间确认退出。 [恢复过程](../../../../FlutterRunlet/SessionController.swift#L587) · [持久完成回执](../../../../FlutterRunlet/ProjectRecoveryStore.swift#L122) · [风险回归](../../../../FlutterRunletTests/ProjectRecoveryTests.swift#L191) · [退出回归](../../../../FlutterRunletTests/SessionLifecycleTests.swift#L7) | closed |
| T-06-07 | Information Disclosure | 日志、复制或恢复提示泄露令牌 | high | mitigate | Flutter 和任务输出均在发布前脱敏，剪贴板读取同一份已脱敏缓冲。恢复失败显示任务及结构化执行结果，真实退出码按状态提取。回归覆盖嵌套 URL、复制、清空边界和新日志追加。Release 从真实 Flutter 会话核对复制、清空、折叠和持续新输出。 [输出边界](../../../../FlutterRunlet/SessionController.swift#L1302) · [复制入口](../../../../FlutterRunlet/SessionController.swift#L1111) · [日志回归](../../../../FlutterRunletTests/SessionLogTests.swift#L25) · [Release 联验](06-ACCEPTANCE.md#实机记录) | closed |
| T-06-08 | Tampering | 故障标记影响日常项目或恢复库 | high | mitigate | Release 使用独立 bundle identifier 隔离偏好，用独立用户目录定位常规恢复库。故障标记仅在独立样例内，主样例配置及脚本与仓库样例逐字节相同。联验时在隔离库观测到风险生成，确认退出后风险归零，且无遗留 Flutter 或 worker。日常恢复库没有风险文件，目录树的数据及元数据修改时间均早于验收前基线。未复用原命令逐字节比对日常库摘要。 [联验隔离说明](06-ACCEPTANCE.md#本地候选与数据隔离) | closed |
| T-06-09 | Information Disclosure | 实测设备或日志证据泄露令牌、路径 | high | mitigate | 本机原始证据父目录权限为 `0700`，由 Git 忽略且无追踪文件。联验记录使用 A、B 代称，复核时未发现本机绝对路径、设备 UUID、环回 URL、常见凭据或内嵌图片。最终改动后应对提交内容重复检查。 [Git 忽略规则](../../../../.gitignore) · [本地联验](06-ACCEPTANCE.md) | closed |

## 已接受风险

无。

## Security Audit Trail

| 日期 | 登记数 | 已关闭 | 未关闭 | 取证 |
|---|---:|---:|---:|---|
| 2026-11-14 | 9 | 9 | 0 | 阶段 06 verify:post。复核计划、代码、Debug 结果、Release 隔离证据及联验记录脱敏。 |

## 签核

- [x] 四份计划登记的 9 项威胁均有判定和依据。
- [x] 高危及以上未关闭威胁为 0。
