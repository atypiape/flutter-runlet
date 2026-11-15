---
phase: 08-devtools-session
plan: "01"
requirements-completed: [DEV-01, DEV-02, DEV-03, DEV-04, VER-01]
---

# DevTools 会话与源码跳转验证

- 已纳入 `7f83aab`、`ce3d1c5` 和 `ac7bc38`，以及 [PR #1](https://github.com/atypiape/flutter-runlet/pull/1) 中已有的 exchange-app 验收。
- `32b8d2b` 加入三个回归场景。独立 DevTools 启动中保留最后一次页面请求，进程退出后取消旧标签查找，真实回环 WebSocket 测试覆盖订阅出错后重试和定位行列。
- 最终产品源码 `8bb6d86` 的隔离测试构建通过 139 项 XCTest。隔离应用标识用于避免和已安装实例触发更新门禁。Release 构建也通过。
- [内存与进程归属](08-MEMORY.md)保留既有采样口径，记录 VS Code 进程拆分的可借鉴之处。相同 exchange-app 调试流程沿用已有实机证据。
