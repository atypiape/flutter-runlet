---
phase: 06-main-window-menu-bar
reviewed: 2026-11-14T15:36:30Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - FlutterRunlet/FlutterRunletApp.swift
  - FlutterRunlet/Localizable.xcstrings
  - FlutterRunlet/MainWindowView.swift
  - FlutterRunlet/MenuBarPanelView.swift
  - FlutterRunlet/SessionController.swift
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# 阶段 06 · 代码审查

审查基线为 `cd64f02536075202bcc60a3afdfc456b1ea7a155`，受审提交为 `929415b285da2a75d6c0ed6fc207dfb0f39b346a`。核对两处入口、配置和设备守卫、运行设备与 VM Service 绑定、恢复任务及租约边界、终止取消、日志和双语资源。追踪关键调用至现有项目身份校验、风险存储和 Flutter 命令构建，核对已覆盖的回归路径。两项警告分别由源码追踪和定向 XCTest 确认。

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: 菜单栏目录选择器结束后无法回到原按钮

**File:** `FlutterRunlet/FlutterRunletApp.swift:227`、`FlutterRunlet/MainWindowView.swift:743`

**Issue:** 从菜单栏打开目录选择器时，场景先关闭菜单栏面板，再打开并激活主窗。对话框结束后，`ProjectControls` 更新的是原菜单栏控件的焦点状态。处理程序没有重新呈现菜单栏面板或让其重新成为当前窗口，原文件夹按钮因此不可继续键盘操作。主窗自己的文件夹按钮属于另一个视图实例。06-01-01 的验收条件明确要求对话框关闭后在原入口恢复焦点。

**Fix:** 在菜单栏路由处理对话框完成后的窗口呈现与回焦。若系统允许重用菜单栏面板窗口，可在对话框完成后重新呈现原窗口，再给原按钮焦点。也可尝试让原面板作为 AppKit 文件选择器的宿主，保持其为焦点归属。两种方案都需在普通候选中实际验证选择和 Escape 取消，确认 Tab 可从同一入口继续。

**处置:** 源码缺口待关闭，原生焦点证据由 06-04 记录。

### WR-02: 旧目录恢复可用后仍缺历史记录

**File:** `FlutterRunlet/SessionController.swift:380`（受审提交）

**Issue:** 从旧版升级时，若原工程所在卷未挂载，首次校验失败仍会把空历史列表持久化。卷恢复后，启动保留的旧路径会正常自动打开项目，但已存空列表使迁移不再重试。历史中看不到这一条，也无法从历史移除其自动重开指针。测试先临时移走隔离目录，再恢复目录，旧代码在历史内容和下一次重开两处断言失败。

**Fix:** `9246e1c` 将暂时无法校验的旧项目保留在待迁移状态。后续校验成功再写入规范化历史和自动重开指针。用户清空后已保存的空列表仍保持为空。

**处置:** 已修复。新增回归 `e50ee49` 复现上述两项断言失败。修复后 ProjectSelectionTests 8 例、LaunchPresentationTests 16 例通过，无失败或跳过。
