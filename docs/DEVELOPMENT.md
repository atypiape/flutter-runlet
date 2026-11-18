# FlutterRunlet 开发者指南

## 构建与运行

准备完整的 Git 检出和 Xcode。项目的最低部署目标为 macOS 15.0。打开 [FlutterRunlet.xcodeproj](../FlutterRunlet.xcodeproj)，选择共享的 `FlutterRunlet` scheme 和本机 Mac，按 Command-R 运行。本地复现 CI 时使用 [CI 同款 Xcode](CI-CD.md#自动-ci)。

主应用源码在 [FlutterRunlet](../FlutterRunlet/)，同一 scheme 会构建 [会话 worker](../FlutterRunletSessionWorker/) 和 [更新助手](../FlutterRunletUpdateHelper/)。构建应用本身无需 Flutter SDK；验证真实调试还需可用的 Flutter SDK、测试项目及模拟器或真机。

## 测试与本地取证

在仓库根目录运行 XCTest（同时构建 Debug 应用）：

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath .build/dev -parallel-testing-enabled NO test
```

用[隔离 Flutter 示例](examples/sample-flutter-app/README.md)验证真实设备、前后置任务及异常恢复。更新和界面验收的前置条件、私有清单及复跑方法见[阶段 07 验证方案](../.planning/milestones/v0.2-phases/07-settings-about-updates/07-VALIDATION.md)；最终结果见[阶段 06 验收](../.planning/milestones/v0.2-phases/06-main-window-menu-bar/06-ACCEPTANCE.md)和[阶段 07 验收](../.planning/milestones/v0.2-phases/07-settings-about-updates/07-ACCEPTANCE.md)。

把可重建的编译缓存和试打包产物放在 `.build/`，把原始验收截图、日志、测试结果包和与签核摘要绑定的候选留在 `.private/`，只提交脱敏结论。清理时保留签核引用的原始证据及候选；重新构建的二进制不能替代锁定摘要的原件。

更新用户文档时，同步维护[英文首页](../README.md)和[简体中文说明](../README.zh-CN.md)。各语言的 [README 截图](screenshots/)按[公开文档与截图约定](../AGENTS.md#公开文档与截图)完成脱敏、压缩与核验。

## 手动处理 Issue

1. 维护者添加 `task:ready` 后，Agent 在队列空闲时复核批准、规格和标签，将候选 Issue 切换为 `task:working`。表单是推荐格式。[Codex 开发任务表单](../.github/ISSUE_TEMPLATE/codex-task.yml)
2. 从最新 `origin/dev` 创建独立 worktree。用包含 Issue 编号的合规分支名，例如 `docs/issue-123-pr-resume`。重跑时先用 `git worktree list` 找到原目录，继续使用原分支。
3. 领取后核对前置依赖，在该 worktree 排查问题、实现改动并做可用的验证。缺少复现信息或设备时，先完成可独立推进的工作，再记录实际阻塞和需要协助的事项。按 Git 工作流检查差异、提交和推送。PR 写明验收结果，并在正文单独一行引用 Issue，例如 `Refs #123`。[Git 工作流](GIT-WORKFLOW.md)

创建 PR 前按来源仓库和分支查找历史 PR。将下例的分支名换成任务分支。查询包含已关闭的 PR，也能发现被改投其他分支的 PR。

```sh
repo=atypiape/flutter-runlet
branch=docs/issue-123-pr-resume
gh api --method GET --paginate --slurp "repos/$repo/pulls" \
  -f state=all -f "head=${repo%/*}:$branch" -F per_page=100
```

只有查询成功且没有匹配项时，才创建目标为 `dev` 的 PR。若已有唯一开放的 PR，确认来源仓库、目标分支和 Issue 引用后复用。查询失败、匹配不唯一、PR 已关闭或目标不符时，先人工核对。

确认 PR 已创建或已找到后，将 Issue 切换为 `task:review`。如果在创建 PR 后、切换标签前中断，先重跑上述查询，再复用原 PR 并补齐标签。

## 定时处理 Issue

定时任务用 [队列核验脚本](../scripts/verify-issue-queue.py)的 `--preflight` 核对 origin、当前 `gh` 身份和四个 `task:*` 标签，再查询队列。推送前在任务 worktree 运行同一脚本的 `--check-push-hook`。检查通过后再推送。

误删标签时，先暂停定时任务，运行 [补建脚本](../scripts/create-github-labels.sh)，再核对并恢复受影响的 Issue 标签。需要重新添加 `task:ready` 时，由维护者复核后贴标。确认任务状态后恢复定时任务。

```sh
bash scripts/create-github-labels.sh --repo atypiape/flutter-runlet
```

新建迁移目标仓库时，将 `--repo` 改为目标仓库全名。脚本只创建缺失的标签定义。迁移流程时另行核对定时任务的仓库目标、批准账号和 `dev` 合并门槛。

在已推送的任务 worktree 内运行 [PR 创建与恢复脚本](../scripts/ensure-issue-pr.py)。使用领取时记录的 `spec_sha256`。

```sh
python3 -B "$RUNLET_ROOT/scripts/ensure-issue-pr.py" \
  --issue "$ISSUE_NUMBER" --spec "$SPEC_SHA256" \
  --title 'docs: 更新开发说明' --body-file "$PR_BODY_FILE"
```

`RUNLET_ROOT` 指向可信的 FlutterRunlet 控制检出目录。定时任务在首次推送前，把标题保存在 `.private/issue-loop/tasks/<Issue 编号>.json`，正文保存在同目录的 `<Issue 编号>-pr.md`。推送后可从这两处恢复开 PR。已有 PR 时可省略标题和正文。

脚本按来源分支查询所有历史 PR。只有查询成功且没有匹配项时才创建 `dev` PR。找到唯一匹配的开放 PR 时复用原编号。确认 PR 后切换为 `task:review`。在开 PR 或切换标签时中断，可用同一参数重跑。匹配不唯一、PR 已关闭或目标不符时，先人工核对。

### 保存独立审查

另起一轮复查 Issue 验收项和 PR 差异。从可信的控制检出目录调用[合并脚本](../scripts/merge-issue-pr.py)，把通过的审查存到 `.private/issue-loop/reviews/<Issue 编号>.json`。

```sh
python3 -B scripts/merge-issue-pr.py --record-review "$REVIEW_FILE" \
  --issue "$ISSUE_NUMBER" --pr "$PR_NUMBER" --author "$PR_AUTHOR_ID" \
  --approval-event "$APPROVAL_EVENT_ID" --spec "$SPEC_SHA256" \
  --head "$PR_HEAD" --base "$DEV_SHA" --test-merge "$TEST_MERGE_SHA" \
  --summary 'O1：通过，附验收证据'
```

批准事件和规格摘要来自领取结果。提交 SHA 来自本轮审查的 GitHub 快照。定时任务从记录运行 `python3 -B scripts/merge-issue-pr.py --review-file "$REVIEW_FILE" --require-strict`。合并时沿用同一记录并加 `--apply`。脚本会重新核对批准、规格、提交和必需 CI。规格、批准或提交变化后重新复审并保存记录。

### 清理已合入的本地分支

从仓库运行 [分支清理脚本](../scripts/cleanup-merged-branches.py)。它先刷新 `origin/dev`，再核对本地分支。预览后可加 `--apply` 删除通过核验的分支。

```sh
python3 -B scripts/cleanup-merged-branches.py
python3 -B scripts/cleanup-merged-branches.py --apply
```

脚本接受两种证据。分支当前提交已在 `origin/dev` 历史中，或同仓库的 `dev` PR 合入了该分支的当前提交，且合并提交已在 `origin/dev` 历史中。后者覆盖 Squash 合并。`checked-out` 表示分支已合入但仍被 worktree 使用。`main`、`dev` 和本地 `codex/*` 是保留分支。

定时任务在关单并移除干净的任务 worktree 后，用 `--apply --branch <任务分支>` 清理该任务的本地分支。

## 打包与发布

目标为 `dev` 或 `main` 的 PR 会自动执行 [CI](CI-CD.md)，执行完整验证时会上传通过校验的 Universal DMG 供检查。在本地可运行 `./scripts/package-release.sh vX.Y.Z` 构建同类候选。用 [Release 模板](RELEASE-TEMPLATE.md)准备版本说明、完成脱敏验收并授权公开发布。

## 项目文档

- [产品需求](01-PRODUCT.md) · [配置与运行技术契约](02-TECHNICAL.md) · [验收矩阵](04-ACCEPTANCE.md)
- [界面规格](design/UI-SPEC.md) · [设计系统](design/DESIGN-SYSTEM.md)
- [开发路线图](../.planning/ROADMAP.md) · [里程碑归档](../.planning/MILESTONES.md) · [协作约定](../AGENTS.md)
