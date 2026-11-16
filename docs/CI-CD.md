# FlutterRunlet CI/CD

## 自动 CI

[CI](../.github/workflows/ci.yml) 在目标为 `dev` 或 `main` 的 PR 上测试拟合入结果；`main` 更新后重测实际提交。工作流检查 Git 差异、工程与权限配置文件、Shell 语法，构建 Debug 并运行 XCTest，再通过 [打包脚本](../scripts/package-release.sh)构建和校验 Release Universal DMG。在 Actions 运行详情下载 DMG 和 SHA-256；PR 产物只供检查，与 GitHub Releases 无关。

工作流使用 [`xcode-27` Apple Silicon 镜像](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md)内置的 Xcode 27.1（Runner 镜像处于公开预览），通过 `DEVELOPER_DIR` 选择工具链；Xcode 26.6 在编译项目时发生 Swift 编译器崩溃。源码编译与 XCTest 不依赖 Flutter SDK；需要真实 Flutter 环境的验证仍按[开发者指南](DEVELOPMENT.md)手工执行。Xcode 无需下载，构建无外部依赖；XCTest 一次完成 Debug 编译和测试，Release 由打包脚本单独构建，不跨运行缓存 DerivedData。

## 设置分支保护

1. 在仓库 **Settings → Actions → General** 确认 Actions 已启用、默认 Workflow permissions 为 **Read repository contents and packages**，且未允许 Actions 创建或批准 PR。各作业另外声明所需权限，只有发布作业拥有 `contents: write`。
2. 先让测试 PR 运行并通过 `macOS build and test`；对尚未出现此检查的仓库，不要提前设为必需。
3. 在 **Settings → Rules → Rulesets** 分别编辑 `dev` 和 `main` 的 Ruleset，在 **Require status checks to pass** 中添加 `macOS build and test`，集成来源选择 **GitHub Actions**。保留相应分支的 `branch-policy (...)`，以及 [Git 规范](GIT-WORKFLOW.md#github-rulesets)规定的保护与合并方式。

## 设置发布环境

在 **Settings → Environments** 创建或编辑 `release`：

- **Required reviewers** 指定有权代表用户批准发布的账号或团队。只有一位维护者时允许其发起和批准同一运行；有独立评审人时可开启 **Prevent self-review**。关闭管理员绕过。
- **Deployment branches and tags → Selected branches and tags**，仅添加类型为 **Branch** 的 `main`，不添加标签。
- 预发布只用当前运行的 `GITHUB_TOKEN`，无需 PAT、Apple 证书或额外 Secrets。发布作业还会检查 GitHub API 的实际部署审批记录；环境未配置评审，或只有跳过保护的操作，不能代替带摘要的批准。

## 运行与排查

[macOS Prerelease](../.github/workflows/release.yml) 在同仓库 `main` 的 push CI 成功后运行。它以版本号最高的已公开发行标签为基准（含 Prerelease），要求该标签在本次提交的历史中。若应用、Xcode 工程、会话 worker 和更新助手均无净改动，跳过候选。若有待发布的应用改动，工作流从该标签到当前提交汇总源 PR，包括经 Merge Commit 合入 `main` 的 `dev` Squash 提交。

按 [PR 模板](../.github/pull_request_template.md)填写发布类型。若本批含 `minor`，升次版本并将补丁位归零。只有 `patch` 时升补丁版本，`none` 不计入。同批只有 `none` 时跳过。应用改动无法关联 PR、缺少必填说明或标为 `manual` 时，停止自动打包，在运行日志中指出原因。

工作流上传双语说明和经过验证的 DMG，等待 `release` 环境批准后才创建 Tag 和 Prerelease。按 [Release 模板](RELEASE-TEMPLATE.md)审计本次产物。需要指定版本时仍可手动触发。发布脚本复核当前 `main` 的提交、CI、批准摘要和资产，并拒绝已有 Tag 或 Release。

| 现象 | 检查项 |
|---|---|
| PR 缺少 CI | 确认 PR 目标、是否有合并冲突、外部贡献者是否等待运行批准，以及 Actions 是否被禁用 |
| Xcode 路径不存在 | 查看运行的 Runner 镜像说明；核实替代版本后同步修改两个工作流，再运行 CI |
| 找不到 Run workflow | 确认 `release.yml` 已合入默认分支，且触发人有仓库写权限 |
| 候选未生成 | 查看 Plan prerelease。仅 CI 或文档改动时会跳过。应用改动缺少发布信息时更新对应 PR，再重新运行 `main` CI |
| 发布未执行或失败 | 使用新运行并核对批准文本。手动运行时确认已勾选 `publish`。如需重建同一提交，可先取消旧的待审批运行，再重跑 `main` CI |
| 打包完成后发布失败 | 仍可下载原 Artifact。若已创建 Tag 或草稿，先检查状态；工作流不会覆盖或删除既有引用和资产 |

Artifact 和日志受仓库可见性约束；公开仓库的候选和日志不能存放私有资料。详见 GitHub 的[工作流触发规则](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow)和[部署环境配置](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments)。

## 后续正式发布

将 Developer ID Application 证书及其私钥导出为 `.p12`，在受保护环境中添加证书、密码与 `notarytool` 凭据的 Secrets。配置信任对应的 Team ID 与应用身份；在临时钥匙串里导入证书，启用 Hardened Runtime，先签内嵌组件、再签主应用。重新打包后提交 Apple 公证，用 `stapler` 附加并验证票据，再核对 Gatekeeper、代码签名、两种架构、安装及最终 SHA-256。正式发行还需完成公开审计；应用内更新要求受信发行签名、已锁定的稳定 Release 及通过验证的资产。当前工作流不执行这些步骤。
