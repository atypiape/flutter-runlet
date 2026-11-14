---
phase: 05-stability-recovery-release
plan: "01"
subsystem: testing
tags: [macos, flutter, recovery, xctest]
provides: [普通 Release A13 时序证据, Debug 原任务有界暂停, 同源冻结候选]
affects: [05-02, 05-03, 05-04, 05-05]
key-decisions: []
requirements-completed: [REL-01]
coverage:
  - id: A13
    description: 真模拟器 prod 停止及按原任务恢复
    requirement: REL-01
    verification:
      - kind: e2e
        ref: "候选 tracer.json、a13/observations.json 与 a13/{ready,running,restored}.ax"
        status: pass
    human_judgment: false
  - id: D-01-D-02
    description: 受限样例可在前后置写入后等待放行并有超时上限
    requirement: REL-01
    verification:
      - kind: integration
        ref: "SessionLifecycleTests#testRestrictedFixturePausesAfterBothWritesBeforeAcknowledgingSuccess"
        status: pass
      - kind: other
        ref: "公开脚本 shell 语法及本机 test 暂停超时退出 1"
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-11-14
status: complete
---

# Phase 05 · Plan 01 · 候选与 A13

冻结源码提交 `052add5e0b554c68a842613ed8680cbea099c2b7`。普通 Release 0.1.0（1），Bundle ID 原样，主程序与 worker 均为 arm64/x86_64，Mach-O 最低版本均为 15.0。宿主 macOS 26.7.1（25G241），Xcode 27.1（27A9275）。Debug 76 项通过，零跳过，Release 构建通过。两套产物均通过执行权限、资源、worker 严格签名和 App 深度严格签名检查。

| 构建 | 主程序 SHA-256 | worker SHA-256 |
|---|---|---|
| Release | `ebe096a53194b107e530fb9432433aeed86fba5f42170a4f21b914a95db1852b` | `ac817931fd987f06662d034a032edc2129144935bf702ca7a309605871671468` |
| Debug | `1d836489113da99b562a3e459eddeb96d91de6d083bfaaa92c3df0aadb3047df` | `9f1f0efdf9046d8266674c89247af21c8d47ca05611c6d669b47ba85e4765147` |

## A13

- 初始提交 `6ea2cfe` 的普通 Release 实测通过。冻结提交从干净源码重建后，在 iOS 27.0 的 iPhone 18 Pro 模拟器和 Flutter 3.47.4 上复验通过。由原生控件选择 prod 和模拟器并运行，确认当前 VM Service 已连接，Run 禁用且 Stop 可用。
- 冻结候选以单调时钟记录 `pre_prod → vm_running → debug_group_exited → original_post_exit_0 → test_and_risk_cleared`。Stop 后，进程退出通知与组存在性查询确认旧调试组已消失，当时仍为 prod 且风险数为 1。随后记录中保存的原任务 `sample:select-test` 将环境恢复为 test。应用仅在收到受管后置任务退出 0 后清除风险，最终风险数为 0，Run 恢复可用。旧组退出到观测到任务成功确认相隔约 114 ms。
- 独立样例和临时恢复库与日常库隔离。前后对比两份配置、脚本以及日常存储的文件摘要与修改时间。最终取证和初始候选分别保存。首次轮询错过组退出窗口，复验改用进程退出通知并直接查询组是否存在。

## Debug 写入边界

提交 `052add5` 增加 `pause-after-prod`、`pause-after-test`，并同步受限任务脚本摘要。定向用例随全量测试通过，观察到前置暂停时调试尚未启动、后置暂停时环境已是 test 且风险仍在。移除暂停标记后完成原任务并清除风险。另以独立副本保持 test 暂停标记，脚本真实等待约 30 秒、退出 1，保留写入标记与超时原因。

## 私有证据

`.private/phase-05/current-candidate` 指向通过复验的候选。候选包含 `candidate.json`、`tracer.json`、`a13/`、构建日志及 XCTest 结果。应用或 worker 发生替换时，从干净源码重建 Debug 和 Release，并重跑 A13 以及所有依赖最终候选的验收。

## 替换候选

日志短测发现清空反馈超时。修正提交 `7fdb1d9ebfb2fa5bf6839b49a0fef3c3a95c2d88` 从干净源码重建后，Debug 全量 76 项、Release 构建与签名、真实 A13 均通过。当前指针已更新。

| 构建 | 主程序 SHA-256 | worker SHA-256 |
|---|---|---|
| Release | `02e5976d824f479d28ae4027a339601f886c0b9c9acbe237e3818937f073ccab` | `e6b579a5c030a9cadc8fcc9b9feaa82ebd0a4fe35b6f7450bcb96ee60d9db1fa` |
| Debug | `2a662be3a620cd41c48cbf6bbe6b2fc6187821ea37c62fd98907c79ff26c695b` | `18593244fec8e303ee6abe81980a60374f24e8da649f61e3afe8b6acc869d5a6` |

第二轮短测显示清空仍需 1.65 秒。提交 `20fee3edd80388d42a143d547a8f2639d0143fa2` 批量发布日志并保留原清空代际。当前冻结候选以此提交为准。Debug 全量 76 项通过，Release 构建、签名、真实 A13 和 ZIP 字节校验通过。

| 构建 | 主程序 SHA-256 | worker SHA-256 |
|---|---|---|
| Release | `1cb693884d6fac00cd59c93f192f019575926878504328f2fc762c1b9fb585ab` | `8884da2a190fa83b2ae48908cf695cb1fd77fbda1f1a8b23c6b18149e6da1bec` |
| Debug | `41f20469a278114c6f2b1d69574e9c6683242e0558fd71bcb6b2647f37d878f0` | `802dc71eab702d21f1e7b16564d99bfa5c02ebbc5ab38732d8b978cdf5274ed8` |

30 分钟压测发现 RSS 持续增长。提交 `c80ec88e5749b8ff219c23089fa13369d3c98b5c` 复用当前端点的 VM Service 连接，重新从干净源码构建，Debug 76 项全通过，Release 签名通过。真实 A13 在 iPhone 17 上通过，旧组退出后约 137 ms 观测到原后置任务成功，随后 test 与零风险均确认。当前冻结指针已更新。

| 构建 | 主程序 SHA-256 | worker SHA-256 |
|---|---|---|
| Release | `79a9293b301bd655f3f3d1e9f03d481508108c52cd59ebf35e0c5c23a8837f4e` | `47b1b927dfebca62c9eae54482b6e534a821849c3175be51e67037c820e5696d` |
| Debug | `58364e6c75ba4af6c0d4b93f7b30f5f9d24008bec7d827bd1188f80e30c1e634` | `dbbbaf1e8d17863fc78d9acc59985ebf4c65b30c001e46ad64313cb876e79edb` |


代码审查发现规范等价但原始编码不同的日志可能触发 UTF-16 越界。`36916dd1f6a6f916a1c76ca93aa37ae84f8247f6` 修正字面比较并新增回归。Debug 77 项全通过，Release 构建、签名和真实 A13 通过。旧调试组退出后约 123 ms 观测到原后置任务成功，最终恢复 test、风险清零。当前冻结指针以本次候选为准。

| 构建 | 主程序 SHA-256 | worker SHA-256 |
|---|---|---|
| Release | `52b6a4b1a6916e4ca0d457efcb98b10359785fc86e745267d1aa30a57fb64455` | `a763ab4b27fb3bc348f2c32aa2edda2f9d5695f96a7ef222f2c95d2822d167e2` |
| Debug | `ded95506f021321f21cb1757a59dad4005dd35b62a3ddf714dd8fd926296f120` | `4fc7a6388a3a64fb15a0c817d2274d2433d1650e621027d5cc27b528a30cb879` |
