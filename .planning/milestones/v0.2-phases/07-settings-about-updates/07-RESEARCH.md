# 阶段 07 · 实施调研

2026-11-15。以 `07-CONTEXT.md` D-01–D-12、`07-UI-SPEC.md` 和 `07-FIGMA-EVIDENCE.md` 为准。先锁定视觉证据，用可控状态验收设置三页和独立关于；`07-VISUAL-GATE.md` 全通过之后才允许编写真实查询、下载、校验、安装、重启及回退。真实更新的第一条完整路径是隔离候选 A → 下载 B → 正常退出和真实替换 → B 就绪 → 三处显示实际 Bundle 信息；可先建立该路径用到的查询、验包和门禁，再扩展完整故障矩阵。公开发布流程继续暂缓。

## 真实 Release 与资产

匿名实查[固定仓库 latest](https://api.github.com/repos/atypiape/flutter-runlet/releases/latest) 返回 `v0.1.1`，正式、非草稿、非预发布、可变。正文里的「预发布版」不参与选版。资产为 `FlutterRunlet-v0.1.1-macOS-universal.dmg` 和同名 `.sha256`；本地同摘要历史副本可正常只读挂载，根目录含 `FlutterRunlet.app` 和 `/Applications` 链接。验证到 App 标识 `com.atypiape.FlutterRunlet`、版本 `0.1.1 (95)`、最低 macOS 15.0、App 与会话 worker 双架构，临时签名无 Team ID。远端入口重定向，未用远端全量下载作为实物证据。格式可以沿用；历史版本没有更新协议或可固定的发行身份，不能作为自动安装目标。

- App 级服务只在明确点击时访问固定公开仓库的 [GitHub latest 正式 Release](https://docs.github.com/en/rest/releases/releases#get-the-latest-release)，两处关于共用进行中的请求和结果。校验正式标记、数字 tag；对实际 `CFBundleShortVersionString` 按数字段比较，build 仅用于身份和重启核对。`404` 时确认固定仓库公开可读，检查匿名 Release 列表是否确无正式版；矛盾、不可读、限流、坏数据进入失败/不可用。列表仅解释 `404`。
- 从 Release 选与 tag 对应、唯一且已上传的通用 DMG，冻结仓库/Release/资产 ID、大小及摘要。按[资产 API](https://docs.github.com/en/rest/releases/assets#get-a-release-asset) 下载，要求受控 HTTPS 跳转、限时限量，缺摘要、歧义和意外源拒绝。新版缺可安装资产时表明原因及发布页。SHA-256 验证字节一致，同一来源 `.sha256` 不证明发行者身份。
- 公有安装要求[不可变 Release](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases)与随可信构建固定的 [Apple Developer ID 签名要求](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements)：Apple 签发链、已确认 Team ID、产品标识、签名覆盖版本/build、架构与嵌套代码，并保留系统安全检查。正式身份未配时检查仍工作、安装保持不可用；运行参数、环境、偏好、网络数据均不能切换测试信任。签名、公证与发行验收在后续解冻后进行。

## 隔离候选与安装事务

用两个真实构建验证：先打包 B，再把 B 的确切 DMG 摘要、预期产品标识、版本与构建号固定进只用于验收的 A。A/B 版本和 build 不同、隔离身份相同。A/B 共用专用账户或虚拟机的隔离偏好及恢复命名空间；各自构建输出单独保存。安装路径为本地可写 APFS 专用目录，和日常 App 分离。回环服务提供受控 GitHub 形状数据及真实下载，不参加信任决策。不同 build 可由隔离打包工具明确注入并用实际产物反查。同一下载、替换、启动与回退路径，只有验收构建可换来源/信任锚和注入故障；验证普通 Release 不包含或不接受该入口。

选用独立的 AppKit 更新助手和全量 DMG，复用现有打包与 worker 嵌入方式。[Sparkle 的发行方式](https://sparkle-project.org/documentation/publishing/)依赖 appcast 和签名归档，接入后仍需解决现有项目恢复门禁、事务健康确认和旧 App 无法自动启动时的独立反馈，本阶段不增加第二个发布源。

1. 下载、大小/摘要、只读挂载与包预检在调试和恢复期间可进行。只取镜像根目录真实 `.app`，拒绝别名、链接和来源变化，检查嵌套签名，私有暂存。独立应用级确认器监视两窗口之外的状态，安装可用时主动确认一次，支持稍后和任一入口继续。
2. 复用 `canTerminate` 的恢复、退出确认及 Doctor 清理；确认调用时无挂起重查并占用预约，Run、恢复和普通退出不能抢占。当前守卫只覆盖单实例，项目租约只锁一项目。设计同恢复命名空间的进程间活动/安装锁：受管活动持共享或等价活动租约直至确认后代退出；确认阶段取得独占并重读恢复状态，锁持续交接给助手。其他实例与活动入口遵守同一约定，无法确定则拒绝安装；不得借普通退出去强停会话。
3. 从旧 App 的可信嵌入代码启动 App 外独立助手。绑定规范目标、目录身份、旧进程与一次性事务凭据，记录私有事务；只有正常退出委托明确交接且旧进程真实退出才改磁盘。要求可写本地 APFS、同卷暂存，禁止符号链接和目标变化。验证保留旧版后用 [Darwin 同卷原子交换](https://raw.githubusercontent.com/apple-oss-distributions/xnu/main/bsd/man/man2/rename.2) 替换，检查交换后两端；不支持时保留原版，不做先删再复制。
4. 用 [NSWorkspace](https://developer.apple.com/documentation/appkit/nsworkspace/openapplication(at:configuration:completionhandler:)) 从原路径启动指定候选，不复用任意运行实例。打开成功不等于健康：等待新进程从预期路径完成关键初始化并回传一次性标记，核对实际进程、Bundle、版本、build、身份，在有限健康窗口确认存活。仅握手用的候选进程可在独占安装锁期间启动受限界面；标记不授权调试或恢复。试运行期间冻结调试、项目副作用和不可逆偏好迁移；现有控制器初始化会读写偏好，须在试运行前分流或延迟副作用。三处显示实际 Bundle；提交后才进入正常运行。
5. 替换失败查实磁盘；新版无法启动、早退或超时，确认试运行进程已停后原子恢复旧版、复验并写回执，再尝试启动旧版。旧版可用时显示失败原因、重试和发布页；已恢复但无法自动打开时由助手窗口显示真实位置、访达与发布页。未恢复或进程退出不能确认时，要明确实际状态并保留可恢复文件。交换前落盘，中断后按事务记录和两端实际身份复原；不引入常驻服务。

## Validation Architecture

| 领域 | 要求与验证 |
| --- | --- |
| 视觉门槛 | `07-VALIDATION.md` V01–V05。两处关于用可控状态，不发真实请求，原图/实拍/叠图/index 区分；缺失或差异先复测。 |
| Release 与下载 | XCTest 使用可控 HTTP，断言零自动请求、两入口合并、错误映射、数字版本、正式过滤、404 验证、网络限流、歧义资产和包篡改（包括同时篡改网络摘要）。另在视觉通过后匿名冒烟 latest，避免把今天的 tag 写成长期预期。 |
| 门禁 | 复用已有真实 worker、恢复和并发测试；覆盖调试/恢复仍可下载、未退出后代、记录不可读、第二实例、确认后竞争及传统退出；两窗都关也只主动提示一次，稍后可继续。 |
| 真实事务 | 两份构建实际下载安装、切换 PID、从原位置启动并更新三处；注入交换失败、新版失败/早退/超时、旧版启动失败、交换前后中断。记录磁盘版本、进程、路径、回执、恢复或保留文件和独立反馈，缺一不算通过。 |
| 最终联验 | 同一候选完成 UI-07、UI-13、UI-14、UI-15 与 UPD-01/02；除自动测试外必须有真实 macOS、窗口和 Flutter 运行/恢复证据。 |

实查环境为 Apple Silicon、Xcode 27.1；Intel 实机、最低支持 macOS 和正式发行安全检查保持待验。技术参考先经 Context7；GitHub 文档查询因 `fetch failed` 未返回，相关契约核对官方 REST 文档；另核对 Apple 官方资料与 Sparkle 发布文档。本轮没有执行更新测试。

计划复核补充：签名包实际版本必须等于正式 Release tag 且严格高于 A，验包和替换边界都独立复核。活动锁只约束遵守同一协议的实例，须另行识别未使用新租约的旧 App 和遗留 worker，无法确认时保守阻断。第一次磁盘交换前，助手就绪确认、B 失败后的 A 恢复及 A 未就绪时的独立反馈均必须可用。
