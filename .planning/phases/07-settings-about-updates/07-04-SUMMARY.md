---
phase: 07-settings-about-updates
plan: "04"
subsystem: update-preflight
tags: [macos, github-releases, urlsession, dmg, code-signing, xctest]
requires:
  - phase: 07-settings-about-updates/07-03
    provides: 受保护的设置与关于原生对照及可执行视觉门槛
provides:
  - 匿名固定仓库正式版查询与两个关于入口的共享状态
  - 有上限的资产传输、只读 DMG 预检及可复验的私有候选
affects: [07-settings-about-updates/07-05]
actuals:
  tasks: 3
  commits: 10
tech-stack:
  added: []
  patterns: [应用级更新协调器, URLSession 限长流式接收, macOS 静态代码签名验证]
key-files:
  created:
    - FlutterRunlet/ReleaseUpdates.swift
    - FlutterRunlet/UpdatePackage.swift
    - FlutterRunlet/UpdateCoordinator.swift
    - FlutterRunletTests/ReleaseUpdatesTests.swift
    - FlutterRunletTests/UpdatePackageTests.swift
  modified:
    - FlutterRunlet/UpdatePresentationSource.swift
    - FlutterRunlet/LaunchPresentation.swift
    - FlutterRunlet/AuxiliaryWindows.swift
    - FlutterRunlet/Localizable.xcstrings
    - FlutterRunletTests/LaunchPresentationTests.swift
    - FlutterRunlet.xcodeproj/project.pbxproj
key-decisions:
  - "公开发行 Team ID 仍在可信构建中留空。已发布的可变 Release 只显示其可信发布页。"
  - "测试固定从本地隔离产物取得的摘要、产品标识、版本、构建号及双架构应用和 worker 的 CDHash。普通 Release 没有测试信任入口。"
  - "PreparedUpdate 持有私有 DMG、冻结发行及资产身份、运行应用身份和两份双架构签名身份。"
requirements-completed: [UPD-01, UPD-02]
coverage:
  - id: D1
    description: 真实匿名查询、按运行 Bundle 选版及两入口合并单次在途请求
    requirement: UPD-01
    verification:
      - kind: integration
        ref: FlutterRunletTests/ReleaseUpdatesTests.swift
        status: pass
      - kind: automated_ui
        ref: .private/phase-07/07-04/native-observed-en-about/actions.json
        status: pass
    human_judgment: false
  - id: D2
    description: 有界真实下载，锁定发行身份，按签名版本和运行版本筛选只读 DMG
    requirement: UPD-02
    verification:
      - kind: integration
        ref: FlutterRunletTests/UpdatePackageTests.swift
        status: pass
      - kind: other
        ref: .private/phase-07/07-04/historical-signature/developer-id-rejection.log
        status: pass
    human_judgment: false
  - id: D3
    description: 新版不可安全安装文案和两窗口视觉
    requirement: UPD-01
    verification:
      - kind: automated_ui
        ref: .private/phase-07/07-04/native-observed-en-about/actions.json
        status: pass
    human_judgment: true
    rationale: 主控负责比较实际新旧画面并签核受保护文件的准确增补。
duration: 43min
completed: 2026-11-15
status: complete
---

# 阶段 07 计划 04 · 正式版查询及签名包预检

两处「关于」经用户点击共享一次匿名正式版查询。可下载的包须通过冻结资产摘要、签名和版本预检才会形成候选。发行信任仍处于冻结状态。

## 前置视觉门槛

在更新源码编辑前，运行计划中的非空、唯一 PASS 检查及 `scripts/verify-phase-07-visual-gate.rb`。退出码 0，实跑输出 `VISUAL PASS: 512 required cases verified`。签核提交 `e0a6e15`，候选提交 `bfd53cc39bd17c0b0d27e76b670b6ba0480c544a`，原候选为 `com.atypiape.FlutterRunlet.Phase07Visual` v0.2.0（构建 256）。Bundle 树 SHA-256 为 `b5054793b997dc4d2fc2a660667eda52ce49b80df87919bc6a7b9d4573f453f7`，可执行文件 SHA-256 为 `cd2f82536650b135da64458933083b106ef76e9821ff81765dafc68ca029aa3d`，manifest SHA-256 为 `dbe0f6aaaa237ab1a641c937e4398dc8c557c75cb447a01c56c47fee72724171`。流水和退出码留在 `.private/phase-07/07-04/visual-gate-before.*`。

主控以接线后的 `f5b1585` 与已签核候选做 88 对 1× 实拍，覆盖两窗、两种语言、深浅外观和 11 个更新状态。窗口尺寸及 AX 一致，sRGB 不透明像素最大单通道差不超过 3。签核提交 `894422f`，复证兼容断言只接受已审查的准确源码、展示模型和字符串摘要。参见 [07-04 视觉复验](07-04-VISUAL-RECHECK.md)。本任务在签核提交上重新运行，退出码 0，再次输出 `VISUAL PASS: 512 required cases verified`。

## 任务提交

| 任务 | 提交 | 结果 |
| --- | --- | --- |
| 07-04-01 | 只读取证 | 在真实候选、清单及冻结基线通过后进入后续任务 |
| 07-04-02 | `5e9fbe7`, `713fac3`, `9e07e76`, `90d0b7b`, `0195c2d` | 写入并运行客户端 RED，接入两处共享状态，新增不可安全安装反馈 |
| 07-04-03 | `7e2868c`, `6c1e4bf`, `af2b309` | 写入并运行包选择 RED，接入真实传输、预检及清理 |
| 实拍发现的设置窗双标题 | `1bd70be`, `f5b1585` | 先用现有回调恢复隐藏，实拍仍复现后增加窗口属性观察 |

RED 来自两次宿主 XCTest 实跑，目标各执行 1 项，结束码 65，两个记录均为 `RED_EVIDENCE_OK`。查询测试通过数字版本比较和请求路径断言发现基线缺少远端结果。资产测试对缺少 SHA-256 的匹配包执行断言，基线错误接受。首次运行使用测试目标内的基线占位，原始 `.xcresult` 和断言记录留在私有目录。两轮 RED 先于对应实现提交。

## 实跑结果

在 macOS 26.7.1（25G241）、Xcode 27.1（27A9275）、arm64 上执行。单独使用 `flutter-runlet-phase-07-04` 与 `flutter-runlet-phase-07-04-release` 派生数据目录，避免覆盖视觉候选。

| 检查 | 结果 |
| --- | --- |
| Debug 指定更新及原生展示套件 | 45 项通过，0 失败，0 跳过，包含 24 项 LaunchPresentation、10 项 ReleaseUpdates 和 11 项 UpdatePackage |
| 最终 Debug 全量 `build-for-testing` 与 `test-without-building` | 122 项通过，0 失败，0 跳过。含设置标题离屏回归 |
| Release `xcodebuild ... -configuration Release -destination 'platform=macOS' build` | 退出码 0。产物 `com.atypiape.FlutterRunlet` v0.1.0（构建 1）。复查 Bundle 签名完整性通过 |
| 计划中的匿名 `curl --silent --show-error --max-time 30 --output /dev/null --write-out '%{http_code}\\n' https://api.github.com/repos/atypiape/flutter-runlet/releases/latest` | HTTP 200。另留存 JSON，实测正式 tag `v0.1.1`，Release ID `445162386`，`immutable=false` |
| 普通 Release 实机和冻结信任 | 中英文分别从两个实际入口完成检查。两窗显示本轮 tag、不可安全安装原因及发布页，失焦设置窗只显示本地化标题。英文轮实际拒绝了 Debug 演示输入 |
| XCTest 隔离 DMG | 本地回环 HTTP 传输双架构签名的 B 及 sidecar，原生只读挂载验证，A 的代码签名完整且 CDHash 保持一致。签名版与 tag 不符、同版高 build、降版、根 App 为链接、字节篡改、替换资产、同时修改包与 API 摘要、错误签名均被拒绝 |
| 历史公开包实物负例 | 与匿名 API SHA-256 一致的本地 DMG 只读挂载成功。临时签名完整性通过，Team ID 缺失，Apple Developer ID 签发要求以退出码 1 拒绝 |

最终截图及 AX 对应 `f5b1585`，见私有目录中的两个 `native-observed-*` 子目录。第一次仅靠 `didUpdate` 恢复隐藏后，普通 Release 的失焦设置窗仍复现。最终监听窗口标题和可见性后，验证两种语言不再出现原生重复标题。

### 主要验证命令

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-07-04" \
  -parallel-testing-enabled NO \
  -only-testing:FlutterRunletTests/ReleaseUpdatesTests \
  -only-testing:FlutterRunletTests/UpdatePackageTests \
  -only-testing:FlutterRunletTests/LaunchPresentationTests test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-07-04" \
  -parallel-testing-enabled NO build-for-testing
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-07-04" \
  -parallel-testing-enabled NO test-without-building
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Release \
  -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-07-04-release" build
```

从实际 Bundle 读取的普通 Release 版本是 v0.1.0（构建 1）。先从设置「关于」点击，后从独立关于点击。两轮分别以 AX 捕获两窗同步检查中、同一结果与重开后状态。应用每次各记录一次 HTTP 200 与实际 tag。本次 tag 仅记于证据及摘要。启动到打开两窗期间，两进程各有零条更新请求记录。英文轮同时传入现有 Debug 演示参数与无效端点环境变量，普通 Release 仍用真实公开仓库。受控 HTTP 覆盖 latest 404 的公开仓库与分页交叉验证、矛盾或不可读结果，以及下载上限、HTTPS 跳转限制和取消。

## 07-05 候选合同

`PreparedUpdate` 持有仓库、Release ID、原始 tag、不可变性、资产 ID、字节数、API SHA-256、可信发布页、运行 App 的产品 ID/版本/build、B 的签名覆盖版本/build 及 App 和 worker 的双架构 CDHash。暂存根是当前用户独占的 0700 目录，DMG 文件经摘要核对并设为只读。返回候选前拆卸镜像并再次核对文件大小与摘要。后续安装波消费这些身份并复验暂存实物，然后执行自身的退出和事务门槛。

本轮未启用公开签名信任，因此没有正式 Developer ID 正向安装证据。磁盘替换、退出交接、重启和回滚由 07-05 验证。STATE 与 ROADMAP 交由主控维护。

## Self-Check: PASSED

最终签核后实跑 512 项视觉门槛及验证器自测。Debug 全量、普通 Release 构建和签名完整性、原生双入口、隔离回环传输及只读预检均通过。
