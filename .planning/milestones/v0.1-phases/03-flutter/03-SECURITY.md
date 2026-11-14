---
phase: "03"
slug: flutter
status: verified
threats_open: 0
asvs_level: 1
register_authored_at_plan_time: true
created: "2026-11-13"
---

# Phase 03 · 调试与恢复安全复核

以计划中的威胁登记为准，复核候选 `9300b9c` 的实现、定向回归及 [G2 证据](03-G2-ACCEPTANCE.md)。阻断阈值为高，未发现登记内尚未验证的高危缓解措施。

| 边界 | 跨界数据与约束 |
| --- | --- |
| 项目配置 → SDK、任务与 worker | 规范项目路径、SDK、设备和任务在执行前复验；受管会话持有租约。 |
| Flutter 机器协议 → App 与浏览器 | 仅当前设备、进程和 `appId` 的连接与命令可改变会话；有效连接凭据只交给当前连接调用和浏览器。 |
| CLI 输出 → 日志、剪贴板与验收记录 | 先遮罩凭据，再进入展示、复制或取证。清空日志不修改恢复状态。 |

| 威胁 | 等级 | 处置 | 复核依据 | 状态 |
| --- | --- | --- | --- | --- |
| T-03-01 · 复验后命令被替换 | 高 | 缓解 | `SessionController.revalidate` 在项目租约内复验配置与原任务；`FlutterToolchain.command` 使用验证后的绝对 SDK 和参数向量。`testInvalidPreflightLeavesEnvironmentAndRiskUntouched` 断言零任务、零风险。 | 已关闭 |
| T-03-02 · 停止响应被误作进程退出 | 高 | 缓解 | `SessionProcessRunner` 分开调试命令输入与停止控制管道；`SessionProcess.wait` 和 worker 的组退出报告决定能否恢复。真实 prod 取证观察到 worker 退出时仍为 prod，随后才恢复 test。 | 已关闭 |
| T-03-03 · 机器输出泄露 VM 令牌 | 高 | 缓解 | `FlutterDebugSession` 隔离机器消息、用本地 RPC 验证当前连接、拒绝重定向；`FlutterLogRedaction` 在输出进入会话日志前处理。机器协议与分片日志回归覆盖。 | 已关闭 |
| T-03-04 · 项目 FVM 指向非信任脚本 | 高 | 缓解 | `projectFVMSDK` 规范化路径，要求指向用户 FVM 缓存，按固定版本检查并避开项目内可执行文件。`testProjectScriptsAndSDKLinksOutsideTrustedRootsAreNeverProbed` 断言无执行。 | 已关闭 |
| T-03-05 · 过期 SDK 或设备扫描越过门槛 | 高 | 缓解 | `SessionController` 按项目和请求 ID 丢弃过期结果，Run 前复验设备与配置。SDK 和设备测试覆盖旧回调、冲突、离线及同 ID 重连，普通 App 实测无自动启动。 | 已关闭 |
| T-03-06 · 旧热操作响应或扫描错误改变状态 | 高 | 缓解 | `FlutterDebugSession` 核对当前请求和会话；设备状态仅在确认断开时停止。XCTest 覆盖错误、迟到和重连，实际 DDS 中断及设备断开分别取证。 | 已关闭 |
| T-03-07 · 浏览器使用旧地址或错误来源 | 高 | 缓解 | `browserDestination` 要求已连接、回环地址、匹配 VM 服务和 DDS 路径；停止和断线撤销许可。`testBrowserUsesOnlyCurrentBoundAddressAndReconnectsBeforeOpeningAgain` 及三次真实 Edge 绑定验证通过。 | 已关闭 |
| T-03-08 · 日志或剪贴板保留原始凭据 | 高 | 缓解 | 流式缓冲在展示前遮罩地址路径及嵌套 URI。`SessionLogTests` 覆盖分片、编码和清空；真实原生选区及整段复制保留端口但无令牌。 | 已关闭 |
| T-03-09 · 验收误操作用户工程 | 高 | 缓解 | G2 仅使用独立公开样例与临时恢复目录。验证前后配置校验值一致，结束时两套样例均为 test、无剩余恢复记录。 | 已关闭 |
| T-03-10 · 取证泄露当前 VM 地址 | 高 | 缓解 | 中间取证曾读到临时连接令牌，已停止相关调试会话使其失效，并移除未遮罩截图。保留的文本证据经过回环地址扫描（88 份，无未分类令牌），浏览器仅归档遮罩文本和 Inspector 内容。 | 已关闭 |
| T-03-SC · 工具链供应风险 | 低 | 接受 | 按计划复用系统框架、签名 worker 和现有用户 SDK；Release 及 Debug worker 均通过严格签名校验。没有增加 App 外部包依赖。 | 已记录 |

低危工具链依赖按已确认计划接受。其余 10 项均有实现和验证依据，`threats_open: 0`。

复核修正 `0416505` 后，T-03-02 的私有回执区分子进程启动和最终退出，缺失或损坏的回执不会被接受为确认退出。T-03-06 的设备缺席还需系统关机证明，或在当前已验证 VM 断线后两次成功扫描均缺席，避免把子探测漏报当作断开。相关定向与全量回归通过，原生复验证据见 [G2 验收记录](03-G2-ACCEPTANCE.md)。

## Security Audit 2026-11-12

| Metric | Count |
|---|---|
| Threats found | 11 |
| Closed | 11 |
| Open | 0 |
