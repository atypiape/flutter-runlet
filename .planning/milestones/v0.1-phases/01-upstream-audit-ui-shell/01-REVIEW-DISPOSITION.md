---
phase: "01"
review: 01-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "Cocoa 引用绑定到当前工具链不存在的 SDK 路径"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "图标式打开项目按钮缺少显式悬停提示"
  - id: IN-01
    severity: info
    disposition: skipped
    title: "当前测试 target 只覆盖共享 scheme 的 Debug 测试配置"
  - id: WR-03
    severity: warning
    disposition: open
    title: "主窗关闭通知的选择器缺少通知参数"
open: 1
total: 4
recorded: 2026-11-12
---

# Phase 1 · 代码审查处置

| Finding | Severity | Disposition | Source |
| --- | --- | --- | --- |
| WR-01 | warning | fixed | `281cafa` 将 Cocoa 改为 SDKROOT 相对引用。Debug XCTest 与 Release 构建复验成功，日志中不再有 26.0 SDK 引用。 |
| WR-02 | warning | fixed | `281cafa` 补上显式 `.help("打开项目")`。修复后 AX 仍暴露禁用按钮名称。该禁用项实际悬停效果纳入 G1 用户验收。 |
| IN-01 | info | skipped | 共享 scheme 按 G1 计划运行 Debug XCTest。Release 重新构建并实际携带 `--g1-ready` 启动，仍显示 Empty。 |
| WR-03 | warning | open | 01-04 补审发现选择器签名与 Foundation 文档契约有差异。已验收构建实测收到通知，Dock 路径获得用户确认。保留为非阻断兼容性警告。 |

两个构建的有效部署目标和 Mach-O 最低系统版本均复核为 15.0。 [原审查](01-REVIEW.md) · [复验记录](01-G1-ACCEPTANCE.md#代码审查后的复验)
