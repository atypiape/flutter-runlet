---
phase: 06
review: 06-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "菜单栏目录选择器结束后无法回到原按钮"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "旧目录恢复可用后仍缺历史记录"
open: 0
total: 2
---

# 阶段 06 · 代码审查处置

| 发现 | 处置 | 依据 |
| --- | --- | --- |
| WR-01 | 已修复 | `ad7ee14` 保留窗口实例，关闭选择器后重新呈现菜单栏窗口并回到文件夹按钮。先在旧候选实际复现取消后切到主窗，修订候选对取消和选中均通过原生复验。 |
| WR-02 | 已修复 | `e50ee49` 的回归在旧实现失败，`9246e1c` 保留未完成的迁移，定向 24 项、最终全量 90 项通过。 |
