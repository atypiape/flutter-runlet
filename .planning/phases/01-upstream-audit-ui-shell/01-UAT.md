---
status: testing
phase: 01-upstream-audit-ui-shell
source: [01-VERIFICATION.md]
started: 2026-11-11T19:43:45.896Z
updated: 2026-11-11T19:43:45.896Z
---

# G1 人工验收

使用本轮构建。启动命令、六张截图和尺寸记录见验收记录。 [G1 验收记录](01-G1-ACCEPTANCE.md)

## Current Test

number: 1
name: 三种启动、运行提示与浅深外观
expected: |
  普通 Debug 和带参数的 Release 两处均为 Empty。只有带参数的 Debug 进入 Ready，且主窗与面板显示同一组固定脱敏数据。主窗外框 640 × 580 pt，面板宽 404 pt，四个调试按钮同排，日志默认展开且空。两处运行只弹出标题、正文及关闭按钮完整可见的原生提示，关闭后保持 Ready。禁用标签仍可辨认。
awaiting: user response

## Tests

### 1. 三种启动、运行提示与浅深外观

核对三种启动状态、两处运行提示及浅深外观。分别用验收记录的命令启动普通 Debug、带 --g1-ready 的 Debug 和带同一参数的 Release。检查主窗与面板的字段及动作，在两处 Ready 点击运行并关闭提示，对照四张主窗和面板截图，重点辨认浅色主窗的禁用按钮标签。

expected: |
  普通 Debug 和带参数的 Release 两处均为 Empty。只有带参数的 Debug 进入 Ready，且主窗与面板显示同一组固定脱敏数据。主窗外框 640 × 580 pt，面板宽 404 pt，四个调试按钮同排，日志默认展开且空。两处运行只弹出标题、正文及关闭按钮完整可见的原生提示，关闭后保持 Ready。禁用标签仍可辨认。
result: [pending]

### 2. 面板关闭与唯一主窗重开

核对菜单栏面板的外侧关闭及主窗重开。用状态项打开面板，分别点击状态项和面板外侧关闭。关闭 Ready 主窗，再从面板打开主窗两次。

expected: |
  两种方式都能关闭面板。关闭主窗后 App 和状态项保持运行，面板入口重开并聚焦同一扇主窗，Ready 数据仍在。
result: [pending]

### 3. 键盘焦点和项目图标提示

核对主窗和面板的完整 Tab 焦点顺序、禁用动作及主窗工具栏文件夹图标的悬停文字。在系统键盘导航可用的情况下依序遍历，用键盘尝试触发禁用的调试和浏览器动作，再将指针停在「打开项目」图标上。

expected: |
  可交互控件按界面阅读顺序获得焦点，禁用动作无法由键盘触发。「打开项目」保持禁用并显示可读悬停提示。
result: [pending]

### 4. 设置与独立关于窗口

核对设置和独立关于窗口。分别从主窗与菜单栏打开设置，切换「通用」「Flutter」并返回。打开关于，对照设置及关于截图和实际 bundle。

expected: |
  两个入口聚焦同一设置窗口，首次显示通用，两项导航可用且清晰。独立关于显示品牌、FlutterRunlet、版本 0.1.0 和构建号 1，与运行 bundle 一致。
result: [pending]

### 5. 长字段和 macOS 部署证据

核对长字段与平台证据。在两份 Debug Live Canvas 预览逐项悬停项目、配置、设备，核对六张归档图、原生尺寸与差异说明，并核对 A31 和 D-09 的记录。

expected: |
  两处长字段单行省略，原生提示显示全文及对应尾段，主窗会话字段可换行。六图和原生差异可追溯。当前系统实测与两个配置的 macOS 15.0 部署证据分别记录，macOS 15 实机明确列为未执行。
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
