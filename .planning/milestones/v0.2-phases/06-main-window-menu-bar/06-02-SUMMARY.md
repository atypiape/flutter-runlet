---
phase: 06-main-window-menu-bar
plan: "02"
subsystem: ui
tags: [swiftui, flutter, xctest]
provides:
  - 两处共享的下次运行设备选择及在线、离线、未知反馈
  - 当前调试会话的实际配置与设备快照
affects: [06-03, 06-04]
actuals:
  tasks: 2
  commits: 2
  plan_head_before: 96fe7edd7416469e118ebe17469f69d22e296919
tech-stack:
  added: []
key-files:
  modified:
    - FlutterRunlet/SessionController.swift
    - FlutterRunlet/MainWindowView.swift
    - FlutterRunlet/MenuBarPanelView.swift
    - FlutterRunlet/Localizable.xcstrings
    - FlutterRunletTests/FlutterDebugSessionTests.swift
    - FlutterRunletTests/FlutterToolchainTests.swift
requirements-completed: [UI-07, UI-08, RUN-07]
completed: 2026-11-14
status: complete
---

# 06-02 · 下次运行设备与当前调试会话

两处共享同一个下次设备选择器。运行中将下次设备从 A 改为 B，当前状态区、设备监测、热操作、DevTools 和 Inspector 仍使用实际启动的 A。启动、停止和恢复期间暂停选择，启动前继续重新校验所选设备和固定设备约束。

列表按设备 ID 合并 Flutter 发现结果、已知设备及关闭的 iOS 模拟器。条目保留原名，显示本地化的设备类型、文字和状态点。探测失败时保留已知条目并标为未知。运行中显示上次扫描说明，空闲时可从同一入口刷新或启动 iOS 模拟器。

## 验证

| 检查 | 结果 |
| --- | --- |
| RED 回归 | 验证新测试在缺少启动快照及候选设备状态时无法编译 |
| FlutterDebugSessionTests | 10 例通过，0 失败或跳过 |
| FlutterDebugSessionTests + FlutterToolchainTests | 25 例通过，0 失败或跳过 |
| macOS Debug 全量 | 83 例通过，0 失败或跳过，用例执行 24.97 秒 |
| 差异检查 | git diff --check 通过 |

运行边界测试记录 A 与 B 各自的 Flutter 参数、热重载请求和 DevTools 端口，验证 B 不可用时 A 的监测继续工作。停止 A 后，B 离线或重新发现失败均不触发新的前置任务或风险写入，B 恢复在线后从新会话启动。Inspector 的版本回退仍打开当前会话的 DevTools。

全量结果位于阶段构建目录下的 Xcode 测试结果包 `Test-FlutterRunlet-2026.11.14_23-17-07-+0800.xcresult`。两处原生键盘交互和真实 Flutter 设备切换由 06-04 验收。

## Task Commits

1. **Task 1: 当前设备与下次偏好分离** - `6fa12ad` (test), `485b8df` (feat)
2. **Task 2: 共用设备状态和启动预检** - `6fa12ad` (test), `485b8df` (feat)
