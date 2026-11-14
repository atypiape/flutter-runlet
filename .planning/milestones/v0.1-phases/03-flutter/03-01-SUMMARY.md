---
phase: 03-flutter
plan: "01"
subsystem: session
tags: [swift, macos, flutter, vm-service, recovery]
requires:
  - phase: 02-config-task-execution-core
    provides: 配置复验、项目租约、worker 退出确认和持久恢复
provides: [PATH Flutter SDK 与 iOS 模拟器发现, Flutter Debug 机器协议, 当前 VM Service 就绪门槛, 停止后原任务恢复]
affects: [03-02, 03-03, 03-04]
actuals:
  tokens: 15351
  tasks: 1
  commits: 1
  plan_head_before: b7f5b6d795b9db687f12f98b7fab9e37f7781589
  plan_head_after: 0ccb59de7a230123f57c559f5585cf758859d65d
tech-stack:
  added: []
  patterns: [Flutter 机器帧与本地 WebSocket RPC, 独立命令输入和控制 EOF, 有界分片日志]
key-files:
  created: [FlutterRunlet/FlutterToolchain.swift, FlutterRunlet/FlutterDebugSession.swift, FlutterRunletTests/FlutterDebugSessionTests.swift]
  modified: [FlutterRunlet.xcodeproj/project.pbxproj, FlutterRunlet/SessionController.swift, FlutterRunlet/SessionProcess.swift, FlutterRunletSessionWorker/main.swift, FlutterRunlet/MainWindowView.swift]
requirements-completed: [RUN-01, RUN-02, RUN-03, RUN-05]
coverage:
  - id: current-flutter-vm-and-recovery
    description: 当前机器会话的 VM 校验、重复 Run 防护和确认退出后的原 prod 恢复
    requirement: RUN-03
    verification:
      - kind: integration
        ref: FlutterRunletTests/FlutterDebugSessionTests.swift
        status: pass
      - kind: automated_ui
        ref: 本记录的真实 iOS 切片
        status: pass
    human_judgment: false
  - id: run-preflight
    description: 同一 SDK、设备和配置复验通过才启动任务
    requirement: RUN-02
    verification:
      - kind: integration
        ref: FlutterRunletTests/FlutterDebugSessionTests.swift#testInvalidPreflightLeavesEnvironmentAndRiskUntouched
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-11-12
status: complete
---

# 03-01 · 从普通主窗启动并停止 iOS Debug

主窗用 PATH 探测到的 Flutter 选择已启动的 iOS 模拟器。当前 `app.start` 的设备和 `appId` 与 `app.debugPort.wsUri` 匹配后，本地 WebSocket `getVersion` 成功才显示「运行中」。启动请求占用控制器，项目锁内重读配置及引用任务，预检失败时不会执行前置任务或写恢复记录。

Flutter 子进程有独立的命令 stdin。停止优先发送当前 `app.stop`，超时后沿用 worker 控制 EOF。机器响应不解锁项目，确认进程及受管组退出后才运行原后置。日志按字节拼接完整行，再解码与遮罩，机器帧和完整 VM 地址留在会话内存。

## Task Commits

1. **Task 1: 从主窗启动 iOS Debug，确认连接并恢复 prod** - `0ccb59d` (feat)

## 真实 iOS 切片

- 环境为 macOS 26.7.1（25G241）、Xcode 27.1（27A9275）、Flutter 3.47.4、Dart 3.13.3、DevTools 2.60.0，设备为 iOS 27.0 的 iPhone 17 模拟器。使用 FVM 管理的 Flutter 3.47.4 SDK 中的 `bin/flutter`。
- 使用共享 scheme 构建的普通 Debug App。用 `codesign --verify --deep --strict` 校验通过，App 可执行文件 SHA-256 为 `e779b2eab1487b01d93a4896deb216954892cbab7fa6e8f34bb9b5143bbff201`，worker 为 `a5d413a63eaf841436a3fae664a4bf0138ef3934dbefecc3be172fb4938781f8`。
- 在临时目录执行 `flutter create --platforms=ios` 并按公开样例复制启动配置、任务和脚本。启动模拟器，给普通 App 提供含 Flutter 的 PATH 和预建 `Library/Application Support` 的临时 `CFFIXED_USER_HOME`，通过最近项目启动参数打开样例。通过 macOS Accessibility 操作主窗，选中 `sample-flutter-app(prod)` 和 iPhone 17，点击「运行」。
- 原生可访问性树先观察到「等待 VM Service」、停止可用。随后观察到「运行中」「VM Service 已连接」，运行禁用，停止可用。环境标记为 `prod`，隔离恢复目录存在一条风险记录。
- 点击「停止」，原生树重新显示运行可用。核对 Flutter 和 worker 已退出，环境标记为 `test`，风险记录为零，`launch.json` 和 `tasks.json` 均通过运行前 SHA-256 比对。遮罩后的取证文件保存在本机临时目录，包括 `wave1-running-ax.txt`、`wave1-stopped-ax.txt`、`wave1-stop-proof.txt`、`wave1-app.sha256`。

## 自动验证与偏差

- 计划指定的四个 XCTest 类共 21 项全部通过，提交后再次运行均通过。Debug 全量 36 项全部通过。
- 首轮流式测试发现 Darwin 上 `FileHandle.read(upToCount:)` 会延迟短帧交付，改用阻塞 POSIX `read` 在后台读取当前可用字节。测试按规范路径核对工作目录，兼容 macOS 临时目录别名。
- 当前验证范围是 A13、A17 的 iOS prod 切片。FVM、手动 SDK、其他设备由 03-02 补齐。热操作、浏览器、连接中断与日志交互由 03-03 补齐，完整 G2 由 03-04 验收。
