---
phase: 06-main-window-menu-bar
plan: "03"
subsystem: session-lifecycle
tags: [swiftui, recovery, xctest]
provides:
  - 两处原位恢复反馈及只重试原任务
  - 主窗恢复后重新验证并启动所选配置
  - 日志复制、清空、展开和折叠图标
affects: [06-04]
actuals:
  tasks: 3
  commits: 4
  plan_head_before: 41fb764b4b43dda8fb771af7ce72189a88a55852
tech-stack:
  added: []
key-files:
  modified:
    - FlutterRunlet/SessionController.swift
    - FlutterRunlet/MainWindowView.swift
    - FlutterRunlet/MenuBarPanelView.swift
    - FlutterRunlet/FlutterRunletApp.swift
    - FlutterRunlet/Localizable.xcstrings
    - FlutterRunletTests/ProjectRecoveryTests.swift
    - FlutterRunletTests/SessionLifecycleTests.swift
    - FlutterRunletTests/FlutterDebugSessionTests.swift
    - FlutterRunletTests/LaunchPresentationTests.swift
requirements-completed: [RUN-08, RUN-09, UI-08, UI-12]
completed: 2026-11-14
status: complete
---

# 06-03 · 恢复、重试与主窗口日志

两处快速重试都只调用原恢复任务。主窗原状态区显示结构化任务结果，只有真实退出状态含退出码时才展示该数字。菜单栏状态标签左侧提供同款青色重试。待打开恢复项目和风险记录异常仍有原入口和原因。运行条件满足时主窗显示恢复后启动的提示。主窗和面板各自注册快捷键来源，恢复失败时 F5 的行为与各自运行按钮一致。

主窗恢复和接续持有同一项目租约，由同一个操作完成。持久清除确认后及异步设备预检结束后再次确认风险库、项目、配置、设备与退出状态。退出确认立即取消新启动意图，等现有恢复任务结束。项目切换与重复运行或重试在整个操作期间禁用。

日志栏使用同色的复制、清空、折叠图标，展开时箭头朝下，收起时朝右。沿用原日志缓冲、脱敏与清空边界，恢复详情留在日志之外。两处顶部补齐现有品牌图标，历史移除用垃圾桶，主窗和面板的历史与设备弹层关闭后尝试将焦点交还打开按钮。原生结果由 06-04 实测。

## 验证

| 检查 | 结果 |
| --- | --- |
| RED | 新恢复操作及结构化结果尚不存在，新增测试未通过编译 |
| 六个目标套件 | 58 项通过，0 失败、0 跳过。之后补充的配置编辑与离线用例在全量执行 |
| Debug 全量 | 89 项通过，0 失败、0 跳过，执行 29.96 秒 |
| 差异检查 | git diff --check 通过 |

恢复回归覆盖真实退出码 1、继续失败保留原风险、只重试原任务、恢复库不可读、风险持久确认失败、所选配置或设备变化、租约、恢复与启动预检中的退出请求，以及菜单栏和主窗快捷键意图。日志回归覆盖清空边界、可继续追加与复制脱敏结果，双语回归覆盖恢复提示和日志操作名称。

全量 Xcode 结果包为 `Test-FlutterRunlet-2026.11.14_23-27-22-+0800.xcresult`，保存在本机第三波 Debug 构建目录。

## Task Commits

1. **Task 1: 原位恢复反馈与单独重试** - `e058ab6` (test), `48b2cb2` (feat)
2. **Task 2: 从主窗恢复后重新预检并启动** - `e058ab6` (test), `48b2cb2` (feat), `97865d3` (fix), `acf2cf6` (test)
3. **Task 3: 可访问的日志工具栏** - `48b2cb2` (feat)
