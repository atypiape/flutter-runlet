# FlutterRunlet 路线图

## 已归档里程碑

- 🗄 **v0.1 FlutterRunlet** — 2026-11-14 完成本地验收并归档（5 个阶段、22 份计划）。[路线图档案](milestones/v0.1-ROADMAP.md) · [需求档案](milestones/v0.1-REQUIREMENTS.md) · [审计](milestones/v0.1-MILESTONE-AUDIT.md)

## v0.2 界面与调试体验

确认的四个界面原型作为实现与验收基线。[需求与阶段追踪](REQUIREMENTS.md) · [Figma 交接说明](../docs/design/FIGMA-HANDOFF.md#v02-界面原型)

- [x] **Phase 06: 主窗口与菜单栏** - 交付共用调试控件、项目与设备选择、会话状态和日志体验。
- [ ] **Phase 07: 设置、关于与更新** - 交付设置和关于窗口、共享版本与更新状态，并完成四处界面联验。

### Phase 06: 主窗口与菜单栏

**Goal**: 交付已确认的主窗口和菜单栏体验，验证设备选择、日志与环境恢复。

**Depends on**: Phase 05（已归档）

**Requirements**: UI-07, UI-08, UI-09, UI-10, UI-11, UI-12, RUN-07, RUN-08, RUN-09

1. 对照确认的原型验证两处布局和控件状态，包括中英文、深浅外观和键盘操作。
2. 验证历史项目打开、逐条清除和系统目录选择。运行中切换下次运行设备时，当前进程与 DevTools 仍绑定原会话。
3. 用真实工程验证选配置、启动、热操作、日志复制与清空、停止和恢复。
4. 模拟后置任务失败，验证重试仅恢复，运行先恢复后启动，恢复再次失败时保持阻断。

**Plans**: 4 份，4 个波次，按依赖顺序执行。

**Wave 1**

- [x] [06-01 共用控件、项目历史与两处布局](phases/06-main-window-menu-bar/06-01-PLAN.md)

**Wave 2（依赖 06-01）**

- [x] [06-02 下次运行设备与当前调试会话](phases/06-main-window-menu-bar/06-02-PLAN.md)

**Wave 3（依赖 06-02）**

- [x] [06-03 恢复、重试与主窗口日志](phases/06-main-window-menu-bar/06-03-PLAN.md)

**Wave 4（依赖 06-03）**

- [x] [06-04 Figma 对照与真实 Flutter 本地联验](phases/06-main-window-menu-bar/06-04-PLAN.md)（原生复验和本地联验通过）

[验证方案](phases/06-main-window-menu-bar/06-VALIDATION.md) · [本地联验](phases/06-main-window-menu-bar/06-ACCEPTANCE.md)

### Phase 07: 设置、关于与更新

**Goal**: 交付设置、关于与更新体验，并完成四处界面的本地联验。

**Depends on**: Phase 06

**Requirements**: UI-07, UI-13, UI-14, UI-15, UPD-01, UPD-02

UI-07 在本阶段完成四处界面的最终联验。

1. 从主窗口和菜单栏打开同一套设置，核对分类、开关、版本显示和 Flutter 环境检测。
2. 对照原型验收独立关于窗口及设置关于页的共享组件、署名和三个链接。
3. 用可控数据逐状态完成截图对照，通过后才接入真实 Release 查询、下载、校验、安装和回退。用两份隔离候选验证重启后刷新实际版本。
4. 对同一候选完成四处界面、运行恢复和已有设置行为的本地回归。

公开发布继续暂缓。签名证书、公证、匿名访问及分享范围复核按原发布交接接续。

**Plans**: 6 份，按依赖顺序执行。

阶段 07 从包含本地 Figma 交接的同一工作区顺序执行，`workflow.use_worktrees=false`。所有波次复用 `.private/phase-07/`；缺少原始取证或候选证据时停止，私有目录不进入 Git。

**Wave 1**

- [x] [07-01 补齐 Figma 图层和逐状态取证基线](phases/07-settings-about-updates/07-01-PLAN.md)（36 张参考图，516 个适用用例）

**Wave 2（依赖 07-01）**

- [x] [07-02 还原设置三页和独立关于，接入受控状态](phases/07-settings-about-updates/07-02-PLAN.md)（100 项测试，Release 构建通过）

**Wave 3（依赖 07-02）**

- [x] [07-03 同候选逐状态截图对照和视觉门槛](phases/07-settings-about-updates/07-03-PLAN.md)（512 项适用用例通过）

**Wave 4（须有 07-03 的有效视觉签核）**

- [ ] [07-04 真实 Release 检查与下载校验](phases/07-settings-about-updates/07-04-PLAN.md)

**Wave 5（依赖 07-04 及 07-03 的有效视觉签核）**

- [ ] [07-05 安装重启、安全等待及回退](phases/07-settings-about-updates/07-05-PLAN.md)

**Wave 6（依赖 07-05）**

- [ ] [07-06 同一最终候选四处界面及真实 Flutter 联验](phases/07-settings-about-updates/07-06-PLAN.md)

[Figma 取证](phases/07-settings-about-updates/07-FIGMA-EVIDENCE.md) · [实施调研](phases/07-settings-about-updates/07-RESEARCH.md) · [验证方案](phases/07-settings-about-updates/07-VALIDATION.md)
