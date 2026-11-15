---
phase: 07-settings-about-updates
plan: "02"
subsystem: ui
tags: [macos, swiftui, appkit, settings, flutter-doctor, update-presentation]
requires:
  - phase: 07-settings-about-updates/07-01
    provides: 批准稿图层度量、1× 原图及 V01–V05 取证索引
provides:
  - 原生设置三页和独立关于窗口
  - 共用更新展示来源、确定性 Debug 场景及可交互本地状态
  - Debug 与 Release 已复制候选和原生取证记录
affects: [07-settings-about-updates/07-03]
actuals:
  tokens: 36703
  tasks: 3
  commits: 6
plan_head_before: 38eb9d6
tech-stack:
  added: []
  patterns: [共享展示状态与用户动作接口, AppKit 窗口配合 SwiftUI 内容, 显式 Debug 取证场景]
key-files:
  created:
    - FlutterRunlet/AppTermination.swift
    - FlutterRunlet/UpdatePresentationSource.swift
    - FlutterRunlet/Assets.xcassets/RunletUpdateSpinner.imageset/image.svg
  modified:
    - FlutterRunlet/AuxiliaryWindows.swift
    - FlutterRunlet/FlutterRunletApp.swift
    - FlutterRunlet/LaunchPresentation.swift
    - FlutterRunlet/RunletAppearance.swift
    - FlutterRunlet/Localizable.xcstrings
    - FlutterRunletTests/LaunchPresentationTests.swift
    - FlutterRunletTests/FlutterToolchainTests.swift
    - FlutterRunlet.xcodeproj/project.pbxproj
key-decisions:
  - "设置与独立关于保留 AppKit 标准控件。用 SwiftUI 隐藏窗口工具栏背景并提供窗口背景色，覆盖初版设置窗口上方的灰色材质。"
  - "两处关于及应用级确认读同一个展示来源。正常版本来自 Bundle，完成样图只在显式 Debug 场景覆盖显示文字。"
  - "SDK 和 Doctor 异常从隔离的真实进程输入触发。恢复动作演示使用本地发布页及隔离 App 副本。"
patterns-established:
  - "用同一隔离 Debug 构建同时复拍冻结状态和实际点击状态。分别记录窗口身份、AX、原始 PNG、必要的 sRGB 对照和变更提交。"
requirements-completed: [UI-13, UI-14, UI-15, UPD-01, UPD-02]
coverage:
  - id: D1
    description: 原生窗口尺寸、入口共用及启动偏好
    requirement: UI-13
    verification:
      - kind: integration
        ref: FlutterRunletTests/LaunchPresentationTests.swift#testGeneralSettingsGeometryAndLaunchSwitchUseHostedPreference
        status: pass
      - kind: automated_ui
        ref: .private/phase-07/07-02/tracer6-menu-reopened.json
        status: pass
    human_judgment: true
    rationale: 核对语言菜单实体键回焦、原生控件及视觉细节。
  - id: D2
    description: 现有 SDK、FVM 与完整 Doctor 输出
    requirement: UI-14
    verification:
      - kind: integration
        ref: FlutterRunletTests/FlutterToolchainTests.swift#testChangingSDKClearsDoctorAndNextCheckUsesTheNewExecutable
        status: pass
      - kind: manual_procedural
        ref: .private/phase-07/07-02/doctor-real-output.json
        status: pass
    human_judgment: true
    rationale: 四种语言和外观组合、长路径和原生选择器细节需按冻结矩阵实拍。
  - id: D3
    description: 两处关于布局、真实 Bundle 版本、同源许可证与六个链接
    requirement: UI-15
    verification:
      - kind: automated_ui
        ref: .private/phase-07/07-02/native-links.log
        status: pass
    human_judgment: true
    rationale: 逐层字体、链接焦点和圆角边界属于视觉签核。
  - id: D4
    description: 冻结帧、连续旋转、双窗口共用状态、确认和恢复演示
    requirement: UPD-01
    verification:
      - kind: automated_ui
        ref: .private/phase-07/07-02/frozen-frames.log
        status: pass
      - kind: automated_ui
        ref: .private/phase-07/07-02/confirm-flow-repeat.log
        status: pass
    human_judgment: true
    rationale: 本波验证可达性及共享行为，逐状态的四组合对照由 07-03 签核。
  - id: D5
    description: 普通 Debug 和 Release 启动保持空闲，Release 排除 Debug 场景参数
    requirement: UPD-02
    verification:
      - kind: automated_ui
        ref: .private/phase-07/07-02/release-negative.log
        status: pass
      - kind: automated_ui
        ref: .private/phase-07/07-02/ordinary-debug.log
        status: pass
    human_judgment: false
duration: 41min
completed: 2026-11-15
status: complete
---

# 阶段 07 计划 02 · 设置、关于与更新演示

设置三页和独立关于沿用原生窗口与真实偏好、SDK、Doctor 和 Bundle。显式 Debug 场景提供共享更新展示、冻结帧、实际点击流程及独立确认和恢复反馈。

## 任务与 TDD

2026-11-15 06:27–07:08 UTC，共 3 项任务，涉及 22 个代码、测试、项目和资源文件。

| 任务 | RED | GREEN | RED 实际失败 |
| --- | --- | --- | --- |
| 通用窗口 tracer | `100a2fc` | `31a325e` | 宿主布局未给出 520 × 520 的可用固有尺寸，旧原生实拍另为 672 × 520 |
| Flutter 页 | `93b3f8b` | `e3b90c4` | 宿主 Bundle 缺少新 SDK 状态及入口的双语文案 |
| 两处关于与更新演示 | `9223f9e` | `9b7bd97` | 宿主 Bundle 缺少更新、确认、继续及访达文案 |

每项 RED 均实际执行 1 项目标宿主 XCTest，退出 65，失败来自预定断言。控制台、原始 xcresult、从 xcresult 逐项转换的 JUnit 及 `RED_EVIDENCE_OK` 结果保存在 `.private/phase-07/07-02/task{1,2,3}-red.*`。GSD 当前分支范围检查识别全部 6 项提交。

## 验证

| 验证 | 实测 | 本机记录 |
| --- | --- | --- |
| 任务 1 `LaunchPresentationTests` | 17 通过，0 失败，0 跳过 | `task1-final.xcresult` |
| 任务 2 工具链和 Flutter 调试会话套件 | 28 通过，0 失败，0 跳过 | `task2-final.xcresult` |
| 任务 3 `LaunchPresentationTests` | 24 通过，0 失败，0 跳过 | `task3-focused.xcresult` |
| Debug 全量 | 100 通过，0 失败，0 跳过，退出 0。执行 31.56 秒，结果包计时 38.97 秒 | `debug-full.log`、`debug-full.xcresult`、`debug-full.exit` |
| 普通 Release 构建 | 退出 0，App 签名完整性检查通过 | `release-build.log`、`release-build.exit` |
| 运行负例 | Release 使用完整场景参数照常启动。随后从应用菜单打开关于可见 v0.1.0 (build 1)，点击后保持待检查。Debug 仅带状态参数同样保持待检查 | `release-negative.log`、`ordinary-debug.log`、同名前缀截图与 AX |

验证机为 macOS 26.7.1、Xcode 27.1、arm64，两块显示器均为 1×。最终视觉代码提交为 `9b7bd976f3c1944ce8f3d82df14ac1f441c475a4`。入口、两份候选实际 Info.plist、二进制、资源及字体摘要见 `.private/phase-07/07-02/candidates.txt`。

## 本机候选与原生证据

- `debug/FlutterRunlet.app` 已复制。隔离包标识为 `com.atypiape.FlutterRunlet.Phase0702Debug`，实际打包 v0.2.0 (build 256) 与批准初始版本一致。`release/FlutterRunlet.app` 是已复制的普通项目 Release，实际 v0.1.0 (build 1)。两份均在 `.private/phase-07/07-02/`，候选清单将它们与阶段预检 App 区分。
- 通用 tracer 在扩展 Flutter 页前完成。主窗 AX 齿轮打开 520 × 520 的设置，主窗启动开关由 1 切为 0。关闭后点菜单栏齿轮，CG 窗口 1515 复用且仍为 0。使用相同隔离偏好重启后主窗未自动出现。证据在早期 tracer 副本及 `tracer6-general-before`、`tracer6-general-off`、`tracer6-menu-reopened`、`tracer6-relaunch.cg.json`。语言点选 English 后触发器获焦，最终 `V01-login-unavailable-en-light` 同时显示禁用开关和系统设置入口。
- Flutter 使用复制项目及本机 Flutter 3.47.4 / Dart 3.13.3 运行真实 Doctor，摘要显示 Flutter 通过、Xcode 与 Android 有环境警告。原始标准输出及标准错误面板见 `doctor-real-output`。实机目录选择器为 880 × 448，取消后「手动」获焦。最终候选接受原生选择器选中的 SDK 后出现「选路径」，之前的 Doctor 结果被清除。项目切换和下一次 Doctor 使用正确可执行文件由工具链测试覆盖。取证见 `doctor-real-native-picker`、`doctor-real-picker-cancel.ax.json`、`V02-picker-before`、`V02-picker-accept-after`、`V02-fvm-active`、`V02-fvm-off-path`。受控超时输入可取消，失败输入退出 23，分别记录了运行、取消、失败和重试，见 `native-slow-doctor-*`、`native-failed-doctor-*`。
- 最终候选实拍设置 520 × 520、独立关于 400 × 412，两处更新按钮均为 116 × 30。六个原生 AXLink 分别在默认浏览器到达仓库、README、LICENSE，见 `native-links.log`。两处许可证 AXHelp 包含同源 MIT、Svame 及上游归属。独立窗有 MIT 和 Svame 可见行。英文浅色长版本见 `V03-version-*-en-light`。
- 最终候选保留 22 张两处各 11 个中文深色冻结状态图，见 `V04-U01`–`V04-U11` 与 `frozen-frames.log`。两段连续旋转从实际点击采集，分别在 1.391 和 1.361 秒内取得 9 个不同的符号像素样本，见 `V04-live-check.json`、`V04-live-update.json`。
- 最终候选从设置启动下载，关闭两处，再解除阻塞，出现单个独立确认。「稍后」之后两处继续入口同步，确认显示时加入待恢复阻塞会回到等待，解除后通过人工继续完成演示。见 `V05-live-*`、`V05-flow-both-closed.cg.json`、`confirm-flow-repeat.log`。独立恢复反馈中，访达选中了隔离的 `Recovered FlutterRunlet.app`，默认浏览器打开本地 `release.html`。截图 `V05-recovery-feedback-zh-light`，两动作由相同最终候选的再次运行核对。

## 复拍入口

从原生可执行文件启动，保留 `CFFIXED_USER_HOME` 与 `HOME`、预建隔离的 `Library/Application Support`。同一个 Bundle ID 的偏好可在不同测试启动间保留，复拍自动 SDK 前先用「自动」清除隔离候选上次的手动路径。真实 SDK、偏好和目录选择仍走 App 实际入口。私有 `desktop.py` 已封装启动，`capture-updates.py` 与 `native-rotation.py` 可复查操作顺序。

```sh
python3 .private/phase-07/07-02/desktop.py launch --home visual-home -- \
  --phase-07-scene both --phase-07-language zh-Hans --phase-07-appearance dark \
  --phase-07-state check-2
```

- 场景为 `general`、`flutter`、`settings-about`、`about`、`both`、`install-confirm`、`recovery-feedback`。未给状态时，常规场景由待检查启动，两个独立反馈场景直接呈现相应窗口。
- V04 顺序为 `idle`、`check-1` 到 `check-4`、`available`、`update-1` 到 `update-4`、`complete`。通过 `--phase-07-version` 指定长发布版本。使用初始待检查并点击按钮，则走两段各约 3 秒的可交互动画。
- V05 可直接冻结 `current`、`no-release`、`check-failed`、`wait-debugging`、`wait-recovery-pending`、`wait-recovery-failed`、`wait-process-unconfirmed`、`wait-recovery-unreadable`、`later`、`confirm`、`confirm-race`，以及 `download-failed`、`verify-failed`、`replace-failed`、`new-launch-failed`、`old-reopen-failed`。以 `--phase-07-flow` 选择相应的检查、下载或确认结果，并通过 `--phase-07-blocker debugging` 或「阶段 07」应用菜单加入和解除阻塞。通用不可配置登录项用 `login-unavailable`。
- `--phase-07-fixtures` 接受绝对本地目录，使用目录内的 `release.html` 及 `Recovered FlutterRunlet.app`。点击仅打开或定位隔离副本。更新实现边界为 `UpdatePresentationSource.swift`，本波只有展示和内存控制状态。

## 差异与待复验

- 设置上方 32 pt 灰层在最终候选修正。通用、初始关于、完成关于和交互完成实拍的 (200,20) 与 (200,34) 归一到 sRGB 均为 `#1D2632`。SwiftUI 有时把设置窗口的系统名称设为「FlutterRunlet设置」，画面中的标题保持「设置」，按 AX 窗口标识或 CG 尺寸取证。原生交通灯和屏幕边缘系统绘制单列。四整窗对照在 `comparisons/`。
- 当前候选沿用已有字体资源。与 Figma 的字形覆盖、栅格和字重差异仍需逐层复验。选语言后回焦已证。外部键盘注入的 Escape 在本机未使语言弹层关闭，实体键路径仍待复验，记录见 `V01-language-escape.ax.json`。语言面板的原生外壳 336 × 174，内容按 310 × 148 布局。目录选择器按实际系统面板验收。
- 完整 516 行矩阵及视觉签核归 07-03。真实查询、下载、校验、替换和重启由获准后续波执行。此波使用原分支及工作区，阶段状态和路线图由主控更新。

## Self-Check: PASSED

已核对任务提交、计划范围、复制候选、全部 Debug 测试、普通 Release 和本文件列出的原生证据。待复验项已在上节具名记录。

签署：07-02 执行者，2026-11-15。
