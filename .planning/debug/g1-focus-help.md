---
status: diagnosed
phase: 01
gap_id: G-01-3
updated: 2026-11-12
---

# G1 键盘焦点与项目图标提示

## 症状

用户在第 3 项验收报告 Tab 未显示控件焦点，悬停「打开项目」也未看到提示。该项约定在系统键盘导航可用的条件下验证，禁用动作应保留禁用语义。 [验收第 3 项](../phases/01-upstream-audit-ui-shell/01-UAT.md) · [G1 界面规范](../phases/01-upstream-audit-ui-shell/01-UI-SPEC.md)

## 证据与诊断

- **Tab 焦点受系统键盘导航控制。** 本机只读查询中 `NSApplication.shared.isFullKeyboardAccessEnabled` 返回 `false`，`defaults read -g AppleKeyboardUIMode` 返回 `1`。主窗和面板均使用 SwiftUI 原生按钮，没有接管 Tab。Apple 说明原生按钮类控件的焦点激活取决于系统的全控件键盘导航，在「系统设置 → 键盘 → 键盘导航」可以启用 Tab／Shift-Tab 遍历。当前读值与用户现象相符，用户按键当时的设置及开启后的主窗、面板焦点链仍待复验。 [主窗控件](../../FlutterRunlet/MainWindowView.swift#L38) · [面板控件](../../FlutterRunlet/MenuBarPanelView.swift#L31) · [Apple 键盘导航](https://support.apple.com/guide/mac-help/-mchlc06d1059/mac) · [SwiftUI 焦点规则](https://developer.apple.com/documentation/swiftui/view/focusable(_:interactions:))
- **当前工具栏的 `.help` 未为禁用项目入口提供实际可见的提示。** 活跃进程由 `.build/phase-01/Build/Products/Debug/FlutterRunlet.app` 带 `--g1-ready` 启动，与 `281cafa` 的本轮复验产物路径一致。该提交将 `.help("打开项目")` 直接加在 `.disabled(true)` 的工具栏按钮上。只读检查当前进程，项目按钮保持 `AXEnabled=false` 且 `AXHelp` 缺失，设置与关于按钮也没有 `AXHelp`。复验日志同样记录项目按钮有名称而无帮助文本，用户实测补齐了可见 Help Tag 的失败证据。AX 字段缺失本身不足以判定视觉提示机制，SwiftUI 工具栏宿主和禁用控件各自的影响仍待对照验证。 [项目按钮实现](../../FlutterRunlet/MainWindowView.swift#L38) · [复验处置](../phases/01-upstream-audit-ui-shell/01-REVIEW-DISPOSITION.md) · [SwiftUI help](https://developer.apple.com/documentation/swiftui/view/help(_:))

## 修复计划输入

1. 在明确开启原生键盘导航的环境下，使用新 Debug Ready 构建复验主窗和面板的 Tab／Shift-Tab、可见焦点环、Space 激活与禁用控件跳过。面板检查需覆盖从其他前台 App 唤起及弹窗返回。若某个宿主仍无法遍历，再定位该宿主的 key window 和焦点链，修复限于该宿主并遵循系统键盘偏好。
2. 在同一构建和窗口状态下，分别对照「打开项目」及两个启用工具栏图标的真实鼠标悬停。让项目提示由独立于禁用动作的原生悬停区域提供，或由明确支持提示的原生工具栏宿主注册。实测可见文字、AX 名称、禁用状态及鼠标和键盘无法激活。 [AppKit toolTip](https://developer.apple.com/documentation/appkit/nsview/tooltip)
