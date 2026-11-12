# Phase 03 · Flutter 调试闭环研究

**日期** 2026-11-12

**依据** 上次研究返回的本机源码、Context7 官方资料和设备盘点结论，本次复核仓库接入点。Flutter 3.47.4、Dart 3.13.3、DevTools 2.60.0 是该次研究的环境记录。正式端到端证据在执行阶段采集。

## 调试协议与恢复边界

- 使用解析后的 SDK 绝对路径执行 Debug `flutter run --machine`。将设备 ID 和机器协议选项作为适配器拥有的参数，保留 `PreparedLaunch` 中已验证的项目目录、程序入口、工具参数、应用参数和环境。复验沿用 `ProjectConfiguration.swift`，在启动前拒绝会覆盖机器模式、设备或 Debug 语义的冲突。
- 本机 Flutter 的 `packages/flutter_tools/lib/src/commands/daemon.dart` 实现机器协议。按请求 ID 和当前 `appId` 匹配 `app.restart`，以 `fullRestart` 区分热操作，并校验响应的实际结果。写入成功或收到事件都不足以确认热操作成功。信号可触发操作，但无法提供规格要求的成功确认。保留相应兼容性依据，使用机器协议获取结果。
- 复用 `SessionProcessRunner.start`、`SessionProcess.wait`、worker 及项目租约。当前 worker 的 stdin 承载控制管道 EOF，现有命令输入只传启动 JSON，Flutter 子进程 stdin 为 `/dev/null`。为 Debug 子进程新增独立的机器命令通道，避免改变任务的输入方式以及 EOF 停止和父进程退出行为。正常停止可尝试机器命令，超时沿用现有进程组终止。只有 worker 确认主进程及受管进程组退出，才可执行原后置任务。进程状态未确认时保留风险记录和阻断。
- 在 `SessionController.run` 保留配置和引用任务复验、项目租约与启动前检查。真实 SDK、设备或配置预检失败时保留日志，且不得启动任何前置任务。进入受管会话后复用 `execute` 和 `restore`。待验收原型不改变两窗口共享一个控制器的结构。

## SDK、设备与连接

- Flutter 设置展示经可执行文件实际查询的 Flutter/Dart 版本。按启用的项目 FVM、有效手动 SDK、PATH 顺序解析。项目要求的 FVM 或已经生效的手动路径无效时按契约阻断，验证新手动路径后再替换。解析与发现回调携带项目和请求身份，过期结果不覆盖当前选择。来源参考 [FVM 项目配置](https://fvm.app/documentation/guides/project) 与 [Flutter CLI](https://docs.flutter.dev/reference/flutter-cli)。
- 设备枚举与启动使用同一个已验证 SDK。依据实际设备 ID 处理显式配置冲突、项目内会话期记忆、离线保留及同 ID 重连。启动 iOS 模拟器后继续刷新，直到 Flutter 发现已启动设备。上次盘点发现关机的 iOS 模拟器和 Android AVD，均需在 G2 验证可用性。一次命令失败不证明设备断开。
- 从当前机器协议的 `app.debugPort` 获取 VM Service 地址，从 `app.devTools` 获取可用 DevTools 地址。使用针对当前会话的实际连接及有效 RPC 验证就绪。进程启动后第 60 秒仍未连接时继续等待，保留停止。连接中断时重连当前会话，设备确认为断开时沿用停止与恢复。通过会话身份拒绝迟到事件。检查地址、来源和当前会话归属，再交给默认浏览器。
- 优先使用 Flutter 为当前会话报告的 DevTools 地址。缺少或不匹配时验证官方支持的当前服务连接方式。[DevTools CLI](https://docs.flutter.dev/tools/devtools/cli) 可作为备选依据。Inspector 直达以目标版本实测为准，若不可靠则打开已连接的 DevTools 并提示进入 Inspector。G2 必须证明可以选取 Widget，并验证新会话绑定更新。

## 日志与数据边界

- 在 `SessionProcess` 读取 stdout/stderr 时增量处理行、UTF-8 分片和机器协议，日志先于进程退出可见，退出时不重复汇入。当前会话原始连接地址仅在内存中保留。显示、选区、复制与验收证据使用遮罩后的连接地址，保留地址与端口。跨读取块及结构化 URL 参数均要验证遮罩，不把机器帧或完整连接凭据写入恢复记录。
- 日志在同一会话中独立于折叠状态。清空之后继续接收新输出。正常结束和恢复后保留日志，实际开始下一轮或成功切换项目才按 D-13/D-14 清空。滚动离开底部时保留位置。复用当前原生布局和共享调试按钮。

## Validation Architecture

| 验证面 | 自动证据 | 实际环境证据 |
| --- | --- | --- |
| RUN-01/02 · A17/A18/A24 | 用受控 SDK/设备输出覆盖优先级、项目明确要求失效、设备离线和显式冲突、过期刷新、阻止前置任务 | 真实 iOS Simulator，确认 Android AVD 和真机可用性，核对实际 SDK 版本 |
| RUN-03/05 · A13/A17/A19/A21/A22 | 用现有 Xcode XCTest 和隔离进程夹具覆盖命令 ACK、超时重连、退出确认、停止竞争、后置顺序和共享状态 | 在公开 dev/test/prod 样例看真实 Debug、热操作、窗口关闭后菜单栏控制、进程退出和设备断开、prod 恢复 |
| RUN-04 · A20 | 验证 VM 地址归属、重连和跨会话更新、入口禁用与回退，使用可观察的打开动作 | 默认浏览器、当前 DevTools、Inspector 选取 Widget、重跑后的新会话 |
| RUN-06 · A30 | 验证运行中输出、跨块遮罩、清空后收到新输出、保留与清除边界 | 核对折叠/展开、跟随、复制和原生滚动位置 |

现有 `FlutterRunletTests`、共享 `FlutterRunlet` scheme 和 Phase 02 验证命令可复用。新测试和必要的短命机器协议夹具随首个覆盖其行为的任务一同加入。Xcode 工程显式登记源文件和测试目标。每任务跑对应测试类，每波跑 Debug 全量，收口做 Release 构建及适用 G2 实测。实测使用独立公开示例项目，记录版本、受测构建、环境、操作和遮罩后的证据。设备条件缺失按验收矩阵区分阻塞与不适用。
