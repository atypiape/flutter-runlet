---
phase: 07-settings-about-updates
reviewed: 2026-11-15T11:27:49Z
depth: deep
files_reviewed: 45
files_reviewed_list:
  - FlutterRunlet.xcodeproj/project.pbxproj
  - FlutterRunlet/AppTermination.swift
  - FlutterRunlet/Assets.xcassets/RunletAboutDocumentation.imageset/Contents.json
  - FlutterRunlet/Assets.xcassets/RunletAboutDocumentation.imageset/image.svg
  - FlutterRunlet/Assets.xcassets/RunletAboutGitHub.imageset/Contents.json
  - FlutterRunlet/Assets.xcassets/RunletAboutGitHub.imageset/image.svg
  - FlutterRunlet/Assets.xcassets/RunletAboutLicense.imageset/Contents.json
  - FlutterRunlet/Assets.xcassets/RunletAboutLicense.imageset/image.svg
  - FlutterRunlet/Assets.xcassets/RunletUpdateCheck.imageset/Contents.json
  - FlutterRunlet/Assets.xcassets/RunletUpdateCheck.imageset/image.svg
  - FlutterRunlet/Assets.xcassets/RunletUpdateDownload.imageset/Contents.json
  - FlutterRunlet/Assets.xcassets/RunletUpdateDownload.imageset/image.svg
  - FlutterRunlet/Assets.xcassets/RunletUpdateSpinner.imageset/Contents.json
  - FlutterRunlet/Assets.xcassets/RunletUpdateSpinner.imageset/image.svg
  - FlutterRunlet/AuxiliaryWindows.swift
  - FlutterRunlet/FlutterRunletApp.swift
  - FlutterRunlet/FlutterToolchain.swift
  - FlutterRunlet/Fonts/NotoSansSC-Medium.ttf
  - FlutterRunlet/Fonts/NotoSansSC-Regular.ttf
  - FlutterRunlet/LaunchPresentation.swift
  - FlutterRunlet/Localizable.xcstrings
  - FlutterRunlet/ProjectRecoveryStore.swift
  - FlutterRunlet/ReleaseUpdates.swift
  - FlutterRunlet/RunletAppearance.swift
  - FlutterRunlet/SessionController.swift
  - FlutterRunlet/SessionProcess.swift
  - FlutterRunlet/UpdateActivityLease.swift
  - FlutterRunlet/UpdateCoordinator.swift
  - FlutterRunlet/UpdatePackage.swift
  - FlutterRunlet/UpdatePresentationSource.swift
  - FlutterRunlet/UpdateTransaction.swift
  - FlutterRunletSessionWorker/main.swift
  - FlutterRunletTests/FlutterToolchainTests.swift
  - FlutterRunletTests/LaunchPresentationTests.swift
  - FlutterRunletTests/ReleaseUpdatesTests.swift
  - FlutterRunletTests/UpdateInstallGateTests.swift
  - FlutterRunletTests/UpdatePackageTests.swift
  - FlutterRunletTests/UpdateTransactionTests.swift
  - FlutterRunletUpdateHelper/Localizable.xcstrings
  - FlutterRunletUpdateHelper/main.swift
  - scripts/package-release.sh
  - scripts/phase-07-update-origin.py
  - scripts/verify-phase-07-update.py
  - scripts/verify-phase-07-update.sh
  - scripts/verify-phase-07-visual-gate.rb
findings:
  critical: 2
  warning: 4
  info: 1
  total: 7
status: issues_found
---

# Phase 07 源码审阅

## 摘要

审阅 `ae6d294^..c52695c` 的 45 个 Phase 07 程序、构建、测试、资源及校验脚本文件，沿应用、更新助手、会话 worker 和原生验收脚本追踪调用。有两处阻断启用安装的事务缺陷，分别涉及准备失败后的下次启动和提交后的重复中断。普通 Release 当前只开放正式发布查询。演示代码受 `DEBUG` 约束，回环信任与故障注入受 `PHASE07_UPDATE` 约束，正式发行 Team ID 为空。双架构 App、worker 和助手的签名覆盖、版本及进程身份检查均定位到实际代码。 [演示入口](../../../../FlutterRunlet/FlutterRunletApp.swift#L178) · [隔离配置及发行信任](../../../../FlutterRunlet/UpdatePackage.swift#L137) · [双架构签名要求](../../../../FlutterRunlet/UpdatePackage.swift#L545)

覆盖判断采用既有 128 项宿主测试和原生 A/B 的成功、门禁、13 项回退记录，包括旧版实例、遗留 worker、错误应答、提交前退出及三处中断注入。下列断点以源码推演为依据。另以临时目录和合成输入验证活动标记与校验器行为，并通过 Ruby 视觉门槛自测及脚本语法检查。本轮未重跑宿主 XCTest 或原生 GUI。 [最终验收](07-ACCEPTANCE.md) · [A/B 场景定义](../../../../scripts/verify-phase-07-update.py#L680)

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: 助手准备失败会留下指向已删除目录的待定事务

**File:** `FlutterRunlet/UpdateTransaction.swift:489`

**Issue:** 父进程等待就绪 8 秒，超时后直接清理待定记录和暂存目录。助手先写暂存意图，再写恢复目录的待定记录，最后应答。如果超时时助手刚写完意图，父进程可以先完成清理，随后助手用已打开的恢复目录重新写出待定记录。还有一条独立的 I/O 失败路径：初次写待定记录在重命名后同步目录，如果同步失败，`marked` 仍为 false，清理会删除暂存目录并留下已可见的待定记录。两条路径中旧版都尚未交换，当前进程仍可用，但下次启动会转入恢复，因暂存目录已不存在而失败。关闭提示后应用退出，重复启动仍遇到同一记录。现有未就绪场景在等待结束前已写完两份记录。 [父进程等待](../../../../FlutterRunlet/UpdateTransaction.swift#L562) · [助手写盘与就绪](../../../../FlutterRunletUpdateHelper/main.swift#L61) · [两份记录的写入顺序](../../../../FlutterRunletUpdateHelper/main.swift#L213) · [重命名与同步](../../../../FlutterRunlet/UpdateTransaction.swift#L108) · [重入核验](../../../../FlutterRunlet/UpdateTransaction.swift#L517) · [启动失败处理](../../../../FlutterRunlet/AppTermination.swift#L55)

**Fix:** 保留助手子进程句柄。准备失败时先取消交接并确认子进程退出，再持独占租约按事务 ID 检查和清理记录。覆盖重命名成功、目录同步失败的情况。只有确认待定记录已清除后才删除暂存目录。补测写完意图但尚未发布待定记录时超时，以及重命名后的同步失败。

### CR-02: 提交与回退的放行缺少可重入的完成边界

**File:** `FlutterRunletUpdateHelper/main.swift:138`

**Issue:** B 提交和 A 回退成功均先删除 `update-pending.json`，再发送 `proceed`。助手在中间退出时，试运行读到连接关闭后终止，原路径上的已验证 App 留在磁盘，自动重启中断，同时下次手动启动已无待定事务可接续。另一个确定的状态退化发生在提交后的重入：第一次重入将 `.committed` 持久改回 `.waitingForNew`，才重新启动 B。如果此时再次中断，第二次重入见到已交换但仍在等待的记录，直接回退已通过健康检查的 B。现有 `interrupt-after-commit` 位于删除待定记录之前，且对重入助手不生效。 [B 放行](../../../../FlutterRunletUpdateHelper/main.swift#L138) · [A 放行](../../../../FlutterRunletUpdateHelper/main.swift#L218) · [重入分支](../../../../FlutterRunletUpdateHelper/main.swift#L83) · [故障注入范围](../../../../FlutterRunletUpdateHelper/main.swift#L306) · [试运行的退出处理](../../../../FlutterRunlet/AppTermination.swift#L42)

**Fix:** 将持久的提交或恢复结果与单次试运行状态分开。在允许正常初始化前释放初始化锁，保留待定记录直到对应进程确认完成启动交接。重入应继续既有结论，只有确认发生新的启动失败并满足退出条件后才转入回退。分别补测发送放行前中断、发送后未确认中断，以及已提交事务连续两次中断。

## Warnings

### WR-01: 会话 worker 异常退出后，残留标记永久阻止安装

**File:** `FlutterRunlet/SessionController.swift:443`

**Issue:** 父进程在启动 worker 前写入并同步零字节标记。启动系统调用失败时父进程删除标记，启动成功后由 worker 在确认进程组退出时删除。即使 worker 已结束全部受管进程，只要它在删除前异常退出，标记仍会保留，重启系统后也一样。安装门禁每次直接拒绝该文件名，界面持续要求等待受管进程退出。已用实际租约实现验证，释放共享租约后已能获取独占租约，标记仍在。现有宿主用例覆盖 worker 正常清理，A/B 遗留 worker 场景验证的是仍存活且没有新标记的旧版进程。 [标记创建](../../../../FlutterRunlet/UpdateActivityLease.swift#L64) · [父进程清理条件](../../../../FlutterRunlet/SessionProcess.swift#L229) · [worker 清理](../../../../FlutterRunletSessionWorker/main.swift#L98) · [既有宿主用例](../../../../FlutterRunletTests/UpdateInstallGateTests.swift#L50)

**Fix:** 持久记录启动会话、worker 和受管进程身份。重启后在独占租约下先核验风险记录，再对能够确认已结束的标记进行回收。对仍无法确认的状态继续阻止安装，并提供可见的处理入口。

### WR-02: Python 优化会移除验收断言及隔离目标检查

**File:** `scripts/verify-phase-07-update.py:644`

**Issue:** Shell 入口继承 `PYTHONOPTIMIZE`，而清单结论、证据路径、截图摘要及运行时目标产品标识均依赖 Python 的 `assert`。对实际验证函数的合成输入测试中，写有 `failed` 且没有任何场景的清单在默认模式被拒绝，在优化模式通过。运行实测时目标 App 的签名产品检查也会消失，脚本仍会移动已存在的目标。 [Shell 入口](../../../../scripts/verify-phase-07-update.sh#L5) · [现有目标的产品检查和移动](../../../../scripts/verify-phase-07-update.py#L230)

**Fix:** 用显式条件和异常执行隔离保护和验收判断。为脚本入口补测开启优化时仍拒绝失败清单和非隔离目标。

### WR-03: A/B 清单复核会接受缺事务、结论冲突或无效截图的成功报告

**File:** `scripts/verify-phase-07-update.py:647`

**Issue:** `--verify-manifest` 只从场景定义传入名称列表。事务校验受结果自行声明的 `journalPath` 控制，阶段也只与结果自行声明的 `expected` 比较。截图检查只核对大小和配套 JSON 中的摘要。默认 Python 模式下，以实际复核函数读取合成 `upgrade` 结果，省略事务、把结论写成 `restored` 并使用有匹配摘要的非 PNG 字节，仍然通过。复核成功因此不能单独证明原生运行脚本所要求的提交阶段和版本切换。 [复核入口](../../../../scripts/verify-phase-07-update.py#L697) · [成功场景现场断言](../../../../scripts/verify-phase-07-update.py#L380)

**Fix:** 从可信场景定义传入期望结论及必需证据。按场景核对事务阶段、目标和保留包身份、进程及版本证据，并复用 PNG 解码与取证身份检查。

### WR-04: 视觉门槛没有从 PNG 验证旋转按钮的像素变化

**File:** `scripts/verify-phase-07-visual-gate.rb:418`

**Issue:** `verify_motion` 核对声明的按钮裁剪坐标和摘要格式，再要求全窗截图摘要有四个不同值。它没有读取按钮像素来重算裁剪摘要。调用实际函数时，仅给出四组全窗摘要和独立填写的裁剪摘要即可通过。由此，全窗其他位置发生变化也能满足自动连续旋转检查，即使实际按钮区域保持静止。 [全窗与裁剪摘要的判定](../../../../scripts/verify-phase-07-visual-gate.rb#L414)

**Fix:** 对实际原生帧解码并裁剪按钮区域，重算像素摘要后核对至少四个不同值。自测加入按钮区域静止、全窗其他区域变化的反例。

## Info

### IN-01: 更新重启沿用默认 Dock 激活策略

**File:** `FlutterRunlet/FlutterRunletApp.swift:198`

**Issue:** 试运行延后读取偏好，控制器初始将「启动后显示主窗口」设为 true，应用据此保存 `.regular`。收到放行后会重读偏好并按正确结果决定是否开窗，但仍恢复早先保存的 `.regular`。因此已关闭该偏好且无待恢复记录的用户，更新重启后主窗口保持关闭，应用仍以普通 Dock 应用运行。下一次常规启动才按该偏好使用 `.accessory`。 [延后初始化的默认值](../../../../FlutterRunlet/SessionController.swift#L381) · [重新读取偏好的时机](../../../../FlutterRunlet/SessionController.swift#L519) · [试运行放行后恢复激活策略](../../../../FlutterRunlet/AppTermination.swift#L44)

**Fix:** 在试运行放行并载入偏好后，按正常启动的同一规则重新决定激活策略。
