---
phase: 05
review: 05-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "日志增量更新可用错误的 UTF-16 偏移截取新文本"
  - id: WR-01
    severity: warning
    disposition: deferred
    title: "旧版 Debug 样例的挂起恢复在新构建中会被摘要校验拒绝"
open: 0
total: 2
---

# Phase 05 · 代码审查处置

| 发现 | 严重度 | 处置 | 依据 |
|---|---|---|---|
| CR-01 | critical | fixed | `36916dd` 改为字面比较。新增回归在旧代码失败，修复后通过。Debug 全量 77 项通过。 |
| WR-01 | warning | deferred | 范围限于旧版 Debug 夹具。旧记录使用匹配旧脚本的构建完成恢复，新回合使用当前公开样例。普通 Release 无此限制。 |
