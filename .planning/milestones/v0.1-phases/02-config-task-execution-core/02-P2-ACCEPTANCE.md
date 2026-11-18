# Phase 02 · P2 验收记录

执行日期为 2026-11-12，时区为 Asia/Shanghai。macOS 26.7.1（25G241，arm64），Xcode 27.1（27A9275）。自动与人工验收的最终结果汇总在 [02-UAT.md](02-VERIFICATION.md)。

## 最终构建

受测源代码提交为 `9a843d0864039639e370de01ec75f85e22c12e27`。共享 scheme 的 Debug XCTest 退出 0，共 34 项，通过 34 项，无失败或跳过。Release build 退出 0。Debug 构建包含 G1 的三个启动策略回归。

```sh
derived="${TMPDIR:-/tmp}/flutter-runlet-phase-02"
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath "$derived" -parallel-testing-enabled NO test
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Release \
  -destination 'platform=macOS' -derivedDataPath "$derived" build
for config in Debug Release; do
  bundle="$derived/Build/Products/$config/FlutterRunlet.app"
  test -x "$bundle/Contents/MacOS/FlutterRunlet" || exit 1
  test -x "$bundle/Contents/Helpers/FlutterRunletSessionWorker" || exit 1
  codesign --verify --deep --strict "$bundle" || exit 1
  (cd "$bundle" && shasum -a 256 Contents/MacOS/FlutterRunlet Contents/Helpers/FlutterRunletSessionWorker)
done
```

| 构建 | 相对 App 的可执行文件 | SHA-256 |
|---|---|---|
| Debug | `Contents/MacOS/FlutterRunlet` | `e178045dc2d2564c2cc0fb01e54d2eb1e2c4b5e0c83dded7ed988073b882a712` |
| Debug | `Contents/Helpers/FlutterRunletSessionWorker` | `59ca7863671ac31cbc2ca7ad0fbfccea0d79dc3da643fb185bcfd0ee5e854bdb` |
| Release | `Contents/MacOS/FlutterRunlet` | `423ded899d402c62a4e2db47f1203b78f83ee626312a0fffbace4839468b2c69` |
| Release | `Contents/Helpers/FlutterRunletSessionWorker` | `84343f6ef42c86378d9de29399a7eeee27ca362c1c42fcf4ae3719a09e325cd2` |

构建产物在上方 DerivedData 的 `Build/Products/{Debug,Release}/FlutterRunlet.app`。测试包在 `Logs/Test/Test-FlutterRunlet-2026.11.12_16-21-00-+0800.xcresult`。两套 App 均通过深度签名验证。Debug 主窗实际 Run 时，`pgrep -P <本次 App PID>` 找到内嵌监督进程。

## 样例准备

先启动 Debug 验收入口，由 App 创建并验证固定根。再从仓库根运行下方命令。两个样例项目与根外对照项目都使用独立临时目录。原始样例说明见 [公开样例 README](../../../../docs/examples/sample-flutter-app/README.md)。

```sh
derived="${TMPDIR:-/tmp}/flutter-runlet-phase-02"
debug="$derived/Build/Products/Debug/FlutterRunlet.app"
open -n "$debug" --args --phase-02-fixture
root="$HOME/Library/Application Support/FlutterRunlet-Phase02Fixture/projects"
for attempt in 1 2 3 4 5; do
  test -d "$root" && break
  sleep 1
done
test -d "$root" || exit 1
sample="$(mktemp -d "$root/Runlet P2 Public Sample.XXXXXX")"
second="$(mktemp -d "$root/Runlet P2 Other Sample.XXXXXX")"
outside="$(mktemp -d "${TMPDIR:-/tmp}/Runlet P2 Outside.XXXXXX")"
alias="$root/Runlet P2 Outside Alias.${sample##*.}"
ln -s "$outside" "$alias"
source="$PWD/docs/examples/sample-flutter-app"
for project in "$sample" "$second" "$outside"; do
  mkdir -p "$project/.vscode" "$project/scripts" "$project/lib" "$project/.runlet-fixture"
  cp "$source/launch.jsonc" "$project/.vscode/launch.json"
  cp "$source/tasks.jsonc" "$project/.vscode/tasks.json"
  cp "$source/scripts/simulate-firebase-switch.sh" "$project/scripts/"
  printf 'name: sample\ndependencies:\n  flutter:\n    sdk: flutter\n' > "$project/pubspec.yaml"
  printf 'void main() {}\n' > "$project/lib/main.dart"
  printf 'test\n' > "$project/.runlet-fixture/firebase-environment"
done
printf '%s\n' "$sample" "$second" "$outside" "$alias"
```

在主窗通过「打开项目」选择 `$sample`。每个正常场景前确认环境标记为 `test`，故障场景只创建对应标记，复验前用 `unlink` 移除本轮创建的标记。异常调试退出使用 `debug-exit` 标记。App 被强制终止的场景只结束本次验收 App 的 PID，随后用相同参数重启。重启和恢复使用固定根及同一个专用存储。对配置编辑场景只修改样例副本，结束后用原文件复位并执行 `cmp`。

```sh
cat "$sample/.runlet-fixture/firebase-environment"
cmp "$source/launch.jsonc" "$sample/.vscode/launch.json"
cmp "$source/tasks.jsonc" "$sample/.vscode/tasks.json"
find "$HOME/Library/Application Support/FlutterRunlet-Phase02Fixture/state" -maxdepth 1 -name '*.risk'
```

## 验收矩阵

「通过」记录执行者实测或可运行回归，另有用户复核的结果见 UAT。主窗操作使用实际 macOS App，调试边界用受管替身，前置和后置仍运行公开脚本。

| 验收项 | 结果 | 观察和证据 |
|---|---|---|
| A07 | 通过 | 主窗重读损坏样例显示 `launch.json 第 1 行第 3 列`，保留并禁用过期 prod 选择。恢复文件后重读成功。XCTest 覆盖 CRLF、非 ASCII 和未闭合注释。 |
| A08 | 通过 | 原生菜单实际显示 `sample-flutter-app(dev)`、`sample-flutter-app(physical)`、`sample-flutter-app(test)`、`sample-flutter-app(prod)`。两个根内项目均可打开和切换。 |
| A09 | 通过 | XCTest 断言新旧 define 原顺序与完整值，应用 argv 单独保留。主窗有效参数变更首次 Run 提示再次点击，零任务。之后只改注释即可直接 Run。原样例两份配置的 `cmp` 均退出 0。 |
| A10 | 通过 | XCTest 断言启动 PATH 为公开前缀加测试继承值 `/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin`。真实任务只收到自己的继承/覆盖环境。 |
| A11 | 通过 | 两个带空格路径的项目都运行真实脚本。真实任务回归比对 cwd、展开路径、空参数与 Unicode 及 shell 特殊字符的 argv 字节。 |
| A12 | 通过 | 缺失、重名、后台和扩展任务在测试中被拒绝。主窗 `fail-before-dev` 显示前置退出 1，环境保持 `test`，未出现 `debug-started`。 |
| A13 | 通过 | 主窗 Run 后标记为 `prod`，风险记录数为 1，并观察到监督进程。Stop 完成后为 `test`，风险记录数为 0。关闭主窗时监督进程和 `prod` 仍在，受管进程退出 19 后恢复 `test`。 |
| A14 | 通过 | `fail-before-test` 后标记为 `prod` 且风险仍在。主窗显示退出 1、原标签和「重试恢复」，收起日志仍可用。系统退出被取消。移除标记后重试恢复为 `test`。 |
| A15 | 通过 | `fail-after-prod` 写入 `prod` 后失败，调试进程未启动，保留原恢复任务。另在运行中强制终止验收 App，重启主窗显示待恢复项目与 `sample:select-test`，点击重试后才恢复。 |
| A16 | 通过 | 主窗运行中禁用 Run，点击打开项目提示先停止，恢复后重新发起才切换。XCTest 分别用 Stop 和父控制管道关闭复现组长先退，确认同组后代退出前阻断别名启动与竞争恢复。用户在 UAT 第 2 项确认菜单栏与主窗同步。 |
| A32 | 通过 | 将临时 prod 模式改为 profile 后重读，名称保留、原因可见、Run 禁用。执行层 XCTest 直接调用也保持环境标记和风险记录不变。 |

## 原生操作和构建隔离

- 普通 Debug 实际启动显示未选择项目，Run 禁用。独立测试主目录下的打开面板交互超时。Release 使用独立偏好及 `-recentProjectPath` 读取根外样例，选择 prod 后实际显示「当前构建尚未接入 Flutter 调试进程」，Run 禁用。
- Debug `--g1-ready` 显示 G1 的演示字段，点击 Run 只出现「演示模式」。Release 同时传 `--g1-ready` 和 `--phase-02-fixture` 后仍进入普通模式。根外标记保持 `test`，未创建 `debug-started` 或测试存储。
- 隔离 Debug 打开根外项目和指向它的根内符号链接，两次都显示「请选择验收目录内的 Flutter 项目」，当前项目未变。根外项目维持 `test`。最终修复复验额外设置 `CFFIXED_USER_HOME`，仍在原固定根实际执行 prod → test，覆盖目录未创建验收存储。
- 原生退出确认「停止并退出」后进程正常退出，环境为 `test`，风险记录为 0。桌面自动化未能定位菜单栏状态项，由用户在 UAT 第 2 项复验。
- 主窗故障、重启、切换与 Profile 场景取证于 `bfe3770`。固定根修复、普通 Debug、G1 和 Release 参数复验于 `6bb37e3`。最终构建在其上加入改名、目录替换、派发前 Stop、macOS 模式覆盖与双实例恢复刷新回归。最终 Debug 重新实测 prod → Stop → test、监督进程启动和配置字节不变。

## Release 参数隔离自动复验

使用上文签名和 SHA-256 已核对的 Release。在临时主目录预建 `Library/Application Support`，从根外样例选择 prod。启动参数如下，其中 `isolated_home`、`outside` 与 `derived` 分别为临时主目录、根外样例及上文的 DerivedData。

```sh
mkdir -p "$isolated_home/Library/Application Support"
CFFIXED_USER_HOME="$isolated_home" \
  "$derived/Build/Products/Release/FlutterRunlet.app/Contents/MacOS/FlutterRunlet" \
  -rememberRecentProject YES -recentProjectPath "$outside" --g1-ready --phase-02-fixture
```

自动交互从配置菜单选中 `sample-flutter-app(prod)`，断言可访问性树包含根外样例、prod 选中值、禁用的「运行」和「当前构建尚未接入 Flutter 调试进程」。脚本对比启动前后样例 `.runlet-fixture` 和固定 Debug 存储 `FlutterRunlet-Phase02Fixture/state` 的文件列表、SHA-256 与修改时间，并断言环境仍为 `test`、无 `debug-started`、临时主目录只创建普通恢复存储。所有断言通过，对应 UAT 第 3 项。

## 清理失败复验

最终 XCTest 额外覆盖完成凭据目录同步失败及清理旧记录失败。完成凭据未持久提交时，原风险记录保留，重启继续显示。凭据已确认持久而清理失败时，重启识别已完成的原会话，新会话的风险仍独立。最终原生 Debug Stop 后标记为 `test`，风险和完成凭据文件均已清理。

## 范围

Flutter 真机、模拟器、SDK/FVM、VM Service、热重载与 DevTools 按路线图进入 Phase 03。
