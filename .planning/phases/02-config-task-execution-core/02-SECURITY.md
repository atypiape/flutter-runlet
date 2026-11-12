---
phase: "02"
slug: "config-task-execution-core"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-11-12"
---

# Phase 02 · 安全核验

按计划中已有的威胁登记核验。当前 GSD 阻断阈值为 high。

## 信任边界

| 边界 | 数据 |
|---|---|
| 项目 → 配置解析 → 监督进程 | 只读 JSONC、命令与 argv、工作目录、环境快照 |
| 会话 → 私有恢复存储 | 规范路径、项目身份、原任务标签及认证校验 |
| Debug 验收 → 原生入口 | 显式开关、固定根、公开脚本及受管替身 |
| 构建 → 验收证据 | 构建配置、签名、二进制摘要及公开样例状态 |

## 威胁登记

| ID | 类别 | 严重度 | 处置 | 核验 | 状态 |
|---|---|---|---|---|---|
| T-02-01 | Tampering | high | mitigate | 风险数据同步、原子替换、目录项同步及实际后置退出。SessionLifecycleTests 逐点注入同步失败并断言零执行。 | closed |
| T-02-02 | Elevation of Privilege | high | mitigate | 验收固定根绑定系统账号，原始脚本、工作目录及状态文件复验。根外路径及别名被拒绝。实际环境变量覆盖试验不改变验收根。 | closed |
| T-02-03 | Tampering | high | mitigate | 租约按设备号与 inode 获取，由 App、监督进程和受管任务共持。测试 Stop 与父管道断开后等待同组后代。 | closed |
| T-02-04 | Information Disclosure | high | mitigate | 0700 存储目录、0600 记录、独立安装密钥与 HMAC。回归检查记录字节及变量名诊断。 | closed |
| T-02-05 | Tampering | high | mitigate | 严格 JSONC、Debug 执行复验、入口及设备覆盖拒绝、配置文件原始字节校验。 | closed |
| T-02-06 | Elevation of Privilege | high | mitigate | 支持的独立命令和参数以 argv 执行，显式 shell 字符串不插入变量。真实 argv 含空格、Unicode 和 shell 元字符的测试通过。 | closed |
| T-02-07 | Tampering | high | mitigate | 加锁后重读并比较有效定义，变化要求再次点击，配置损坏禁用运行。 | closed |
| T-02-08 | Tampering | high | mitigate | 记录认证、规范路径和身份复验，按原标签比较原始定义和展开结果，项目改名仍阻断新运行。 | closed |
| T-02-09 | Information Disclosure | high | mitigate | 定义、执行、逐变量值与完整记录分别认证，变化诊断只输出变量名。 | closed |
| T-02-10 | Denial of Service | high | mitigate | 监督进程等待原组静止，组长不可确认后不再发送信号。结果不明时 App 保留租约并阻断。 | closed |
| T-02-11 | Tampering | high | mitigate | 单个控制器串行 Run、Stop、恢复与退出。实际系统退出确认及失败取消通过。 | closed |
| T-02-12 | Elevation of Privilege | high | mitigate | Release 传相同参数仍无注入，Run 禁用。外部标记和测试存储未写入，两套监督进程签名通过。 | closed |
| T-02-13 | Information Disclosure | medium | mitigate | 仓库验收记录使用公开样例、相对路径和脱敏文字，无原始环境值或桌面图像。 | closed |
| T-02-14 | Tampering | medium | mitigate | 验收记录保存最终提交、测试统计、签名及 SHA-256，并注明各原生观察所用提交。 | closed |
| T-02-SC | Tampering | low | accept | 采用计划已接受的系统框架、Xcode 构建工具与仓库公开样例，无新增第三方运行依赖。 | closed |

证据见 [验证覆盖](02-VALIDATION.md) 和 [P2 验收记录](02-P2-ACCEPTANCE.md)。

## 已接受风险

计划中的 T-02-SC 保留原处置。底层持久同步由 macOS 和文件系统提供，实际掉电验证留待稳定性阶段。

## 审计记录

2026-11-12 核验 15 个唯一条目。所有 high 和 medium 缓解在实现或测试中找到，低风险依赖项沿用阶段计划的处置。
