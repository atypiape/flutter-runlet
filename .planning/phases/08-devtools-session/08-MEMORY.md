# v0.3 · 调试内存与进程归属

## VS Code 的做法

VS Code 把 Electron 主进程、工作台渲染进程、扩展宿主和共享任务分开。Process Explorer 和 `code --status` 可识别进程角色。Dart Code 可按设置在 VS Code 内嵌或外部浏览器显示 DevTools，也支持与 Flutter 共用 DevTools 服务。内嵌时页面相关内存仍计入对应的 VS Code 进程。[VS Code 进程架构](https://code.visualstudio.com/blogs/2022/11/28/vscode-sandbox) · [Process Explorer](https://github.com/microsoft/vscode/wiki/Performance-Issues#visual-studio-code-is-consuming-a-lot-of-cpu) · [Dart Code DevTools 设置](https://dartcode.org/docs/settings/#dartdevtoolslocation)

FlutterRunlet 已有分工。主进程管理 SwiftUI、会话状态、界面日志和 VM Service 连接。会话 worker 管理子进程和清理。项目编译、热重载所用的 `frontend_server` 由 Flutter SDK 启动，独立 DevTools 服务由所选 Dart SDK 启动，页面由浏览器渲染。[进程启动](../../../FlutterRunlet/SessionProcess.swift) · [独立服务](../../../FlutterRunlet/SessionController.swift)

## 已有实测

下列数据来自同一工程配置、SDK 与 iOS 模拟器的既有采样，单位为 MiB。统计宿主机进程的 macOS physical footprint，运行稳定值为模拟器 App 启动后 30–40 秒窗口的采样中位数。模拟器和其中运行的 App 单独记录。直接对比的两行都保留 VS Code 和 FlutterRunlet，分别只让其中一个发起调试。浏览器 Inspector 关闭。

| 场景 | 启动峰值 | 稳定中位数 |
|---|---:|---:|
| VS Code 发起调试，FlutterRunlet 保持空闲 | 4,377.3 | 3,721.2 |
| FlutterRunlet 发起调试，VS Code 保持打开 | 4,351.6 | 3,599.4 |
| FlutterRunlet 发起调试，VS Code 关闭 | 2,250.9 | 1,690.0 |

前两行的单轮差值为启动峰值 25.7 MiB、稳定值 121.8 MiB。第三行独立采集，可用来查看组成。稳定期 FlutterRunlet 主进程约 51 MiB，会话 worker 约 1.6 MiB，`flutter run` 约 102 MiB，`frontend_server` 约 1,391 MiB。前两行的 `frontend_server` 也约为 1,392 和 1,397 MiB。三个进程的角色可以用进程树确认，活动监视器或其他菜单工具的应用汇总可能采用不同归属规则。

另一轮首次打开独立 Inspector 时，FlutterRunlet 和 Edge 合计多约 479 MiB。Edge 约增加 329 MiB，独立 DevTools 服务约占 90 MiB。已打开后连点五次的另一轮中，合计增加约 4.7 MiB，标签仍为一个。各轮数字保留原采样条件，不能把不同轮次的增量直接相加。[PR #1 验收与内存对比](https://github.com/atypiape/flutter-runlet/pull/1)

## 是否继续拆进程

主进程已在 51 MiB 左右，调试常驻大头已经在子进程里。把现有 UI 或会话状态移到另一个进程会改变归属，新增进程基线和 IPC，还会扩大清理与恢复路径。没有测量证据表明这样可以降低整套调试的总内存。此次保留现有进程结构。

借鉴 VS Code 的做法可以先提供按角色查看进程的诊断。对比时同时记录主进程、全部相关进程合计和相对空闲的增量。固定 Flutter/Dart SDK、设备、交换前后状态和启动缓存。比较 Inspector 时固定是否打开、打开方式及浏览器基线。把可能脱离父进程树的 Xcode 构建服务单独记录，模拟器保持同一台并单独列出，避免漏计或重复归属。报告每轮峰值、同一稳定区间的中位数和多轮离散程度。已有数据用于判断进程构成与量级。
