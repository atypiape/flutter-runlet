---
phase: 03-flutter
plan: "03"
subsystem: debug-session
tags: [swift, macos, flutter, vm-service, devtools, logs]
requires:
  - phase: 03-flutter
    provides: 03-01 的受管 Flutter 进程、机器协议和项目恢复
  - phase: 03-flutter
    provides: 03-02 的设备可用性与实际 Flutter/DevTools 版本
provides: [共享热操作与连接状态, 当前会话的默认浏览器入口, 可选取和复制的流式运行日志]
affects: [03-04]
tech-stack:
  added: []
  patterns: [受信报告管道传递调试子进程启动时刻, 当前机器请求结果匹配, 日志读取代数隔离]
key-files:
  created: [FlutterRunletTests/SessionLogTests.swift]
  modified: [FlutterRunlet.xcodeproj/project.pbxproj, FlutterRunlet/FlutterDebugSession.swift, FlutterRunlet/SessionController.swift, FlutterRunlet/SessionProcess.swift, FlutterRunletSessionWorker/main.swift, FlutterRunlet/MainWindowView.swift, FlutterRunlet/MenuBarPanelView.swift, FlutterRunletTests/FlutterDebugSessionTests.swift]
key-decisions:
  - 60 秒提示从 worker 成功派发 Flutter 子进程的单调时钟时刻计算
  - Inspector 直达只使用实测 Flutter 3.47.4 和 DevTools 2.60.0 对应的认证路径
  - 清空边界由每次管道读取携带，旧半行仍允许解析机器协议
requirements-completed: [RUN-03, RUN-04, RUN-05, RUN-06]
coverage:
  - id: current-hot-operation-and-reconnect
    description: 当前机器 ACK、59/60 秒、VM 断线、设备断开、真实退出和适用恢复
    requirement: RUN-03
    verification:
      - kind: integration
        ref: FlutterRunletTests/FlutterDebugSessionTests.swift
        status: pass
      - kind: automated_ui
        ref: 03-04 的真实 iOS 热操作与退出取证
        status: unknown
    human_judgment: false
  - id: current-browser-binding
    description: 当前 VM 地址的浏览器绑定、Inspector 回退和换会话更新
    requirement: RUN-04
    verification:
      - kind: integration
        ref: FlutterRunletTests/FlutterDebugSessionTests.swift#testBrowserUsesOnlyCurrentBoundAddressAndReconnectsBeforeOpeningAgain
        status: pass
      - kind: automated_ui
        ref: 03-04 的系统默认浏览器与 Widget 选择取证
        status: unknown
    human_judgment: false
  - id: shared-window-session
    description: 主窗和菜单栏共用同一调试控制器和动作
    requirement: RUN-05
    verification:
      - kind: integration
        ref: FlutterRunletTests/FlutterDebugSessionTests.swift#testHotOperationsWaitForCurrentFlutterResultAndKeepStopAvailable
        status: pass
      - kind: automated_ui
        ref: 03-04 的关闭主窗与菜单栏操作取证
        status: unknown
    human_judgment: false
  - id: live-redacted-logs
    description: 任务和调试日志先于退出显示、清空、跨项目保留、令牌遮罩和复制
    requirement: RUN-06
    verification:
      - kind: integration
        ref: FlutterRunletTests/SessionLogTests.swift
        status: pass
      - kind: automated_ui
        ref: 03-04 的原生滚动与折叠取证
        status: unknown
    human_judgment: false
actuals:
  tokens: 22435
  tasks: 3
  commits: 4
  plan_head_before: c67e314c19651c8f6b927370a6cd75df825c839d
  plan_head_after: d531bca597cf3fb2b53783b8f84aa68c65b35dc9
duration: 23min
completed: 2026-11-12
status: complete
---

# 03-03 · 热操作、浏览器入口与流式日志

主窗和菜单栏共用 App 持有的调试会话。当前 Flutter 确认热操作成功后才显示反馈，VM Service 重连恢复操作，设备确认断开时经受管停止和退出确认后恢复 prod 环境。

## Task Commits

1. **Task 1: 热操作、连接中断和设备断开沿同一会话处理** - `caa193f`, `d531bca` (feat, fix)
2. **Task 2: 在默认浏览器打开绑定当前会话的 DevTools 和 Inspector** - `4a76dac` (feat)
3. **Task 3: 保留、清空、跟随和复制实时运行日志** - `6b6c65c`, `0416505` (feat, fix)

阶段审查后在 `0416505` 补齐设备断开确认、实际任务启动回执、裁剪后的日志位置与选区，以及共享 Run 的原生样式和可访问名称、日志等宽字体。定向 23/23、全量 Debug 57/57 通过；原生复验见 [G2 验收记录](03-G2-ACCEPTANCE.md)。

全量回归补正见 `d531bca`，保留 Phase 02 注入适配器原有的调试退出错误反馈。

## 验证

- 任务 1 指定的调试会话、项目并发与恢复 XCTest 共 19 项通过。真实 worker 夹具覆盖 59/60 秒、忽略无关响应、超时、VM 重连、设备确认断开、退出组仍在时保留 prod、自然退出及恢复重试。
- 任务 2 指定的调试会话 XCTest 共 8 项通过。浏览器启动夹具验证旧会话、错误本地前缀、外部地址和日志伪造地址无法打开，也验证打开失败、重连和新会话地址。
- 任务 3 指定的日志、项目选择与调试会话 XCTest 共 16 项通过。断言任务和调试输出先于退出、旧排队或半行输出保持清空、同一 worker 继续输出、复制遮罩、切换和配置重读边界及后置任务时序。
- 波次末共享 scheme 的 Debug XCTest 全量 54 项通过。回归补正使用原测试断言。

## 会话、日志与验收边界

- 启动时刻经 worker 私有报告管道送回父进程，现有退出报告仍用于确认退出。VM 已连接时每次健康 RPC 间隔 2 秒，未连接时每次重试间隔 500 毫秒。设备扫描间隔 5 秒，另计 SDK 查询耗时。扫描失败保持未知状态。热操作等待 Flutter 结果最多 30 秒。
- 运行日志每行与可见 UTF-8 尾部各限 64 KiB。可选取的原生文本视图按当前滚动位置决定跟随。已知 VM Service 与 DevTools 路径凭据在进入显示和复制前遮罩，浏览器使用当前机器协议的私有地址。
- Inspector 路径依据 Flutter 3.47.4、Dart 3.13.3、DevTools 2.60.0 和 iPhone 17 隔离样例的独立浏览器探测。Chromium 对带认证前缀和原 `uri` 查询的 Inspector 路径返回 HTTP 200，并渲染样例 Widget Tree。探测证据为本机临时目录 `/tmp/flutter-runlet-phase03-fixture.TdrzUC` 的 `devtools-route-proof.txt` 和 `devtools-probe-path.png`。[DevTools 2.60.0 路由源码](https://raw.githubusercontent.com/flutter/devtools/v2.60.0/packages/devtools_app/lib/src/shared/primitives/url_utils.dart)
- 原生主窗关闭后菜单栏操作、系统默认浏览器实际连接和 Widget 选择、日志滚动与折叠由 03-04 对候选构建取证。

## 偏差

为在真实子进程派发时开始计时，增补 `SessionProcess.swift` 和 `FlutterRunletSessionWorker/main.swift` 的报告读取与写入。为在读取时标记日志清空边界，复用 `SessionProcess.swift` 管道读取。App 层继续通过现有 App 级控制器向主窗和菜单栏传递同一对象。
