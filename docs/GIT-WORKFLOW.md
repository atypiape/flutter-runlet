# Git 工作流与推送安全

本规范适用于影响 Git 分支、暂存区、提交、远端、PR 或发布状态的操作。只读查询无需加载。

本文件是 `.github/` 和 `.githooks/` 中 Git 规则的依据。修改本规范、[GitHub PR 来源检查](../.github/workflows/branch-policy.yml)或[本地推送检查](../.githooks/pre-push)时，核对另外两处，在同一变更中同步受影响的规则与实现，并验证相关的允许及拒绝场景。

## 分支与 PR

- `main` 是 GitHub 默认分支和稳定发布分支，`dev` 是开发集成分支。保护规则缺失时，报告并由仓库管理员补齐。不得以直接 Push 代替 PR 或擅自更改保护规则。
- 日常从 `dev` 创建 `feat/`、`fix/`、`docs/`、`refactor/`、`perf/`、`test/`、`chore/` 工作分支；紧急修复从 `main` 创建 `hotfix/`。`codex/*` 仅限本地。
- 日常改动以 PR 合入 `dev`。创建时在 GitHub 选择 `base: dev`，或使用 `gh pr create --base dev`。`hotfix/* → main` 合入后须通过 PR 同步回 `dev`，可使用原 `hotfix/*` 分支。
- `main` 只接受同仓库的 `dev` 发布 PR，以及从 `main` 创建的 `hotfix/*` 紧急修复 PR。热修复分支须包含当前 `main` 的顶端提交，且不得带入 `dev` 独有的提交。
- 每个 PR 聚焦一项逻辑变更，写明内容与验证结果；Commit 和 PR 标题遵循 Conventional Commits，使用简体中文，scope 可选。沿用已配置的 Git 提交身份，并确认邮箱适合公开。
- Commit 前完成必要本地验证，合并前通过已配置的必需 CI，并解决阻塞项；不得虚报验证结果。
- 合并后删除不再需要的远端工作分支。
- Agent 可自动 Commit、Push 合规工作分支、创建 PR，并在完成代码、安全及必要检查后合入 `dev`；外部贡献 PR 也须审查代码，不能仅凭 CI 通过合并。**合入 `main` 及对应的发布操作须经用户明确授权**，不得自动合并。
- Push 失败时报告原因；不得强推、擅自改写远程历史或绕过保护。发布遵循 [Release 模板](RELEASE-TEMPLATE.md)及[公开前脱敏审计](PUBLIC-RELEASE-AUDIT.md)。

### GitHub Rulesets

- `main` 和 `dev` 均须通过 PR 合并，禁止直接 Push、强推和删除，且无豁免。 [共用保护 Ruleset](https://github.com/atypiape/flutter-runlet/rules/27331981)
- `dev` 要求 GitHub Actions 的 `branch-policy (dev)` 检查通过，仅允许 Squash Merge。 [dev Ruleset](https://github.com/atypiape/flutter-runlet/rules/27350459)
- `main` 要求 GitHub Actions 的 `branch-policy (main)` 检查通过，仅允许 Merge Commit 和 Squash Merge。`dev → main` 使用 Merge Commit，`hotfix/* → main` 使用 Squash Merge。 [main Ruleset](https://github.com/atypiape/flutter-runlet/rules/27350524)
- 两条分支都应将 `macOS build and test` 加入必需检查，来源选择 GitHub Actions，并保留各自的 `branch-policy`。先让测试 PR 出现并通过新检查，再启用必需状态，避免首次部署阻塞。具体操作见 [CI/CD 指南](CI-CD.md#设置分支保护)。
- 开放 PR 仅编辑标题或正文时，必需检查可复用同一拟合入提交的成功结果。若目标分支变化，按新目标重新执行 CI 和分支规则检查。已关闭 PR 的标题和正文编辑跳过检查作业。
- PR 检查验证拟合入结果；合入 `main` 后，CI 再验证实际发布提交。发布 PR 须在合入前按 [Release 流程](RELEASE-TEMPLATE.md)完成脱敏审计，并由仓库所有者合入。发布工作流在合并提交的 CI 和产物校验通过后创建 Tag 和 Prerelease。

## `codex/*` 的安全迁移

- `codex/*` 不得 Push、创建 PR，亦不得直接改名后 Push。不得以普通 Merge、Rebase 或 Cherry-pick 将其原始提交带入远端历史。
- 从已更新且可信的 `dev` 创建干净工作分支，在该分支执行本地 `git merge --squash codex/<分支>`（或等效的无历史迁移）。仅保留授权范围内的最终改动，完成脱敏及差异审查后创建新的 Commit。
- 检查新分支不包含 `codex/*` 的原始提交，复核暂存内容、文件名、附件元数据、提交身份，以及待推送的全部新增提交历史；通过后方可 Push、创建 PR。
- Squash 只隔离原始提交历史，不会自动脱敏最终文件；发现敏感内容、来源不明或冲突无法可靠解决时停止推送并报告。

## Git Hooks 初始化与检查

- 首次 Git 写操作前检查 `core.hooksPath`、现有 Hooks 与 `.githooks/`；若未正确启用，安全整合旧 Hooks，以受版本管理的 `.githooks/` 统一维护；不得覆盖已有行为或重复初始化。
- 自动设置 `git config --local core.hooksPath .githooks`，确保脚本具有可执行权限，并验证配置和 Hook 拦截效果。无法安全整合时报告，不盲目覆盖。
- `pre-push` 逐项检查实际源、目标引用和待推送提交：拒绝本地或远端 `codex/*`、直接 Push `main`/`dev`，并处理 `HEAD`、refspec、标签和来源不明确的形式；无法可靠判断来源时拒绝推送。
- Commit 前检查暂存差异、文件名、提交说明和附件元数据；Push 前检查新增提交历史中的凭据、个人信息、本机路径、内网地址及未公开业务数据。优先复用现有扫描能力；无法完成必要检查时停止推送并说明，不能声称已经扫描。
- Hooks 可被绕过，不能替代 GitHub Rulesets、实际脱敏与人工发布授权；禁止使用 `--no-verify` 等方式绕过检查。
