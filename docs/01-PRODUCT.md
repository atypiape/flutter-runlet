# 01 · 产品需求（PRD）— FlutterRunlet v0.1

状态：**v0.1 需求基线，G0 最终视觉验收已通过**。仓库：`flutter-runlet`。平台：macOS。[视觉基线](design/FIGMA-HANDOFF.md#最终原型与播放入口)

## 1. 产品定义

FlutterRunlet 是一个无需启动 VS Code / Android Studio 的轻量 Flutter 运行与调试控制台。为使用 Codex、Claude Code、Zed、终端或其他编辑器的 Flutter 开发者提供「**选择 Flutter 项目 → 从原有 VS Code 配置选启动环境 → 选设备 → 启动/热重载 → 浏览器 DevTools Inspector**」的最短路径。

**成功标准**：打开 FlutterRunlet 后，使用现有项目的 `.vscode` 配置就能完成日常调试，不必在 FlutterRunlet 中重复维护 dev/test/prod 环境变量或 Firebase 脚本。

## 2. 已确认（不可擅改）

| ID | 需求 / 决策 | 说明 |
|---|---|---|
| P-01 | `flutter-runlet` / FlutterRunlet | 仓库/显示名已定 |
| P-02 | macOS 原生 Swift | SwiftUI 优先，AppKit 按需补充。参考 Flutter GUI Runner 的共享场景设计，独立实现 |
| P-03 | 从 `.vscode/launch.json` 加载配置 | 按 `name` 原样显示，来源单一 |
| P-04 | 从 `.vscode/tasks.json` 执行任务 | 服从 `preLaunchTask`、`postDebugTask`，特别是 Firebase 任务 |
| P-05 | 选择 Flutter 设备 | iOS 和 Android 模拟器及真机、macOS 桌面在可用时显示 |
| P-06 | 仅支持 Debug 运行会话 | Run / Stop / Hot Reload / Hot Restart、状态、日志。不可用的非 Debug 配置显示原因 |
| P-07 | 浏览器 DevTools & Inspector | 两个按钮；不嵌入 DevTools，不复刻其他 DevTools 子页 |
| P-08 | 独立主窗口 + macOS 菜单栏快捷面板 | 图标点击展开；快捷面板可以控制同一会话 |
| P-09 | 中文/英文界面 | 默认跟随系统；可手动覆盖；一项文本只显示当前语言 |
| P-10 | 紧凑的 macOS 原生风格 | 主窗口无侧栏，默认外框 640 × 580 pt，深浅色随系统外观切换 |
| P-11 | 设置左侧导航仅「通用」「Flutter」 | 「关于」独立窗口，SDK 信息只在 Flutter 设置展示 |
| P-12 | Logo 简洁扁平 | Dock 无周边黑色或透明画布；状态栏用同源单色 glyph |
| P-13 | 先 Figma，再 GSD | Figma 视觉验收通过后才开始分阶段实现 |

## 3. 用户工作流

### 3.1 初次使用

1. 打开 App → 选择一个包含 `pubspec.yaml` 的 Flutter 项目文件夹。
2. 检测 Flutter SDK / FVM、读取 `.vscode/launch.json`、查找可用设备。
3. 选择启动配置，例如 `sample-flutter-app(test)`，再选择可用的 iOS 模拟器。
4. 点击「运行」；按任务配置先执行环境切换，再启动 App。
5. 会话建立后启用「热重载」「热重启」「打开 DevTools」「打开 Inspector」。
6. 点击「停止」→ 等待 Flutter 进程真正退出 → 执行 `postDebugTask`（存在时）→ 恢复可启动状态。

### 3.2 菜单栏快速操作

点击图标展开简洁面板：查看项目/配置/设备/会话状态，按状态执行运行、停止、热重载、热重启，打开 DevTools / Inspector，必要时进入主窗口或设置。面板与主窗口操作同一会话，不产生第二个 Flutter 进程。

### 3.3 多环境项目

不硬编码 dev/test/prod；项目可有任意数量的合法命名配置。以下是可公开的[虚构测试配置](examples/sample-flutter-app/README.md)。

| 配置名 | 启动前 | Dart define 重点 | 调试后 |
|---|---|---|---|
| `sample-flutter-app(dev)` | `sample:select-dev` | `APP_ENV=dev`、`ENABLE_SAMPLE_FEATURE=true`、`USE_MOCK_TRANSPORT=false`、`DEMO_BUILD_NUMBER=1001`、`SHOW_SAMPLE_INSPECTOR=true` | 无 |
| `sample-flutter-app(physical)` | `sample:select-dev` | 与 dev 相同 | 无 |
| `sample-flutter-app(test)` | `sample:select-test` | `APP_ENV=test`、`ENABLE_SAMPLE_FEATURE=false`、`DEMO_BUILD_NUMBER=1001`、`SHOW_SAMPLE_INSPECTOR=true` | 无 |
| `sample-flutter-app(prod)` | `sample:select-prod` | `APP_ENV=prod`、`ENABLE_SAMPLE_FEATURE=false`、`DEMO_BUILD_NUMBER=1001` | `sample:select-test` |

注意：`physical` 与 `dev` 在示例中参数相同，**名称本身不代表指定设备**。Dart Define 键名和值按原配置透传，即使键名含拼写差异也不得改写。

## 4. v0.1 功能范围

### 必须

- 项目文件夹打开/切换、最近项目、配置重新读取与错误展示。
- `launch.json` JSONC、基础配置解析；`tasks.json` 中常规 shell/process 任务和启动前/后执行；明确不支持项。
- 设备刷新、选择、可用性校验；Debug Flutter 运行、停止、热重载、热重启、会话状态与日志。
- DevTools / Inspector 按钮连接**当前** VM Service 会话，优先复用 Flutter 输出的 URL。
- 单项目同一时刻一个受管理的运行会话；Firebase prod 环境退出时恢复 test，失败可见。
- 主窗口、菜单栏 popover、通用设置、Flutter 设置和关于窗口。
- 中文/英文/跟随系统语言及记忆；应用图标与状态栏 template 图标。

### 建议保留但不扩大

- SDK 路径自动发现/手工选择、项目 FVM 优先、Flutter/Dart 版本读取、简单的 `flutter doctor` 结果与原始输出查看。
- 日志折叠、清空和复制。清空后的旧日志在折叠和展开时保持清空。必要错误提醒、手动打开主窗口与退出 App。

### 明确不做

- IDE：源码编辑、代码导航、断点/变量/调用栈 DAP UI。
- Build/Sign/Release、包管理、Git、复杂脚本面板、`build_runner` UI、SDK 安装升级或版本下载。
- 独立的 Doctor 全功能页。
- 内嵌 WebView DevTools、重新实现 Inspector、无限多设备并行启动、Windows/Linux 版本。
- 自动更新、遥测、云账号、远程调试或自定义环境变量编辑器（已有配置为准）。

## 5. 状态与安全原则

- 状态包含未选择项目、就绪、前置任务、启动中、等待 VM Service、运行中、停止中、后置任务、完成和错误或需恢复。
- **运行中**：Run 可确认重启当前会话，Stop 可用；热重载/热重启仅在 Debug 会话且可用时允许。
- 启动前任务失败：不得启动 Flutter。prod 如果可能已部分写入配置，进入恢复/风险提示流程。
- 停止 Flutter != 后置恢复已完成。需要区分「Flutter 已退出」与「Firebase 恢复成功」。
- App 强制退出、macOS 崩溃无法保证即时恢复；保留风险标记并在再次启动时提示并处理。

## 6. 验收目标（可演示）

1. 不打开 VS Code，选择 `sample-flutter-app(dev)`，Firebase dev 任务执行后在 iOS 模拟器启动。
2. 选择 `sample-flutter-app(test)`，正确传递 Dart define，打开浏览器 Inspector 并选中 Widget。
3. 选择 `sample-flutter-app(prod)`，停止后执行 `sample:select-test`；失败时清晰显示阻塞级错误。
4. Hot Reload / Restart 不造成额外会话；菜单栏与主窗口同步。
5. 手动切换语言后，所有 UI 文案立即切换；恢复「跟随系统」后生效；项目名/设备名/日志保持原文。
6. 关闭主窗口后菜单栏仍可管理运行会话；退出 App 时明确处理运行中会话及后置任务。

最低部署目标为 macOS 15.0。按[验收矩阵](04-ACCEPTANCE.md) A31 审查 API 可用性并核对最终 Release 主程序及内嵌 worker 的最低部署版本。2026-11-14 经用户确认，取消 macOS 15 实机和虚拟机运行验收，该系统的运行兼容性未验证。

## 7. 实施阶段确认的交互

- 登录时启动默认关闭。启动后显示主窗口、记住最近打开的项目默认开启。启动检测到待恢复记录时显示主窗口和处理入口，由用户触发恢复。
- 应用内使用 F5 运行、Shift+F5 停止、Option+F5 热重载、Shift+Command+F5 热重启。快捷键与按钮共用当前会话及启用条件，仅在受管界面取得焦点时生效。[P4 验收记录](../.planning/milestones/v0.1-phases/04-macos/04-P4-ACCEPTANCE.md)
- DevTools 与 Inspector 由用户手动打开。Inspector 直达按已验证的 Flutter 与 DevTools 版本启用，其他版本打开已连接当前会话的 DevTools。
- 强退后如有未完成的环境恢复，保留风险记录并提供恢复入口。项目所需的 Flutter SDK 无法解析时提示原因并阻止启动。
