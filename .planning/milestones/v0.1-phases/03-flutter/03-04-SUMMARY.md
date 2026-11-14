---
phase: 03-flutter
plan: "04"
subsystem: g2-acceptance
tags: [swift, macos, flutter, simulator, android, devtools]
requires:
  - phase: 03-flutter
    provides: 03-01 至 03-03 的真实会话、工具链、热操作、浏览器和日志
provides: [同一候选的 Debug 和 Release 构建证据, 公开样例的 G2 验收矩阵, 原生窗口与默认浏览器取证]
affects: [03-verification, 04-ui]
tech-stack:
  added: []
  patterns: [独立公开样例, 真实设备与 XCTest 组合取证, 临时主目录隔离]
key-files:
  created: [.planning/milestones/v0.1-phases/03-flutter/03-G2-ACCEPTANCE.md]
  modified: []
key-decisions:
  - Android 兼容构建参数限于独立样例，真实运行仍通过普通 App
  - 浅色截图使用仅调整外观 Info.plist 的隔离 App 副本
requirements-completed: [RUN-01, RUN-02, RUN-03, RUN-04, RUN-05, RUN-06]
coverage:
  - id: g2-real-mobile-session
    description: iOS 和 Android 模拟器的选择、Debug、VM 连接和退出
    requirement: RUN-01
    verification:
      - kind: automated_ui
        ref: 03-G2-ACCEPTANCE.md
        status: pass
    human_judgment: false
  - id: g2-real-fvm-settings
    description: FVM 缺失阻断、修复后重检和运行期锁定
    requirement: RUN-02
    verification:
      - kind: automated_ui
        ref: 03-G2-ACCEPTANCE.md
        status: pass
    human_judgment: false
  - id: g2-real-flutter-control
    description: 真实热操作、断线重连、退出确认和 prod 恢复
    requirement: RUN-03
    verification:
      - kind: automated_ui
        ref: 03-G2-ACCEPTANCE.md
        status: pass
    human_judgment: false
  - id: g2-default-browser-and-inspector
    description: 默认 Edge 中打开当前会话和真实 Inspector Widget 选择
    requirement: RUN-04
    verification:
      - kind: automated_ui
        ref: 03-G2-ACCEPTANCE.md
        status: pass
    human_judgment: false
  - id: g2-menu-bar-shared-session
    description: 主窗关闭后菜单栏热重启和重开主窗的会话同步
    requirement: RUN-05
    verification:
      - kind: automated_ui
        ref: 03-G2-ACCEPTANCE.md
        status: pass
    human_judgment: false
  - id: g2-native-logs
    description: 真实输出、滚动、清空折叠、选区复制和令牌遮罩
    requirement: RUN-06
    verification:
      - kind: automated_ui
        ref: 03-G2-ACCEPTANCE.md
        status: pass
    human_judgment: false
actuals:
  tasks: 2
  commits: 2
  plan_head_before: 9300b9c35e2887731a34bc650c8aa5462b6e4afd
  plan_head_after: 0c74d63c0514320a8ce1f338265965997f118b5e
duration: 27min
completed: 2026-11-13
status: complete
---

# 03-04 · 验收真实 Flutter 调试闭环

候选提交 `9300b9c` 的 Debug XCTest 54 项全部通过，Release 构建成功，两套 App 和内嵌 worker 签名与执行位验证通过。Release 带两种历史参数进入普通模式，独立样例和固定 Debug 存储的前后摘要一致。

## Task Commits

1. **Task 1: 验证同一候选提交的 Debug 与 Release 产物** - `a0fd0b9` (docs)
2. **Task 2: 用独立真实 Flutter 工程验证并归档 G2** - `0c74d63` (docs)

## 验证

- iPhone 17 模拟器实测公开 dev、test 和 prod。正常停止先确认 Flutter 和 worker 退出，再由原后置任务恢复 test 并清除风险记录。设备断开后复验恢复失败与重试。
- 主窗热重载保留计数，关闭主窗后菜单栏热重启重置计数，两次操作及重开主窗使用同一 Flutter 进程。暂停实际 DDS 验证单独 VM 断线和重连。
- 默认 Microsoft Edge 两个入口绑定同一当前端口，重跑后端口均更新。独立 Edge 上下文连接原生 Inspector 入口的同一实际地址，选择 `MyHomePage` 并查看属性。
- Android 16 arm64 AVD 由普通 App 启动并验证 VM 连接，停止后 Flutter、worker 和设备内样例进程退出。没有可用真机，按 A18 记为不适用。
- 原生滚动、日志清空后折叠及重开、全量和选区复制均取证。深色候选 App 与浅色隔离副本验证原生尺寸、同排控件、长名称、冲突提示及恢复入口。

九项适用行为均通过，G2 记录已归档。证据目录、签名摘要、配置校验和复现操作见 [G2 验收记录](03-G2-ACCEPTANCE.md)。

审查修正后的最终候选为 `0416505`。同一 scheme 的 Debug 全量 57 项和 Release 构建通过。两套主程序及 worker 的执行位与签名均通过。实际复验 iPhone 17 prod 正常停止与模拟器断开后的恢复、Android 启动和停止、Release 历史参数隔离，以及 Run 可访问名称、禁用样式和日志等宽渲染。原矩阵保留，最终候选摘要及新证据见[审查修正复验](03-G2-ACCEPTANCE.md#审查修正复验)。
