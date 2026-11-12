---
phase: 02-config-task-execution-core
reviewed: 2026-11-12T08:00:17Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - FlutterRunlet.xcodeproj/project.pbxproj
  - FlutterRunlet/AuxiliaryWindows.swift
  - FlutterRunlet/FlutterRunletApp.swift
  - FlutterRunlet/JSONCReader.swift
  - FlutterRunlet/MainWindowView.swift
  - FlutterRunlet/MenuBarPanelView.swift
  - FlutterRunlet/ProjectConfiguration.swift
  - FlutterRunlet/ProjectRecoveryStore.swift
  - FlutterRunlet/SessionController.swift
  - FlutterRunlet/SessionProcess.swift
  - FlutterRunletSessionWorker/main.swift
  - FlutterRunletTests/ProjectConcurrencyTests.swift
  - FlutterRunletTests/ProjectConfigurationTests.swift
  - FlutterRunletTests/ProjectRecoveryTests.swift
  - FlutterRunletTests/ProjectSelectionTests.swift
  - FlutterRunletTests/SessionLifecycleTests.swift
findings:
  critical: 2
  warning: 4
  info: 0
  total: 6
status: issues_found
---

# Phase 02 · 代码审查

审查范围为 `a61e76d..911662d` 的 16 个工程、实现和测试文件。核对配置校验、Debug 验收边界、锁租约交接及恢复记录的读写顺序。现有 29 项 XCTest 的结果引用阶段验收记录。本轮通过源码追踪确认发现，未另行运行 App 或测试。

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: 项目目录被替换后自动后置可能清除原项目风险

**级别** BLOCKER

**位置** [SessionController.swift:302](../../../FlutterRunlet/SessionController.swift#L302)、[SessionController.swift:415](../../../FlutterRunlet/SessionController.swift#L415)、[ProjectRecoveryStore.swift:119](../../../FlutterRunlet/ProjectRecoveryStore.swift#L119)、[main.swift:5](../../../FlutterRunletSessionWorker/main.swift#L5)。

**问题** Run 按原目录的设备号与 inode 加锁，监督进程的每次派发仍按字符串路径进入工作目录。调试运行时若用户把原目录移走并把另一个项目放到同一路径，自动后置会使用旧快照中的路径操作新项目。验收模式的后置检查确认路径、样例脚本和状态文件，未核对最初的项目身份。新项目任务返回 0 后，删除记录只按路径计算文件名，可清除原项目的风险记录，原项目仍处于 prod。

**修复** 自动后置派发和清除前核验记录的目录身份，并让派发后的工作目录使用已验证的句柄或由监督进程核对同一身份。路径指向发生变化时保留记录并阻断。增加运行中改名并用另一项目占据原路径的回归，断言两个项目状态及旧记录。

### CR-02: macOS 启动覆盖被静默忽略

**级别** BLOCKER

**位置** [ProjectConfiguration.swift:176](../../../FlutterRunlet/ProjectConfiguration.swift#L176)、[ProjectConfiguration.swift:193](../../../FlutterRunlet/ProjectConfiguration.swift#L193)。

**问题** 解析器只检查顶层 `flutterMode` 并默认 Debug，随后从 `osx` 读取 `env`，静默丢弃其它 macOS 覆盖字段。例如 `osx.flutterMode` 为 `profile` 的配置仍可生成 Debug 计划并派发前置任务。当前范围只定义了 `osx.env`，未支持的模式、入口和设备覆盖应明确拒绝。

**修复** 解析 `osx` 后验证允许的字段，或者先应用已明确支持的 macOS 覆盖再校验实际模式。增加带前置任务的 `osx.flutterMode: profile` 回归，断言配置保留名称但禁止派发。

## Warnings

### WR-01: 另一实例已恢复后，本实例可能无法正常退出

**级别** WARNING

**位置** [SessionController.swift:23](../../../FlutterRunlet/SessionController.swift#L23)、[SessionController.swift:228](../../../FlutterRunlet/SessionController.swift#L228)、[FlutterRunletApp.swift:206](../../../FlutterRunlet/FlutterRunletApp.swift#L206)。

**问题** 两个实例都加载待恢复记录后，先恢复的实例成功移除记录。另一个实例重试时读到 `nil`，进入「请重新启动应用后核对」分支并保留内存中的旧记录。退出裁决又因旧记录拒绝正常退出，界面要求重启却未提供正常重启路径。

**修复** 在租约内区分记录不存在、被更新及读取失败，刷新恢复列表并显示当前状态。若缺失记录不足以证明恢复，可保留可验证的完成证据供第二实例读取。补充两个控制器先后重试的回归。

### WR-02: 组长退出后 Stop 无法处理拒绝退出的同组进程

**级别** WARNING

**位置** [main.swift:36](../../../FlutterRunletSessionWorker/main.swift#L36)、[main.swift:50](../../../FlutterRunletSessionWorker/main.swift#L50)、[SessionController.swift:336](../../../FlutterRunlet/SessionController.swift#L336)。

**问题** 监督进程先回收组长，随后只在 `leader == nil` 时传递 TERM 和三秒后的 KILL。如果包装进程先退出，剩余同组进程将一直被动等待。即使 Stop 的 TERM 先送达并让组长退出，忽略 TERM 的后代也无法触发当前升级分支。控制器禁用 Stop 并持续显示「正在停止」，正常退出请求也一直等待。

**修复** 继续持锁，直到确认执行组退出。通过监督层保留可验证的组身份后再处理信号升级。若仍无法确认安全终止，向控制器报告明确的等待或受阻原因。增加组长自然退出和 TERM 后退出、同组后代拒绝结束的回归。

### WR-03: Flutter 项目判定拒绝合法 YAML 并接受无关标记

**级别** WARNING

**位置** [ProjectConfiguration.swift:16](../../../FlutterRunlet/ProjectConfiguration.swift#L16)。

**问题** 项目判断只搜索未引号包裹的独立 `sdk: flutter` 行。合法的 `sdk: "flutter"` 或流式 `dependencies: {flutter: {sdk: flutter}}` 会被拒绝。自定义字段或 YAML 多行标量中的同样文本又可能被当作 Flutter 依赖。

**修复** 读取 YAML 中 `dependencies.flutter.sdk` 的实际值。对目前无法正确解析的表示给出具体诊断，并为引用值、流式映射和多行标量增加边界覆盖。

### WR-04: 恢复记录删除失败时回补也可能失败

**级别** WARNING

**位置** [ProjectRecoveryStore.swift:126](../../../FlutterRunlet/ProjectRecoveryStore.swift#L126)、[ProjectRecoveryStore.swift:132](../../../FlutterRunlet/ProjectRecoveryStore.swift#L132)。

**问题** 清除先执行 `unlink`，然后同步目录。同步失败后以 `try?` 回写原记录。存储持续故障时回写同样可能失败，内存里仍显示待恢复，但重启后可能已无原记录。现有 `.removal` 注入只覆盖第一次失败，未覆盖回补写入也失败。

**修复** 使用认证的完成记录与可区分的保留状态，或用可重启识别的暂存记录保证同步失败时仍可发现。保留回补错误并测试清除和回补连续失败。
