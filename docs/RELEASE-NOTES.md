# FlutterRunlet 版本说明

## v0.4.1 · 手动更新提示

- 检测到新版发布尚未锁定时，引导用户手动下载安装，并高亮「查看发布页」。

Universal DMG 支持 Apple Silicon 和 Intel，最低部署目标为 macOS 15.0。安装包使用临时签名，未经 Apple 公证，需手动安装。[下载与中英文更新日志](https://github.com/atypiape/flutter-runlet/releases/tag/v0.4.1)

## v0.4.0 · 桌面调试与模拟器

- 支持 macOS 桌面调试。选择离线 iOS 模拟器或 Android AVD 时可自动启动设备，在 iOS 模拟器上开始调试时会显示模拟器窗口。
- 首次打开时提供项目入口提示，打开项目后默认选中启动配置和设备。
- 运行中可确认重启当前会话。主窗口显示调试状态和启动进度，日志区分启动与诊断消息，并自动换行。

Universal DMG 支持 Apple Silicon 和 Intel，最低部署目标为 macOS 15.0。安装包使用临时签名，未经 Apple 公证，需手动安装。[下载与中英文更新日志](https://github.com/atypiape/flutter-runlet/releases/tag/v0.4.0)

## v0.3.0 · DevTools 与设置

- Inspector 可按需启动独立 DevTools 并连接当前调试会话。同一会话重复打开会复用浏览器标签，选中 Widget 后可从 Inspector 跳到源码，按需打开 VS Code、Cursor 或 Zed。
- 设置新增 DevTools 页。独立 Dart SDK 路径单独显示，过长时从中间省略。可通过悬停查看完整地址，或点击行尾「…」在浮窗中查看并复制。通用设置提供深色、浅色和跟随系统，未保存偏好时默认深色。
- 独立「关于」窗口提供项目主页、文档、许可证和近期更新四个入口。

本地验收覆盖完整路径浮窗与独立 DevTools 2.61.0。项目沿用原有 Flutter、Dart 配置。预发布包使用临时签名，未经过 Apple 公证，需手动安装。[下载与中英文更新日志](https://github.com/atypiape/flutter-runlet/releases/tag/v0.3.0)

## v0.2.0 · 双架构 DMG

- 主窗口和菜单栏共享项目历史、设备选择和调试状态；运行中改选设备只影响下一次运行。主窗口支持复制、清空和折叠日志。
- 设置集中提供语言、启动偏好、Flutter SDK 来源和环境诊断。设置中的「关于」与独立「关于」窗口显示实际版本，并共享手动检查更新的结果。
- 本地验证覆盖真实 Flutter 调试、停止后的环境恢复，以及隔离环境中的更新安装和失败回退。

最低部署目标为 macOS 15.0，实机运行验证使用 Apple Silicon（macOS 26.7.1）。Intel 已核对构建架构和签名，Intel 和 macOS 15 实机运行仍待验证。本版使用临时签名，未经过 Apple 公证，需手动安装。[下载与中英文更新日志](https://github.com/atypiape/flutter-runlet/releases/tag/v0.2.0)

## v0.1.1 · 已提供下载

新增双架构 DMG 打包脚本和配套 SHA-256 校验文件。打包时可指定版本号，构建号取 Git 提交数。[下载与安装](https://github.com/atypiape/flutter-runlet/releases/tag/v0.1.1)

## v0.1.0 · 本地验收归档

构建号 1。候选提供 macOS 原生主窗口、菜单栏和中英文设置。Flutter 调试使用现有 VS Code 配置，支持 Debug 会话的启动、停止、热重载、热重启和当前会话的浏览器 DevTools。支持按原配置运行前后置任务，发生恢复失败或异常退出时可从应用内重试原任务。

最低部署目标为 macOS 15.0。主程序及内嵌 worker 的最低版本已从实际二进制核对。宿主实测使用 macOS 26.7.1。按阶段决定取消 macOS 15 实机及虚拟机运行验收，该版本的运行兼容性未验证。

冻结候选源码为 `36916dd`。G3 本地包使用 ad hoc 签名，签名校验及解包复验通过。该 ZIP 的 SHA-256 为 `5e4e29423b539090e8ed3867b94c0b6e50637e4f6abc8e9581928f756d262e55`。同一候选通过 30 分钟日志压力、真实项目三环境及强退恢复验收。[阶段验证](../.planning/milestones/v0.1-phases/05-stability-recovery-release/05-VERIFICATION.md) · [G3 验收记录](../.planning/milestones/v0.1-phases/05-stability-recovery-release/05-G3-ACCEPTANCE.md)

后续已在 GitHub 提供 [v0.1.0 预发布包](https://github.com/atypiape/flutter-runlet/releases/tag/v0.1.0)。正式分发所需的 Developer ID 签名、公证及最终公开复核留待后续完成。[公开前检查](PUBLIC-RELEASE-AUDIT.md)

启动、恢复操作和配置限制见使用文档。项目采用 MIT 许可证，关于窗口保留 Flutter GUI Runner 的上游归属。[使用说明](../README.zh-CN.md) · [项目许可证](../LICENSE)
