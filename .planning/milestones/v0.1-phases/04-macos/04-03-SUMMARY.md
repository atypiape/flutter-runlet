---
phase: 04-macos
plan: "03"
subsystem: ui
tags: [swiftui, appkit, servicemanagement, flutter, fvm, xctest]
requires:
  - phase: 04-macos
    provides: 共享原生窗口、恢复入口与即时双语资源
provides:
  - 主窗启动偏好、待恢复启动和菜单栏重开
  - 系统登录项状态及用户主动注册和取消
  - 实际 Flutter SDK 的环境检测、摘要和双流输出
affects: [04-04, 04-05]
actuals:
  tokens: 16986
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns: [SceneLaunchBehavior, SMAppService, 独立诊断进程组]
key-files:
  created: []
  modified: [FlutterRunlet/FlutterRunletApp.swift, FlutterRunlet/AuxiliaryWindows.swift, FlutterRunlet/SessionController.swift, FlutterRunlet/FlutterToolchain.swift, FlutterRunlet/Localizable.xcstrings, FlutterRunletTests/LaunchPresentationTests.swift, FlutterRunletTests/FlutterToolchainTests.swift]
key-decisions:
  - 主窗启动判断读取已发现的恢复状态，主窗关闭时仍保留菜单栏和同一会话。
  - 登录项仅在用户显式操作时修改，显示以 ServiceManagement 查询结果为准。
  - 环境检测使用已选 SDK、独立目录、25 秒及两路合计 1 MiB，取消或越界时回收进程组。
patterns-established:
  - AppKit 重开与菜单栏使用同一主窗入口。
  - Flutter doctor 结果绑定请求、项目及实际 SDK，变更时取消并丢弃旧请求。
requirements-completed: [UI-03, UI-04]
coverage:
  - id: D1
    description: 主窗偏好持久化、仅菜单栏启动、手动重开和待恢复优先。
    requirement: UI-03
    verification:
      - kind: integration
        ref: FlutterRunletTests/LaunchPresentationTests.swift#testMainWindowLaunchPreferencePersistsAndRecoveryTakesPriority
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-03.b9Mfdo/startup-suppressed.state
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-03.b9Mfdo/startup-recovery-before-action.ax
        status: pass
    human_judgment: false
  - id: D2
    description: 登录项状态、显式注册和取消、待批准、重新查询和异常。
    requirement: UI-03
    verification:
      - kind: integration
        ref: FlutterRunletTests/LaunchPresentationTests.swift#testLoginItemUsesSystemStatusAndOnlyWritesOnExplicitChanges
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-03.b9Mfdo/login-before.ax
        status: pass
    human_judgment: true
    rationale: 本机无可用代码签名身份，隔离重签副本的系统登录项返回不可用，仍需有效安装的候选验证系统注册与实际重新登录。
  - id: D3
    description: 实际 FVM 版本、调试所用 SDK、锁定和无效 FVM 阻断。
    requirement: UI-04
    verification:
      - kind: integration
        ref: FlutterRunletTests/FlutterToolchainTests.swift
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-03.b9Mfdo/fvm-settings.ax
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-03.b9Mfdo/fvm-invalid.ax
        status: pass
    human_judgment: false
  - id: D4
    description: 真实 doctor 的三类摘要、完整输出、取消重试和有界进程。
    requirement: UI-04
    verification:
      - kind: integration
        ref: FlutterRunletTests/FlutterToolchainTests.swift
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-03.b9Mfdo/fvm-doctor-output.ax
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-03.b9Mfdo/fvm-doctor-cancel.ax
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-11-13
status: complete
---

# Phase 04 Plan 03 · 原生启动和实际 SDK 诊断

**通用设置管理主窗启动与系统登录项。Flutter 设置用实际选中的 SDK 检测环境，并提供双语摘要与完整输出。**

## Accomplishments

- 主窗偏好与最近项目偏好独立持久化。启动发现恢复记录或记录读取异常时显示主窗。恢复任务仍等待用户主动操作。
- 登录项保留系统已有状态，启动仅查询，通用页操作后刷新。待批准、系统找不到应用和调用错误有对应提示及系统设置入口。
- Flutter 设置显示实际 SDK 来源、路径、Flutter/Dart 版本和经验证的项目 FVM 版本。用户可主动检测环境。超时、取消、截断、启动失败与退出状态有对应反馈，成功捕获的输出仍可查看。
- 环境检测使用绝对 SDK、固定参数、安全 PATH 与独立工作目录。两路轮流非阻塞读取，合计最多 1 MiB，25 秒后或取消时终止独立进程组并回收。诊断输出只呈现在设置，切换项目或 SDK 丢弃旧结果。

## Task Commits

1. 启动偏好与待恢复。RED `8b170e7`，GREEN `3b56076`，定向 21/21。
2. 系统登录项。RED `97db420`，GREEN `0c25a3f`，定向 12/12。
3. 实际 SDK 环境检测。RED `a19619c`，GREEN `f2f64d6`，定向 22/22。

三次 RED 分别复现双语主窗启动偏好、登录项批准指引和环境检测入口缺失。原始 XCTest 日志与 xcresult 保留，从实际报告生成 JUnit 后三次均获 GSD `RED_EVIDENCE_OK`。GREEN 扩展验证偏好组合、系统状态和进程边界。

## 验证

- macOS 26.7.1、Xcode 27.1。隔离重签 Debug 候选默认激活策略 regular 且有一扇主窗。关闭启动开关后重启为 accessory 且主窗数为 0，原生状态栏仍在。从菜单栏打开变为 regular 且主窗数为 1，重复打开仍为 1。关闭主窗变回 accessory，从 Launch Services 重开恢复 regular 及唯一主窗。波次证据目录为 `/tmp/runlet-04-03.b9Mfdo`。
- 独立公开样例在 prod 后置任务失败时保留一条恢复记录和 prod 标记。关闭两个启动开关后重启，仍显示一扇主窗、无自动打开项目、显示原任务及打开待恢复项目入口。打开项目后仍为 prod，显式重试后才恢复 test。见 `startup-recovery-*`。
- 用独立 bundle identifier 的重签副本观察到系统返回不可用、开关禁用和系统设置入口。有效安装后的实际注册、批准、取消及登录启动待复验。定向测试通过窄接口覆盖用户切换、实际状态读取和异常。
- 有效项目 FVM 在设置显示 3.47.4、Dart 3.13.3 及 FVM 版本；真实 iOS 样例的 Flutter run 进程使用该 SDK。会话期间 FVM、路径和环境检测控件禁用。暂换隔离样例 FVM 链接后验证提示及 Run 禁用，最后还原链接、标记和模拟器启动状态。
- 真实 Flutter doctor 的 Flutter 通过，Xcode 与 Android Toolchain 显示警告，对应输出 `[✓]`、`[!]`、`[!]`。英文原生输出窗口分别显示两路输出，标准错误为空。用户主动取消出现原因及重试，重试重新得到摘要。可控脚本覆盖非零退出、双流大输出、超限、超时、启动失败和切换项目后的取消及进程回收。

## Deviations from Plan

- 为保证关闭主窗偏好后仍能通过 Launch Services 重开，AppKit 重开回调复用原有窗口定位与去重，Settings 和 About 场景禁用系统恢复以维持仅菜单栏启动。
- 正常模式诊断输出的原生 sheet 实测没有自动继承设置界面的语言。已显式注入同一 locale，复验英文摘要和输出窗口。
- 宿主无有效代码签名身份。系统登录项不可用路径已实测，实际注册和重新登录仍需有效安装候选。UI-03 和 UI-04 的完成标记等共享需求门禁允许后再更新。

## Next Phase Readiness

04-04 可直接补关于和品牌。04-05 可复用启动、恢复、FVM 及 doctor 探针，对最终候选复验系统外观、Dock 实际图标和系统登录项。
