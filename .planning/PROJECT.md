# FlutterRunlet

## What This Is

FlutterRunlet 是面向使用终端或其他编辑器的 Flutter 开发者的 macOS 原生调试工具。开发者可以打开项目，从现有 VS Code 配置选择启动环境和设备，在主窗口或菜单栏管理 Debug 会话，并用默认浏览器检查当前运行实例。

## Core Value

开发者无需打开 VS Code 即可复用项目已有配置完成 Flutter Debug，并在会话结束后按原配置恢复环境。

## Requirements

### Validated

- G0 最终 Figma 原型已通过视觉验收，覆盖主要窗口、双语、深浅外观和恢复流程。
- Phase 1 已完成 Flutter GUI Runner 上游审计、原生窗口和菜单栏骨架、macOS 15.0 部署构建验证，并通过 G1 用户验收。[阶段验证](phases/01-upstream-audit-ui-shell/01-VERIFICATION.md)

### Active

- [ ] 打开与切换项目、记住最近项目、重读启动配置，按契约解析 JSONC、参数、变量、环境和任务。
- [ ] 在单项目锁下执行前后置任务，阻止不合法启动，保留 prod 风险并支持恢复重试。
- [ ] 选择 SDK、FVM 与设备，运行、停止、热重载或热重启当前 Debug 会话，查看和管理日志。
- [ ] 主窗口与菜单栏共用会话状态，浏览器 DevTools 与 Inspector 连接当前 VM Service。
- [ ] 完成双语、跟随系统外观、通用与 Flutter 设置、独立关于窗口和品牌图标。
- [ ] 用公开示例和获授权的真实项目验证异常处理、恢复、性能及目标系统，完成发布准备。

### Out of Scope

- IDE 的源码编辑、导航和 DAP 调试界面超出轻量调试工具范围。
- 构建签名发布管理、包管理、Git、复杂脚本和 SDK 安装升级由现有工具处理。
- 独立全功能 Doctor、内嵌 DevTools 和自建 Inspector 超出调试入口范围。
- Windows/Linux、远程调试、云账号、自动更新、遥测和多设备并行运行超出 v0.1 范围。
- 自定义环境变量编辑器会引入第二套配置来源，继续以用户项目配置为准。

## Context

- 首个里程碑为 v0.1。仓库已有需求、技术契约、设计资产、脱敏配置示例和通过 G1 的原生 App 骨架。
- [产品需求](../docs/01-PRODUCT.md)定义范围，[技术契约](../docs/02-TECHNICAL.md)定义配置、任务、会话与恢复行为。
- [开发路线](../docs/03-ROADMAP.md)定义 G1 原生骨架、G2 调试闭环和 G3 最终验收。[验收矩阵](../docs/04-ACCEPTANCE.md)定义各阶段测试条件。
- [设计交接](../docs/design/FIGMA-HANDOFF.md)、[UI 规格](../docs/design/UI-SPEC.md)和[设计系统](../docs/design/DESIGN-SYSTEM.md)记录 G0 基线及开发待处理项。
- [公开示例](../docs/examples/sample-flutter-app/README.md)覆盖 dev、physical、test、prod 与模拟 Firebase 恢复。配置名称原样展示，由实际选择确定设备。
- 待在相应阶段验证 macOS 15、Inspector 直达链接、强制终止后的恢复交互、SDK 无效提示及设置默认值。关于窗口接入已确认链接。

## Constraints

- **平台**：Swift 6，SwiftUI 优先，AppKit 按需补充。暂以 macOS 15 为最低目标，P1 验证构建和 API 可用性，P5 实机复验。
- **配置来源**：现有 `.vscode/launch.json` 与 `.vscode/tasks.json` 为权威来源。应用保留原文件，按契约透传值并明确报告不支持项。
- **环境恢复**：同项目的会话和环境切换互斥。prod 启动前持久化风险，Flutter 退出后按配置执行恢复，成功后才清除风险。恢复是发布门槛。
- **隐私**：应用默认避免持久化未遮罩的 VM Service URL。真实项目源码、私有配置与设计播放入口留在独立环境。
- **设计**：使用原生窗口和控件，按 G0 布局实现并记录原生差异。G2 之后的额外视觉精修由用户选定。
- **验收**：每个阶段须有相关自动验证、人工验证、适用的截图和提交记录。达到门槛后再进入下一阶段。

## Key Decisions

| 决策 | 依据 | 状态 |
|---|---|---|
| 沿用 G0 最终同步稿与原生控件 | 设计交接及原生实验 | G1 原生骨架已验收 |
| 先审计，再按需导入 Flutter GUI Runner | 优先复用可验证的能力并保留必要许可与版权 | P1 已审计，未导入上游源码或资源 |
| 仅支持 Debug，复用项目原有任务与参数 | 保持日常调试和环境恢复与现有工作流一致 | 已确认，待实施 |
| 主窗口与菜单栏控制同一会话 | 窗口关闭后仍可管理当前实例 | 已确认，待实施 |
| 沿用 P1–P5 及 G1–G3 门槛 | 按交接顺序交付骨架、调试闭环及发布验收 | 初始化已确认 |

## Evolution

1. 每次 Phase 验收后同步已验证需求、失效需求、新增需求和关键决策。
2. 每次里程碑结束后复核产品定义、核心价值、范围和当前上下文。

---
*Last updated: 2026-11-12 after Phase 1*
