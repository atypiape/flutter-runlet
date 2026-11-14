# Phase 05 · G3 验收矩阵

受测版本 0.1.0（1）。macOS 26.7.1、Xcode 27.1、iOS 27.0。早期通过项及复用范围分别见 [G1](../01-upstream-audit-ui-shell/01-G1-ACCEPTANCE.md)、[P2](../02-config-task-execution-core/02-P2-ACCEPTANCE.md)、[G2](../03-flutter/03-G2-ACCEPTANCE.md)、[P4](../04-macos/04-P4-ACCEPTANCE.md)。最终候选见 [构建记录](05-01-SUMMARY.md) 和 [恢复矩阵](05-RECOVERY.md)。

| ID | 判定 | 候选与证据 |
|---|---|---|
| A01 | 通过 | 最终候选主窗实测 640 × 580 pt，原生控件顺序与 G1 基线一致。 |
| A02 | 通过 | 复用 G1 原生面板宽度证据，最终候选复验两种语言与共享会话。 |
| A03 | 通过 | Phase 04 状态基线与 Phase 05 的真实 Run、Stop、等待、恢复错误证据。 |
| A04 | 通过 | Phase 04 设置、窗口及登录项证据。最终候选复验两项启动偏好和恢复优先。 |
| A05 | 通过 | Phase 04 深浅色、长字段、焦点与双语证据。最终候选主窗及面板复验中英文，日志控件可读。 |
| A06 | 通过 | Phase 04 两套图标基线及最终 Release 包资源检查。 |
| A07 | 通过 | P2 JSONC 报错及重读，最终候选配置测试通过。 |
| A08 | 通过 | P2 四个公开样例启动项，最终候选选中并实测 prod。 |
| A09 | 通过 | P2 参数转换和文件保护，最终候选配置测试通过。 |
| A10 | 通过 | P2 PATH 继承覆盖，最终候选配置测试通过。 |
| A11 | 通过 | P2 cwd、参数和空格路径测试，最终 A13 复用公开脚本。 |
| A12 | 通过 | P2 缺失与不支持任务检查，Phase 05 前置失败实测。 |
| A13 | 通过 | 最终 Release A13 时序及解包复验。 |
| A14 | 通过 | 原后置失败留风险及重试成功，见 05-RECOVERY.md。 |
| A15 | 通过 | 三时点强退及重启恢复，见 05-RECOVERY.md。 |
| A16 | 通过 | 重复 Run、项目切换、第二实例租约，见 05-RECOVERY.md。 |
| A17 | 通过 | 当前 Release 实测 iPhone 18 Pro 与 iPhone 17，VM Service 已连接。 |
| A18 | 通过 | 当前 Release 在 Android 16 arm64 模拟器实测设备 ID、VM Service 和 Stop。实体设备适用性沿用 G2。 |
| A19 | 通过 | 当前 Release 在 Android 16 模拟器上热重载及热重启通过，设备内 App PID 相同。 |
| A20 | 通过 | 最终候选两轮原生点击均将 DevTools 和 Inspector 委派给默认浏览器，两入口指向同轮 VM Service，第二轮地址更新。Inspector 选取 Widget 沿用 G2 实测。 |
| A21 | 通过 | 沿用 Phase 04 关窗、面板和快捷键证据，Phase 05 实测双界面共享同一 Running。 |
| A22 | 通过 | 进程异常退出及目标设备断线后恢复，见 05-RECOVERY.md。 |
| A23 | 通过 | Phase 04 持久语言及系统语言基线。最终候选双语日志及控件名称复验。 |
| A24 | 通过 | Phase 04 FVM 实测与最终候选工具链测试。 |
| A25 | 通过 | Phase 04 Flutter Doctor 实测和最终候选工具链测试。 |
| A26 | 通过 | 最终候选关于页版本、构建号、上游版权及默认浏览器三个目标已实测。 |
| A27 | 通过 | 最终候选 30 分钟实测约 200.51 行/秒，四项反馈低于 184 ms，RSS 峰值增加 8.25 MiB，末段回落。见 05-LOG-STRESS.md。 |
| A28 | 通过 | 取消退出、正常停止并退出、恢复失败阻止退出均通过。 |
| A29 | 通过 | commit=36916dd1f6a6f916a1c76ca93aa37ae84f8247f6 app=52b6a4b1a6916e4ca0d457efcb98b10359785fc86e745267d1aa30a57fb64455 worker=a763ab4b27fb3bc348f2c32aa2edda2f9d5695f96a7ef222f2c95d2822d167e2。已定位获授权工程，完成隔离副本、真实 Firebase 文件基线备份和脚本的逐环境切换复验。VS Code 和当前候选逐环境验证 dev、test、prod 的参数与 Firebase 结果。两工具停止 prod 后均由原后置任务恢复 test 基线。 |
| A30 | 通过 | 最终候选 64 KiB 严格 UTF-8，清空及折叠展开无旧编号，新日志持续到达。 |
| A31 | 通过 | commit=36916dd1f6a6f916a1c76ca93aa37ae84f8247f6 app=52b6a4b1a6916e4ca0d457efcb98b10359785fc86e745267d1aa30a57fb64455 worker=a763ab4b27fb3bc348f2c32aa2edda2f9d5695f96a7ef222f2c95d2822d167e2。主程序和内嵌 worker 的各架构 Mach-O 最低版本均为 15.0。2026-11-14 用户取消 macOS 15 实机及虚拟机运行验收，该系统的运行兼容性未验证。 |
| A32 | 通过 | P2 非 Debug 配置禁用及最终候选 XCTest。 |

## 人工复核

commit=36916dd1f6a6f916a1c76ca93aa37ae84f8247f6 app=52b6a4b1a6916e4ca0d457efcb98b10359785fc86e745267d1aa30a57fb64455 worker=a763ab4b27fb3bc348f2c32aa2edda2f9d5695f96a7ef222f2c95d2822d167e2

无新增或改变的视觉差异。最终候选与 Phase 04 及上一候选对照了 640 × 580 pt 主窗、中英文日志区、配置及设备控件名称、原生面板和深色外观。最终替换改动在 VM Service 探活及日志原始编码比较。私有证据为 `g3/ui-unicode/`、`g3/about-unicode/` 及恢复矩阵对应场景。

无需人工补验。受影响的双语原生控件和运行状态已复验，浅色语义、四窗布局和系统焦点沿用 Phase 04 的原生证据。

## G3 判定与本地交付

G3 通过。32 项验收均有记录。A18 覆盖 Android 模拟器，实体设备按 G2 记录的不适用范围执行。A31 按用户更新后的 15.0 部署目标验收，macOS 15 运行兼容性未验证。

本地交付为 0.1.0（1）的同一签名 `FlutterRunlet.app`、`FlutterRunlet.zip` 和 `FlutterRunlet.zip.sha256`。ZIP SHA-256 为 `5e4e29423b539090e8ed3867b94c0b6e50637e4f6abc8e9581928f756d262e55`。解包候选通过文件、执行位、签名、普通启动、真实调试停止与恢复复验。公开分发、公证和链接匿名访问另按发布审计执行。 [归档证据](05-ENVIRONMENT.md) · [使用说明](../../../../README.md) · [发布说明](../../../../docs/RELEASE-NOTES.md) · [项目许可证](../../../../LICENSE)
