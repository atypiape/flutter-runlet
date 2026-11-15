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

## 需要实际复拍的范围

冻结设置、关于界面及其展示词源码保持签核版本。新接线需要核对真实更新时的确认与失败反馈、新 Bundle 的三处版本，以及从主 App 移到实际独立助手后的恢复界面。独立助手使用 AppKit 原生提示，实际窗口尺寸与 07-03 的独立反馈演示有差异。需按两种语言、两种外观复拍实际恢复成功但无法打开及无法确认恢复两类状态。原有设置和关于的 512 项门槛仍通过。
