---
phase: "03"
review: 03-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "一次设备漏报会停止仍可用的调试会话"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "裁剪日志头部会移动仍保留的阅读行并丢失选区"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "监督进程启动成功会提前清空上一轮日志"
open: 0
total: 3
---

# Phase 03 · 代码审查处置

| Finding | Severity | Disposition | Source |
| --- | --- | --- | --- |
| WR-01 | warning | fixed | `0416505`；设备列表缺席不等同于断开。系统确认当前 iOS 模拟器已关机可停止；其他设备需当前已验证的 VM 断线且连续两次成功扫描缺席。`testVMReconnectDoesNotStopUntilDeviceScanConfirmsDisconnect` 和 `testAvailabilityDistinguishesAggregateOmissionFromTheSelectedSimulatorShutdown` 通过。 |
| WR-02 | warning | fixed | `0416505`；按缓冲区被裁掉的 UTF-16 长度重定位可见文本和选区。`testTrimmingLiveLogPreservesTheVisibleLineAndSelection` 在实际 AppKit 文本视图中跨过 64 KiB 上限并通过。 |
| WR-03 | warning | fixed | `0416505`；读取受管子进程的启动回执后才清空旧日志、读取新输出。`testWorkerSpawnFailureBeforeFirstTaskKeepsPreviousLogs` 使用实际缺解释器的可执行文件，派发失败后保留旧日志。 |

三项定向回归所在测试组 23/23、全量 Debug XCTest 57/57 通过。候选构建与原生复验见 [G2 验收记录](03-G2-ACCEPTANCE.md)。
