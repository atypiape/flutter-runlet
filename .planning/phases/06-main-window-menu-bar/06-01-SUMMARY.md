---
phase: 06-main-window-menu-bar
plan: "01"
subsystem: ui
tags: [swiftui, appkit, preferences, xctest]
provides:
  - 两处共享的项目目录选择、持久历史、配置及调试操作
  - 主窗口 640 × 520 pt 默认尺寸及 348 pt 菜单栏面板
affects: [06-02, 06-03, 06-04]
actuals:
  tokens: 8782
  tasks: 3
  commits: 2
  plan_head_before: cd64f02536075202bcc60a3afdfc456b1ea7a155
tech-stack:
  added: []
key-files:
  modified:
    - FlutterRunlet/SessionController.swift
    - FlutterRunlet/MainWindowView.swift
    - FlutterRunlet/MenuBarPanelView.swift
    - FlutterRunlet/FlutterRunletApp.swift
    - FlutterRunlet/Localizable.xcstrings
    - FlutterRunletTests/ProjectSelectionTests.swift
    - FlutterRunletTests/LaunchPresentationTests.swift
requirements-completed: [UI-07, UI-08, UI-09, UI-10, UI-11]
duration: 11min
completed: 2026-11-14
status: complete
---

# 06-01 · 共享项目入口与调试布局

主窗与菜单栏使用同一个会话。两处均可从原生目录选择或历史项目打开工程，看到同一启动配置与六项常驻调试操作。

- 项目入口和历史行共用项目切换守卫，实际打开再次校验目录和会话状态。无效目录不改变已打开项目和历史。
- 历史按最近打开顺序保存规范化目录；旧偏好仅在首次迁移时读取。自动重开开关仍控制启动行为。移除当前项目的历史条目不会关闭项目，且不会改写恢复记录。
- 运行三角形紧邻共用配置下拉，另保留重读配置与全名入口。主窗与菜单栏分别组合相同调试控件，设置齿轮共用原窗口路由。「关于」仍可从原生应用菜单打开。
- 菜单栏的目录选择复用现有面板关闭和主窗激活流程。主窗原生目录选择及返回文件夹按钮焦点通过早期冒烟；菜单栏焦点、双语和深浅外观矩阵待最终候选验证。

## 验证

| 检查 | 结果 |
| --- | --- |
| RED 项目历史回归 | 新用例因尚无公开历史及切换条件而未通过编译 |
| Debug 计划所列四个套件 | 35 例通过；无跳过 |
| 补充项目切换守卫、恢复失败与历史删除隔离用例 | ProjectSelectionTests 7 例通过；无跳过 |
| Debug 全量 | 81 例通过，0 失败，0 跳过；测试执行 24.55 秒 |
| 差异检查 | git diff --check 通过 |

本机 Xcode 结果位于阶段构建目录的 `Logs/Test`，全量为 `Test-FlutterRunlet-2026.11.14_23-05-04-+0800.xcresult`。以两处原生交互为证的条目保留到 06-04。

## 提交

- `ff9f6b6`：历史机制的回归测试。
- `5f42b8a`：守卫、目录选择、历史及两处布局，包含运行与恢复期间的阻断和双语回归测试。
