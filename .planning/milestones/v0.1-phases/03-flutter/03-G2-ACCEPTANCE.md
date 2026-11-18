# Phase 03 · G2 候选构建验收

最终受测候选为 `0416505`。构建、签名和受审查影响的原生操作见[审查修正复验](#审查修正复验)。下文保留 `9300b9c` 的完整矩阵和未改动路径的取证。

## 候选构建

受测提交为 `9300b9c35e2887731a34bc650c8aa5462b6e4afd`。macOS 26.7.1（25G241）、Xcode 27.1（27A9275）、Flutter 3.47.4、Dart 3.13.3、DevTools 2.60.0。Debug 与 Release 复用共享 scheme 和同一 DerivedData。

```sh
derived="${TMPDIR:-/tmp}/flutter-runlet-phase-03"
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet \
  -configuration Debug -destination 'platform=macOS' -derivedDataPath "$derived" \
  -parallel-testing-enabled NO test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet \
  -configuration Release -destination 'platform=macOS' -derivedDataPath "$derived" build
for cfg in Debug Release; do
  bundle="$derived/Build/Products/$cfg/FlutterRunlet.app"
  worker="$bundle/Contents/Helpers/FlutterRunletSessionWorker"
  test -x "$bundle/Contents/MacOS/FlutterRunlet" && test -x "$worker" || exit 1
  /usr/bin/codesign --verify --strict "$worker" || exit 1
  /usr/bin/codesign --verify --deep --strict "$bundle" || exit 1
done
```

两条构建命令退出 0。Debug XCTest 54 项全部通过。Debug 和 Release 主程序与内嵌 worker 都有执行位，独立 worker 签名和 App 深度签名均通过。

| 构建 | 主程序 SHA-256 | worker SHA-256 |
|---|---|---|
| Debug | `e6a2157ca02998aede90f003655a5f155a12fb387fa0ae1703e534d948dc42c4` | `344fb3f88f29fa87ac76e6a5de15038ee524279dd3a53911528ebbe83d2c5704` |
| Release | `bea810315eb8b060a61d978b7ae2cfd38c66cbc5513d03f7aa22513ca9c15fb8` | `5900151ce6e28de472778096a218842f1ea17c1b376bada66b6c3ee19ff55034` |

## Release 历史参数隔离

预建临时主目录的 `Library/Application Support`。以该目录设置 `CFFIXED_USER_HOME`，启动上表签名核验通过的 Release 主程序。参数为 `-rememberRecentProject YES -recentProjectPath "$outside" --g1-ready --phase-02-fixture`，其中 `outside` 为固定 Debug 夹具根外的独立公开样例。

Accessibility 读取真实项目 `Sample Flutter App`，实际选择 `sample-flutter-app(prod)`，观察设备扫描和可打开的设置窗。未点击 Run，App 无受管 worker。前后比对样例 `.runlet-fixture`、固定 Debug 专用存储和临时主目录下的同名存储，存在性、文件列表、SHA-256 与纳秒修改时间全部一致。环境标记仍为 `test`，未产生 `debug-started`。对应 [P2 隔离复验](../02-config-task-execution-core/02-P2-ACCEPTANCE.md#release-参数隔离自动复验)。

本机临时证据目录为 `/tmp/flutter-runlet-phase03-fixture.TdrzUC/g2-proof`。构建与签名取证见 `debug-xctest.log`、`release-build.log`、`candidate-artifacts.txt`。隔离复验见 `release-ordinary.ax`、`release-settings.ax`、`release-before.txt`、`release-after.txt`。

## 真实设备与样例

普通 Debug App 使用隔离的临时主目录。iOS 使用 iOS 27.0 的 iPhone 17 模拟器和路径含空格的独立工程。Android 使用只读 arm64 AVD `emulator-5560`，Flutter 设备名称为 `sdk gphone16k arm64`，系统为 Android 16。可按下列方式准备样例。用样例 UI 显示 `String.fromEnvironment('APP_ENV')`、版本文案和 State 计数，加入两秒计时器驱动计数和日志。只在样例的 Dart 源码中切换 v1/v2 文案或添加用于遮罩检查的虚构令牌。

```sh
fixture="$(mktemp -d)/G2 Flutter Sample"
flutter create --platforms=ios,android --project-name sample_flutter_app "$fixture"
sample="$PWD/docs/examples/sample-flutter-app"
mkdir -p "$fixture/.vscode" "$fixture/scripts"
cp "$sample/launch.jsonc" "$fixture/.vscode/launch.json"
cp "$sample/tasks.jsonc" "$fixture/.vscode/tasks.json"
cp "$sample/scripts/simulate-firebase-switch.sh" "$fixture/scripts/"
(cd "$fixture" && /bin/sh scripts/simulate-firebase-switch.sh test --quiet)
```

Android 隔离副本采用 Gradle 8.14.3、AGP 8.13.2、Kotlin 2.3.20 并显式应用 Kotlin Android 插件。默认生成模板在本机 AGP 9.1/Kotlin DSL 编译失败。兼容修改与 Gradle 缓存均只用于临时工程。可先运行 `flutter build apk --debug --target-platform android-arm64` 预构建，随后仍从普通 App 选设备运行。iOS 和 Android 的两份配置及脚本都与公开源文件逐字节一致。iOS 配置运行前后的 SHA-256 分别为 `e721589aebb4235174798bd1a45ae1b3cc65ddf6d7e3de2eddea804bdd8a9a43`（launch）和 `61a7061d9dfc53a035fc5e4c1ba8e6531223d5249444745c32b6bb3b4c4284a5`（tasks）。[公开样例与故障标记](../../../../docs/examples/sample-flutter-app/README.md)

## G2 验收矩阵

实测和 XCTest 分别记录各自覆盖的条件。无可用真机属于 A18 允许的不适用情形。九项适用行为通过，G2 达成。[验收矩阵及证据规则](../../../../docs/04-ACCEPTANCE.md)

| 验收项 | 结果 | 观察和证据 |
|---|---|---|
| A13 | 通过 | iOS 模拟器上真实 dev/test/prod 的 Flutter 参数保留相应 `APP_ENV`、其他定义值和顺序，界面分别显示对应环境，公开任务标记一致。正常 Stop 的 45 毫秒轮询先观察到 Flutter 退出，再观察到其 worker 退出且标记仍为 prod、风险仍为 1。随后原 `sample:select-test` 将标记改为 test，风险从 1 清为 0，Run 恢复可用。任务顺序及完成凭据只在成功退出时提交由 `FlutterDebugSessionTests`、`SessionLifecycleTests` 和 `ProjectRecoveryTests` 覆盖。实测见 `dev-flutter`、`test-flutter`、`prod-first-flutter`、`prod-stop-order.txt`、`prod-stopped.ax`。 |
| A17 | 通过 | 从普通 App 的模拟器菜单启动关机的 iPhone 17，Flutter 发现后在同一主窗选择它并实际运行 dev，显示「VM Service 已连接」。断开后保留同名离线选项，原设备重启并刷新后恢复选择与 Run，未发起新会话。派生的长名称配置指定 iPhone 17，选 Android 时保留所选设备、显示指定设备并禁用 Run。零、一、多台和扫描失败由 `FlutterToolchainTests` 覆盖。实测见 `ios-booting.ax`、`dev-running.ax`、`dev-simulator.png`、`ios-same-id-reconnected.ax`、`long-conflict.ax`。 |
| A18 | 通过（模拟器），不适用（真机） | 普通 App 选择 `sdk gphone16k arm64`，实际 Flutter 命令包含精确 ID `emulator-5560`，test Debug 运行且 VM 已连接。Android 屏幕显示真实样例，Stop 后 Flutter、worker 和设备内样例进程均退出。ADB 没有 Android 真机，发现的无线 iOS 真机隧道处于断开状态且本机可用代码签名身份数为 0，未以设备名称替代可用性判断。实测见 `android-ready.ax`、`android-first-flutter`、`android-running.ax`、`android-running.png` 和 `android-stop.txt`。 |
| A19 | 通过 | iPhone 17 上，主窗热重载将样例文案从 v1 改为 v2，计数由 75 继续到 76。菜单栏热重启后，v2 文案保留、计数为 0。两个动作都有当前成功反馈，Flutter PID 都是 41929。当前请求匹配、重复操作和晚到回复由 `FlutterDebugSessionTests` 断言。实测见 `hot-before.png`、`hot-reloaded.png`、`hot-restarted.png`、`hot-pid.txt`、`hot-reload.ax`、`menu-restart.ax`。 |
| A20 | 通过 | 系统默认 HTTP 应用实际为 Microsoft Edge。普通 App 的 DevTools 和 Inspector 两个入口都打开当前 DDS 端口。dev 端口为 55491，重跑 test 后为 56364，再跑 prod 后两入口均为 58872。实际版本直达 `/devtools/inspector`。用独立 Edge 上下文读取当前原生 Inspector 入口同一地址，HTTP 200，选择样例 `MyHomePage` 后显示其 Widget properties 和含 test/v2 的真实子树。保留端口和遮罩地址，清洁上下文的截图仅含 Inspector 内容。其他版本的已连接回退路径由 `FlutterDebugSessionTests` 覆盖。实测见 `test-DevTools-browser.ax`、`test-Inspector-browser.ax`、`prod-DevTools-browser.ax`、`prod-Inspector-browser.ax`、`test-selected-widget.png`。 |
| A21 | 通过 | 真实 test 会话关闭主窗后，菜单栏面板显示运行中及同一配置，热重启成功反馈。打开主窗后仍显示运行中和 VM 已连接，Flutter PID 41929 持续。实测见 `main-closed.ax`、`menu-running.ax`、`menu-restart.ax`、`reopened-running.ax` 和 `hot-pid.txt`。 |
| A22 | 通过 | 终止模拟器中的 dev App 后，原 Flutter 进程自然退出，主窗显示退出码 0 并恢复 Run。另一次 test 会话中仅挂起实际 DDS 子进程，模拟器和 Flutter 调试进程仍在，显示连接中断，热操作与浏览器禁用而 Stop 可用。恢复 DDS 后同一 PID 重连。再用 prod 会话关掉隔离模拟器，保留离线选择，受管组退出后原 post 故障，标记 prod、风险 1，折叠日志仍有重试入口。移除故障标记重试后为 test、风险 0，显示设备已断开原因。同一 ID 恢复后可 Run。59/60 秒及受管组时序由 XCTest 覆盖。实测见 `dev-after-app-terminate.ax`、`test-vm-interrupted.ax`、`test-vm-reconnected.ax`、`device-disconnected.ax`、`device-disconnect-recovery.txt` 和 `device-recovery-retried.ax`。 |
| A24 | 通过 | 隔离 iOS 样例用 `.fvmrc` 固定 3.47.4，缺少 `.fvm/flutter_sdk` 时 Run 禁用并可直达 Flutter 设置。恢复链接到已有用户缓存后重新激活 App，显示项目 FVM、Flutter 3.47.4、Dart 3.13.3，实际 Flutter 进程使用同一 SDK。调试中路径选择与 FVM 开关禁用。手动路径的候选失败保留旧值、来源优先级和恢复期锁定由 `FlutterToolchainTests` 断言。实测见 `fvm-blocked.ax`、`fvm-settings-before.ax`、`fvm-settings-after.ax`、`dev-running.ax`。 |
| A30 | 通过 | 真实定时输出在底部跟随。向上滚动后新增两行，滚动位置保持在阅读区；回到底部后新行仍保持底部。全量复制与实际原生文本选区复制都保留虚构 URL 的本地端口、遮住令牌，选区复制只包含该行。清空后折叠、展开、重开主窗时旧批次均未重现，新输出仍追加且 Flutter PID 保持。Stop 后保留本轮日志；项目切换与启动复验保留边界由 `SessionLogTests` 覆盖。实测见 `log-scrolled-after-append.txt`、`log-bottom-after-append.txt`、`log-clipboard-full.txt`、`prod-selection-clipboard.txt`、`log-reopened-after-clear.txt`、`log-test-stopped.txt`。 |

## 原生界面补验

截取候选 App 自身窗口，确认主窗 640 × 580 pt、菜单栏面板宽 404 pt，四个调试按钮同排。原生深色就绪、运行和恢复失败取证为 `native-main-ready.png`、`native-menu-ready.png`、`native-main-running.png` 和 `native-main-recovery-folded.png`。恢复失败时折叠日志，原因和「重试恢复」仍可见。Flutter 设置直达和锁定见 A24 取证。

浅色仅做界面补验。隔离复制候选 App，在副本 Info.plist 增设 `NSRequiresAquaSystemAppearance` 并重新签名，用长名称及显式设备冲突的派生样例打开窗口。候选源码及本机外观偏好保持原样。原生省略长文本，Accessibility 仍提供完整项目及配置名称。设备冲突原因和底部窗口操作可读。浅色取证为 `native-main-light-long-conflict.png`、`native-menu-light-long-conflict.png`、`long-conflict.ax`、`long-menu.ax`。完整双语与视觉验收沿用 Phase 04 范围。[Phase 03 UI 契约](03-VERIFICATION.md)

## 审查修正复验

最终候选 `0416505db76e7dde868db92110e8a0fb2d074520` 修正设备断开确认、日志裁剪与真实子进程派发边界，以及 Run 样式、可访问名称和日志字体。2026-11-13 在同一 macOS、Xcode 和共享 scheme 上重跑上述构建及签名命令。Debug XCTest 57 项全部通过，Release 构建退出 0。两套 App 主程序及内嵌 worker 有执行位，worker 严格签名与 App 深度严格签名通过。用两种历史参数启动此 Release，实际打开独立样例并选择 prod 与 Android 模拟器。未发起 Run，样例及固定 Debug 存储前后摘要相同，受管 worker 数为零。

| 构建 | 主程序 SHA-256 | worker SHA-256 |
|---|---|---|
| Debug | `c4e3cf8d553683af01371a16ca9bcdb7853b6da8e3374b03031eced1e7df3b5f` | `678ea622d6d3bb4981ac5b7dcd92363db6cd6890b4e7cb204327395e1d3191bf` |
| Release | `b7edced7e5cc99d02c828f821fe38fb844ecf2eb87325c97d707e2f8a518c086` | `648bcf6e2f4874a8728f63268cd4588a405be1942ddcb2f088165bff3bca32a9` |

- **A13、A17、A22**。普通 App 在 iPhone 17 上运行 prod 并连接 VM Service。正常 Stop 先观察到 Flutter、worker 依次退出，退出时标记仍为 prod、风险仍为 1，随后原后置任务使标记为 test、风险为 0。第二轮连接后只挂起隔离样例的 Flutter 子进程，再关机同一模拟器。App 确认设备断开并停止会话，待 Flutter 和 worker 退出后恢复 test，风险归零，离线原因仍可读。XCTest 同时覆盖扫描短暂漏报但 VM 健康时继续运行。
- **A18**。普通 App 再次选定 `emulator-5560`，实际运行 test 并连接 VM Service。Stop 后 Flutter、worker 和设备内样例进程均退出，标记为 test、风险为 0。
- **A30 与 UI 补验**。同一 iOS 主窗从中文日志空态切换至实际 ASCII 输出，App 窗口截图记录等宽渲染。XCTest 断言系统等宽字体 12 pt、超过 64 KiB 裁剪后保留仍有效的阅读行和选区，以及首个子进程实际派发失败时保留上一轮日志。前台 Android 主窗截图显示 Run 可用时为系统强调色，运行中禁用时为中性色。两种状态的 AX 名称均为「运行当前调试配置」，视觉标签为「运行」。

复验证据位于 `/tmp/flutter-runlet-phase03-fixture.TdrzUC/g2-proof/recheck-0416505`。构建与签名见 `debug.log`、`release.log`、`candidate-artifacts.txt`。Release 参数隔离见 `release-ordinary.ax` 和前后摘要。会话证据见 `ios-normal-stop.txt`、`ios-disconnect-order.txt`、`ios-disconnected.ax`、`android-running.ax`、`android-stop.txt`。App 自身窗口截图见 `native-ready-placeholder.png`、`native-running-log.png`、`native-ios-disconnected.png`、`native-android-active-ready.png`、`native-android-active-running.png`。

两份真实工程的公开配置及脚本再次通过字节比对。菜单栏热操作、浏览器和其余未改动路径沿用原矩阵证据。九项适用结果仍为通过，真机条件仍记为不适用。
