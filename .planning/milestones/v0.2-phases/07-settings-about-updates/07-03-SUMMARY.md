---
phase: 07-settings-about-updates
plan: "03"
subsystem: ui
tags: [figma, macos, visual-gate, accessibility]
requires:
  - phase: 07-settings-about-updates/07-02
    provides: 原生设置与关于窗口、受控更新展示
provides:
  - 同一原生候选的逐状态视觉签核
  - 真实更新波次可运行的视觉验证器
affects: [07-settings-about-updates/07-04, 07-settings-about-updates/07-05]
key-files:
  created:
    - scripts/verify-phase-07-visual-gate.rb
    - .planning/phases/07-settings-about-updates/07-VISUAL-GATE.md
  modified:
    - FlutterRunlet/AuxiliaryWindows.swift
    - .planning/phases/07-settings-about-updates/07-VISUAL-BASELINE.md
requirements-completed: [UI-13, UI-14, UI-15, UPD-01, UPD-02]
completed: 2026-11-15
---

# 07-03 · 原生窗口逐状态视觉签核

候选 `bfd53cc` 的实际 Debug Bundle 为 v0.2.0 (build 256)。512 项适用用例通过，0 项失败、0 项阻塞、32 项不适用。四种语言与外观组合均已取得原生证据，明细见[视觉门槛](07-VISUAL-GATE.md)。其中 272 项为两处关于的原型及扩展更新状态。2613 个证据条目留在本机 `.private/phase-07/visual/manifest.json`。

- 按原图实测的透明度修复两处旋转按钮，保留其实际禁用及 AX。通过隐藏关于窗口的滚动条占位消除英文长反馈时的横移。设置侧栏的长版本可换行。
- 测过实际通用偏好、SDK 选择、Doctor、两处关于链接、键盘操作和系统目录导航。补采 Tab／Shift-Tab、Space 激活、Escape 回焦及 Doctor 滚动、复制末行选中文字和关闭弹层。
- 以系统 HID 按键记录、前后实拍和 AX 取证核对键盘行为。长版本以同一原生候选的受控展示输入检验，正常窗口另验实际 Bundle 版本。这两项证据方法已记录在[视觉基线](07-VISUAL-BASELINE.md)。
- 本机仅注册、撤回并清理隔离候选登录项。撤回后开关关闭，系统没有产生待批准状态。四个依赖该系统状态的实机用例标为 N/A。真实登录偏好另有四种组合的开关和重启验证，待批准分支的状态、文案和注销操作由宿主 XCTest 覆盖。

Debug 全量 100 项通过，0 失败、0 跳过。固定 Bundle 的签名完整性通过。验证器隔离自检通过，拒绝按例串图、复用采集事件、遗漏及修改受保护资源。真实门槛命令返回 `VISUAL PASS: 512 required cases verified`。

## Self-Check: PASSED

已核对候选源码、Bundle 与截图绑定，核验原图 SHA-256、证据清单及所有适用用例。07-04 现在可以通过同一门槛接入真实更新查询。
