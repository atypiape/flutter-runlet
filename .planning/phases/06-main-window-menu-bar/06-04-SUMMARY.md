---
phase: 06-main-window-menu-bar
plan: "04"
subsystem: validation
tags: [macos, release, flutter, xctest, uat]
key-files:
  created:
    - .planning/phases/06-main-window-menu-bar/06-ACCEPTANCE.md
    - .planning/phases/06-main-window-menu-bar/06-UI-REVIEW.md
  modified:
    - .planning/phases/06-main-window-menu-bar/06-VALIDATION.md
requirements-completed: [UI-10, UI-11, UI-12]
status: human_needed
completed: 2026-11-14
---

# 06-04 · Figma 与真实 Flutter 本地联验

[本地联验](06-ACCEPTANCE.md)逐项记录实测结果和候选身份。前三波实现已提交；第四波完成实际调试、双模拟器验证、两处共享状态与恢复验证，保留尚未取证的验收项。

最终普通 Release 生产源码为 `ad7ee14`，构建和严格签名检查通过。最终 Debug 全量 90 项通过，无失败和跳过。目标测试套件均在全量执行。两个审查发现均已修复，安全复核无未关闭风险。

- 早期候选主窗实测 A 的热操作、浏览器 DevTools / Inspector、B 离线复连、三条故障边界及退出。最终候选实测菜单栏选择目录及回焦、英文弹层、跨界面改选仍保留 A、底部入口、菜单栏故障拦截与单独重试。
- `9246e1c` 修复旧目录暂不可用时的历史迁移（新增回归在旧实现失败，定向 24 项通过）。`ad7ee14` 修复菜单栏目录选择后不能回原按钮、以及英文弹层仍使用系统语言的问题。
- 两处齿轮打开同一设置窗口，两台本地模拟器均使用真实 Flutter 进程。会话已停止，环境为 test、隔离恢复风险为 0，系统已恢复深色。
- 后续复验仍需同一最终候选的主窗故障和浏览器连接、两处离线/复连同步、历史双向删除、剩余外观与原生辅助操作。阶段 07 保留独立规划，未公开发布。
