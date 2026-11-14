# Phase 02 · 配置和任务执行内核研究

**日期** 2026-11-12

**依据** [阶段上下文](02-CONTEXT.md) D-01–D-15、[产品需求](../../../../docs/01-PRODUCT.md) §2–§5、[技术契约](../../../../docs/02-TECHNICAL.md) §1–§4、§8 和 [验收矩阵](../../../../docs/04-ACCEPTANCE.md) A07–A16、A32。

## 代码与实施边界

- `FlutterRunletApp` 创建两个原生场景，目前共享静态 `LaunchPresentation` 和 `showRunDemo`。让 App 持有唯一的可观察项目与会话控制器，沿用 `MainWindowView`、`MenuBarPanelView`、`DebugControls` 和已验收的窗口行为。项目选择、重读、Run、Stop、退出与恢复都由控制器裁决。设置窗口已有通用分组，接入最近项目偏好。 [G1 上游审计](../01-upstream-audit-ui-shell/01-UPSTREAM-AUDIT.md)
- `FlutterRunlet.xcodeproj/project.pbxproj` 显式列出 Swift 文件，新增源码和测试要加入对应 target。当前共享 scheme 已包含 `FlutterRunletTests`，项目目标为 Swift 6、macOS 15。沿用 SwiftUI、AppKit、Foundation、Darwin、CryptoKit 和 XCTest，无需引入第三方包或拷贝上游进程代码。
- Phase 02 的完整执行路径使用显式启用的 Debug 验收入口，注入可控子进程作为 Flutter 启动边界。解析、前后置任务、锁和持久恢复走正式组件。普通构建仍可打开项目、读配置与展示恢复状态。真实 Flutter 进程适配器、SDK/FVM、设备、热操作和浏览器调试归 Phase 03。Release 排除测试注入路径。

## 配置和执行

- JSONC 支持 `//`、`/* … */` 和单个尾随逗号。只在内存中识别注释、字符串转义和容器边界，保留源坐标并用严格 JSON 校验。明确测试未闭合注释、连续逗号、带注释标记的字符串、CRLF 和非 ASCII 行。语法错误报告文件、行、列及原因。文件缺失报告路径与原因。合法 JSON 的单个不支持配置保留名称和禁用原因。 [VS Code JSONC](https://code.visualstudio.com/docs/languages/json#_json-with-comments)
- 保持原始配置名、`toolArgs`、应用 `args`、`program`、`cwd`、`deviceId` 和环境语义。仅将完整 `--dart-define=KEY=VALUE` 从旧 `args` 迁入工具参数，保留原值、顺序和首个 `=` 后的值。测试空 `program`、两种 define 写法之间的冲突、等号和空格、mode/target/device 覆盖及应用参数映射失败。只接受能保证 Debug 且按契约映射的参数。用公开样例断言四个原名、旧和新参数及 prod PATH。 [Dart Code Launch Configuration](https://dartcode.org/docs/launch-configuration/) [公开样例](../../../../docs/examples/sample-flutter-app/README.md)
- 任务按唯一 `label` 解析。`process` 使用参数向量。基本 `shell` 命令带独立参数时逐项安全传递，命令字符串形式按显式 shell 语义执行，变量替换不得改变原有 shell 语法。对无法安全表达的引用或不支持的任务特性明确阻断。测试空参数、空字符串、Unicode、含空格或 shell 元字符的 argv。任务继承父进程环境再覆盖自身 `options.env`，启动配置的 `osx.env` 单独合并。执行器明确区分启动错误、退出码、信号和取消，持续读取 stdout/stderr，等子进程退出后才进入后置任务。 [VS Code Tasks](https://code.visualstudio.com/docs/debugtest/tasks) [Foundation Process](https://developer.apple.com/documentation/foundation/process.md)
- Run 前重新读 launch 和引用的 task，按有效执行定义比较，忽略注释、空白和无关配置。合法变更先刷新并消费本次点击，无效内容立即阻断。准备结果包含不可变的 launch/pre/post 计划，并在任务执行和子进程启动两个边界校验 Debug 条件。自动后置恢复使用运行前快照，重试按原项目和标签重读任务并检查记录。

## Security Domain

- **配置到子进程。** 用户明确执行后才运行项目声明的命令。配置选择、最近项目恢复和重读均为只读。工作目录、环境和 argv 通过独立字段交给执行器。禁用配置、未知变量、后台任务和依赖任务不得进入启动路径。
- **控制器到风险存储。** 对所有声明 `postDebugTask` 的配置，在前置任务或子进程之前提交恢复记录。记录放在用户私有的 App Support，原子替换并按需要同步，写入失败阻断执行，读取损坏进入可见的阻断状态。持久化版本、规范项目路径、原任务标签、任务定义指纹和显式引用变量的分项校验值。原始环境值、执行参数、原始命令和任务输出留在内存，变量变化只显示名称。对低熵环境值使用独立于记录保存的密钥生成 HMAC。恢复退出码为 0 后才清除记录，清除失败保留可见风险。 [Foundation atomic write](https://developer.apple.com/documentation/foundation/nsdata/writingoptions/atomic.md)
- **App 到受管进程。** 在首个异步边界前占用共享会话，按解析符号链接后的项目路径加进程间锁。在父 App 异常退出后，锁必须继续覆盖仍活动的受管任务或调试进程。可用持有锁的独立监督进程或等效机制，先用真实子进程实测，再确认最小实现。单靠 App 持有的 `flock` 会在 App 死亡时释放，PID 也可能复用。对无法确认退出的进程继续阻断重试或新运行。区分窗口关闭、正常 App 退出和强制退出。 [Apple flock(2)](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/flock.2.html) [AppKit 应用退出委托](https://developer.apple.com/documentation/appkit/nsapplicationdelegate/applicationshouldterminate(_:).md)

## Validation Architecture

本机 `xcodebuild -version` 返回 Xcode 27.1（27A9275）。测试基础设施复用共享 scheme 和宿主 XCTest target。新增行为测试先观察目标断言失败，再实现通过。每个任务用其测试类筛选，波次末运行全量 XCTest。命令沿用 G1 的 macOS destination，Phase 02 的 DerivedData 放在本机临时目录。

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet -configuration Debug -destination 'platform=macOS' -derivedDataPath "${TMPDIR:-/tmp}/flutter-runlet-phase-02" -parallel-testing-enabled NO test
```

| 验证 | 检测依据 |
|---|---|
| A07–A11、A32 | 复制公开 JSONC 和脚本到带空格的临时项目，用原始文件字节、配置选择状态、真实 argv/cwd/env 和子进程调用次数断言。 |
| A12、A13 | 执行公开脚本和可控子进程，记录 pre/launch/exit/post 先后及退出码，确认前置失败不会产生调试子进程。 |
| A14–A16 | 注入公开故障标记，重建或终止 App 进程并从同一测试存储启动，核对风险状态、锁、原任务校验、重试及清除。 |
| D-01–D-04、D-10–D-15 | Debug 主窗用隔离样例人工走完，记录项目/菜单栏一致性、配置错误和日志外的恢复入口。单独构建 Release 验证验收注入不可进入。 |

### 待实测

- Xcode 共享 scheme 和 G1 命令可复用。Phase 02 的测试文件与可控进程尚待实施，实际耗时、App 强制退出后的进程归属和 macOS 15 上的行为以执行证据为准。
- 公开脚本的 `fail-after-prod` 在写入环境标记后返回 1，`fail-before-dev` 和 `fail-before-test` 在写入前返回 1。验收从隔离的 test 基线开始，App 退出或重启时仅使用其测试存储。 [样例脚本](../../../../docs/examples/sample-flutter-app/scripts/simulate-firebase-switch.sh)
