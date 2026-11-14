---
phase: 03-flutter
reviewed: 2026-11-12T16:23:20Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - FlutterRunlet.xcodeproj/project.pbxproj
  - FlutterRunlet/AuxiliaryWindows.swift
  - FlutterRunlet/FlutterDebugSession.swift
  - FlutterRunlet/FlutterRunletApp.swift
  - FlutterRunlet/FlutterToolchain.swift
  - FlutterRunlet/MainWindowView.swift
  - FlutterRunlet/MenuBarPanelView.swift
  - FlutterRunlet/SessionController.swift
  - FlutterRunlet/SessionProcess.swift
  - FlutterRunletSessionWorker/main.swift
  - FlutterRunletTests/FlutterDebugSessionTests.swift
  - FlutterRunletTests/FlutterToolchainTests.swift
  - FlutterRunletTests/SessionLogTests.swift
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---

# Phase 03 · 代码审查

## Summary

按标准深度审查基线 `b7f5b6d` 至候选 `9300b9c` 的 13 个文件，核对 SDK 探测、设备判定、受管进程与恢复、机器协议、日志及相关回归。发现一次扫描漏报可结束当前会话，以及两处日志保留边界错误。工程文件通过 `plutil -lint`。本报告引用候选的 G2 与 XCTest 记录，未重新执行全量测试。

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: 一次设备漏报会停止仍可用的调试会话

**File:** `FlutterRunlet/FlutterToolchain.swift:138-142`

**Issue:** 设备列表缺少当前 ID 即返回 `.disconnected`。受测 Flutter 3.47.4 的 `xcdevice list` 子探测失败会变成 iOS 空列表，外层 `flutter devices --machine` 仍能返回成功和合法 JSON。`SessionController` 会立即将仍有可用 VM Service 的真机会话标为断开，发送 Stop 并执行适用的后置恢复。当前回归只区分外层抛错和列表缺少设备，漏报会走确认断开的分支。 [设备监控](../../../../FlutterRunlet/SessionController.swift#L1036) · [现有回归](../../../../FlutterRunletTests/FlutterDebugSessionTests.swift#L272) · Flutter 外层成功返回（SDK 内 `packages/flutter_tools/lib/src/commands/devices.dart:77`） · iOS 子探测返回空列表（SDK 内 `packages/flutter_tools/lib/src/macos/xcdevice.dart:451`）

**Fix:** 将列表缺少设备视为待确认。收到明确的平台断开状态才直接停止。没有明确状态时结合当前 VM 探测及连续缺席复验，保留仅有一次漏报且 VM 仍正常的会话。补测外层查询成功、一次缺少当前设备、下次扫描恢复的情况。

### WR-02: 裁剪日志头部会移动仍保留的阅读行并丢失选区

**File:** `FlutterRunlet/MainWindowView.swift:293-300`

**Issue:** 日志到达 64 KiB 后，追加内容会移除旧前缀。视图仍沿用旧文档的像素偏移，并因新内容不再以旧字符串开头而丢弃选区。即使用户正在阅读的行和选中文字都还留在缓冲内，连续追加也会将它们移走，违反 D-15。 [缓冲裁剪](../../../../FlutterRunlet/SessionController.swift#L1048) · [阅读位置契约](03-CONTEXT.md#L44)

**Fix:** 将本轮日志裁剪的前缀长度随快照交给视图。非跟随模式按仍存在的首个可见字符重新定位，换算仍在缓冲内的选区范围。阅读锚点确实被裁掉时移动到最早保留的行。补测超过 64 KiB 后持续追加时仍保留的阅读行。

### WR-03: 监督进程启动成功会提前清空上一轮日志

**File:** `FlutterRunlet/SessionController.swift:1000-1002`

**Issue:** 清空发生在监督进程创建完成时，此时执行进程尚未派发。权限正确的 process 前置脚本可能因解释器缺失而在 worker 中得到 `.launchFailed(ENOENT)`。本机用临时可执行脚本核对了可执行权限成立且 Darwin `posix_spawn` 返回 `ENOENT` 的行为。新一轮任务未执行，旧日志仍已丢失，违反 D-13。 [监督进程回调](../../../../FlutterRunlet/SessionProcess.swift#L206) · [实际任务派发](../../../../FlutterRunletSessionWorker/main.swift#L32) · [日志保留契约](03-CONTEXT.md#L42)

**Fix:** 复用 worker 的启动回执确认首个前置或调试子进程确实启动，再清空旧日志。协调启动回执和首批输出，避免成功启动后的首批日志被清空。补测 worker 已启动、首个命令派发失败、上一轮日志保留的情况。
