# FlutterRunlet

**FlutterRunlet — Lightweight Flutter Debug GUI Console**\
仓库名：`flutter-runlet` · 平台：macOS · 规划版本：`v0.1` · 当前阶段：**G0 通过，待 GSD 初始化**

FlutterRunlet 是一个不依赖 VS Code 或 Android Studio 运行的原生 macOS Flutter 调试控制台。它直接读取已有 Flutter 项目的 `.vscode/launch.json` 与 `.vscode/tasks.json`，让开发者选择启动配置和设备，运行、停止、热重载 Flutter App，并在浏览器中打开 Flutter DevTools / Inspector。

> 最终 Figma 同步稿已通过人工视觉验收，是 v0.1 的视觉基线。仓库当前包含文档、设计资产和兼容性示例，正式应用尚未开发。上游代码经审计后按需复用，保留 [Flutter GUI Runner](https://github.com/huseyiniriss/flutter-gui-runner) 的 MIT 许可证与版权声明。

## 首版只做什么

- 项目选择与最近项目；从 `launch.json` 选择配置；从设备列表选择模拟器/真机。
- 按 `tasks.json` 执行 `preLaunchTask`、`postDebugTask`，支持现有的 Firebase 环境切换流程。
- Debug 模式下 Run / Stop / Hot Reload / Hot Restart；显示会话状态和可折叠日志。
- 一键在默认浏览器打开 Flutter DevTools 与 Inspector（不内嵌）。
- 原生主窗口和 macOS 菜单栏图标/快捷面板。
- 界面支持简体中文和 English，默认跟随系统语言。深浅色随系统外观切换。
- 基础 SDK/FVM 检测、设置和关于窗口。

不做 IDE 源码编辑器、断点调试器、Flutter SDK 安装器、构建/签名/发布、依赖管理、`build_runner` 图形入口或内嵌 DevTools。详见范围边界。

## 文档导航（阅读顺序）

| 文档 | 用途 |
|---|---|
| [产品需求](docs/01-PRODUCT.md) | 目标、范围、核心流程、已确认决策与待确认项 |
| [技术设计与 VS Code 兼容](docs/02-TECHNICAL.md) | 配置解析、Firebase 任务、SDK、进程、安全性和架构 |
| [设计系统](docs/design/DESIGN-SYSTEM.md) | macOS 视觉、排版、布局、图标/状态栏图标规则 |
| [界面与状态规格](docs/design/UI-SPEC.md) | 主窗口、菜单栏面板、设置与关于页面及状态约束 |
| [最终 Figma 设计交接](docs/design/FIGMA-HANDOFF.md) | G0 验收记录、最终画板与播放入口、开发待处理项 |
| [v0.1 GSD 分阶段计划](docs/03-ROADMAP.md) | 设计门禁、建议 Phase、验收与启动 GSD 的方式 |
| [验收矩阵](docs/04-ACCEPTANCE.md) | Figma G0 与 P1–P5 的功能/UI 场景验收 |
| [开发协作约束](AGENTS.md) | Codex 执行边界、质量与提交约定 |

## 工作流程

1. **G0 已通过**。以[最终 Figma 的深色与浅色页面](docs/design/FIGMA-HANDOFF.md#最终原型与播放入口)为视觉基线，历史稿保留供回溯。
2. **初始化 GSD**。按[里程碑交接与路线图](docs/03-ROADMAP.md)导入需求、技术契约、验收矩阵及设计基线，审阅 GSD 生成的计划。
3. **分阶段验收**。G1 验证整体粗实现，G2 验证可用 MVP，再由用户决定有限的视觉精修范围，G3 执行最终验收。

## 已有视觉资产

已验收的矢量主标志、Dock 图标和菜单栏 Template 图标位于[品牌导出资产](docs/design/assets/)。

## 技术基线

- macOS 原生：Swift 6，SwiftUI 优先，AppKit 按需补充。暂以 macOS 15 为最低版本目标，API 兼容性和 Xcode 工具链在 P1 审查并验证。
- 外部工具：项目现有 Flutter/Dart SDK，必要时使用 FVM；Flutter DevTools 用浏览器。
- 配置真相来源：Flutter 项目的 `.vscode/launch.json` 与 `.vscode/tasks.json`；不另建重复的运行参数配置。
- 源码基础计划：Flutter GUI Runner；在导入代码前审查实际实现、许可证与可复用模块。

## 参考

- [Flutter GUI Runner（上游）](https://github.com/huseyiniriss/flutter-gui-runner)
- [Dart Code Launch Configuration](https://dartcode.org/docs/launch-configuration/)
- [Flutter DevTools CLI](https://docs.flutter.dev/tools/devtools/cli)
- [GSD Core 命令参考](https://github.com/open-gsd/gsd-core/blob/next/docs/COMMANDS.md)
