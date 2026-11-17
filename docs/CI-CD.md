# FlutterRunlet CI/CD

## 自动 CI

[CI](../.github/workflows/ci.yml) 在 Ubuntu 检查 Git 差异、Shell 语法和 Python 发布脚本测试。PR 按拟合入结果选择验证范围，`main` 推送按更新前后的提交差异选择范围。

- 仅改文档、截图或工作流中列出的通知、分支检查和发布脚本等文件时，只运行 Ubuntu 检查。
- 若还改了 XCTest，则在 macOS 校验工程与权限配置文件、构建 Debug 并运行 XCTest。
- 涉及其他路径时执行完整验证，包括应用、Xcode 工程、随包资源、CI 和打包脚本。完整验证在 XCTest 后通过[打包脚本](../scripts/package-release.sh)构建并校验 Release Universal DMG。DMG 和 SHA-256 可在 Actions 运行详情下载，PR 产物只供检查，与 GitHub Releases 无关。

`main` 的轻量路径还会比较最新已发布版本与本次提交的应用文件。存在累计应用改动或无法核实发布基线时，执行完整验证。

必需检查 `macOS build and test` 汇总 Ubuntu 和 macOS 作业结果。Ubuntu 检查通过且本次只需静态检查时，才接受 macOS 作业跳过。

开放 PR 仅编辑标题或正文时，Ubuntu 作业查找同一拟合入提交的检查结果。已有检查通过时沿用结果，跳过实际验证步骤。先前检查仍运行时等待其结果，检查失败时保留失败状态。没有同一提交的记录或目标分支变化时重新验证。已关闭的 PR 仅编辑标题或正文时，跳过所有作业。

工作流使用 [`xcode-27` Apple Silicon 镜像](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md)内置的 Xcode 27.1（Runner 镜像处于公开预览），通过 `DEVELOPER_DIR` 选择工具链；Xcode 26.6 在编译项目时发生 Swift 编译器崩溃。源码编译与 XCTest 不依赖 Flutter SDK；需要真实 Flutter 环境的验证仍按[开发者指南](DEVELOPMENT.md)手工执行。Xcode 无需下载，构建无外部依赖；XCTest 一次完成 Debug 编译和测试，Release 由打包脚本单独构建，不跨运行缓存 DerivedData。

## 设置分支保护

1. 在仓库 **Settings → Actions → General** 确认 Actions 已启用、默认 Workflow permissions 为 **Read repository contents and packages**，且未允许 Actions 创建或批准 PR。各作业另外声明所需权限，只有发布作业拥有 `contents: write`。
2. 先让测试 PR 运行并通过 `macOS build and test`；对尚未出现此检查的仓库，不要提前设为必需。
3. 在 **Settings → Rules → Rulesets** 分别编辑 `dev` 和 `main` 的 Ruleset，在 **Require status checks to pass** 中添加 `macOS build and test`，集成来源选择 **GitHub Actions**。保留相应分支的 `branch-policy (...)`，以及 [Git 规范](GIT-WORKFLOW.md#github-rulesets)规定的保护与合并方式。

## Slack 私信通知

新建 PR、PR 合入 `main`，以及 CI、Branch policy 或 macOS Prerelease 运行结束时，[通知工作流](../.github/workflows/slack-notifications.yml)发送 Slack 私信。CI 或 Branch policy 整条运行均跳过时省略通知。新建 PR 通知包含 ➕、PR 编号、标题和指向 PR 的「详情」链接。发布流程选出候选版本后通知开始打包，构建结束后单独报告结果。DMG 和校验文件上传后才报告打包完成；工作流仍须另行通过发布校验。跳过候选时不发送打包通知。

1. 在 [Slack API](https://api.slack.com/apps)创建 Slack App，添加 Bot Token Scope `chat:write`，并安装到收件人所在工作区。保存 Bot User OAuth Token，从收件人 Slack 个人资料复制成员 ID。
2. 在 GitHub 仓库 **Settings → Environments** 新建 `slack-notifications`，只允许 `dev` 和 `main` 两条分支使用，不设审批。将 Bot Token 和成员 ID 分别填入环境 Secrets `SLACK_BOT_TOKEN` 和 `SLACK_USER_ID`，避免出现在公开日志中。
3. 工作流进入默认分支后，在 **Actions → Slack notifications → Run workflow** 发送测试私信。测试失败时查看运行日志；自动通知失败会记录警告，不影响构建和发布。Release 打包通知随改动进入 `main` 后生效。

自 2026 年 12 月 2 日起，公开仓库须在 Actions 事件策略中为此工作流显式允许 `pull_request_target`，才能发送新建 PR 和 PR 合入通知。[GitHub 事件策略变更](https://github.blog/changelog/2026-11-02-pull_request_target-blocked-by-default-december-2/)

## 发布授权和 AI

仓库所有者在发布 PR 合入前完成 [公开脱敏审计](PUBLIC-RELEASE-AUDIT.md)，并按 [Release 模板](RELEASE-TEMPLATE.md)留下授权评论。评论绑定 PR 源提交、目标提交和发布方式。发布脚本核对评论作者和时间，拒绝合入后的补签或审批后发生变动的提交。通过授权检查后无需 Actions 部署审批。

版本计算作业使用只读仓库权限。缺少双语说明时，通过 GitHub Actions 的 `GITHUB_TOKEN` 调用 Copilot CLI，需仓库所有者可用的 Copilot 权益。模型只接收公开 PR 文本，无仓库写权限。发布作业单独拥有 `contents: write`，不调用 AI。

## 运行与排查

[macOS Prerelease](../.github/workflows/release.yml) 监听同仓库 `main` 的 push CI，CI 成功后仅在运行引用为 `main` 时规划候选。GitHub 为 [`workflow_run`](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_run) 使用默认分支；默认分支为 `dev` 时，自动入口会跳过，可在 `main` 手动运行候选构建。

候选以版本号最高的已公开发行标签为基准（含 Prerelease），要求该标签在本次提交的历史中。若应用、Xcode 工程、会话 worker、更新助手和随包分发的菜单栏图标均无净改动，跳过候选。若有待发布的应用改动，工作流从该标签到当前提交汇总源 PR，包括经 Merge Commit 合入 `main` 的 `dev` Squash 提交。

按 [PR 模板](../.github/pull_request_template.md)填写发布类型。若本批含 `minor`，升次版本并将补丁位归零。只有 `patch` 时升补丁版本，`none` 不计入。同批只有 `none` 时跳过。缺少中文或英文说明时用 Copilot 补齐。PR 无法关联、缺少发布类型或标为 `manual` 时，日志指出原因并停止自动处理。

对合入前已授权的应用改动，工作流确认同一 `main` 提交的推送 CI 已通过 XCTest、DMG 构建校验和上传，再构建候选。公开 Prerelease 前再次核对当前 `main` 提交、完整 CI、授权和产物校验值。已有 Tag 或 Release 时停止。需要指定版本时仍可手动触发。

| 现象 | 检查项 |
|---|---|
| PR 缺少 CI | 确认 PR 目标、是否有合并冲突、外部贡献者是否等待运行批准，以及 Actions 是否被禁用 |
| PR 检查显示通过但 GitHub 拒绝合并 | 确认合并提示并核对当前拟合入提交的必需检查。PR 检查列表也会显示同一源提交的历史运行 |
| 核对 `main` 合入后的验证范围 | 在 Actions 选择由 `main` 推送触发的 CI 运行，打开运行摘要查看 `CI scope`。值为 `static` 时，`Xcode tests and packaging` 显示为跳过 |
| PR 找不到 DMG | 在 CI 运行摘要查看 `CI scope`。只有 `package` 会打包，并在通过校验后上传 DMG 和 SHA-256 |
| DMG 构建或校验失败 | 在 Build and verify Universal DMG 日志查看最后一个阶段。若 `hdiutil` 命令失败，日志会保留其操作、退出码和诊断输出 |
| Xcode 路径不存在 | 查看运行的 Runner 镜像说明；核实替代版本后同步修改两个工作流，再运行 CI |
| 找不到 Run workflow | 确认 `release.yml` 已合入默认分支，且触发人有仓库写权限 |
| 候选未生成 | 查看 Plan prerelease。自已发布版本起无可发布应用改动时会跳过。应用改动缺少发布类型或 Copilot 补写失败时，修正源 PR 信息后重跑 `main` CI |
| 发布未执行或失败 | 核对发布 PR 的所有者授权记录、源和目标提交。缺少合入前授权时，须走新的发布 PR。手动运行还需勾选 `publish`，且版本与授权一致 |
| 打包完成后发布失败 | 仍可下载原 Artifact。若已创建 Tag 或草稿，先检查状态；工作流不会覆盖或删除既有引用和资产 |

Artifact 和日志受仓库可见性约束；公开仓库的候选和日志不能存放私有资料。详见 GitHub 的[工作流触发规则](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow)和 [Copilot CLI 用法](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli-in-actions)。

## 后续正式发布

将 Developer ID Application 证书及其私钥导出为 `.p12`，在受保护环境中添加证书、密码与 `notarytool` 凭据的 Secrets。配置信任对应的 Team ID 与应用身份；在临时钥匙串里导入证书，启用 Hardened Runtime，先签内嵌组件、再签主应用。重新打包后提交 Apple 公证，用 `stapler` 附加并验证票据，再核对 Gatekeeper、代码签名、两种架构、安装及最终 SHA-256。正式发行还需完成公开审计；应用内更新要求受信发行签名、已锁定的稳定 Release 及通过验证的资产。当前工作流不执行这些步骤。
