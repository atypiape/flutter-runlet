# Phase 04 · macOS 界面与双语设置验收

## 受测构建

最终候选为 `97a6713d3a65d3d49fbad2012e26bff3c40266d3`。macOS 26.7.1（25G241）、Xcode 27.1（27A9275）、最低部署目标 macOS 15.0。下方真实模拟器、双语深浅外观和 Release 参数隔离的全量原生证据来自审查前候选 `988ac8148aa7e93e102f6435f5e73fd6748c590e`。真实会话使用 iOS 27.0 的 iPhone 17 模拟器、Flutter 3.47.4、Dart 3.13.3 和公开样例的独立副本。审查后在新候选复验三处受影响的行为。

Debug XCTest **75/75 通过**，Release 构建成功，两命令均退出 0。Debug 与 Release 均声明 `CFBundleIconFile = AppIcon`，包含对应 ICNS、两份菜单栏模板和两套编译语言资源。主程序及内嵌 worker 可执行，worker 独立严格签名和 App 深度严格签名均通过。两套构建使用同一共享 scheme 及源码。

| 构建 | 主程序 SHA-256 | worker SHA-256 |
|---|---|---|
| Debug | `1b53b74610c8475ab4e25797f15d394da771e2c7ca549ff2731347d0ef29c2d0` | `0ae05b9519c93722a97cb5eb008fd9f1271375fbda86d88965ad96c4bbbe9f6a` |
| Release | `5b5d020918e15ebb5ab5296b973af0de2f313913f839ae28ee3f145c0d286e85` | `2ee7aaae50baf8aab602d326749afa0a292fe9dd744780aa695d09a28e7bfdc9` |

Debug 动态库 SHA-256 为 `4f9d5a7b09a713d921a05a8d6afc8ac6a8479a809868c2a043bd4003357d30fe`。最终候选证据位于 `/tmp/runlet-04-review-final.9Zc6wM`，含 `debug.xcresult`、`release.xcresult` 和 `package.txt`。审查前候选的测试和原生证据位于 `/tmp/runlet-04-05.VMZlFG`，含 74/74 的 `candidate-debug.xcresult`、`candidate-release.xcresult` 和 `final-package.txt`。

```sh
derived="${TMPDIR:-/tmp}/flutter-runlet-phase-04"
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet \
  -configuration Debug -destination 'platform=macOS' -derivedDataPath "$derived" \
  -parallel-testing-enabled NO test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet \
  -configuration Release -destination 'platform=macOS' -derivedDataPath "$derived" build
for cfg in Debug Release; do
  bundle="$derived/Build/Products/$cfg/FlutterRunlet.app"
  icon=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$bundle/Contents/Info.plist") || exit 1
  test "${icon%.icns}" = AppIcon || exit 1
  for resource in AppIcon.icns flutterrunlet-menubar-template@1x.png \
    flutterrunlet-menubar-template@2x.png en.lproj/Localizable.strings zh-Hans.lproj/Localizable.strings; do
    test -s "$bundle/Contents/Resources/$resource" || exit 1
  done
  worker="$bundle/Contents/Helpers/FlutterRunletSessionWorker"
  test -x "$bundle/Contents/MacOS/FlutterRunlet" && test -x "$worker" || exit 1
  codesign --verify --strict "$worker" || exit 1
  codesign --verify --deep --strict "$bundle" || exit 1
done
```

审查前候选 `988ac81` 的 Release 同时传入 `--g1-ready` 和 `--phase-02-fixture`，进入普通项目并实际选中公开样例的 prod 配置。样例环境标记、固定 Debug 夹具存储与隔离用户目录中的同名存储，其存在性、文件摘要和纳秒修改时间均保持一致。证据见 `final-release-prod-ordinary.ax`、`release-isolation-result.txt`。本次修复涉及应用退出、设置激活和诊断字号，沿用该项原生证据。 [G2 复验基线](../03-flutter/03-G2-ACCEPTANCE.md#release-历史参数隔离)

## 验收矩阵

下表的全量原生记录来自 `988ac81`。A04 与 A25 的受影响路径由 `97a6713` 补验，见下方复验。

| ID | 结果 | 候选证据 |
|---|---|---|
| A03 | 通过 | 主窗和面板的 Ready、等待、Running 及停止按钮状态一致。真实 prod 会话连接前热操作禁用，连接后 Run 禁用、Stop 和两项热操作可用。后置任务故障时两处提供原任务 `sample:select-test` 和退出码 1，主窗折叠日志后仍可重试。面板重试后标记由 prod 变 test，风险记录由 1 变 0。见 `final-ready-en.ax`、`final-panel-wait-en.ax`、`final-panel-stopping.ax`、`final-folded-recovery.ax`、`final-shared-recovery-en.ax`、`final-recovery-proof.txt`。XCTest 补齐启动、恢复时序及禁用条件。 |
| A04 | 通过 | 设置外框 672 × 520 pt，侧栏只有通用和 Flutter，SDK 元数据仅在 Flutter 页。关于外框 440 × 480 pt。主窗启动和记住最近项目默认开启且保留显式关闭，隔离候选重启后只有菜单栏，无 Dock 项。手动打开和重复重开只有一扇主窗，恢复记录优先打开一扇主窗并等用户明确操作。旧候选在 `notFound` 时禁用开关。修复候选通过系统登记、登录启动、主窗偏好及撤销后的重新登录验证。见 `final-general-en.ax`、`suppressed-relaunch.state`、`manual-reopen.state`、`repeated-reopen.state`、`pending-recovery-at-launch.ax`。 |
| A05 | 通过 | 四组截图覆盖浅／深与简中／英文，主窗和 404 pt 面板四按钮同排完整。长项目名在面板尾部省略，AX 帮助和全名弹出层提供原名。锁定配置可点独立按钮，设备全名可经 Tab／Shift-Tab 到达并按 Space 打开。见 `final-{light,dark}-{zh,en}-*.png`、四份 `*-layout.txt`、`final-hover-layout.txt`、`final-full-config-en.ax`、`final-key-full-name-en.ax`、`final-tab-proof.txt`。 |
| A06 | 通过 | 两包包含同一 Dock ICNS 和 1x/2x 单色模板。首次注册的隔离标识在两种外观中都显示青蓝 Dock 图标及可辨认的原生单色状态图标。见 `final-{light,dark}-dock.png`、`final-{light,dark}-menu-icon.png`、`final-package.txt`。 |
| A21 | 通过 | 真实运行中关闭主窗，菜单栏显示同一配置与 Running，F5 可从就绪面板发起会话，Option+F5、Shift+Command+F5 可在仅菜单栏控制同一 Flutter PID 91570，重开主窗保持连接，Shift+F5 可在面板停止。日志文本焦点下的两项热操作成功且焦点保持。Finder 在前台时发送四键，运行状态及热操作输出均不变。见 `final-panel-f5-en.ax`、`final-closed-running.state`、`final-only-panel-{reload,restart}.ax`、`final-reopen-running.ax`、`final-session-pid.txt`、`final-log-focus-proof.txt`、`final-background-keys.txt`。 |
| A23 | 通过 | 四个场景、应用自有菜单、已有恢复错误、项目／SDK 选择面板与退出确认使用当前语言。设置两个页面往返时窗口标题保持当前语言。重启保留显式 English，选跟随系统后匹配宿主简体中文。项目、配置、设备和 CLI 原文在切换前后保持，会话保持同一 PID。见 `final-flutter-{en,zh}.ax`、`final-general-return-{en,zh}.ax`、`final-follow-system.ax`、`final-recovery-zh.ax`、`final-app-menu-en.ax`、`final-{project,sdk}-directory-en.ax`、`final-exit-alert-en.ax`。 |
| A24 | 通过 | Flutter 设置显示 Project FVM、SDK 路径、Flutter 3.47.4、Dart 3.13.3 和 FVM 3.47.4。真实 Flutter 进程来自同一 SDK，运行时 SDK 路径、FVM 选择及诊断锁定。暂移隔离样例的 `.fvm/flutter_sdk` 并刷新，界面明确显示缺失原因，Run 禁用，F5 无动作。还原后可重新发现 SDK。见 `final-flutter-en.ax`、`final-session-pid.txt`、`final-fvm-invalid.ax`。 |
| A25 | 通过 | 真实 doctor 摘要为 Flutter 通过、Xcode 通过、Android Toolchain 警告，对应原始输出。完整输出在独立原生 sheet 分别展示 stdout 与 stderr。取消显示明确原因，重试再次得到三项摘要。见 `final-doctor-{summary,output,cancel,retry}.ax`。XCTest 覆盖双流、截断、失败与过期请求。 |
| A26 | 通过（阶段范围） | 关于使用实际 0.1.0／构建 1、上游归属与版权、MIT 声明。三条已确认链接交给默认浏览器 Edge，AX 地址栏核对仓库、README 和 LICENSE 地址。匿名可访问性按阶段决定留待发布复验。见 `final-about-en.ax`、`final-links.txt`、`final-{light,dark}-{zh,en}-about.png`。 |

[验收矩阵及判定规则](../../../../docs/04-ACCEPTANCE.md) · [阶段 UI 契约](04-UI-SPEC.md) · [阶段决定](04-CONTEXT.md)

## 审查修正复验

- **菜单栏打开设置与主窗重开。** 启动主窗偏好关闭后，从 Finder 前台打开状态栏面板，选择 Settings。应用仍为 `.accessory`、主窗数为 0，设置窗已显示并取得应用内辅助功能焦点。明确选择 Open Main Window 后切换为 `.regular` 并出现一扇主窗。再次用 Launch Services 打开仍只有一扇。见 `finder-before-settings.txt`、`settings-only.{txt,ax}`、`explicit-reopen.txt`、`repeated-reopen.txt`。
- **退出收尾。** 将独立临时测试 SDK 配成保留子进程的慢诊断。开始检查后，设置窗有进度与取消入口。点击菜单栏 Quit 后，App、诊断组长及其子进程均退出，诊断临时目录已清理。XCTest `testTerminationWaitsForCurrentAndCancelledDoctorCleanup` 同时覆盖当前请求与已取消且尚待收尾的请求。见 `doctor-before-menu-quit.ax`、`doctor-menu-quit.ax`、`doctor-menu-quit.txt`、`debug.xcresult`。
- **完整诊断输出。** 同一候选通过隔离测试 SDK 产生已知的 stdout 和 stderr。原生 sheet 分别展示两路原文，截图核对了等宽渲染和分组。对应生产视图显式指定 12 pt 系统等宽字号。实际 Flutter 3.47.4 三项摘要及取消重试继续引用审查前真实 SDK 证据。见 `doctor-output.{ax,png}`、`doctor-font.txt`。
- **实际登录项。** 同一独立 Bundle ID 的 ad hoc 签名副本移入用户 Applications 目录并注册到 Launch Services，打开通用设置后仍显示 `notFound`、关闭且禁用的开关和系统设置入口。结束后退出应用并撤掉安装副本。另核对本机可用签名身份数为 0。见 `installed-login-status.ax`、`available-signing-identities.txt`。

## 原生复验与差异

- 在 `988ac81` 的 Debug 候选上，用辅助功能树、原生按键探针和区域截屏检查四窗。测试副本仅修改 Bundle ID 以隔离偏好与旧 Dock 图标缓存，然后临时重签。原始 Debug 和 Release 签名证据取自构建产物。脚本 `ax.swift`、`native.swift`、`final-appearance.sh` 与截图保存在审查前宿主证据目录。外观测试结束后恢复系统原有深色。
- 主窗外框 640 × 580 pt，实测工具栏占 52 pt，其下布局区 640 × 528 pt，正文宽 600 pt。设置外框 672 × 520 pt，顶部原生工具栏占 52 pt，其下布局区 672 × 468 pt，侧栏可访问滚动区宽 142 pt，分隔线距外框左边 150 pt。关于外框 440 × 480 pt，标题栏下内容约 440 × 452 pt。菜单栏运行态外框 404 × 278 pt，反馈出现时高度随内容增长。四按钮原生实测高 24 pt，设计参考为 26 pt。未观察到标签裁切或换行。
- 在基线 `67a6270` 中，从通用切换到 Flutter 时系统会把英文设置标题改为中文。`988ac81` 在设置详情显式设置导航标题，在两种语言下往返两个分类并重新截取四窗，均保留所选语言。基线证据为 `title-regression-en.ax`，复验证据为 `final-flutter-{en,zh}.ax` 和 `final-general-return-{en,zh}.ax`。原生文件面板的「打开」「取消」及系统生成的警告辅助名称由 macOS 提供，本次保持系统简体中文。应用提供的标题、说明和退出按钮随偏好切换。 [SwiftUI 导航标题](https://developer.apple.com/documentation/swiftui/view/navigationtitle(_:)-avgj)
- Dock 旧标识缓存现象见第四波记录。原生验收以独立标识复验图标。两种外观中的状态项均取原生菜单栏区域，宿主菜单栏背景相同。 [图标基线](04-04-SUMMARY.md)
- 真实模拟器阶段使用公开样例副本，prod 后置失败通过 `fail-before-test` 模拟。启动恢复补验在 `988ac81` 的同源 Debug 构建保留原任务记录并重启，关闭启动主窗及记住项目后仍出现一扇主窗。点击「打开待恢复项目」后标记仍为 prod。移除故障标记，从面板明确重试，恢复至 test。公开样例配置及脚本前后 SHA-256 一致，FVM 链接还原，风险记录归零，模拟器恢复关机。证据见 `recovery-result.txt`、`sample-before.txt`、`sample-after.txt`、`simulator-after.txt`。 [公开样例](../../../../docs/examples/sample-flutter-app/README.md)

## 剩余验收

A04 已完成跨登录验证。旧候选在 `SMAppService.mainApp.status = .notFound` 时禁用了首次登记。修复候选 `dd1061d` 允许用户显式登记，并继续用系统状态和实际操作结果更新开关。14 项定向 XCTest 通过，Release 构建成功。安装在用户 Applications 中的隔离副本实测开关可用，登记和撤销后依次为关、开、关，未显示错误。证据为 `/tmp/runlet-a04-retry.tAc0Dx/{before,enabled,disabled}.ax`。

固定路径安装后的实际重启确认 `loginwindow` 于 18:34:38 通过已启用的登录项启动 FlutterRunlet。主窗偏好为开启，辅助功能树仍显示零窗口。修复候选 `184ffc5` 在菜单栏场景就绪后按偏好显式打开主窗。隔离副本在正常、后台及直接启动中，偏好开启时均为一扇主窗，关闭时均为仅菜单栏，重复打开仍只有一扇。Debug 75 项及 Release 构建通过。同路径安装更新后，主窗打开且系统登记仍启用。

用户确认 `184ffc5` 登录启动与主窗行为符合预期。关闭主窗偏好时，登录后仅有菜单栏。撤销「登录时启动」后，用户注销并重新登录，确认菜单栏图标未自动出现。只读检查未发现应用进程或登录项记录。 [A04 用户验收](04-UAT.md)
