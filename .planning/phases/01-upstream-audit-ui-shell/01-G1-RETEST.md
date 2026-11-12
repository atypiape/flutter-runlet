# Phase 01 · G1 缺口复验

执行者在 2026-11-12 使用 macOS 26.7.1（25G241）和 Xcode 27.1（27A9275）验证。原始五项结果及第 2、3 项反馈可在提交 `541d976` 的验收文件查阅。[原始验收记录](01-UAT.md)

## 构建

构建目录为 `.build/phase-01-gaps`。Debug 的三项 `LaunchPresentationTests` 全部通过，Release 构建成功。两种配置的有效部署目标均为 15.0，只有 Debug 含 `DEBUG`。Mach-O 的 macOS 最低版本均为 15.0，SDK 为 27.0。Release 同时包含 arm64 和 x86_64。构建日志、有效设置 JSON、Mach-O 输出及校验值留在该目录。D-09 的 macOS 15 实机复验未执行。[部署目标基线](01-G1-ACCEPTANCE.md#a31--macos-15-部署目标与-api)

| 产物 | `Contents/MacOS` 文件 | SHA-256 |
| --- | --- | --- |
| `Build/Products/Debug/FlutterRunlet.app` | `FlutterRunlet` | `40fc9f5b4413918f7970274be1dc5224ff966c8f170562abb0fb6a8aefe7c007` |
| `Build/Products/Debug/FlutterRunlet.app` | `FlutterRunlet.debug.dylib` | `249fee3d3b8083518eb1f24146af7eae027be62e8843a3fcd5d0db4d357541d8` |
| `Build/Products/Release/FlutterRunlet.app` | `FlutterRunlet` | `ed154017a22d708904b7ed2a06a406bb210f77039aa303fc481ad4c5ca205b39` |

## G-01-2 · 面板与 Dock

- 两个面板开窗动作调用面板内容所附的 `NSWindow.close()`，然后复用原主窗路由和设置动作。保留系统 `MenuBarExtra(.window)` 和内容约束，关窗作用域限于面板宿主。主窗使用公开 `willCloseNotification` 和激活策略 API，在关窗后进入 `.accessory`，打开前恢复 `.regular`。重开路由也识别最小化的窗口，原位恢复。[NSWindow.close](https://developer.apple.com/documentation/appkit/nswindow/close()) · [AppKit 激活策略](https://developer.apple.com/documentation/appkit/nsapplication/setactivationpolicy(_:))
- 最终 Debug Ready 的 PID `57510` 在关闭主窗前后相同，`NSRunningApplication.activationPolicy` 从 `0`（`.regular`）变为 `1`（`.accessory`）。关于和设置窗口仍显示，关于可取得焦点，设置仍能从 Flutter 切回「通用」。另一实例 PID `57695` 最小化主窗后仍为 `.regular`。
- 远程界面工具只操作应用窗口，没有暴露菜单栏状态项，Dock 窗口也无法读取。两个菜单栏开窗动作的收起与重复打开、点外关闭、最小化后的同窗恢复，以及固定和未固定状态下的 Dock 运行指示均待本地界面复验。

## G-01-3 · 键盘与悬停

- 「打开项目」图标继续使用原 SwiftUI 工具栏按钮。独立 AppKit 视图为对应区域注册原生 `toolTip`，自身不接收点击。最终构建的可访问性树仍显示名称「打开项目」和禁用状态。点击图标未触发项目选择，相邻设置和关于可正常打开。[AppKit toolTip](https://developer.apple.com/documentation/appkit/nsview/tooltip)
- 检查时 `NSApplication.shared.isFullKeyboardAccessEnabled` 为 `false`，单次启动参数也无法更改该系统偏好。保持原生焦点链和系统键盘设置。开启「系统设置 → 键盘 → 键盘导航」后，主窗与面板的 Tab／Shift-Tab 可见焦点、顺序、回绕、Space 激活及提示关闭后的焦点恢复待复验。当前远程工具没有原生悬停动作，实际提示字样也待用本机指针复验。

## G1 回归

普通 Debug 主窗与带 `--g1-ready` 的 Release 主窗均显示 Empty。带该参数的 Debug 主窗显示 Ready，浅深模式均为 640 × 580 pt，示例字段、四个同排调试按钮和展开的空日志均可见。主窗原生演示提示可用回车关闭，关闭后恢复 Ready。设置外框为 672 × 520 pt，关于外框为 440 × 480 pt，版本显示为 0.1.0（构建号 1）。本轮未重取面板外观和长字段预览。[六张 G1 基线图和原生差异](01-G1-ACCEPTANCE.md)

## 最终用户复验

最终 Debug Ready 构建已启动。若已退出，可在仓库根目录运行：

```sh
open -n .build/phase-01-gaps/Build/Products/Debug/FlutterRunlet.app --args --g1-ready
```

1. **G-01-2**。分别从菜单栏打开「打开主窗口」和「设置」，观察面板是否收起且目标窗口取得焦点。用状态图标及点外方式关闭面板。关闭主窗后核对菜单栏仍可用且 Dock 无运行指示点，再重复打开主窗，核对仅一扇主窗且 Ready 数据仍在。最小化主窗后从面板打开，核对恢复原窗。
2. **G-01-3**。开启「系统设置 → 键盘 → 键盘导航」，在主窗与面板用 Tab／Shift-Tab 正反遍历，核对可用控件的可见焦点及禁用动作。将指针停在禁用的文件夹图标上，核对是否显示「打开项目」。

两项均待用户确认。
