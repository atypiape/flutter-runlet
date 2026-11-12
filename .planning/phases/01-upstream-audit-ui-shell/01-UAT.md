---
status: complete
phase: 01-upstream-audit-ui-shell
source: [01-VERIFICATION.md]
started: 2026-11-11T19:43:45.896Z
updated: 2026-11-12T02:51:33.152Z
---

# G1 人工验收

使用本轮构建。启动命令、六张截图和尺寸记录见验收记录。 [G1 验收记录](01-G1-ACCEPTANCE.md)

## Current Test

[testing complete]

## Tests

### 1. 三种启动、运行提示与浅深外观

核对三种启动状态、两处运行提示及浅深外观。分别用验收记录的命令启动普通 Debug、带 --g1-ready 的 Debug 和带同一参数的 Release。检查主窗与面板的字段及动作，在两处 Ready 点击运行并关闭提示，对照四张主窗和面板截图，重点辨认浅色主窗的禁用按钮标签。

expected: |
  普通 Debug 和带参数的 Release 两处均为 Empty。只有带参数的 Debug 进入 Ready，且主窗与面板显示同一组固定脱敏数据。主窗外框 640 × 580 pt，面板宽 404 pt，四个调试按钮同排，日志默认展开且空。两处运行只弹出标题、正文及关闭按钮完整可见的原生提示，关闭后保持 Ready。禁用标签仍可辨认。
result: pass

### 2. 面板关闭与唯一主窗重开

核对菜单栏面板的外侧关闭及主窗重开。用状态项打开面板，分别点击状态项和面板外侧关闭。关闭 Ready 主窗，再从面板打开主窗两次。

expected: |
  两种方式都能关闭面板。关闭主窗后 App 和状态项保持运行，面板入口重开并聚焦同一扇主窗，Ready 数据仍在。
result: issue
reported: "点“打开主窗口”按钮或“设置”按钮弹出窗口，应该关闭面板才更符合；关闭主窗口后，菜单栏图标仍可用，但 dock 上应为关闭状态（图标底下不应有小圆点）。"
severity: minor

### 3. 键盘焦点和项目图标提示

核对主窗和面板的完整 Tab 焦点顺序、禁用动作及主窗工具栏文件夹图标的悬停文字。在系统键盘导航可用的情况下依序遍历，用键盘尝试触发禁用的调试和浏览器动作，再将指针停在「打开项目」图标上。

expected: |
  可交互控件按界面阅读顺序获得焦点，禁用动作无法由键盘触发。「打开项目」保持禁用并显示可读悬停提示。
result: issue
reported: "Tab 遍历没反应，没见到哪个控件获得焦点；鼠标悬停也没见到悬停提示"
severity: major

### 4. 设置与独立关于窗口

核对设置和独立关于窗口。分别从主窗与菜单栏打开设置，切换「通用」「Flutter」并返回。打开关于，对照设置及关于截图和实际 bundle。

expected: |
  两个入口聚焦同一设置窗口，首次显示通用，两项导航可用且清晰。独立关于显示品牌、FlutterRunlet、版本 0.1.0 和构建号 1，与运行 bundle 一致。
result: pass

### 5. 长字段和 macOS 部署证据

核对长字段与平台证据。在两份 Debug Live Canvas 预览逐项悬停项目、配置、设备，核对六张归档图、原生尺寸与差异说明，并核对 A31 和 D-09 的记录。

expected: |
  两处长字段单行省略，原生提示显示全文及对应尾段，主窗会话字段可换行。六图和原生差异可追溯。当前系统实测与两个配置的 macOS 15.0 部署证据分别记录，macOS 15 实机明确列为未执行。
result: pass

## Summary

total: 5
passed: 3
issues: 2
pending: 0
skipped: 0
blocked: 0

## Gaps

- gap_id: G-01-2
  truth: "从菜单栏面板打开主窗口或设置时，面板自动收起。关闭主窗口后，菜单栏图标仍可用，Dock 图标下不显示运行指示点。"
  status: resolved
  resolved_by: 01-04-PLAN.md
  resolved_at: 2026-11-12
  reason: "User reported: 点“打开主窗口”按钮或“设置”按钮弹出窗口，应该关闭面板才更符合；关闭主窗口后，菜单栏图标仍可用，但 dock 上应为关闭状态（图标底下不应有小圆点）。"
  severity: minor
  test: 2
  root_cause: "面板入口只打开或聚焦窗口，缺少收起面板的动作。主窗关闭后进程仍存活且保留 AppKit 普通激活策略，Dock 继续显示运行指示。"
  artifacts:
    - path: FlutterRunlet/MenuBarPanelView.swift
      issue: "主窗和设置按钮只调用开窗回调。"
    - path: FlutterRunlet/FlutterRunletApp.swift
      issue: "主窗生命周期未切换激活策略，窗口入口未收起面板。"
  missing:
    - "两个开窗入口主动收起当前面板，保留图标点击和点外关闭。"
    - "主窗关闭后移除 Dock 运行指示并保持同一进程和菜单栏可用，重开恢复常规窗口行为。"
  debug_session: .planning/debug/g1-panel-dock.md

- gap_id: G-01-3
  truth: "主窗和面板的可交互控件按阅读顺序获得可见的 Tab 焦点，禁用动作无法由键盘触发。「打开项目」保持禁用并显示可读的悬停提示。"
  status: resolved
  resolved_by: 01-04-PLAN.md
  resolved_at: 2026-11-12
  reason: "User reported: Tab 遍历没反应，没见到哪个控件获得焦点；鼠标悬停也没见到悬停提示"
  severity: major
  test: 3
  root_cause: "本机检查时原生键盘导航关闭，原生按钮的 Tab 焦点依赖该系统偏好，开启后的焦点链仍待验证。禁用工具栏按钮上的 SwiftUI help 未显示原生提示，具体宿主机制仍待对照。"
  artifacts:
    - path: FlutterRunlet/MainWindowView.swift
      issue: "项目入口的 help 直接附在禁用工具栏按钮上。"
    - path: FlutterRunlet/MenuBarPanelView.swift
      issue: "面板使用原生焦点，开启系统键盘导航后的焦点链尚无证据。"
  missing:
    - "开启系统键盘导航复验两处可见焦点、阅读顺序与禁用动作，仅修正实际失败的焦点路径。"
    - "使用可实际显示的原生悬停区域，保持项目入口禁用与可访问名称。"
  debug_session: .planning/debug/g1-focus-help.md
