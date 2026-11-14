---
phase: "05"
slug: stability-recovery-release
status: verified
threats_open: 0
asvs_level: 1
register_authored_at_plan_time: true
created: "2026-11-14"
---

# Phase 05 · 安全复核

复核候选 `36916dd1f6a6f916a1c76ca93aa37ae84f8247f6`。本阶段按 ASVS L1 核对计划登记的 12 项唯一威胁，门槛为 high。当前 Debug 全量 77 项通过，零跳过。每次强退和退出异常的原生取证按实际构建标注，恢复执行、记录认证、进程监管及 VM Service 实现与已完成 16 项恢复实测的 `c80ec88` 相同。 [候选及 A13](05-01-SUMMARY.md) · [恢复记录](05-RECOVERY.md) · [代码审查处置](05-REVIEW-DISPOSITION.md)

## 信任边界

| 边界 | 越界数据与授权 |
|---|---|
| 所选工程与运行器 | 工程身份、租约、已解析任务及其参数、原恢复定义与进程退出状态。 |
| Debug 夹具与日常应用 | 仅 Debug 验收入口使用固定项目根、独立恢复库和独立偏好域。 |
| Flutter 进程与原生日志 | 机器事件绑定当前 VM Service。日志发布前遮罩令牌，界面与复制读取裁剪后的日志。 |
| 真实工程与隔离副本 | 原工程只用于基线核对。授权副本逐轮运行，prod 仅启动至调试就绪后停止。 |
| 本机证据与交付 | 私有副本、探针与输出留在忽略目录。公开记录保留候选标识、摘要、参数类别和判定。 |

## 威胁登记

| 威胁 ID | STRIDE | 组件 | 严重度 | 处置 | 缓解与证据 | 状态 |
|---|---|---|---|---|---|---|
| T-05-01 | Tampering | 样例与日常工程和恢复库 | high | mitigate | A13 使用独立样例与恢复库。最终候选记录配置和日常存储摘要、修改时间前后一致。原进程组消失时仍为 prod 且风险仍在，原任务成功后才恢复 test 和清除风险。 [A13 取证](05-01-SUMMARY.md#替换候选) | closed |
| T-05-02 | Elevation of Privilege | Debug 夹具脚本与状态文件 | high | mitigate | Debug 固定根、状态文件所有者与链接数、命令和参数、cwd 和脚本 SHA-256 在任务前校验。脚本摘要与配置一致，Shell 语法和有界暂停、脚本改写、链接和越界相关 XCTest 通过。旧版夹具待恢复记录的兼容范围见审查处置。 [校验实现](../../../../FlutterRunlet/ProjectConfiguration.swift#L41) · [夹具测试](../../../../FlutterRunletTests/SessionLifecycleTests.swift#L137) · [审查处置](05-REVIEW-DISPOSITION.md) | closed |
| T-05-03 | Tampering | 会话、任务与租约 | high | mitigate | 工程锁随受管工作保持。重试重新读取风险并验证原任务定义与执行，worker 等进程组退出才报告结束。当前 XCTest 和 A13 通过，`c80ec88` 的重复启动、第二实例、项目切换、退出取消和恢复失败原生取证通过。 [租约](../../../../FlutterRunlet/SessionProcess.swift#L57) · [重试](../../../../FlutterRunlet/SessionController.swift#L456) · [worker](../../../../FlutterRunletSessionWorker/main.swift#L47) · [恢复记录](05-RECOVERY.md) | closed |
| T-05-04 | Tampering | 强退与风险持久化 | high | mitigate | 持久记录认证，恢复任务必须返回 0 后才清风险。当前候选恢复和会话 XCTest 通过。前置写入后、后置写入后及 Release 运行中三个强退重启点均在最终候选通过。 [记录认证](../../../../FlutterRunlet/ProjectRecoveryStore.swift#L195) · [清除风险守卫](../../../../FlutterRunlet/SessionController.swift#L1077) · [强退取证](05-RECOVERY.md) | closed |
| T-05-05 | Denial of Service | 高频日志与原生缓冲 | medium | mitigate | 批量发布、64 KiB UTF-8 边界裁剪和视图字面前缀检查已实现，Unicode 回归与日志 XCTest 通过。最终候选 30 分钟实测约 200.51 行/秒，四项反馈低于 184 ms，RSS 峰值增加 8.25 MiB，末段回落。 [日志裁剪](../../../../FlutterRunlet/SessionController.swift#L1210) · [Unicode 回归](../../../../FlutterRunletTests/SessionLogTests.swift#L255) · [压力记录](05-LOG-STRESS.md) | closed |
| T-05-06 | Information Disclosure | 日志、截图与 VM Service 地址 | high | mitigate | 两路任务和 Flutter 日志均在发布前遮罩，测试覆盖普通文本、嵌套令牌与清空代际。VM Service 端点限制为当前会话的环回地址。私有证据目录被 Git 忽略，公开摘要复核未发现所查路径、密钥或令牌形态。 [发布边界](../../../../FlutterRunlet/SessionController.swift#L1113) · [端点校验](../../../../FlutterRunlet/FlutterDebugSession.swift#L257) · [日志测试](../../../../FlutterRunletTests/SessionLogTests.swift#L25) | closed |
| T-05-07 | Tampering | 候选 App 与跨环境归档 | high | mitigate | 最终 ZIP 校验值正确。源包与解包文件逐字节比对，主程序和 worker 执行位、两套严格签名均通过。两文件各架构的最低版本均为 15.0。最终解包候选普通运行、连接当前 VM Service、停止并恢复 test，风险清零。 [归档与部署目标](05-ENVIRONMENT.md) | closed |
| T-05-08 | Tampering | 真实项目任务与 Firebase 环境 | high | mitigate | 授权副本从已校验基线逐轮运行，生成配置及原任务脚本单独备份。两工具 prod 停止后由原任务恢复五项 test 基线文件，当前候选的 dev、test、prod 均已运行通过。最终复验后，原工程 16 项摘要和 Git 状态均与基线一致。 [环境对照与恢复](05-ENVIRONMENT.md#a29--真实项目) | closed |
| T-05-09 | Information Disclosure | 真实项目配置与原始证据 | high | mitigate | `.private/` 受 Git 忽略且无追踪文件。公开对照保留环境、参数类别、结果和候选摘要。复核 10 份公开文件未发现所查本机路径、Firebase API 密钥、私钥和 VM Service 令牌形态。 [忽略规则](../../../../.gitignore) · [环境对照](05-ENVIRONMENT.md) | closed |
| T-05-10 | Tampering | 验收证据与交付 | high | mitigate | 私有核验器已检查同候选二进制摘要、唯一 A29/A31 行、G3 状态和人工复核标识。封存模式进一步要求所有适用项通过、ZIP 校验、签名及同候选解包恢复证据。一致性和最终封存检查均通过。 [G3 记录](05-G3-ACCEPTANCE.md) · [封存计划](05-05-PLAN.md) | closed |
| T-05-11 | Information Disclosure | 真实工程或本机证据进入交付记录 | high | mitigate | 审查当前候选摘要、恢复、环境、压力、审查处置、G3、README 与发布说明等 10 份文件。未发现所查私有路径与凭据形态。真实工程配置、原始 AX 输出和候选实物留在 Git 忽略目录。 [G3 记录](05-G3-ACCEPTANCE.md) · [发布说明](../../../../docs/RELEASE-NOTES.md) | closed |
| T-05-SC | Tampering | SDK、构建及验收依赖 | low | accept | 沿用既有 SDK、系统框架、受管 worker、共享 scheme、XCTest 和原生校验工具。阶段差异未修改应用依赖清单或工程配置。 [阶段计划](05-01-PLAN.md#verification) | closed |

## 已接受风险

| 风险 ID | 关联威胁 | 依据 | 日期 |
|---|---|---|---|
| T-05-SC | T-05-SC | 五份计划预先接受沿用 SDK、系统工具与既有应用依赖的低危风险，按原计划记录。 | 2026-11-14 |

## Security Audit Trail

| 日期 | 登记数 | 已关闭 | 未关闭 | 审计 |
|---|---:|---:|---:|---|
| 2026-11-14 | 12 | 12 | 0 | Phase 05 verify:post，核对候选 `36916dd`、A13、XCTest、最终日志实测、归档、解包运行、证据发布范围与 G3 封存。 |

## 签核

- [x] 12 项威胁均有处置与证据记录。
- [x] 低危依赖风险已按计划记录。
- [x] 高危及以上未关闭威胁为 0。
- [x] 安全复核状态为 verified。
