# 07-05 · 更新事务实测

## 前置与隔离

- 施工前实际执行视觉验证器，验证 07-03 冻结候选的 512 项及 07-04 `894422f` 增补，结果 `VISUAL PASS: 512 required cases verified`。07-04 的 88 对原生复证签核和 `517bbf5` 下载验包交接均已核对。交接同机重跑 `UpdatePackageTests` 11 项通过，新增嵌入助手后复验 12 项通过。终版再次执行视觉验证器。
- 下载和验包分别使用 Xcode Release 的隔离编译条件及签名覆盖的配置。App、worker 和助手均含 arm64 与 x86_64。先签并打包 B，再把 DMG 的精确 SHA-256 和 B 的版本、构建号、产品标识固化到 A。GitHub 形状的数据和真实资产来自非特权回环端口。普通 Release 保持固定公开源和未配置的发行者信任。
- 隔离身份 `com.atypiape.FlutterRunlet.Phase07Update`，A 为 7.5.0（750），B 为 7.5.1（751），目标为 `.private/phase-07/update/target/FlutterRunlet.app`。偏好和恢复状态使用该目录下的独立 home。旧版、A、B 通过同一恢复命名空间验证。使用现有 APFS 本地卷、现有隔离测试设备和 `.private/phase-07/flutter-fixtures` 项目副本。

## 原生场景清单

每份清单指向场景结果，再指向 APFS 对象身份、进程、事务原始记录、回环字节数和带 AX 的截图。场景结束后再次用 `--verify-manifest` 读取清单、逐项核对状态和文件，校验截图的 SHA-256。

| 场景 | 私有证据路径（相对 `.private/phase-07/update/`） | 实测 |
| --- | --- | --- |
| 助手就绪与回退 | `bootstrap-safety-20261115T103032065434Z/manifest.json` | 就绪失败保持 A。B 超时退出后恢复 A。A 早退及 A 活着但 30 秒无应答时显示独立窗口及恢复位置 |
| A → B | `success-20261115T103211479770Z/manifest.json` | 从原路径正常退出 A，替换后以新 PID 启动 B，旧 inode 随旧包保留。同一次受限启动完成双向健康应答，设置侧栏、设置关于和独立关于都显示实际 `v7.5.1 (build 751)` |
| 跨实例与恢复门禁 | `gate-20261115T101914273897Z/manifest.json` | 真实 prod 下载、失败和暂停恢复、恢复后自动提示、稍后及双入口、不可读记录、无新租约旧版、遗留 worker、现行版跨项目活动。目标签名、SHA-256、inode 全程相同 |
| 失败、实际回退与中断 | `rollback-20261115T102753153191Z/manifest.json` | 13 组通过，含坏包、换名前故障、B 早退、错误应答、提交前退出、目录实物变更、确认后的旧版竞态、交换前后及健康提交中断。双语独立提示实点验证访达选择及默认浏览器发布页。 |
| 普通 Release | `native-07-05-final-en-about/actions.json`、`native-07-05-final-zh-Hans-settings/actions.json` | 两个入口均收到 HTTP 200，显示 `v0.1.1` 尚未锁定、不可安全安装，并保留查看发布页。英文轮额外传入演示参数和假端点，实际请求仍发往固定公开仓库。 |

终版成功轮的 B DMG SHA-256 为 `ae17030ecb085abae54b51db0b14be0a3e3d29c104f41134e6e65887902399c8`。A PID 为 16057，B PID 为 16141。原路径从 inode 323554819 换为 323554908，保留处仍是 323554819。A 活着却未应答的轮次按 30 秒期限结束，含轮询调度的实测耗时为 30.023 秒。

最终 Debug 报告为 `debug-07-05.xcresult`，128 项通过。普通 Release 候选位于 `ordinary-release-final/FlutterRunlet.app`。另由 `scripts/package-release.sh` 产出本地 v0.1.0（178）双架构 DMG，并检验 App、worker、嵌入助手的架构和代码签名。

## 复跑

```sh
for scenario in bootstrap-safety success gate rollback; do
  bash scripts/verify-phase-07-update.sh --scenario "$scenario" --workspace .private/phase-07/update
done
```

`gate` 使用已准备的专用 iOS 模拟器和两个 Flutter 项目副本。原生场景使用现有 Phase 07 AX 探针和窗口取证器。命令逐轮生成新候选和场景目录，输出的清单路径可通过 `--verify-manifest <路径>` 重新核对。用户安装的 App、Flutter 原工程和应用账号保持原状。验收后专用设备恢复关机。

## 独立源码审查修复复证

修复前基线为 `69870a2`，隔离候选仅加故障注入。8 个原生断言均复现失败。助手晚于父进程清理写出了待定记录，父进程的重命名后同步失败也留下指向已删除目录的记录。A 和 B 在放行前及放行后、ACK 前中断时均失去待定记录。B 连续两次中断时，持久阶段由 `committed` 降为 `waitingForNew`。关闭启动主窗口偏好后，主窗口未打开，实际激活策略仍是 `.regular`。各轮的磁盘、进程和 UI 证据保留在 `.private/phase-07/update/review-red-late-20261115T113949322031Z/`。

修复在准备失败时关闭握手，确认回收助手，在独占租约内按事务 ID 清除待定记录，最后清理暂存目录。助手持久写入 `committed` 或 `restored`，释放初始化锁后放行。通过验证的试运行进程将 ACK 写入暂存事务，再清除待定记录并加载偏好。放行中断后的接续按磁盘终态继续。WR-01 的跨系统启动标记清理已接入更新预约。

以下清单均使用 APFS 上的签名隔离 A/B，通过原有回环下载。证据路径相对于 `.private/phase-07/update/`。

| 程序源码 | 场景 | 结果与证据 |
| --- | --- | --- |
| `2fcb4a3` | `success` | 通过。B 从原路径启动，三处读出 v7.5.1（751），旧包仍在。 `success-20261115T115844363046Z/manifest.json` |
| `2fcb4a3` | `handoff-boundaries` | 7 项通过。两处准备故障后 A 可重启。A、B 放行边界中断均保留终态，B 连续两次中断仍为 `committed`，最终 ACK 对应实际启动的 PID。 `handoff-boundaries-20261115T115920109673Z/manifest.json` |
| `2fcb4a3` | `gate` | 通过。真实 Flutter 调试和恢复、旧实例与遗留 worker、同版跨项目活动均阻止安装，原包身份保持。首次尝试未启动专用模拟器，重跑后恢复关机。 `gate-20261115T120103084468Z/manifest.json` |
| `5a7f567` | `rollback` | 13 项清单通过。首轮「交换后中断」涉及系统已启动 A、助手未记录试运行身份，A 实物和待定记录保留。保留失败记录后用同签名 A/B 复跑该轮与后续场景。 `rollback-20261115T114742446429Z/manifest.json` |
| `5a7f567` | `bootstrap-safety` | 4 项通过。A 的 30 秒超时轮，助手确认试运行退出后仍保留 `restored` 待定记录，并显示独立恢复提示。 `bootstrap-safety-20261115T115109456923Z/manifest.json` |
| `5a7f567` | 启动偏好 | 实际关闭启动主窗口开关后安装，观察 B 的 AppKit 激活策略为 `.accessory`，主窗口未打开。 `review-green-accessory-20261115T115658425887Z/accessory/evidence.json` |

`5a7f567` 的事务、更新门禁和验包宿主测试共 22 项通过，见 `.private/phase-07/cr-final-5a7f567/focused.xcresult`。最终候选 `2fcb4a3` 新增助手在握手期限内等待内核进程身份可读的处理，最终源码的全量 Debug 实跑 133 项均通过，其中前序阶段的 8 个套件共 93 项通过。完整 `rollback` 的 13 项和 `bootstrap-safety` 的 4 项也已按该源码复跑，清单分别为 `rollback-20261115T120735379352Z/manifest.json` 和 `bootstrap-safety-20261115T120610968740Z/manifest.json`。用收紧后的脚本再次复核 `success`、`gate`、`rollback`、`bootstrap-safety` 和 `handoff-boundaries` 五份最终清单，全部退出 0。

```sh
bash scripts/verify-phase-07-update.sh --scenario handoff-boundaries --workspace .private/phase-07/update
```

## 需要实际复拍的范围

冻结设置、关于界面及其展示词源码保持签核版本。新接线需要核对真实更新时的确认与失败反馈、新 Bundle 的三处版本，以及从主 App 移到实际独立助手后的恢复界面。独立助手使用 AppKit 原生提示，实际窗口尺寸与 07-03 的独立反馈演示有差异。需按两种语言、两种外观复拍实际恢复成功但无法打开及无法确认恢复两类状态。原有设置和关于的 512 项门槛仍通过。

最终程序源码的助手另完成「已恢复但未打开」与「无法确认恢复」两种 AppKit 反馈，各在中英文及深浅外观实拍。坏包从两处显示同一摘要失败，重试产生第二次真实回环下载，原包保持。见 `recovery-appearance-2026-11-15T122229.911940_0000/appearance-manifest.json`。
