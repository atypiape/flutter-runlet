---
phase: 05-stability-recovery-release
reviewed: 2026-11-13T18:02:39Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - FlutterRunlet/FlutterDebugSession.swift
  - FlutterRunlet/MainWindowView.swift
  - FlutterRunlet/ProjectConfiguration.swift
  - FlutterRunlet/SessionController.swift
  - FlutterRunletTests/SessionLifecycleTests.swift
  - FlutterRunletTests/SessionLogTests.swift
  - docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 05 · 代码审查

## Summary

审查 `6ea2cfe` 到 `c80ec88` 的六个源文件，并复审 `36916dd` 的日志修复和回归测试。核对 VM Service 探活的端点绑定、请求 ID、超时和取消路径，以及日志代际、裁剪和恢复任务。样例脚本通过 `sh -n`，SHA-256 与 Debug 入口配置一致。CR-01 已通过修复代码的静态复审和本机 Foundation 字面比较检查，修正版 XCTest 和候选复验由本轮主执行记录。

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: 日志增量更新可用错误的 UTF-16 偏移截取新文本

**File:** `FlutterRunlet/MainWindowView.swift:373`（`c80ec88`）

**Issue:** Swift `String` 的相等和前缀判断接受规范等价字符。两个原始编码不同、规范等价的 64 KiB 日志快照可由普通任务的 stdout 分批产生。第二次快照使裁剪位置前进，旧视图仍因规范等价保留第一份编码。第三次追加使字面内容发生变化后，增量分支将旧视图的 UTF-16 长度传给新快照的 `NSString.substring(from:)`。本机 Swift 核对的两份合成快照均为 65,536 字节，第三次快照的 UTF-16 长度为 36,871，实际计算的偏移为 45,053，超出可用范围。基线遇到第三次更新会完整替换文本，越界截取由本阶段新增的增量分支引入。

**Fix:** `36916dd` 使用 `NSString.isEqual(to:)` 判断字面相等，并用 UTF-16 码元验证可保留的字面前缀。复审确认旧编码会在第二次快照更新时被替换，第三次快照的相同前缀可安全截取。前缀不匹配时执行完整替换。新增 `testLogViewReplacesCanonicallyEquivalentTextBeforeTrimmingAgain` 覆盖全量替换与随后追加。原候选定向测试在旧编码仍保留的断言失败，修正版通过本机 Swift 独立核对字面相等、前缀和后缀。 [修正实现](../../../../FlutterRunlet/MainWindowView.swift#L354) · [定向回归](../../../../FlutterRunletTests/SessionLogTests.swift#L255)

## Warnings

### WR-01: 旧版 Debug 样例的挂起恢复在新构建中会被摘要校验拒绝

**File:** `FlutterRunlet/ProjectConfiguration.swift:8`

**Issue:** Debug 验收入口沿用原命名空间和恢复库，只接受新样例脚本的 SHA-256。已有隔离样例仍保留基线脚本时，新构建在准备原任务时拒绝该脚本，原有模拟风险记录会保留并等待可接受的原任务。该限制只作用于固定根的 Debug 夹具。 [任务校验](../../../../FlutterRunlet/ProjectConfiguration.swift#L41) · [恢复重试](../../../../FlutterRunlet/SessionController.swift#L456)

**Fix:** 本阶段沿用计划指定的当前脚本摘要。若旧 Debug 夹具仍有风险记录，用与旧脚本匹配的 Debug 构建重试原任务并核对恢复完成。新回合从当前候选复制独立公开样例。若以后要求旧夹具跨构建恢复，可在现有路径、参数和状态校验下允许两份已知摘要。
