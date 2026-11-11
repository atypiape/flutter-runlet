---
phase: "01"
slug: "upstream-audit-ui-shell"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-12"
---

# Phase 1 · 验证策略

## Test Infrastructure

采用 Xcode 内建 XCTest。首个工程任务创建 macOS App target、测试 target 和共享 scheme。下列命令从仓库根目录运行，工程配置以实际生成的文件为准。

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath .build/phase-01 build
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath .build/phase-01 test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Release -destination 'platform=macOS' -derivedDataPath .build/phase-01 build
```

## Sampling Rate

- 上游审计任务先核对固定提交、SwiftPM 清单和许可证。工程任务建立共享 scheme 后，代码任务运行相应的 Debug 构建或测试。
- 在 G1 手工验收前运行 Debug 测试和 Release 构建。保存退出状态、实际构建设置、产物最低版本、工具链及运行系统版本。
- 构建及测试耗时由首次执行记录。

## Per-Task Verification Map

| 需求 | 自动证据 | 人工证据 |
| --- | --- | --- |
| BASE-01 | 核对固定 Git 对象中的源码、`Package.swift` 和 `LICENSE` | 核对模块取舍、实际导入清单与随导入保留的许可 |
| BASE-02 | 共享 scheme 下的 Debug 构建与关键启动策略测试 | Empty、Ready、原生提示、窗口唯一性、设置导航、关于信息和六张截图 |
| BASE-03 | Debug 和 Release 的 `-showBuildSettings` 与二进制 `xcrun vtool -show-build` | 记录 API 可用性及替代路径，在当前系统实测窗口 |

## Wave 0 Requirements

- [ ] 在最早的工程任务建立 macOS App target、共享 scheme 和最小 XCTest target，满足后续构建与启动策略测试的依赖。

## Manual-Only Verifications

按 [UI 契约](01-UI-SPEC.md)验收 A01、A02、D-04 至 D-07，测量外框和面板、实测重开与导航、留存六张脱敏截图。Release 用相同的专用参数复验仍为 Empty。A31 的部署目标与 API 核查继续执行，macOS 15 实机部分按 D-09 记录为未执行。

## Validation Sign-Off

- [ ] 计划任务、验证命令和证据逐项对应。
- [ ] 执行后记录首次测试耗时及证据。
- [ ] Nyquist 合规状态由执行后的验证流程填写。
