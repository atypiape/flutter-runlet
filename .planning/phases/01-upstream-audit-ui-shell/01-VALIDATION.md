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

采用 Xcode 内建 XCTest。任务 01-01-01 创建 macOS App target、测试 target 和共享 scheme。任务 01-01-02 先加入三个启动策略用例，再实现参数解析。下列命令从仓库根目录运行，工程配置以实际生成的文件为准。派生文件、冒烟记录和测试日志保存在 `.build/phase-01/`。

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath .build/phase-01 build
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath .build/phase-01 -parallel-testing-enabled NO -only-testing:FlutterRunletTests/LaunchPresentationTests test > .build/phase-01/debug-tests.log 2>&1
grep -Eq 'Executed 3 tests?, with 0 failures' .build/phase-01/debug-tests.log
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Release -destination 'platform=macOS' -derivedDataPath .build/phase-01 build
```

## Sampling Rate

- 上游审计任务先核对固定提交、SwiftPM 清单和许可证。工程任务建立共享 scheme 后，代码任务运行相应的 Debug 构建或测试。
- 01-01-01 的 Empty 主窗重开、01-02-01 的设置与关于入口由执行者在各自首个切片当场实测。进入扩展任务前须有实际窗口结果。
- 在 G1 最终验收前运行 Debug 测试和 Release 构建。保存退出状态、实际构建设置、产物最低版本、工具链及运行系统版本。
- 构建及测试耗时由首次执行记录。

## Per-Task Verification Map

| 任务 | 计划 | Wave | 需求 | 威胁 | 自动证据 | 人工证据 | 状态 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 01-01-01 | 01-01 | 1 | BASE-01、BASE-02、BASE-03 | T-01-01 | `git -C .build/phase-01/upstream cat-file -e` 验证固定对象，检查审计 SHA、忽略规则、Debug 产物和原生冒烟记录 | 当场验证 Empty、关闭后同一进程存活、菜单栏重开及唯一主窗 | 待执行 |
| 01-01-02 | 01-01 | 1 | BASE-02 | T-01-02 | Debug XCTest 并检查日志中三个用例无失败 | 带参数启动，核对两处 Ready 固定数据 | 待执行 |
| 01-01-03 | 01-01 | 1 | BASE-02 | T-01-02 | Debug 构建和 App 可执行文件检查 | 两处 Ready Run 提示、状态保持、主窗重开和四按钮同排 | 待执行 |
| 01-02-01 | 01-02 | 2 | BASE-02 | T-01-05 | Debug 构建，核对 App、`PlistBuddy` 读出的版本和构建号、冒烟记录 | 当场验证两个设置入口、导航和独立关于窗口 | 待执行 |
| 01-02-02 | 01-02 | 2 | BASE-02 | T-01-06 | Debug 构建和 App 可执行文件检查 | 两个 Debug 交互预览的三处长字段省略与全文提示 | 待执行 |
| 01-03-01 | 01-03 | 3 | BASE-02、BASE-03 | T-01-02、T-01-03、T-01-04 | Debug 测试、Release 构建、两种配置的 `-showBuildSettings -json`、产物的 `xcrun vtool -show-build`、两张主窗 PNG 可读取 | 三种启动、A01 原生几何、主窗浅深图、API 与环境证据 | 待执行 |
| 01-03-02 | 01-03 | 3 | BASE-01、BASE-02、BASE-03 | T-01-04、T-01-05、T-01-06 | 验收记录非空及六张 PNG 可读取 | 四个界面、菜单栏几何、长字段结果、六图与上游清单复核 | 待执行 |

## Wave 0 Requirements

- [ ] 01-01-01 建立 macOS App target、共享 scheme 和 XCTest target，满足后续构建与启动策略测试的依赖。
- [ ] 01-01-02 先加入 `FlutterRunletTests/LaunchPresentationTests.swift`，实现启动策略后运行测试命令。

## Manual-Only Verifications

按 [UI 契约](01-UI-SPEC.md)验收 A01、A02、D-04 至 D-07，测量外框和面板、实测重开与导航、留存六张脱敏截图。Release 用 `--g1-ready` 复验仍为 Empty。A31 的部署目标与 API 核查继续执行，macOS 15 实机部分按 D-09 记录为未执行。各切片执行者先完成冒烟，01-03-02 集中交付阶段末用户确认的路径与证据。

## 来源覆盖

| 来源 | 范围 | 任务 |
| --- | --- | --- |
| ROADMAP、REQUIREMENTS | BASE-01 固定来源、依赖及许可和实际导入 | 01-01-01、01-03-02 |
| ROADMAP、REQUIREMENTS、CONTEXT、UI 契约 | BASE-02、A01、A02，D-01 至 D-04 的 Empty／Ready、两处共享及重开 | 01-01-01 至 01-01-03、01-03-01、01-03-02 |
| CONTEXT、UI 契约 | D-05 至 D-07 的截图、设置、关于和长字段覆盖 | 01-02-01、01-02-02、01-03-01、01-03-02 |
| ROADMAP、REQUIREMENTS、CONTEXT、RESEARCH | BASE-03、A31、D-08、D-09，原生 API 和两种配置的 macOS 15 目标证据、当前系统实测 | 01-01-01、01-03-01、01-03-02 |
| RESEARCH、PATTERNS | Swift 6 共享工程、系统场景与现有品牌素材、XCTest 及有效构建设置 | 01-01-01 至 01-01-03、01-02-01、01-03-01 |

## Validation Sign-Off

- [x] 计划任务、验证命令和证据逐项对应。
- [ ] 执行后记录首次测试耗时及证据。
- [ ] Nyquist 合规状态由执行后的验证流程填写。
