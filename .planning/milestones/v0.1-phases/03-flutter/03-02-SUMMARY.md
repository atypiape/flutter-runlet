---
phase: 03-flutter
plan: "02"
subsystem: toolchain
tags: [swift, macos, flutter, fvm, simulator]
requires:
  - phase: 03-flutter
    provides: 03-01 的共享控制器、受管 Flutter 进程和项目租约
provides: [可验证的 Flutter SDK 解析, Flutter 设置和修复入口, 移动设备选择, iOS 模拟器启动]
affects: [03-03, 03-04]
tech-stack:
  added: []
  patterns: [Flutter 与 simctl 结构化输出, 项目设备会话内记忆, 请求身份校验]
key-files:
  created: [FlutterRunletTests/FlutterToolchainTests.swift]
  modified: [FlutterRunlet.xcodeproj/project.pbxproj, FlutterRunlet/FlutterToolchain.swift, FlutterRunlet/SessionController.swift, FlutterRunlet/FlutterRunletApp.swift, FlutterRunlet/AuxiliaryWindows.swift, FlutterRunlet/MainWindowView.swift, FlutterRunlet/MenuBarPanelView.swift]
key-decisions:
  - 项目 FVM 链接须指向用户级缓存的项目固定版本
  - 设备查询失败保留已知选择，成功扫描缺失才确认离线
requirements-completed: [RUN-01, RUN-02, RUN-05]
coverage:
  - id: verified-sdk-selection
    description: FVM、手动和 PATH 优先级、无效阻断、设置持久和恢复期锁定
    requirement: RUN-02
    verification:
      - kind: integration
        ref: FlutterRunletTests/FlutterToolchainTests.swift
        status: pass
      - kind: automated_ui
        ref: 本记录的 FVM 失败、设置直达及激活修复观察
        status: pass
    human_judgment: false
  - id: mobile-device-selection
    description: 精确设备标识、配置冲突、项目记忆、离线与未知状态
    requirement: RUN-01
    verification:
      - kind: integration
        ref: FlutterRunletTests/FlutterToolchainTests.swift#testSelectionPreservesConflictOfflineAndPerProjectHistory
        status: pass
      - kind: integration
        ref: FlutterRunletTests/FlutterToolchainTests.swift#testAndroidUsesExactDeviceAndDefinesAndBlocksUnsupportedApplicationArguments
        status: pass
    human_judgment: false
  - id: simulator-boot-gate
    description: 用户启动指定模拟器，待 Flutter 发现后恢复运行资格
    requirement: RUN-05
    verification:
      - kind: integration
        ref: FlutterRunletTests/FlutterToolchainTests.swift#testSimulatorStartWaitsForFlutterAndNeverLaunchesDebug
        status: pass
      - kind: automated_ui
        ref: 本记录的普通 App 启动和选择 iPhone 17 观察
        status: pass
    human_judgment: false
actuals:
  tokens: 19409
  tasks: 2
  commits: 2
  plan_head_before: 986ab61d5f24181200d92d6c920000690eb5f1d1
  plan_head_after: b57060d25827200e70b04b84ca8ed02cf16359ba
duration: 20min
completed: 2026-11-12
status: complete
---

# 03-02 · Flutter SDK 和设备选择

设置显示经同一 Flutter 可执行文件验证的来源、路径和 Flutter/Dart 版本。项目 FVM 失效会阻断运行并提供设置直达。手动路径在校验后保存。会话活动及恢复期间锁定 SDK 设置和已验证的快照。设备扫描使用同一 SDK，按实际 ID 选择 iOS 和 Android。主窗与菜单栏共用选择及阻断原因。

## Task Commits

1. **Task 1: 在 Flutter 设置验证、应用和修复当前 SDK** - `23a80e2` (feat)
2. **Task 2: 刷新和选择真实设备并启动 iOS 模拟器** - `b57060d` (feat)

## 验证

- 任务 1 指定的 SDK 与调试会话 XCTest 共 6 项全部通过。任务 2 指定的 SDK、项目选择和调试会话 XCTest 共 14 项全部通过。波次末 Debug 全量 44 项全部通过。
- SDK 用受控可执行文件验证实际版本、FVM 优先级、失效阻断、应用激活重检、偏好重建、候选失败和恢复期锁定。FVM 配置与缓存链接格式依据 [FVM 项目与环境配置](https://github.com/btwld/fvm/blob/main/docs/pages/documentation/getting-started/configuration.mdx)。
- 设备回归验证零、一、多台，规范项目路径的会话内记忆，配置冲突，离线和同 ID 重连，扫描失败与过期回调，Android 参数顺序和不支持的应用参数阻断。
- 使用独立公开样例副本、临时 App 主目录和正常签名的 Debug 构建运行原生 AX 冒烟。缺失 FVM 缓存链接时主窗运行禁用，「打开 Flutter 设置」直达 Flutter 页。恢复链接并重新激活 App 后，设置显示「项目 FVM」、Flutter 3.47.4 和 Dart 3.13.3。
- 从主窗选择启动关机的 iPhone 17，系统清单随后显示已启动。Flutter 设备菜单出现 iPhone 17，手动选择设备和 prod 后运行按钮启用。样例配置字节一致，环境标记仍为 test，恢复记录及受管 worker 均不存在。原生证据在本机临时目录 `/tmp/flutter-runlet-phase03-fixture.TdrzUC`，见 `wave2-fvm-blocked-ax.txt`、`wave2-fvm-settings-before-ax.txt`、`wave2-fvm-repaired-ax.txt`、`wave2-device-menu-ax.txt`、`wave2-simulator-selected-ax.txt` 和 `wave2-no-launch-proof.txt`。

## 后续验证

Android 真机及模拟器上的实际 Debug 纳入 03-04 G2 验收。03-03 可用 `FlutterToolchain.availability` 区分设备可用、成功扫描确认断开和扫描失败，并通过同一 SDK 快照读取 DevTools 版本。
