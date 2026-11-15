---
phase: 07-settings-about-updates
plan: "05"
subsystem: update-transaction
tags: [macos, appkit, apfs, code-signing, xctest]
requires:
  - phase: 07-settings-about-updates/07-03
    provides: 冻结的视觉证据与验证器
  - phase: 07-settings-about-updates/07-04
    provides: 真实发行查询、签名包预检和原生复证
provides:
  - 签名 App 和嵌入助手的同卷事务及健康交接
  - 覆盖调试和环境恢复的跨进程安装门禁
  - 以磁盘实物为准的中断重入和独立恢复反馈
  - 四组可重放的原生验收及证据清单
actuals:
  tasks: 3
  commits: 7
tech-stack:
  added: []
  patterns: [APFS 原子交换, 继承活动租约, Unix 本地域套接字进程认证, 双向健康握手]
key-files:
  created: [FlutterRunlet/UpdateTransaction.swift, FlutterRunlet/UpdateActivityLease.swift, FlutterRunletUpdateHelper/main.swift, scripts/verify-phase-07-update.sh]
  modified: [FlutterRunlet/UpdateCoordinator.swift, FlutterRunlet/AppTermination.swift, FlutterRunlet/SessionController.swift, FlutterRunlet/UpdatePackage.swift]
key-decisions:
  - 使用同一 macOS 用户下独立签名产品、固定 APFS 目录及隔离偏好和恢复命名空间。
  - 复用恢复初始化锁在交接期间拦住旧版新启动，并核对旧项目锁、worker 和同产品进程。
  - 普通 Release 继续访问固定公开仓库。发行者信任保持冻结，测试接线只编入专用构建。
requirements-completed: [UPD-01, UPD-02]
coverage:
  - id: D1
    description: 受信助手就绪后由 AppKit 正常退出，原路径完成实际签名包升版和三处版本刷新
    requirement: UPD-02
    verification:
      - kind: e2e
        ref: .private/phase-07/update/success-20261115T103211479770Z/manifest.json
        status: pass
    human_judgment: false
  - id: D2
    description: 调试及恢复期间可下载，安装被真实受管活动、旧版和遗留 worker 阻挡
    requirement: UPD-02
    verification:
      - kind: automated_ui
        ref: .private/phase-07/update/gate-20261115T101914273897Z/manifest.json
        status: pass
      - kind: integration
        ref: FlutterRunletTests/UpdateInstallGateTests.swift
        status: pass
    human_judgment: false
  - id: D3
    description: 按实际目录、签名和进程恢复，无法自动打开时独立提供恢复路径和操作
    requirement: UPD-02
    verification:
      - kind: e2e
        ref: .private/phase-07/update/rollback-20261115T102753153191Z/manifest.json
        status: pass
    human_judgment: true
    rationale: AppKit 独立提示需要与签核视觉对照，取证范围记录在 07-UPDATE-EVIDENCE.md。
  - id: D4
    description: 普通 Release 从固定公开仓库查询并明确显示不可安全安装
    requirement: UPD-01
    verification:
      - kind: automated_ui
        ref: .private/phase-07/update/native-07-05-final-en-about/actions.json
        status: pass
    human_judgment: false
completed: 2026-11-15
status: complete
---

# 07-05 · 原子更新、运行门禁与回退

隔离候选 A 从真实回环源下载 B。嵌入助手经独立通道证明就绪，A 走 AppKit 正常退出。同卷交换后，B 从原路径以新进程完成双向健康应答。设置侧栏、设置关于和独立关于均显示实际 `v7.5.1 (build 751)`。旧版 A 的原 inode 保留在私有暂存区。

## 任务提交

| 任务 | 提交 | 实测内容 |
| --- | --- | --- |
| 07-05-01 | `1c58f24`, `16cf309`, `d002404`, `05d7a78`, `cc338b9` | 两次 RED。真实下载及签名预检、租约、助手交接、同卷交换和最小回退 |
| 07-05-02 | `74cd7fb` | Doctor 及项目活动守卫、真 Flutter 跨实例、恢复、旧版与遗留 worker |
| 07-05-03 | `a067de7` | 提交边界复验、启动重入、中断恢复、原生场景重放和证据校验 |

## 验证

- 施工前和终版均实际执行视觉门槛并通过 512 项。包含 07-04 已批准的查询和不可安全安装展示复证。07-04 下载验包交接重跑 11 项通过，加入嵌套更新助手后同一验包套件 12 项通过。
- RED 两轮各实跑一项、失败一项、无跳过，Xcode 退出码均为 65，报告校验为 `RED_EVIDENCE_OK`。旧实现分别放行缺助手的真实签名 DMG、以及独占预约下的项目活动。
- `bootstrap-safety` 4 组、`success` 1 组、`gate` 1 组综合实测、`rollback` 13 组通过。清单条目直接链接到原生截图与 AX、实际签名及磁盘身份、PID、下载字节与事务回执。具体路径见 [07-UPDATE-EVIDENCE.md](07-UPDATE-EVIDENCE.md)。
- Debug 全量 128 项通过，0 失败、0 跳过。普通 Release 构建和签名完整性通过，本地双架构 Release DMG 与助手签名校验通过。
- 普通 Release 两个入口分别在中英文实测匿名查询。两个入口均收到 HTTP 200，显示 `v0.1.1` 尚未锁定、不可安全安装，并保留查看发布页。英文轮额外传入演示参数和假端点，实际请求仍发往固定公开仓库。

## 实施时的调整

- 在现有专用目录复用 APFS 隔离，沿用测试 Bundle ID 及独立 home，并在 NSWorkspace 重启时传递隔离配置。保留主控对 STATE、ROADMAP 和 07-06 的管理。
- PID 短暂失去签名可读性时仍在有界时间内等待系统确认退出。取得确认后再回退。恢复 A 的单调等待最长 30 秒，回执先落盘、锁先释放，再让 A 完成普通初始化。
- 新的独立恢复界面采用 AppKit 提示。与冻结演示尺寸不同，需复拍两种语言与两种外观中的两个恢复状态。既有关于窗口、设置页面和已有展示词通过冻结源验证。

## Self-Check: PASSED

四份场景清单已读取并核对链接的状态、原始记录及截图摘要。所有提交位于当前分支。
