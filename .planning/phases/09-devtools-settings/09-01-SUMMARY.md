---
phase: 09-devtools-settings
plan: "01"
requirements-completed: [SET-01, SET-02, SET-03]
---

# 设置与外观验证

用 `8bb6d86` 的隔离构建在原生窗口验证中英文 DevTools 页面、侧栏标签完整、Flutter 自带与独立 Dart SDK 切换、目录选择后显示 2.61.0 以及默认 VS Code。验证浅色、深色和跟随系统可切换，重启后恢复之前选择的浅色。全量 XCTest 139/139，Release 构建通过。

仓库中的 v0.1.0、v0.1.1 和设计交接记录显示，已有版本通过系统设置驱动深浅色。交接涵盖两套外观画板，这些资料未发现显式外观选择入口。
