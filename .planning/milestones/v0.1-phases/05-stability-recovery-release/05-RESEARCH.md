# Phase 05 · 稳定性、异常恢复与最终验收调研

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### 强退恢复

- **D-01** 在隔离的公开样例及独立恢复存储上覆盖三个强退时点。前置任务写入 `prod` 后尚未退出和后置任务写入 `test` 后尚未以退出码 0 完成，使用 Debug 隔离验收入口。Flutter 调试运行中使用最终 Release 候选和真实 Flutter 模拟器。
- **D-02** 在后置任务已写入 `test` 的场景，以任务成功退出并确认恢复为清除风险的条件。重启后应仍显示风险，按原后置任务手动重试成功后才清除。用可观察的暂停点定位前后置边界，记录强退前后的环境标记、任务状态和风险记录。
- **D-03** A15 的 Release 运行中强退场景同时关闭「启动后显示主窗口」和「记住最近打开的项目」。重启仍自动显示主窗口及待恢复项目和入口。用户通过入口打开该项目并手动重试，确认恢复到 `test` 后清除风险。沿用项目锁和受管进程退出确认。

#### 日志压力

- **D-04** A27 使用最终 Release 候选和隔离公开样例，运行真实 Flutter 调试会话共 30 分钟。前 25 分钟低频输出，最后 5 分钟约 200 行/秒，使用带递增编号的中英文混合短行。用编号核对 64 KiB 缓冲裁剪处的 UTF-8 完整性、清空边界和新输出。
- **D-05** 高频输出时实际操作清空、折叠、展开和停止。各操作从触发到界面反馈在 1 秒内，停止以进入「停止中」为准。在高频时段末尾触发停止并记录耗时。核对清空后折叠再展开仍无清空前的旧日志，并继续收到新输出（A30）。
- **D-06** 采样 FlutterRunlet 主进程 RSS，以低频阶段最后 5 分钟的采样中位数为基线。高频阶段采样峰值较基线增长不超过 50 MiB，且曲线无持续上升。归档采样曲线、基线、峰值和增长量。

#### 真实项目与最低系统

- **D-07** A29 使用用户在 Phase 05 对话中指定的「真实项目 A」。授权范围是在隔离副本中用 VS Code 和 FlutterRunlet 运行 `dev`、`test`、`prod`。按验收矩阵为 `prod` 用例准备可恢复测试环境及 Firebase 文件基线备份。公开记录逐环境列出脱敏后的参数类别、任务顺序、环境结果及 `prod` 停止后恢复 `test` 的结果。原始路径、配置值及原始证据留在本地私有环境。
- **D-08** A31 接受 macOS 15 虚拟机作为实机替代，最低部署目标维持 macOS 15.0。规划时核实虚拟机能否用最终 Release 候选覆盖适用的原生窗口、控件和关键调试流程。优先用独立的公开样例复验。虚拟机不可用或无法覆盖的预期记为阻塞。本轮决定更新了原有的实机限定，规划时将相应验收口径同步到项目文档。

#### Release 交付

- **D-09** G3 交付本地 Release `.app`、同一 `.app` 的 ZIP 归档及 ZIP 的 SHA-256。归档保留 App 和内嵌 worker 的签名与执行权限，解包后复验。交付记录关联受测提交和构建，备齐文档、许可证及发布说明。
- **D-10** G3 复核关于窗口的项目主页、README 和 LICENSE 目标地址及浏览器打开行为。公开分发前再复验三个地址的匿名可访问性。
- **D-11** G3 沿用 G0 与 Phase 04 的视觉基线及已通过的证据。最终 Release 候选重跑受影响界面的自动检查，仅将受影响界面和新增或改变的视觉差异交给用户确认。

### Deferred Ideas (OUT OF SCOPE)

公开分发安排、面向外部用户的签名和公证、匿名链接复验，以及公开前审计留到分发前处理。
</user_constraints>

<phase_requirements>
## Phase Requirements

| 需求 | 执行重点 |
| --- | --- |
| REL-01 | A13–A16、A22、A28。任务或启动失败、并发、断线、退出、三时点强退、恢复与重试 |
| REL-02 | A27、A30。真实 Flutter 会话压力、响应、内存、UTF-8 和日志清空 |
| REL-03 | A29、A31。真实项目双工具对照及 macOS 15 适用窗口、控件和关键调试流程 |
| REL-04 | A26 和 G3 适用矩阵。视觉复核、本地 Release、ZIP 解包复验和文档 |
</phase_requirements>

## 项目约束

`CLAUDE.md` 委托 `AGENTS.md`。按技术契约 §3–§6 执行项目锁、受管进程退出确认、原任务核对及风险持久化。FlutterRunlet 只读项目配置。回归限定在获授权副本及公开样例。仅影响既有验收布局、视觉和交互的调整需要用户确认。GSD 更新阶段运行态。D-08 对应的旧实机措辞见 `docs/01-PRODUCT.md`、`docs/04-ACCEPTANCE.md`、`README.md`、`.planning/PROJECT.md`、`.planning/milestones/v0.1-REQUIREMENTS.md`、`.planning/milestones/v0.1-ROADMAP.md`、`docs/design/FIGMA-HANDOFF.md` 和 `docs/design/g0.1/README.md`。同步现行口径，历史证据保留当时事实。 [VERIFIED: AGENTS.md, CLAUDE.md, docs/02-TECHNICAL.md:75-159]

## 调研结论

- 首先建立同一提交的 Debug 和 Release 候选及样例，跑通 Release `prod → Running → Stop → test`。后续场景都从此基线扩展。用 `SessionController` 和内嵌 worker 的真实入口观测前置、调试、后置、租约和风险。 [VERIFIED: .planning/milestones/v0.1-phases/03-flutter/03-G2-ACCEPTANCE.md:9-64, FlutterRunlet/SessionController.swift:979-1095]
- Phase 02 夹具拒绝任意脚本。Debug 边界若需要增加暂停能力，应在既有公开脚本追加只受夹具标记触发的有界分支，并同步固定摘要和覆盖拒绝篡改的回归。一次性修改副本脚本会被拒绝。 [VERIFIED: FlutterRunlet/ProjectConfiguration.swift:7-8,39-52, FlutterRunletTests/SessionLifecycleTests.swift:137-176]
- A31 目前没有可用目标环境，A29 目前没有能定位真实项目 A 的私有映射。两个执行条件可在计划中分别记录和验收，G3 需等待适用预期的完整证据。 [VERIFIED: 本地只读探测见下节, 05-CONTEXT.md]

## Environment Availability

| 依赖 | 实查 | 执行条件 |
| --- | --- | --- |
| macOS 宿主、Xcode、iOS 模拟器 | `sysctl -n hw.optional.arm64` 输出 `1`，`sw_vers` 显示 `26.7.1 (25G241)`，`xcodebuild -version` 显示 `27.1 (27A9275)`，`xcrun simctl list runtimes` 列出 iOS `18.5`、`27.0`、`27.1`，探测时没有已启动设备 | 宿主可以准备 D-01 的运行中强退及 D-04 压测。先验证所选 SDK、设备及真实 VM Service |
| Flutter、VS Code、ADB | `command -v flutter code adb` 均有结果。Phase 03 证据记录 Flutter `3.47.4`，当前运行版本由执行时重新核实 | 使用对应项目 SDK 和本次实际运行版本 |
| macOS 15 实机或客体 | 本阶段没有指定可访问实机。Fusion `vmrun list` 返回 `Total running VMs: 0`，默认库中的唯一 `.vmx` 配置报告 `guestOS = "arm-windows11-64"`。常用 Tart、UTM、Parallels 入口未找到，未在限定范围内发现可用 macOS 15 客体 | A31 的原生窗口、控件、设备发现、真实 Flutter 与 VM Service 均未获得目标环境证据，当前记为阻塞 |
| 真实项目 A | 阶段上下文及讨论记录保存了授权。限定的公开文档及已有 `.private` 记录未找到 A 的可解析映射 | 使用已授权项目的本地私有映射、隔离副本与 Firebase 基线备份。映射缺失时 A29 记为阻塞 |

[VERIFIED: 规划期本地只读探测 `sw_vers`、`sysctl`、`xcodebuild -version`、`xcrun simctl list runtimes`、`xcrun simctl list devices booted`、`command -v`、`vmrun list` 及默认配置 `guestOS` 字段]

Broadcom 明确列出 Apple Silicon Fusion 对 Arm macOS 客体不支持。Apple Virtualization Framework 支持使用 Apple 恢复映像创建 macOS 客体。取得可用 macOS 15 环境后先记录精确版本、构建、架构和候选 ZIP 摘要，再验证客体原生交互。Apple 的 Xcode 表可用于选择匹配客体版本的工具，例如 macOS 15.6 可选 Xcode 26.3。客体能启动、Xcode 与系统版本匹配、真实设备能发现和运行是独立前置条件。先在客体实际检查 `xcodebuild -version`、`xcrun simctl list devices available` 和 `flutter devices --machine`，再从同一 Release 候选走 VM Service、热操作、停止与恢复。模拟器受限时可验证其它可用且受支持的真实设备路径，并单独记录仍未覆盖的预期。宿主截图与 `15.0` 部署目标均只作为补充证据。 [CITED: [Broadcom Fusion Arm 客体支持](https://knowledge.broadcom.com/external/article/315602/), [Apple macOS 虚拟化](https://developer.apple.com/documentation/virtualization/virtualize-macos-on-a-mac), [Xcode 系统要求](https://developer.apple.com/xcode/system-requirements), [Flutter iOS 环境设置](https://docs.flutter.dev/platform-integration/ios/setup)]

## Architecture Patterns

### A13–A16、A22、A28 · 生命周期与强退

复用公开样例 `sample:select-prod`、`sample:select-test`、`.runlet-fixture/firebase-environment` 和 `fail-before-dev`、`fail-before-test`、`fail-after-prod`。候选为正常 Release App，Flutter 会话仍使用 Debug。每轮从已知 `test` 环境开始，对照项目、`.vscode` 配置、脚本及风险存储与其他测试实例隔离。验收前后比对配置与脚本 SHA-256。 [VERIFIED: docs/examples/sample-flutter-app/launch.jsonc:48-66, docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh:12-25, docs/examples/sample-flutter-app/README.md]

沿用 `--phase-02-fixture`，其 Debug 专用项目根是 `Library/Application Support/FlutterRunlet-Phase02Fixture/projects`，风险库是同一根下 `state`。现有夹具用 `.runlet-fixture/debug-started` 表示替身已经启动，`debug-exit` 请求异常退出。前、后置分别需要新暂停点。计划可在公开脚本保留现有失败标记优先级，在写入和失败判断后加 `pause-after-prod`、`pause-after-test` 的有界等待及可观察的就绪日志或文件。超时以非零退出，只有主动放行后才可成功退出。脚本及固定摘要作为同一改动提交。夹具只承认原有固定相对脚本、`/bin/sh`、三项实参、原 cwd 和校验摘要。无需给 Release 加测试开关。 [VERIFIED: FlutterRunlet/SessionController.swift:288-363,1098-1105, FlutterRunlet/ProjectConfiguration.swift:39-52, docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh:12-25]

| 场景 | 强退前确定边界 | 重启与重试证明 |
| --- | --- | --- |
| 前置写入后 | Debug 实际界面处于前置任务。暂停点已到达，标记为 `prod`，风险存在，`debug-started` 尚未出现 | 仅结束本次 App PID，等待受管任务组退出。相同入口重启看到风险，移除本轮暂停标记，手动重试原 `sample:select-test` 成功后变为 `test`、风险消失 |
| 调试运行中 | 最终 Release 的两项启动偏好都关闭。真实模拟器进程和当前 VM Service 已连接，标记为 `prod`，风险存在 | 重启同一构建和存储时自然打开主窗，显示待恢复项目。通过入口打开该项目，保留 `prod` 直到手动重试。原后置任务成功和进程组退出均确认后才清风险 |
| 后置写入后 | Debug 先 Stop，观察调试替身和受管组退出，再观察后置暂停点、标记 `test`、后置状态及风险仍存在。暂停中的进程尚未退出 `0` | 保持证据直至原任务组退出，随后同一入口重启。即使文件为 `test` 仍显示风险。仅移除本轮暂停标记并手动重试，原任务定义维持不变，成功确认后才清风险 |

通过 App 或会话记录及已确认的本轮进程树获得 PID。强退只针对该 App PID。worker 观察 App 控制管道关闭，对本轮组发 TERM 并按现有时限回收，组清空后报告。后置仅接受 `.exited(0)`，风险库持久完成凭据后清理；断电边界的有效风险以应用重启发现为准，文件数量单独不能判定结果。运行中退出先复验取消保持会话，确认「停止并退出」等待后置恢复。另用失败后置验证退出被阻止并可见重试。 [VERIFIED: FlutterRunletSessionWorker/main.swift:41-70, FlutterRunlet/SessionController.swift:1071-1095, FlutterRunlet/ProjectRecoveryStore.swift:122-169, FlutterRunlet/FlutterRunletApp.swift:512-549]

Release 使用独立 macOS 测试账户或先验确认隔离的常规偏好与恢复库。Phase 02/03 证明过 `CFFIXED_USER_HOME` 下的普通 Release 启动，执行时先检查该测试实例的存储位置及偏好写入可持续、默认账户恢复记录不受影响。以实际设置关闭「启动后显示主窗口」「记住最近打开的项目」，重启时通过正常启动测试恢复优先级，避免显式的打开窗口动作先改变结果。 [VERIFIED: .planning/milestones/v0.1-phases/02-config-task-execution-core/02-P2-ACCEPTANCE.md, .planning/milestones/v0.1-phases/03-flutter/03-G2-ACCEPTANCE.md:32-40, FlutterRunlet/SessionController.swift:195-199,278-285,328-330]

### A27、A30 · 真机工具链中的日志压力

在隔离公开样例的 Dart 入口添加仅该验收样例使用的日志生产器，采用 `Stopwatch` 和定时器，待样例启动和 FlutterRunlet 确认当前 VM Service 后启动计时。前 25 分钟低频，随后 5 分钟按约 200 行/秒生成 `P5 000001 中英 UTF-8` 形式的短行及可识别的阶段边界。可使用 `print` 或 `debugPrintSynchronously`，避免默认 `debugPrintThrottled` 改变负载。先做短时实测，用编号和实际时间核实真实 `flutter run --machine` 的 `app.log` 到达速率和 UI 路径，再进行完整 30 分钟。上游工具或设备日志通道丢弃导致无法证明负载时查明原因并复验。 [CITED: [Flutter debugPrint 默认实现](https://api.flutter.dev/flutter/rendering/debugPrint.html), [Flutter 同步打印](https://api.flutter.dev/flutter/foundation/debugPrintSynchronously.html), [Flutter CLI DevTools](https://docs.flutter.dev/tools/devtools/cli)] [VERIFIED: FlutterRunlet/FlutterToolchain.swift:398, FlutterRunlet/FlutterDebugSession.swift:172-174]

按相同 App PID 每秒 `ps -p "$app_pid" -o rss=`，与高低频阶段在同一时间轴保留时间戳及样本，退出或 PID 变化应暴露为采样失败。单位为 KiB，基线取第 20–25 分钟中位数，峰值取高频窗口最大值，差值除以 1024 得 MiB。保留原始样本与曲线，检查增长是否持续至高频末尾。记录清空、折叠、展开、停止的事件和首次可见/可访问性状态变化，反馈上限各 1 秒，停止取进入「停止中」的首次证据。高频阶段结束时触发停止，另记后续真实退出及恢复。 [VERIFIED: 宿主 `ps -p $$ -o rss=` 可读, 05-CONTEXT.md D-04–D-06]

裁剪前后用已有复制日志入口取样并在本地检查 UTF-8 严格解码、`<= 65536` 字节、无 U+FFFD，首行允许合法 UTF-8 的截断片段，随后完整编号行应可解析。实际捕获清空操作后、折叠再展开和后续输出。以清空反馈时已到达的编号、采样时间和新输出编号判断旧缓冲是否重现，区分清空后才进入收集器的设备缓冲日志。现有 `logGeneration` 处理队列和已部分接收的行，XCTest 同时覆盖该精确边界。只归档脱敏输出。 [VERIFIED: FlutterRunlet/SessionController.swift:926-951,1108-1115,1203-1215, FlutterRunletTests/SessionLogTests.swift:8-39]

### A29 · VS Code 和 Release 对照

取得已授权工程的私有映射后，在隔离副本确认工程解析后的真实路径及任务/符号链接目标均处于授权范围。对可恢复测试环境的实际 Firebase 文件做基线备份和校验。相同 SDK、设备、配置分别串行运行 VS Code 和 FlutterRunlet。每次从等价基线开始，按 `dev`、`test`、`prod` 记录参数类别及可观察效果、前后置任务顺序、运行环境、停止后的结果。涉及 `prod` 时记录恢复到 `test` 的证据再进入下一轮。原始路径、参数值、任务明文、Firebase 文件、终端日志、截图或令牌仅进本地私有证据。公开表按环境记录差异和判定。 [VERIFIED: docs/04-ACCEPTANCE.md:35-48, docs/02-TECHNICAL.md:75-124, docs/PUBLIC-RELEASE-AUDIT.md, 05-CONTEXT.md D-07]

### A26 与 G3 · 候选一致性和交付

从已知源提交建立普通 Release，不替换 Bundle ID、不临时重签用于最终验收的包。冻结本轮 `.app`，记录 App 版本/构建、提交、SDK、主程序和 worker SHA-256、各签名验证、归档摘要。若候选因缺陷修改或重建，以新候选重跑所有受影响的验证和明确要求最终 Release 的验证；旧候选证据继续保留来源。关于窗口从同一候选实际点击三项并在默认浏览器核对固定目的地址。URL 来自 `AboutInformation.Destination`，依次为 `https://github.com/atypiape/flutter-runlet`、`https://github.com/atypiape/flutter-runlet/blob/main/README.md`、`https://github.com/atypiape/flutter-runlet/blob/main/LICENSE`。已有 Phase 04 浏览器取证可复用操作方法。 [VERIFIED: FlutterRunlet/AuxiliaryWindows.swift:281-294, FlutterRunletTests/LaunchPresentationTests.swift:7-23, .planning/milestones/v0.1-phases/04-macos/04-P4-ACCEPTANCE.md]

以实际受测 `.app` 为源，在私有交付目录生成 ZIP、SHA-256 和独立解包验证。`ditto --help` 确认 `-c -k --sequesterRsrc --keepParent` 及 `-x -k`。示例中的 `bundle` 是已冻结的候选绝对路径，`release_dir` 为本轮新建的私有交付目录。验收包与源码仓库中的发布说明及许可证建立对应关系。 [VERIFIED: 本机 `/usr/bin/ditto --help`, .planning/milestones/v0.1-phases/04-macos/04-P4-ACCEPTANCE.md:12-33, LICENSE]

```sh
set -eu
cd "$release_dir"
test ! -e FlutterRunlet.zip
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$bundle" FlutterRunlet.zip
/usr/bin/shasum -a 256 FlutterRunlet.zip > FlutterRunlet.zip.sha256
/usr/bin/shasum -a 256 -c FlutterRunlet.zip.sha256
unpacked="$(mktemp -d "$release_dir/unpacked.XXXXXX")"
/usr/bin/ditto -x -k FlutterRunlet.zip "$unpacked"
for app in "$bundle" "$unpacked/FlutterRunlet.app"; do
  test -x "$app/Contents/MacOS/FlutterRunlet"
  test -x "$app/Contents/Helpers/FlutterRunletSessionWorker"
  /usr/bin/codesign --verify --strict "$app/Contents/Helpers/FlutterRunletSessionWorker"
  /usr/bin/codesign --verify --deep --strict "$app"
done
for binary in Contents/MacOS/FlutterRunlet Contents/Helpers/FlutterRunletSessionWorker; do
  /usr/bin/cmp "$bundle/$binary" "$unpacked/FlutterRunlet.app/$binary"
done
```

主程序和 worker 的 Xcode 配置都写有 `MACOSX_DEPLOYMENT_TARGET = 15.0;`。对两者运行 `xcrun vtool -show-build` 记录实际 Mach-O 最低版本，再在 A31 的目标系统运行签名相符的候选。原生回归参照 G0、Phase 04 辅助功能、实际控件和已确认偏差。按受影响窗口、状态、语言和外观补齐自动证据，人工复核新增或变更的视觉差异。 [VERIFIED: FlutterRunlet.xcodeproj/project.pbxproj:370-379,451-460,524-546, docs/design/UI-SPEC.md, docs/design/DESIGN-SYSTEM.md, .planning/milestones/v0.1-phases/04-macos/04-P4-ACCEPTANCE.md]

## Validation Architecture

### Test Framework

现有 XCTest 的 `FlutterRunletTests` 目标和共享 `FlutterRunlet` scheme。Debug 全量测试与 Release 构建命令如下。定向运行在 `test` 之前插入 `-only-testing:FlutterRunletTests/<类名>`。任何退出非零、失败或意外跳过须进入阶段记录。 [VERIFIED: FlutterRunlet.xcodeproj/xcshareddata/xcschemes/FlutterRunlet.xcscheme, .planning/milestones/v0.1-phases/04-macos/04-VALIDATION.md:12-20]

```sh
set -eu
derived="${TMPDIR:-/tmp}/flutter-runlet-phase-05"
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath "$derived" -parallel-testing-enabled NO test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Release \
  -destination 'platform=macOS' -derivedDataPath "$derived" build
```

### Phase Requirements → Test Map

| 需求 | 已有 XCTest | 阶段自动或交互补证 |
| --- | --- | --- |
| REL-01 | `SessionLifecycleTests`、`ProjectRecoveryTests`、`ProjectConcurrencyTests`、`FlutterDebugSessionTests`、`LaunchPresentationTests` | 公开样例的进程、环境、风险和辅助功能断言。分别记录启动失败、前后置失败、正常 Stop、并发、设备断线、正常退出及三时点强退 |
| REL-02 | `SessionLogTests` 覆盖清空代际、遮罩、运行与任务日志、裁剪和视口 | 同一 Release 真实 30 分钟、RSS 样本和曲线、实际 UI 响应、UTF-8 与编号断言 |
| REL-03 | `ProjectConfigurationTests`、`FlutterToolchainTests` 可验证已有解析与设备边界 | A29 私有双工具逐环境对照；A31 目标系统和实际设备的候选验收。未覆盖项记阻塞 |
| REL-04 | `LaunchPresentationTests` 核对包内文案、版本、URL 及启动偏好 | 受影响界面复验、关于链接浏览器交接、`codesign`、`test -x`、`cmp`、`shasum -a 256 -c`，G3 适用矩阵全绿 |

### Sampling Rate

每项用既有类做定向回归。候选建立时运行 Debug 全量、Release 构建及签名。各次用例记录提交、构建、系统、复现方法和自动证据边界。最终汇总逐一审核适用 A 编号，自动证据完整时直接通过，人工只确认新增或改变的视觉差异及其他未被覆盖的交互。任何失败或阻塞须可追溯到待补项。 [VERIFIED: docs/04-ACCEPTANCE.md:39-50]

### Wave 0 Gaps

现有 scheme 和 XCTest 可以直接运行。第一波在公开隔离样例准备有界暂停并验证摘要约束；日志生成器仅置于本轮样例。A29 私有项目输入、A31 客体或实机为实际验收所需的环境条件，可与宿主候选验证并行核实。

## Security Domain

| 风险 | 控制与验证 |
| --- | --- |
| 调试夹具扩张到任意任务 | 保留 DEBUG 条件、目录和所有权约束、参数匹配及固定摘要。验证改写脚本、目录外项目和符号链接仍被拒绝 |
| 原任务未成功却清除风险，或在旧组仍运行时再次启动 | 复用路径及 inode 身份、跨进程租约、后置任务快照、真实退出及持久完成凭据。测试强退、失败、重启、原任务手动重试和并发 |
| 私有配置、Firebase 文件或 VM token 泄漏 | 逐环境公开脱敏，原始材料放私有验收目录。用现有日志遮罩与发布审计约束核对证据 |
| 交付文件与测试候选不一致 | 同一 `.app` 打包，保留 ZIP SHA-256，解包后验证主程序、worker 的权限、签名和字节 |

适用 ASVS 类控制集中在输入约束、任务权限及敏感数据保护。现有恢复认证和权限边界通过既有实现验证。 [VERIFIED: FlutterRunlet/ProjectConfiguration.swift:7-52, FlutterRunlet/ProjectRecoveryStore.swift:61-74,96-135, FlutterRunlet/FlutterDebugSession.swift:372-390, docs/PUBLIC-RELEASE-AUDIT.md]

## Sources

- 需求及行为来源为 `05-CONTEXT.md`、`.planning/milestones/v0.1-REQUIREMENTS.md`、`docs/02-TECHNICAL.md`、`docs/04-ACCEPTANCE.md` 和文中所列源码。
- 已验收参考见 Phase 02 `02-P2-ACCEPTANCE.md`、Phase 03 `03-G2-ACCEPTANCE.md`、Phase 04 `04-P4-ACCEPTANCE.md` 及 `04-VALIDATION.md`。
- 文档经 Context7 核对 Apple Virtualization 和 Flutter，Fusion 客体边界和 Xcode 版本支持见上文厂商来源。当前 macOS 15 环境的覆盖以实际验收为准。

**调研日期** 2026-11-13。源码及宿主探测置信度高，目标系统与真实项目的可用性保留上述执行条件。
