---
phase: 04-macos
plan: "02"
subsystem: ui
tags: [swiftui, appkit, recovery, localization, keyboard]
requires:
  - phase: 04-macos
    provides: 持久语言偏好和延迟解析的会话文案
provides:
  - 主窗及菜单栏共享恢复原因、目标与操作守卫
  - 主窗及菜单栏的独立全名入口和本地调试快捷键
  - 配置、恢复存储、进程与 SDK 内部错误的双语资源
affects: [04-03, 04-05]
actuals:
  tokens: 54612
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns: [AppKit 本地事件监听, SwiftUI Popover, LocalizedStringResource]
key-files:
  created: []
  modified: [FlutterRunlet/SessionController.swift, FlutterRunlet/FlutterRunletApp.swift, FlutterRunlet/MainWindowView.swift, FlutterRunlet/MenuBarPanelView.swift, FlutterRunlet/ProjectConfiguration.swift, FlutterRunlet/ProjectRecoveryStore.swift, FlutterRunlet/JSONCReader.swift, FlutterRunlet/FlutterToolchain.swift, FlutterRunlet/SessionProcess.swift, FlutterRunlet/Localizable.xcstrings]
key-decisions:
  - 恢复原因独立于通用消息，共用原项目和任务守卫。
  - 原生键盘事件由一处 AppKit 本地监听派发，只接受受管窗口键盘焦点。
patterns-established:
  - 按钮与键盘均调用同一 DebugAction 守卫。
  - 配置及任务错误沿调用链保留资源，嵌套原因在展示时翻译。
requirements-completed: [UI-01, UI-02]
coverage:
  - id: D1
    description: 两处呈现相同恢复失败原因和动作，折叠日志后可从菜单栏重试原任务。
    requirement: UI-01
    verification:
      - kind: integration
        ref: FlutterRunletTests/ProjectRecoveryTests.swift#testFailedPostRestartAndExplicitRetryUseOriginalLabelAndDefinition
        status: pass
      - kind: integration
        ref: FlutterRunletTests/ProjectConcurrencyTests.swift
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-02.1TethI/recovery-main-folded.ax
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-02.1TethI/recovery-retried.ax
        status: pass
    human_judgment: false
  - id: D2
    description: 四键映射、重复按键和会话状态共用生产守卫。
    requirement: UI-01
    verification:
      - kind: integration
        ref: FlutterRunletTests/FlutterDebugSessionTests.swift
        status: pass
    human_judgment: false
  - id: D3
    description: 实际窗口焦点、两种语言的四键布局及全名交互。
    requirement: UI-01
    verification:
      - kind: automated_ui
        ref: /tmp/runlet-04-02.1TethI/f5-wait-or-running.ax
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-02.1TethI/panel-stop-by-f5.ax
        status: pass
      - kind: automated_ui
        ref: /tmp/runlet-04-02.1TethI/full-config.ax
        status: pass
    human_judgment: true
    rationale: 真实连接后的两项热操作、仅菜单栏模式、日志焦点、后台无动作、悬停和 Tab 仍需候选复验。
  - id: D4
    description: 同一配置及恢复错误可按当前语言解析，原始位置、任务名、退出码和环境变量名保留。
    requirement: UI-02
    verification:
      - kind: integration
        ref: FlutterRunletTests/ProjectConfigurationTests.swift
        status: pass
      - kind: integration
        ref: FlutterRunletTests/ProjectRecoveryTests.swift
        status: pass
      - kind: integration
        ref: FlutterRunletTests/FlutterToolchainTests.swift
        status: pass
    human_judgment: false
duration: 11min
completed: 2026-11-13
status: complete
---

# Phase 04 Plan 02 · 共享恢复、全名、功能键及双语错误

**主窗和菜单栏共用恢复与调试动作，锁定选择时仍可查看原名，配置和运行错误随当前语言更新。**

## Accomplishments

- 恢复原因与项目切换等通用提示分开保存。打开待恢复项目后仍需明确点击重试，原任务、租约、持久记录和进程退出守卫沿用生产实现。
- 四个调试键统一由受管主窗或菜单栏面板的 AppKit 本地事件派发。键盘与原生按钮共用动作与启用条件。选择器外提供独立全名按钮，原始名称在可选择的 Popover 显示。
- JSONC、启动配置、任务、恢复、进程和 SDK 错误携带待渲染资源，嵌套错误保留原始参数。JSONC 保留文件、行列，恢复保留任务名与退出码，环境变量校验只显示变量名。

## Task Commits

1. 共享恢复原因和动作。RED `e8633b2`，GREEN `4754df1`。
2. 受管窗口功能键和全名入口。RED `b9c6e1d`，GREEN `98c7111`。
3. 配置与工具链结构化错误。RED `2b9de30`，GREEN `69d6c3b`。

三次 RED 分别断言恢复原因被切换项目覆盖、F5 映射缺失和英文 JSONC 错误仍为中文。保留原始 xcresult 与日志，从报告生成 JUnit 后均通过 GSD `RED_EVIDENCE_OK`。

## 验证

- ProjectRecoveryTests 与 ProjectConcurrencyTests 共 13 项通过，FlutterDebugSessionTests 9 项通过，配置、工具链、恢复与调试定向共 34 项通过。证据目录 `/tmp/runlet-04-02.1TethI` 含 `recovery-green.xcresult`、`keys-final.xcresult` 和 `errors-green.xcresult`。
- macOS 26.7.1 上，运行 `98c7111` 对应的隔离重签 Debug 副本，使用独立的公开 iOS 样例、加长项目及 prod 配置名称、已启动的 iPhone 18 Pro。AX 从主窗选择设备和配置，前台投递 F5 后真实 Flutter 进入 Waiting for VM Service。Run 禁用、Stop 可用、热操作禁用。前台菜单栏面板收到 Shift+F5 后两处同步为 Stopping。锁定的主窗配置选择器旁，全名按钮仍可打开包含完整配置原名的 Popover。见 `f5-wait-or-running.ax`、`full-config.ax`、`panel-stop-by-f5.ax`。
- 独立样例故意令原 post 退出 1。两处显示同一失败原因、原任务名和重试。折叠主窗日志后从菜单栏重试，恢复标记为 test，主窗显示 Ready，风险记录清除，配置与脚本哈希保持。见 `recovery-main-folded.ax`、`recovery-retried.ax`、`fixture-before.sha256`。
- 上述原生运行在 VM Service 连接前停止。实际热重载、热重启和完全关闭主窗后的四键，连同日志焦点、后台、Tab、悬停及两种系统外观，留待最终候选复验。测试覆盖连接后操作的生产守卫及发送到当前会话。

## Deviations from Plan

- 菜单栏使用系统提供的 accessory 面板。AppKit 本地监听随第一个受管窗口登记安装，以键盘事件目标和当前键窗为边界，背景 App 的键盘事件不会进入监听。保留系统 VoiceOver 与常规导航。
- 恢复和结构化错误共用原有生产路径，附带调整了工具链测试的语言断言，使测试不受系统语言影响。恢复记录和任务协议结构保持。

## Next Phase Readiness

04-03 可复用恢复记录和共享动作守卫。04-05 可复用独立样例、原生 AX 探针与故障标记。UI-01 和 UI-02 由共享需求门禁等待 04-05。
