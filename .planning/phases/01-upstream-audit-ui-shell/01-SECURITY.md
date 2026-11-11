---
phase: "01"
slug: upstream-audit-ui-shell
status: verified
threats_open: 0
asvs_level: 1
created: "2026-11-12"
---

# Phase 1 · 安全验证

## Trust Boundaries

| 边界 | 已验证范围 |
| --- | --- |
| 上游 Git 对象 → 项目源码及 App | 固定提交、包清单、许可证与最终导入清单 |
| 本地启动参数 → 展示和操作 | Debug 精确参数、Release 编译条件、运行演示提示 |
| App bundle 与构建产物 → 用户及验收 | 版本和构建号、两种配置的 Mach-O、原生截图 |

## Threat Register

| Threat ID | 类别 | 范围 | 级别 | 处置 | 证据 | 状态 |
| --- | --- | --- | --- | --- | --- | --- |
| T-01-01 | Tampering | 上游来源 | medium | mitigate | 核对固定 SHA、SwiftPM 清单与 MIT。比对源码和最终资源，实际导入清单为空。 [审计](01-UPSTREAM-AUDIT.md) · [分发复核](01-G1-ACCEPTANCE.md#base-01--上游来源与许可) | closed |
| T-01-02 | Elevation of Privilege | 演示入口和操作 | high | mitigate | 解析限定于 `#if DEBUG`，使用精确参数匹配。XCTest 三项通过，Release 携带同一参数时两处均为 Empty。两处 Run 只进入同一个 `NSAlert`。 [启动策略](../../../FlutterRunlet/LaunchPresentation.swift) · [XCTest](../../../FlutterRunletTests/LaunchPresentationTests.swift) · [实测](01-G1-ACCEPTANCE.md#a01--主窗口) | closed |
| T-01-03 | Tampering | 兼容性证据 | medium | mitigate | 本轮成功产物的有效设置和全部 Mach-O 切片均为 15.0，当前运行系统另行记录。 [A31](01-G1-ACCEPTANCE.md#a31--macos-15-部署目标与-api) | closed |
| T-01-04 | Information Disclosure | 取证范围 | medium | mitigate | 按窗口编号捕获六张图，逐图核查只有 App 界面和固定样例。 [截图及核对记录](01-G1-ACCEPTANCE.md) | closed |
| T-01-05 | Spoofing | 关于与许可 | low | mitigate | 关于窗口的版本与构建号来自运行 bundle，实际显示与两份构建的 Info.plist 一致。最终无上游源码或资源导入。 [关于实现](../../../FlutterRunlet/AuxiliaryWindows.swift) · [实测与上游复核](01-G1-ACCEPTANCE.md) | closed |
| T-01-06 | Information Disclosure | 长字段预览 | low | mitigate | 两份 Live 预览和长文本固定值限定在 Debug。样例脱敏，正常和 Release 启动均未显示长样例。 [固定值和编译条件](../../../FlutterRunlet/LaunchPresentation.swift) · [预览实测](01-G1-ACCEPTANCE.md#长字段复验) | closed |
| T-01-SC | Tampering | 工具链与资源 | low | accept | Xcode 自带 SwiftUI、AppKit 和 XCTest，使用既有设计资源。项目无第三方 SwiftPM 依赖。 [审计](01-UPSTREAM-AUDIT.md) | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | 已登记的范围 | 来源 |
| --- | --- | --- | --- |
| 01-SC | T-01-SC | G1 依赖 Apple 系统工具链与仓库已有品牌资源。 | 01-01 至 01-03 计划的风险登记 |

## Sign-Off

- [x] 三份计划的风险均有处置及本轮证据。
- [x] ASVS 1 级检查完成。高危及以上未关闭项为 0。

## Security Audit 2026-11-11

| Metric | Count |
|---|---|
| Threats found | 7 |
| Closed | 7 |
| Open | 0 |
