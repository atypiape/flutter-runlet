---
phase: "02"
slug: "config-task-execution-core"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-12"
---

# Phase 02 · 验证策略

## 测试基础设施

- 复用 `FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme` 的 macOS XCTest target `FlutterRunletTests`。已有 `LaunchPresentationTests` 用于 G1 回归。
- 全量命令为 `xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-02" -parallel-testing-enabled NO test`。单任务在 `test` 前加计划指定的 `-only-testing:FlutterRunletTests/<测试类>`。
- 每个关键行为先见目标断言失败再实现，任务完成后运行对应测试，波次末和人工验收前运行全量。复用同一 DerivedData，首次执行记录冷启动和增量反馈耗时。另构建 Release 验证 Debug 注入边界。

## 验证覆盖

| 验证行为 | 需求 / 验收 | 方法 |
|---|---|---|
| 真实样例前置 → 可控子进程 → 退出 → 后置 | CONF-02、TASK-01、SAFE-01 / A07、A08、A11、A13 | 实际任务脚本和可控进程，断言真实退出顺序、test 环境标记和两份配置字节。 |
| 项目打开、自动选择、重读、记住最近项目 | CONF-01、CONF-02 / A07、A08 | 临时项目、多配置、旧选择、重复名、缺失和损坏文件。人工核对两处状态和打开入口。 |
| 启动参数、工作目录、环境和不支持项 | CONF-03–CONF-05、TASK-01、TASK-02 / A09–A12、A32 | 公开样例和定向变体，断言文件诊断、真实 argv/cwd/env、任务独立环境、禁用配置无执行及合法变更二次点击。 |
| 风险提交、恢复失败和重试 | SAFE-02、SAFE-03 / A14、A15 | 测试文件数据及父目录项各自同步失败、前置部分写入、仅 post、重启、原任务/变量变化、后置失败和清除同步失败。断言前置／调试进程启动次数和环境标记。 |
| 会话和项目锁 | SAFE-04 / A16 | 重复 Run、目录别名、运行中切换和退出。分别用 Stop 和父控制管道断开让受管包装进程先退出，验证同组同步后代活动期间不得执行后置或取得竞争租约。 |
| Debug 验收边界 | D-15、SAFE-04 / A15、A16 | 两个样例放在固定根内，重启复用同一身份。普通项目和指向它的根内符号链接在打开、Run 和恢复均产生零副作用。 |

## 任务级验证

下表的测试类使用上文共享命令的 `-only-testing:FlutterRunletTests/<测试类>`。最终 Debug XCTest 32 项通过。原生桌面场景的证据和用户复验状态见验收记录。

| 任务 | 波次 | 验证入口 | 威胁引用 | 断言与证据 | 结果 |
|---|---:|---|---|---|---|
| 02-01-01 | 1 | SessionLifecycleTests、LaunchPresentationTests | T-02-01–T-02-04 | 真实前置、持久风险、真实受管退出、后置和字节校验，重复 Run 只启动一次，Debug 固定根及重启身份隔离。 | 通过 |
| 02-01-02 | 1 | SessionLifecycleTests | T-02-01 | 仅后置时先持久提交记录。非 Debug、文件同步和父目录项同步失败均零副作用，部分写入及恢复失败保留风险。 | 通过 |
| 02-02-01 | 2 | ProjectConfigurationTests、SessionLifecycleTests | T-02-05 | 四原名、JSONC 坐标、旧 define、PATH、入口及参数，执行层阻断非 Debug。 | 通过 |
| 02-02-02 | 2 | ProjectConfigurationTests、SessionLifecycleTests | T-02-06 | 真实 shell/process 的 argv、cwd、env、退出码，非法输入和任务文件独立诊断。 | 通过 |
| 02-02-03 | 2 | ProjectSelectionTests、LaunchPresentationTests | T-02-07 | 过期、重名、删除和最近项目状态，复验发现有效变更时当次零副作用。 | 通过 |
| 02-03-01 | 3 | ProjectRecoveryTests、SessionLifecycleTests | T-02-08、T-02-09 | 首次快照、重试原定义和环境、重启恢复入口、记录字节、清理持久性和验收根外记录阻断。 | 通过 |
| 02-03-02 | 3 | ProjectConcurrencyTests、ProjectRecoveryTests | T-02-03、T-02-10、T-02-11 | 项目别名、跨实例和切换，验证 Stop 或控制管道断开后执行组仍活动时阻断竞争及后置。 | 通过 |
| 02-04-01 | 4 | 全量 Debug XCTest、Release build、两套主程序及监督进程可执行性 | T-02-12、T-02-14 | 记录本轮测试、构建、两套主程序及 Contents/Helpers 内监督进程的摘要、签名嵌入及启动模式。 | 通过 |
| 02-04-02 | 4 | A07–A16、A32 的记录行检查与阶段末人工验收 | T-02-12–T-02-14 | 逐项比对可复现命令输出、截图或实际阻塞，复验根外项目及符号链接隔离。 | 通过，用户验收待确认 |

共享 scheme 现包含 LaunchPresentationTests 及五个阶段新增 XCTest 类。回归探针先观察到缺失接口或失败断言，再验证实现后的通过结果。派发前 Stop 和改名目录的回归均先失败、后通过。审查发现的目录替换、macOS 启动覆盖和另一实例已清除记录也经过失败及通过验证。

## 测试样例与人工验收

- 首个执行任务创建定向 XCTest 与隔离样例，使用 `docs/examples/sample-flutter-app` 的原始 JSONC 和脚本。人工验收在专用 App Support 的 `FlutterRunlet-Phase02Fixture/projects` 下创建两个名称含空格的临时目录。重启复用根目录身份和存储，根外项目与越界别名用临时普通项目复验。执行真实脚本，仅替换 Flutter 进程启动边界。
- 用 Debug App 的实际主窗入口验收 A07–A16、A32。按 D-15 保留每项结果、适用截图或命令输出。恢复失败时折叠日志，入口仍可见。记录 `fail-before-dev`、`fail-before-test`、`fail-after-prod`、App 异常退出及根外项目零副作用证据。
- 各 PLAN 的 `<automated>` 命令及断言是任务级验证依据。实施后记录文件是否存在、自动测试结果、人工验收证据及安全威胁对应项。

## 来源覆盖

| 来源 | 条目 | 覆盖 |
|---|---|---|
| ROADMAP | 只读配置、任务和恢复内核，A07–A16、A32 | 02-01–02-04 |
| REQUIREMENTS | CONF-01、CONF-02、CONF-03、CONF-04、CONF-05 | 02-02-01、02-02-03，02-04 复验 |
| REQUIREMENTS | TASK-01、TASK-02 | 02-01-02、02-02-02，02-04 复验 |
| REQUIREMENTS | SAFE-01、SAFE-02、SAFE-03、SAFE-04 | 02-01、02-03，02-04 复验 |
| RESEARCH | G1 场景和工程复用、精确 Debug 注入、真实退出及写前记录 | 02-01-01、02-01-02 |
| RESEARCH | JSONC 坐标、参数及环境保真、安全任务、有效定义比较 | 02-02-01、02-02-02、02-02-03 |
| RESEARCH | 私有持久存储、原定义和环境的比较、租约与真实进程竞态 | 02-01-01、02-03-01、02-03-02 |
| RESEARCH | XCTest 和样例、Release 隔离及原生取证 | 02-04-01、02-04-02 |
| CONTEXT | D-01、D-02、D-03、D-04、D-11、D-12、D-13、D-14 | 02-02 |
| CONTEXT | D-05、D-06、D-07、D-08、D-09、D-10 | 02-01、02-03 |
| CONTEXT | D-15 | 02-01-01、02-04-02 |

## 边界复核

本阶段没有独立 SPEC。TASK-01 的空输入与编码探针已进入 02-02 的可执行断言。其余自动探针无法分类的条目保留为人工复核项，以下判据从已确认上下文与验收矩阵取得。

| 人工复核项目 | 执行期核对 |
|---|---|
| CONF-01 | 有效目录内坏 launch 仍打开，重启偏好只影响打开和读盘。 |
| CONF-02 | 引号内符号、非 ASCII 与 CRLF 的错误位置对应原文，配置字节未变。 |
| CONF-03 | 非 Debug 显示原因，直接调用执行层也无任务及调试进程。 |
| CONF-04 | 兼容转换后工具与应用参数边界、顺序、原值可追溯，冲突能阻断。 |
| CONF-05 | program、cwd 和 PATH 按契约解析，macOS 启动环境与任务环境独立。 |
| TASK-02 | 缺失、无效或失败的前置各有诊断，受管调试进程未启动。 |
| SAFE-01 | 受管进程实际退出后才执行原 post，以其退出码确认恢复。 |
| SAFE-02 | 风险先提交，部分写入或 App 异常后重启可见。 |
| SAFE-03 | 只重试原标签的相同任务和显式环境，退出 0 后清除。 |
| SAFE-04 | 目录别名、跨实例、重复 Run、切换和退出均无法绕过租约和恢复状态。 |

## 签署

- [x] 各任务验证命令已运行，记录失败方向和修复后结果
- [x] 全量 XCTest 和 Release 构建通过
- [x] A07–A16、A32 的执行证据归档，菜单栏和独立用户确认保留在 UAT
- [x] 执行后的 Nyquist 合规状态已核对

## Validation Audit 2026-11-12

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
