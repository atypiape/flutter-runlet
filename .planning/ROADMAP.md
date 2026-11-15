# FlutterRunlet 路线图

## 已归档里程碑

- 🗄 **v0.1 FlutterRunlet** — 2026-11-14 完成本地验收并归档（5 个阶段、22 份计划）。[路线图档案](milestones/v0.1-ROADMAP.md) · [需求档案](milestones/v0.1-REQUIREMENTS.md) · [审计](milestones/v0.1-MILESTONE-AUDIT.md)
- 🗄 **v0.2 界面与调试体验** — 2026-11-15 完成本地验收并归档（2 个阶段、10 份计划）。[路线图档案](milestones/v0.2-ROADMAP.md) · [需求档案](milestones/v0.2-REQUIREMENTS.md) · [审计](milestones/v0.2-MILESTONE-AUDIT.md)

## v0.3 Inspector 与设置

- [x] **Phase 08: DevTools 会话与源码跳转** - 纳入 PR #1 的既有工作并修复三个已复现问题。
- [x] **Phase 09: DevTools 设置与外观** - 调整设置分类并补上应用外观。

### Phase 08: DevTools 会话与源码跳转

**Requirements**: DEV-01, DEV-02, DEV-03, DEV-04, VER-01

[计划](phases/08-devtools-session/08-01-PLAN.md) · [验证](phases/08-devtools-session/08-01-SUMMARY.md)

- 独立 DevTools 按需启动，连接当前 VM Service，复用并随调试会话退出。项目 Flutter 与 Dart SDK 继续按现有配置解析。
- Inspector 重复点击时复用当前标签，关闭后可重开。进程退出时作废未完成的旧标签请求。
- 启动期间采用最后一次页面选择，源码事件遇到临时订阅错误可自动恢复。
- 汇总 PR #1 的 exchange-app 验收、内存对比和进程拆分研究，补齐三个回归测试并运行全量测试。

本地验证通过。全量 XCTest 139/139，包括三个复现场景和更新安装门禁。沿用 PR 中已有的 exchange-app 实机验收记录。[进程归属与测量口径](phases/08-devtools-session/08-MEMORY.md)

### Phase 09: DevTools 设置与外观

**Requirements**: SET-01, SET-02, SET-03

[计划](phases/09-devtools-settings/09-01-PLAN.md) · [验证](phases/09-devtools-settings/09-01-SUMMARY.md)

与阶段 08 在同一个 PR 验证。

- 侧栏在 Flutter 后放置 DevTools，页面集中管理来源和源码编辑器。
- 来源选择、SDK 路径、版本或错误以及更换操作分行显示，检查中英文和深浅外观下的窄窗口排版。
- 通用页提供跟随系统、浅色和深色。选择立即应用，并在重启后保留。

本地验证通过。用隔离构建检查中英文 DevTools 页面、独立 Dart SDK 的目录选择与自带模式切换、深色和浅色即时生效、跟随系统与重启后保留设置。
