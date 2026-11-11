# 03 · FlutterRunlet v0.1 · Figma → GSD 交接与分阶段路线

状态为 **G0 最终视觉验收已通过，v0.1 待 GSD 初始化**。正式应用尚未开发。本文提供里程碑输入和建议 Phase，正式计划及状态由 GSD 生成和维护。

## 0. 总原则

**全局优先 → 渐进收敛 → 先可运行/可验收 → 用户决定精修程度。** 不能因为 UI 视觉问题把配置/任务/运行功能长期推迟；也不能因为 CLI 已经可用就跳过最终 UI 验收。

- 主干为 **macOS 原生 Swift，SwiftUI 优先，AppKit 按需补充**。以 Flutter GUI Runner 为复用基线，先审计，再按需导入。
- 先隐藏超出 v0.1 范围的上游界面入口，确认模块未被保留功能使用后再清理。
- [产品需求](01-PRODUCT.md)定义范围，[技术设计](02-TECHNICAL.md)定义行为与安全契约，[已验收的 Figma](design/FIGMA-HANDOFF.md#最终原型与播放入口)定义视觉基线。GSD 负责实施计划和阶段验证。
- 不把图片当可编辑原型，不把文档当已完成代码，不提前宣布 GSD 阶段完成。
- **每个 Phase 必须具有明确验收**：自动测试 / 手动验证 / 截图证据（有 UI 的 Phase）/ 提交记录。

## 1. 设计阶段（不计入实施 Phase）

| 门禁 | 交付物 | 人工验收 |
|---|---|---|
| D0 文档基线 | PRD、技术契约、UI-SPEC、设计系统、旧图冲突清单 | 功能范围和安全边界无歧义 |
| G0 Figma 最终验收 | 主窗口、菜单栏、通用与 Flutter 设置、关于、Logo 的可编辑原型 | **已通过**。用户确认中英文、深浅色及关键状态的最终同步稿 |

[设计交接](design/FIGMA-HANDOFF.md)记录 Figma 文件、页面、播放入口、设计变量、图标资产及开发待处理项。G0、G0.1、G0.2 保留供回溯。

## 2. v0.1 里程碑输入与建议初始化步骤

1. 核对目标运行环境的 GSD Core 版本和技能入口。交接时本机确认的 Core 为 1.18.0，运行环境标记为 Kimi。若在 Codex 初始化，先确认 Codex 环境能加载对应的 GSD 技能和工作流。
2. 当前仓库没有 `.planning/PROJECT.md`。首次初始化使用本机的 `gsd-new-project` 入口，以 **FlutterRunlet v0.1** 为首个里程碑。已初始化且完成上一里程碑后，才用 `gsd-new-milestone` 开启后续版本。Codex 的技能调用形式为 `$gsd-new-project`，以本机实际安装为准。
3. 输入 [README](../README.md)、[协作约束](../AGENTS.md)、[PRD](01-PRODUCT.md)、[技术契约](02-TECHNICAL.md)、[设计交接](design/FIGMA-HANDOFF.md)、[UI 规格](design/UI-SPEC.md)、[设计系统](design/DESIGN-SYSTEM.md)、本路线图和[验收矩阵](04-ACCEPTANCE.md)。项目目标是在不启动 VS Code 的情况下，利用现有 `.vscode` 配置完成 Flutter Debug、环境恢复和浏览器检查。正式应用的上游代码导入安排在 P1。
4. 由 GSD 生成 `.planning/PROJECT.md`、`REQUIREMENTS.md`、`ROADMAP.md`、`STATE.md` 及工作流配置。先核对需求、验收条目和下面的 Phase 边界，再讨论并规划 P1。GSD 管理实际的阶段状态。

## 3. 建议 v0.1 五个 Phase

| Phase | 主要工作 | 不做 | 验收门槛 |
|---|---|---|---|
| **P1 · 上游审计与 UI 骨架** | 审查 Flutter GUI Runner 代码、许可证和可复用能力，审查 macOS 15 API。搭建原生主窗、菜单栏、设置和关于骨架，按审计结果复用模块 | 不要求功能已连通，不在本阶段像素精修 | **G1 整体粗实现**。原生 App 可启动并打开各界面，记录兼容性证据和必要设计偏差，核实上游许可处理 |
| **P2 · 配置和任务执行内核** | JSONC 读取 `.vscode/launch.json` 和 `tasks.json`，校验 Debug 配置，映射变量、环境和参数。实现 Firebase 前后置任务、项目锁及恢复风险记录 | 不支持所有 VS Code 扩展任务 | 覆盖 dev、physical、test、prod、旧 `args --dart-define`、非 Debug 禁用、失败阻断和恢复。用户配置原样保留 |
| **P3 · Flutter 调试闭环** | 设备与 SDK/FVM 选择，Run/Stop/Reload/Restart、VM Service、浏览器 DevTools/Inspector、日志和共享会话。清空后折叠、展开保持旧日志已清空 | 不做 DAP/IDE 调试能力 | **G2 可用 MVP**。真实工程能在 iOS 模拟器及可用设备上运行，dev/test/prod 任务顺序正确，菜单栏可控制同一会话，DevTools Inspector 可连接 |
| **P4 · 完成 macOS UI 与双语设置** | 完成双语和系统外观、主窗及菜单栏、两类设置、关于、图标接入。配置已确认的项目链接 | 视觉精修仅限 G2 后经用户选定的范围 | 关键状态、语言、两种外观、设置和图标符合验收矩阵，原生控件偏差有记录 |
| **P5 · 稳定性、异常恢复与最终验收** | 验证启动失败、设备断线、任务失败、应用退出、崩溃恢复、日志回归、性能和最低目标系统。准备 Release 打包 | 不追求超出需求的增量功能 | **G3 最终验收**。适用验收项通过，视觉差异经用户确认，文档、许可证和发布说明齐全 |

G1 → G2 → G3 保持顺序。G2 后由用户决定是否进行有限视觉精修，P4 的双语、外观和设置仍按已确认范围交付。GSD 可细分 Phase，并保留各验收目标。

## 4. 阶段操作模板

每一阶段以当前 GSD 安装版本对应命令进行，至少包含：

1. **Discuss**：界定范围、列出开放问题和不变项。
2. **UI Spec**（涉及 UI 时）：以 Figma 与 `UI-SPEC` 生成可追踪 UI 契约；如本地 GSD 提供 UI Phase 功能则使用。
3. **Plan**：对关键行为和测试用例建立实施项；校验计划没有扩张范围。
4. **Execute**：按计划实现，不提前精修，也不绕过用户标注的限制。
5. **Verify/UAT**：自动测试 + 用户可重复操作验证 + 视觉截图；问题修复后再验收。
6. **Commit/Handoff**：更新文档、完成提交及摘要，让下一阶段能可靠继续。

**不接受“代码已经提交，所以阶段完成”的单一验收依据。** `docs/04-ACCEPTANCE.md` 提供可执行的场景清单。

## 5. 起点到开发结束的停点

- **当前交接**。G0 已通过，记录基线、待处理项和里程碑输入。
- **启动开发**。GSD 正式初始化，审阅路线和验收目标，再按 Phase 实施并验收。
- **所有 Phase 完成之后**：milestone audit → complete milestone → Git tag `v0.1.0`（前提是符合真正的发布条件；不要仅因 roadmap 完成就打标）。
- **下一期**：如需 UI/功能细调，另建 `v0.2` milestone，不把尚未批准的追加想法塞回 v0.1。

## 6. 版本、风险与特别约束

- 若上游某个实现不适配新的配置任务机制，优先局部改造而非整体重写。
- prod Firebase 恢复是 release blocker；不允许「仅正常停止能恢复」而忽略崩溃后的可见风险状态。
- macOS UI 以已验收的 Figma 布局为基线，使用系统原生窗口与控件。控件外观或交互出现差异时，遵循 macOS 原生行为并记录设计偏差。
- 验收用[公开示例](examples/sample-flutter-app/README.md)复现任务与恢复流程，并用至少一套获授权的真实 Flutter 测试项目回归。测试项目的源码与私有配置留在独立环境。

## 7. GSD 参考文档

- [GSD Core 运行环境安装指南](https://github.com/open-gsd/gsd-core/blob/next/docs/how-to/install-on-your-runtime.md)
- [GSD Core 命令参考](https://github.com/open-gsd/gsd-core/blob/next/docs/COMMANDS.md)
