# FlutterRunlet 开发者指南

## 构建与运行

准备完整的 Git 检出和 Xcode。v0.2 的本地验收使用 macOS 26.7.1、Xcode 27.1；项目的最低部署目标为 macOS 15.0。打开 [FlutterRunlet.xcodeproj](../FlutterRunlet.xcodeproj)，选择共享的 `FlutterRunlet` scheme 和本机 Mac，按 Command-R 运行。

主应用源码在 [FlutterRunlet](../FlutterRunlet/)，同一 scheme 会构建 [会话 worker](../FlutterRunletSessionWorker/) 和 [更新助手](../FlutterRunletUpdateHelper/)。构建应用本身无需 Flutter SDK；验证真实调试还需可用的 Flutter SDK、测试项目及模拟器或真机。

## 测试与本地取证

在仓库根目录运行 XCTest：

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath .build/dev -parallel-testing-enabled NO test
```

用[隔离 Flutter 示例](examples/sample-flutter-app/README.md)验证真实设备、前后置任务及异常恢复。更新和界面验收的前置条件、私有清单及复跑方法见[阶段 07 验证方案](../.planning/phases/07-settings-about-updates/07-VALIDATION.md)；最终结果见[阶段 06 验收](../.planning/phases/06-main-window-menu-bar/06-ACCEPTANCE.md)和[阶段 07 验收](../.planning/phases/07-settings-about-updates/07-ACCEPTANCE.md)。

把可重建的编译缓存和试打包产物放在 `.build/`，把原始验收截图、日志、测试结果包和与签核摘要绑定的候选留在 `.private/`，只提交脱敏结论。清理时保留签核引用的原始证据及候选；重新构建的二进制不能替代锁定摘要的原件。

更新用户文档时，同步维护[英文首页](../README.md)和[简体中文说明](../README.zh-CN.md)。为每种语言拍摄对应的 [README 截图](screenshots/)。用隔离示例取图，检查画面和图像元数据后再提交。

## 打包本地候选

```sh
./scripts/package-release.sh v0.2.0
```

版本参数可省略 `v` 前缀，只覆盖本次打包；不传参数则使用 Xcode 工程的 Release 默认版本。构建号取 `git rev-list --count HEAD` 的结果。浅克隆先用 `git fetch --unshallow` 补齐提交历史。

Xcode 在签名前剥离主程序、会话 worker 和更新助手的调试符号。脚本创建 DMG 后以只读方式挂载，逐个核对三者的 arm64 与 x86_64 架构、签名和构建机路径。全部检查通过后才输出 `FlutterRunlet-v<版本>-macOS-universal.dmg` 和配套 `.dmg.sha256`，每次结果位于 `.build/release/` 下独立目录。在输出目录用 `shasum -a 256 -c *.dmg.sha256` 复核摘要，再从 DMG 安装并验证启动。

该脚本生成 ad hoc 签名的本地测试包，不执行 Apple 公证。供授权测试者手动下载的预发布应标为 GitHub pre-release，并附带校验文件。正式分发及应用内更新还需配置受信发行签名、完成公证，并验证正式 Release 元数据和资产；公开前按[脱敏记录](PUBLIC-RELEASE-AUDIT.md)复核。当前公开发布仍暂缓。

## 项目文档

- [产品需求](01-PRODUCT.md) · [配置与运行技术契约](02-TECHNICAL.md) · [验收矩阵](04-ACCEPTANCE.md)
- [界面规格](design/UI-SPEC.md) · [设计系统](design/DESIGN-SYSTEM.md)
- [开发路线图](../.planning/ROADMAP.md) · [里程碑归档](../.planning/MILESTONES.md) · [协作约定](../AGENTS.md)
