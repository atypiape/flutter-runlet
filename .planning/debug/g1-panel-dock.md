---
status: diagnosed
trigger: G-01-2
created: 2026-11-12T01:53:00Z
updated: 2026-11-12T01:53:00Z
---

# G1 菜单栏面板和 Dock

## 症状

从面板打开主窗或设置时，面板仍展开。关闭主窗后菜单栏可用，Dock 图标下仍显示运行指示点。用户要求两个开窗入口收起面板，主窗关闭后保持菜单栏可用并移除 Dock 的运行指示。[UAT 第 2 项](../phases/01-upstream-audit-ui-shell/01-UAT.md)

## 根因与证据

- **面板收起。** `MenuBarPanelView.swift:36–45` 的两个按钮仅调用开窗回调。`FlutterRunletApp.swift:37–49, 63–95` 的回调只打开或聚焦窗口并激活应用，没有收起当前面板的动作。当前使用的 SwiftUI `MenuBarExtra(.window)` 公共接口没有面板展开状态绑定。`isInserted` 控制系统状态图标的插入。SwiftUI 文档描述了标准弹出层和窗口的 `dismiss`，仍需在真实菜单栏场景上验证其行为。[MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra) · [isInserted](https://developer.apple.com/documentation/swiftui/menubarextra/init(isinserted:content:label:)) · [dismiss](https://developer.apple.com/documentation/swiftui/environmentvalues/dismiss)
- **Dock 指示。** `FlutterRunletApp.swift:107–119` 的主窗桥接只设置窗口标识，应用无窗口关闭监听或激活策略切换。Debug bundle 的 `Info.plist` 未设置 `LSUIElement`，本机读取正在运行的 Debug 进程为 `activationPolicy=0`（`.regular`）。G1 已记录关闭主窗后进程仍存活，符合菜单栏常驻契约。Dock 指示点由系统按应用运行和激活策略显示。Apple 文档确认 `.regular` 参与 Dock 展示，切到 `.accessory` 可继续运行、展示窗口和被激活，且移除应用的运行指示。用户固定的 Dock 启动图标属于独立的系统项，实际显示应在固定与未固定两种情况下复验。[G1 实测](../phases/01-upstream-audit-ui-shell/01-G1-ACCEPTANCE.md#a02--菜单栏快捷面板) · [AppKit 激活策略](https://developer.apple.com/documentation/appkit/nsapplication/activationpolicy-swift.enum) · [后台运行与 Dock](https://developer.apple.com/documentation/appkit/managing-ongoing-background-processes-in-your-mac) · [Dock 设置](https://support.apple.com/guide/mac-help/change-desktop-dock-settings-mchlp1119/mac)

## 修复方向与复验

- 给面板的两个开窗按钮接入显式关闭动作。先在真实构建验证当前面板是否响应公共关闭方式，复验关闭、重新打开和重复点击。若无法可靠控制现有宿主，可用原生 `NSStatusItem` 和 `NSPopover` 承载同一 SwiftUI 内容，以便直接调用 `performClose(_:)`。保留状态图标、404 pt 布局、面板外关闭、Ready 数据及原有开窗入口。[NSPopover 关闭](https://developer.apple.com/documentation/appkit/nspopover/performclose(_:))
- 监听已标识的主窗关闭，在切换到菜单栏常驻状态时使用 `.accessory`，重开主窗前恢复 `.regular`，并验证切换返回值。显式复验设置或关于窗口仍开着时的焦点和应用菜单，区分关闭、最小化和切换应用。记录相同 PID、Dock 运行指示、可用的菜单栏图标及唯一主窗重开。[设置激活策略](https://developer.apple.com/documentation/appkit/nsapplication/setactivationpolicy(_:))

本次只核对源码、构建元数据、运行进程的当前激活策略和 Apple API。面板主动关闭方式、固定 Dock 图标表现和附属窗口焦点需在修复构建中复验。
