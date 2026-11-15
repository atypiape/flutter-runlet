---
phase: 07-settings-about-updates
plan: "06"
subsystem: final-local-acceptance
tags: [macos, appkit, flutter, xctest, update]
requires:
  - phase: 07-settings-about-updates/07-05
    provides: 真实签名替换、活动门禁和回退
provides:
  - 同一普通 Release 的四处界面、真实 Flutter 会话和恢复记录
  - 同源码隔离 A/B 安装、门禁、回退及独立反馈记录
  - 六项需求及 D-01 至 D-12 的本地判定
key-files:
  created:
    - .planning/phases/07-settings-about-updates/07-ACCEPTANCE.md
    - .planning/phases/07-settings-about-updates/07-06-SUMMARY.md
requirements-completed: [UI-07, UI-13, UI-14, UI-15, UPD-01, UPD-02]
coverage:
  - id: ui-matrix
    description: 同一普通候选四处界面的中英文、系统深浅、键盘和 AX
    requirement: UI-07
    verification:
      - kind: automated_ui
        ref: .private/phase-07/final/ordinary-window-audit.json
        status: pass
      - kind: e2e
        ref: .private/phase-07/final/flutter-normal-final/actions.json
        status: pass
    human_judgment: false
  - id: settings-layout
    description: 设置三页、语义颜色、版本和开关
    requirement: UI-13
    verification:
      - kind: automated_ui
        ref: .private/phase-07/final/windows-isolated/
        status: pass
    human_judgment: false
  - id: preferences-and-doctor
    description: 登录项、语言与启动偏好持久化以及 Doctor 和 FVM
    requirement: UI-14
    verification:
      - kind: e2e
        ref: .private/phase-07/final/settings-preferences/actions.json
        status: pass
      - kind: e2e
        ref: .private/phase-07/final/settings-doctor-auto-replay/actions.json
        status: pass
    human_judgment: false
  - id: about-links-and-credit
    description: 关于窗口、实际 Bundle、六次真实浏览器导航和同源归属
    requirement: UI-15
    verification:
      - kind: automated_ui
        ref: .private/phase-07/final/links-isolated/en-dark/actions.json
        status: pass
    human_judgment: false
  - id: public-check
    description: 普通 Release 真实双入口、共享状态和信任冻结
    requirement: UPD-01
    verification:
      - kind: e2e
        ref: .private/phase-07/final/ordinary-update-audit.json
        status: pass
    human_judgment: false
  - id: isolated-install-and-rollback
    description: 同源码真实安装、活动门禁和隔离回退
    requirement: UPD-02
    verification:
      - kind: e2e
        ref: .private/phase-07/final/update-success.manifest-verify.log
        status: pass
      - kind: e2e
        ref: .private/phase-07/final/update-gate.manifest-verify.log
        status: pass
      - kind: e2e
        ref: .private/phase-07/final/update-rollback.manifest-verify.log
        status: pass
    human_judgment: false
actuals:
  tasks: 3
  commits: 1
completed: 2026-11-15
status: complete
---

# 07-06 · 最终本地验收

普通 Release 基于 `7752dab`，其程序源码树与 07-05 的 `5da4fd4` 相同。同一复制件 `com.atypiape.FlutterRunlet`、`v0.1.0 (build 1)` 用于普通界面、真实 Flutter 及公开查询。临时签名的双架构 App 可执行 SHA-256 为 `4146e0a9c8a953029af725a55717f7a7013fdb0987699d278cca19995c1ed316`。隔离 A/B 使用相同程序源码和各轮独立签名身份，记录见验收表。[最终验收](07-ACCEPTANCE.md)

| 任务 | 实测 |
| --- | --- |
| 07-06-01 | 冻结视觉 512 项，四种系统外观／语言组合共 28 张原生截图及 AX 操作证据，六次真实浏览器导航。普通 Release 构建和双架构签名完整性通过 |
| 07-06-02 | 通用偏好与真实登录项，手动、Auto 和 FVM，Doctor 正常／失败／取消，真实 iOS Flutter 会话、失败重试、暂停和退出恢复。全量 XCTest 128 项，定向 53 项，均 0 失败和 0 跳过 |
| 07-06-03 | 普通 Release 四轮真实查询保持安装门禁。同源 A/B 重跑 `success` 1 组、`gate` 1 组综合实测、`rollback` 13 组，补验坏包双入口重试与实际助手 8 种状态。六项本地需求及 D-01 至 D-12 逐项记录 |

## 执行调整与保留证据

- 早期四窗试拍读到宿主最近项目。签核采用显式启动隔离样例的重拍矩阵及同候选六次链接证据。普通 macOS 偏好仍由宿主默认域持有，恢复记录存放在各次独立的私有 Application Support。
- 私有 Flutter 取证沿用真实 HOME 缓存，为 VM 留出冷编译时间，并以实际 AX 选中值校对设备。一次采集中断后经同候选重开验证风险持久化和原任务恢复。其余重拍调整了窗口前置、HID 点击与真实 AX 观测时序，使用同一已固定 App。
- 对宿主已有登录项做前置检查，实际候选注册后注销并复核系统原状态。候选退出后精确移除测试新增偏好，11 个偏好键全量导出逐值、逐类型一致。专用 iOS 模拟器恢复初始 `Shutdown`。私有取证根为 `.private/phase-07/final/` 和 `.private/phase-07/update/`。

## 保留限制

运行实测覆盖 arm64 macOS 26.7.1 和隔离 iOS 模拟器。最低 macOS 15、Intel 实机、Apple Developer ID 正式签发、公证及公开可用性仍待各自实测。公开发布保持冻结，阶段级规划和独立验证交由主控。

## Self-Check: PASSED


普通候选的签名、Bundle 树、四组 UI、三轮真实 Flutter、四轮公开查询及三组隔离清单已复核。六项需求的唯一状态及全 PASS 约束通过。

## 审阅后复验

以 `2fcb4a3` 固定同源码最终普通 Release 和隔离 A/B。普通四组合、六链接、真实 GitHub 查询、系统偏好、Flutter 与 Doctor 全部复验。全量 133 项通过，其中前序回归 93 项。隔离包五套原生清单复核成功，新增 7 个安装交接故障场景已纳入。详细身份、原始取证位置、执行量与仍待覆盖的系统范围见[最终验收](07-ACCEPTANCE.md)。
