# FlutterRunlet v0.1.0 本地验收候选

构建号 1。候选提供 macOS 原生主窗口、菜单栏和中英文设置。Flutter 调试使用现有 VS Code 配置，支持 Debug 会话的启动、停止、热重载、热重启和当前会话的浏览器 DevTools。支持按原配置运行前后置任务，发生恢复失败或异常退出时可从应用内重试原任务。

最低部署目标为 macOS 15.0。主程序及内嵌 worker 的最低版本已从实际二进制核对。宿主实测使用 macOS 26.7.1。按阶段决定取消 macOS 15 实机及虚拟机运行验收，该版本的运行兼容性未验证。

冻结候选源码为 `36916dd`。G3 本地包使用 ad hoc 签名，签名校验及解包复验通过。该 ZIP 的 SHA-256 为 `5e4e29423b539090e8ed3867b94c0b6e50637e4f6abc8e9581928f756d262e55`。同一候选通过 30 分钟日志压力、真实项目三环境及强退恢复验收。[候选构建](../.planning/milestones/v0.1-phases/05-stability-recovery-release/05-01-SUMMARY.md) · [G3 验收记录](../.planning/milestones/v0.1-phases/05-stability-recovery-release/05-G3-ACCEPTANCE.md)

公开发布暂缓。公开分发所需的 Developer ID 签名、公证及关于窗口链接的匿名访问复验留待发布阶段完成。[公开前检查](PUBLIC-RELEASE-AUDIT.md)

启动、恢复操作和配置限制见使用文档。项目采用 MIT 许可证，关于窗口保留 Flutter GUI Runner 的上游归属。[使用说明](../README.md) · [项目许可证](../LICENSE)
