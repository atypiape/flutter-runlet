---
status: testing
phase: 06-main-window-menu-bar
source: [06-VERIFICATION.md]
started: 2026-11-14T23:56:43+08:00
updated: 2026-11-14T23:56:43+08:00
---

# 阶段 06 · 待补本地验收

使用[本地联验](06-ACCEPTANCE.md)记录的最终候选及隔离样例。每项单独记录结果，保留该轮原始证据于本机。

## Current Test

number: 1
name: 两处界面的双语、深浅外观和英文长状态辨识
expected: |
  同一 Release 在中英文与深浅色下，两处尺寸、布局、状态和禁用语义符合画板。核对无项目、就绪、等待 VM、运行、恢复中和恢复失败。实测英文长状态标签若截断，记录正常阅读场景能否明确区分等待和恢复失败，以及现有提示、详情与辅助名称是否足够。
awaiting: user response

## Tests

### 1. 两处界面的双语、深浅外观和英文长状态辨识
expected: 同一 Release 在中英文与深浅色下，两处尺寸、布局、状态和禁用语义符合画板。核对无项目、就绪、等待 VM、运行、恢复中和恢复失败。实测英文长状态标签若截断，记录正常阅读场景能否明确区分等待和恢复失败，以及现有提示、详情与辅助名称是否足够。
result: [pending]

### 2. 主窗和菜单栏的 VoiceOver、Return 与目录 Escape 回焦
expected: VoiceOver 读出图标动作、状态与不可用语义。Tab 和 Shift-Tab 能逐项移动，Return 触发焦点动作，Escape 从历史或设备弹层及系统目录对话框返回原触发项。目录 Escape 保留原项目，下一次 Tab 从原入口继续。
result: [pending]

### 3. 跨入口同步逐行删除的项目历史
expected: 以两个隔离项目建立历史，从一处逐条删除，在另一处依次看到仅对应条目消失和最终空态。删除当前项目条目不关闭它，重新启动后仍为空。运行和恢复期间尝试切换时仍保持原项目。
result: [pending]

### 4. 最终候选反向切换设备、两处离线复连和当前调试链接
expected: 从菜单栏在 A 启动 prod，在主窗改选 B。两处下一次均显示 B，实际进程、当前会话、热操作、DevTools 和 Inspector 或其回退仍连接 A。停止后确认旧进程先退出，原后置恢复 test、风险为 0。断开 B 后两处显示名称、类型、红点和离线文字并阻止启动，复连后都显示绿点及在线，下一次实际使用 B。
result: [pending]

### 5. 最终候选主窗恢复故障矩阵和日志边界
expected: 使用隔离样例制造原后置退出 1，主窗原位显示任务、实际退出码、运行提示和重试。故障保留时再次恢复继续阻断启动及退出。单独重试只恢复。另一次先清除旧风险再运行新前置与 Flutter。暂停原恢复时挡住运行、F5、重试与切换，确认退出会等待恢复且不会接续。复制、清空、收起再展开时没有旧日志，后续输出可追加，恢复详情独立可用。
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
