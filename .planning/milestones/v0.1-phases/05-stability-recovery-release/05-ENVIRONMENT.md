# Phase 05 · 真实工程、最低部署目标与归档

| ID | 判定 | 候选与证据 |
|---|---|---|
| A29 | 通过 | commit=36916dd1f6a6f916a1c76ca93aa37ae84f8247f6 app=52b6a4b1a6916e4ca0d457efcb98b10359785fc86e745267d1aa30a57fb64455 worker=a763ab4b27fb3bc348f2c32aa2edda2f9d5695f96a7ef222f2c95d2822d167e2。已定位获授权工程，完成隔离副本、真实 Firebase 文件基线备份和脚本的逐环境切换复验。VS Code 和当前候选逐环境验证 dev、test、prod 的参数与 Firebase 结果。两工具停止 prod 后均由原后置任务恢复 test 基线。 |
| A31 | 通过 | commit=36916dd1f6a6f916a1c76ca93aa37ae84f8247f6 app=52b6a4b1a6916e4ca0d457efcb98b10359785fc86e745267d1aa30a57fb64455 worker=a763ab4b27fb3bc348f2c32aa2edda2f9d5695f96a7ef222f2c95d2822d167e2。主程序和内嵌 worker 的各架构 Mach-O 最低版本均为 15.0。2026-11-14 用户取消 macOS 15 实机及虚拟机运行验收，该系统的运行兼容性未验证。 |

## A29 · 真实项目

从已授权工程的干净提交生成独立副本，核对路径及脚本写入目标均在副本内，并校验、备份 16 项配置和任务文件。按项目 FVM 版本获取依赖。使用原脚本验证 dev 和 test 的 Firebase 文件匹配 test 基线，prod 匹配 prod 基线，重跑原 test 任务后恢复，包含 iOS URL scheme。原工程的配置及任务指纹和 Git 状态已复核。

| 环境 | 已通过的本地预检 | 双工具运行 |
|---|---|---|
| dev | Firebase 选用 test 文件 | VS Code 与当前候选在 iOS 27.0 iPhone 17 模拟器和同版 FVM 上通过。环境、功能开关、代理、版本和 Inspector 参数值匹配原配置。 |
| test | Firebase 选用 test 文件 | 两种工具均在同一设备、SDK 和基线上通过环境、功能开关、版本和 Inspector 参数检查。 |
| prod | Firebase 选用 prod 文件，原 test 任务可恢复 | VS Code 和当前候选依次运行同一独立 iPhone 17 模拟器。环境、功能开关和版本参数一致。调试就绪后立即停止，两次均由原后置任务恢复 test。 |

原始路径、配置、备份及命令输出仅保存在私有证据目录。使用相同 SDK 和设备逐轮运行，环境从校验通过的 test 基线开始。prod 取得 2026-11-14 用户授权，只启动到 VM Service 连接即发出停止，未登录或操作业务。停止后四份生成配置和包含 Firebase URL scheme 的 Info.plist 均与同轮 test 基线字节一致。两工具的停止指令分别在观测就绪后约 6 ms 和 83 ms 发出。原项目 16 项摘要及 Git 状态均与初始记录一致。

## A31 · 最低部署目标

用 `xcrun vtool -show-build` 检查主程序及 worker 的 arm64 与 x86_64 架构，最低版本均为 15.0。宿主为 macOS 26.7.1。已确认取消目标系统运行验收。[阶段决定](05-CONTEXT.md) · [验收矩阵](../../../../docs/04-ACCEPTANCE.md)

## 归档

候选 0.1.0（1）的 `FlutterRunlet.zip` SHA-256 为 `5e4e29423b539090e8ed3867b94c0b6e50637e4f6abc8e9581928f756d262e55`。通过 `shasum -a 256 -c`、文件字节、执行位和签名校验。从解包后的 App 普通启动，使用独立公开样例和 iPhone 17 模拟器，连接 VM Service。Stop 后旧进程组退出，原后置任务恢复 test，风险清零。见候选的 `unpacked-a13.json`。
