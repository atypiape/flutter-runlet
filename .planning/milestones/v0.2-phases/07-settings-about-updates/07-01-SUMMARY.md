---
phase: 07-settings-about-updates
plan: "01"
subsystem: ui
tags: [figma, macos, settings, about, visual-baseline]
requires:
  - phase: 06-main-window-menu-bar
    provides: 原生窗口、系统选择器与键盘证据的复核方法
provides:
  - 设置三页、独立关于及共用更新组件的批准稿度量及私有原图索引
  - V01–V05 逐状态截图矩阵及复拍条件
affects: [07-settings-about-updates]
actuals:
  tokens: 35301
  tasks: 2
  commits: 2
plan_head_before: 78627b8bfedbeb925107b72ccaf054f5e161b61f
tech-stack:
  added: []
  patterns: [同节点原图与原生截图按比例配对, Figma 实例及状态索引]
key-files:
  created: [.planning/phases/07-settings-about-updates/07-VISUAL-BASELINE.md, .planning/phases/07-settings-about-updates/07-01-SUMMARY.md]
  modified: []
key-decisions:
  - "117:260 与 145:230 用于 Flutter 和设置关于整窗导出，保留计划指定的 165:543 与 165:609 实例测量。"
  - "中文深色按钮变体使用 116 × 30 pt 原图局部，整窗反馈依据实例与变量。"
  - "保留 2× 原始参考，1× 显示器优先配同节点 1× 补导。"
patterns-established:
  - "按窗口、状态、语言、外观和帧固定用例 ID，保留适用性、输入、参考与证据类型。"
requirements-completed: [UI-13, UI-14, UI-15, UPD-01, UPD-02]
coverage:
  - id: D1
    description: 批准稿实例读数和两种比例的原图
    verification:
      - kind: other
        ref: 07-01-PLAN.md 任务 1 的四节点检查及 36 张 PNG 完整性检查
        status: pass
      - kind: manual_procedural
        ref: 四整窗各复核文字、图标与边界，11 变体核对两组四帧
        status: pass
    human_judgment: false
  - id: D2
    description: V01–V05 逐状态矩阵
    verification:
      - kind: other
        ref: 07-01-PLAN.md 任务 2 的 Ruby 索引检查及 136 个窗口状态帧组合交叉核对
        status: pass
    human_judgment: false
duration: 19min
completed: 2026-11-15
status: complete
---

# 阶段 07 计划 01 · 批准稿度量与逐状态证据基线

**四窗、三个辅助画板与 11 个更新按钮变体已复测，V01–V05 冻结 516 个适用取证用例。**

## 执行记录

- 两项任务完成。自首张原图保存至两项任务验证结束约 19 分钟，2026-11-15 06:05–06:24 UTC。
- 任务 1 `ae6d294` 复测四窗、公共组件、字体段与条件显示层，登记三张设置外框 520 × 520 pt、标题栏 47 pt、侧栏 116 pt，独立窗 400 × 412 pt、内容组 398 × 374 pt，两处更新按钮及 11 变体均 116 × 30 pt。独立窗 MIT 和 Svame 两条可见行分别复测。
- 任务 2 `ebc11f2` 冻结 544 行，其中 516 行 `REQUIRED`、28 行 `N/A`，覆盖 136 个窗口／状态／帧组合。检查与更新各有四个静态位相和连续旋转记录入口。两处关于均有窗口同步、稍后继续，以及五类等待阻塞的取证行，旧版无法自动打开用独立反馈窗口。
- 18 个节点保存为 `P07-F01`–`P07-F07`、`P07-U01`–`P07-U11`。本机 `.private/phase-07/figma-originals/` 保留 2× 原始 PNG，`figma-1x/` 有同节点 1× 补导，`exports.tsv` 保存尺寸及 SHA-256，`measurements/` 保存 379 条主读数和补测记录。

## 复测决定与偏差

- 四个计划节点全部保留。批准稿中的 `165:543` 是 Flutter 侧栏，`165:609` 是设置关于标题栏，整窗采用各自父画板 `117:260` 和 `145:230`。
- 批准实例优先于旧取证概述。语言菜单中文标题与中文项为 Noto Sans SC，English 项为 SF Pro。两处品牌和版本为 SF Pro，反馈为 Noto Sans SC Regular。Svame 署名为 SF Pro Regular。记录了设置关于侧栏中通用齿轮保留蓝色的实例差异。
- 11 个更新原图的截取范围为按钮，整窗状态由各自批准布局、反馈与版本变量配合实拍核对。英文、浅色、系统焦点和无原图分支使用对应组件、变量和本机证据。两块当前显示器为 1×，优先使用补导文件。
- Figma 连接器完成了全部读取与导出。新候选的原生 AX、1× 捕获、实机视觉和真实更新验证属于后续波次。

## 验证

- 两条计划命令通过。另逐行核对 12 列、用例 ID 唯一、双语双外观覆盖、帧与参考匹配及每个不适用原因。抽查语言菜单、原生目录取消、独立窗四个检查帧、两处稍后及旧版无法打开后的独立反馈。
- 36 张 PNG 的解码、逻辑边界、实际尺寸、sRGB 与清单 SHA-256 全部通过。四窗文字、图标及边界与实例读数对应，两个旋转组分别复核 0°／90°／180°／−90°。六个项目链接的目标与现有定义一致，三个网页均返回 HTTP 200，LICENSE 原文与仓库文件哈希一致。
- GSD 当前分支范围核对识别两项任务提交。此波完成设计取证，App 构建、测试与原生视觉签核由相应波次执行。

## 后续

[视觉与取证基线](07-VISUAL-BASELINE.md) 已满足 07-01 的实施输入，无关键批准图层读数阻塞。下一波由协调者启动。

## Self-Check: PASSED
