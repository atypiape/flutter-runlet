# FlutterRunlet 开发者指南

## 构建与运行

准备完整的 Git 检出和 Xcode。项目的最低部署目标为 macOS 15.0。打开 [FlutterRunlet.xcodeproj](../FlutterRunlet.xcodeproj)，选择共享的 `FlutterRunlet` scheme 和本机 Mac，按 Command-R 运行。本地复现 CI 时使用 [CI 同款 Xcode](CI-CD.md#自动-ci)。

主应用源码在 [FlutterRunlet](../FlutterRunlet/)，同一 scheme 会构建 [会话 worker](../FlutterRunletSessionWorker/) 和 [更新助手](../FlutterRunletUpdateHelper/)。构建应用本身无需 Flutter SDK；验证真实调试还需可用的 Flutter SDK、测试项目及模拟器或真机。

在仓库根目录运行 `./scripts/build-debug.sh`，构建本机架构的 Debug 版。传入工作树目录即可构建该处检出的代码，例如 `./scripts/build-debug.sh ../flutter-runlet-fix`。

脚本将产物写到目标工作树的 `.build/debug/Build/Products/Debug/FlutterRunlet.app`，并将绝对路径输出到标准输出。加 `--open` 可在构建成功后打开应用。重测前先退出正在运行的 FlutterRunlet。

### 在 VS Code 中构建、启动和停止

用 VS Code 打开仓库根目录，在「运行和调试」侧栏顶部选择操作，再点击左侧的绿色 ▶。仅需上文的 Xcode 环境，无需安装扩展。

- 「FlutterRunlet: 构建并启动」构建并打开应用。应用运行期间，可点击 VS Code 工具栏的红色停止按钮退出应用。
- 「FlutterRunlet: 仅构建」构建 Debug 版。也可按 `⇧⌘B` 运行默认构建任务。

如果 Flutter 会话仍在运行，在 FlutterRunlet 中确认停止并退出。

## 测试与本地取证

在仓库根目录运行 XCTest（同时构建 Debug 应用）：

```sh
xcodebuild -project FlutterRunlet.xcodeproj -scheme FlutterRunlet \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath .build/dev -parallel-testing-enabled NO test
```

用[隔离 Flutter 示例](examples/sample-flutter-app/README.md)验证真实设备、前后置任务及异常恢复。历史结果见[阶段 06 验收](../.planning/milestones/v0.2-phases/06-main-window-menu-bar/06-VERIFICATION.md)和[阶段 07 验收](../.planning/milestones/v0.2-phases/07-settings-about-updates/07-VERIFICATION.md)。复验时重新构建候选并采集当轮证据。

把可重建的编译缓存和试打包产物放在 `.build/`，把原始验收截图、日志、测试结果包和与签核摘要绑定的候选留在 `.private/`，只提交脱敏结论。清理时保留签核引用的原始证据及候选；重新构建的二进制不能替代锁定摘要的原件。

更新用户文档时，同步维护[英文首页](../README.md)和[简体中文说明](../README.zh-CN.md)。各语言的 [README 截图](screenshots/)按[公开文档与截图约定](../AGENTS.md#公开文档与截图)完成脱敏、压缩与核验。

## 手动处理 Issue

「任务或问题」表单只要求填写标题和「问题与预期」。「补充信息」可填写复现步骤、截图、验证方法或改动边界。有前置任务时，用 GitHub 的阻塞关系标记，或在正文 `### 前置 Issue` 标题下列出本仓库 Issue 编号，例如 `- #123`。[任务或问题表单](../.github/ISSUE_TEMPLATE/codex-task.yml)

1. 普通 Issue 和表单提交的 Issue 都由维护者添加 `task:ready` 批准领取。贴标后若修改标题或正文，请移除后重新添加该标签。队列空闲时，Agent 复核批准、规格、标签及前置依赖，将候选 Issue 切换为 `task:working`。
2. 从最新 `origin/dev` 创建独立 worktree。用包含 Issue 编号的合规分支名，例如 `docs/issue-123-pr-resume`。重跑时先用 `git worktree list` 找到原目录，继续使用原分支。
3. 在该 worktree 排查问题、实现改动并做可用的验证。缺少复现信息或设备时，先完成可独立推进的工作，再记录实际阻塞和需要协助的事项。按 Git 工作流检查差异、提交和推送。PR 写明验收结果，并在正文单独一行引用 Issue，例如 `Refs #123`。[Git 工作流](GIT-WORKFLOW.md)

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

同一轮可以处理多条 Issue。队列默认按编号升序，领取前检查明确的前置依赖。依赖未完成时，优先领取符合条件的前置 Issue，支持多级依赖。前置 Issue 尚未获准领取时，被阻塞的 Issue 保留 `task:ready`，队列继续检查其他可领取项。

独立子任务在专属 worktree 开发、验证并开 PR。独立审查和当前拟合入提交的必需 CI 通过后，定时任务自动 Squash 合入 `dev`，关单并清理任务标签。本地 `dev` 快进到最新 `origin/dev` 后，重新查询并领取下一条。当前任务未完成合并和收尾时，保留记录以便恢复，暂缓领取。

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

开发子任务交付 PR 后，单独复查 Issue 验收项和 PR 差异。从可信的控制检出目录调用[合并脚本](../scripts/merge-issue-pr.py)，把通过的审查存到 `.private/issue-loop/reviews/<Issue 编号>.json`。

```sh
python3 -B scripts/merge-issue-pr.py --record-review "$REVIEW_FILE" \
  --issue "$ISSUE_NUMBER" --pr "$PR_NUMBER" --author "$PR_AUTHOR_ID" \
  --approval-event "$APPROVAL_EVENT_ID" --spec "$SPEC_SHA256" \
  --head "$PR_HEAD" --base "$DEV_SHA" --test-merge "$TEST_MERGE_SHA" \
  --summary '已核对预期结果，附验证证据'
```

批准事件和规格摘要来自领取结果。提交 SHA 来自本轮审查的 GitHub 快照。定时任务从记录运行 `python3 -B scripts/merge-issue-pr.py --review-file "$REVIEW_FILE" --require-strict`。合并时沿用同一记录并加 `--apply`。脚本会重新核对批准、规格、提交和必需 CI。规格、批准或提交变化后重新复审并保存记录。

### 清理已合入的本地分支

从仓库运行 [分支清理脚本](../scripts/cleanup-merged-branches.py)。它先刷新 `origin/dev`，再预览可清理的本地分支及其 worktree。加 `--apply` 后先移除关联的 worktree，再删除分支。被 Git 忽略的构建产物会随 worktree 移除。Git 拒绝移除有未提交改动、未忽略的未跟踪文件或被锁定的 worktree 时，脚本保留对应分支并报告原因。

```sh
python3 -B scripts/cleanup-merged-branches.py
python3 -B scripts/cleanup-merged-branches.py --apply
```

脚本接受两种证据。分支当前提交已在 `origin/dev` 历史中，或同仓库的 `dev` PR 合入了该分支的当前提交，且合并提交已在 `origin/dev` 历史中。后者覆盖 Squash 合并。脚本保留运行命令时所在的分支、`main`、`dev` 和本地 `codex/*`。

定时任务关单后用 `--apply --branch <任务分支>` 一并清理任务分支及其 worktree。没有进行中的任务时，定时任务也会扫描并清理其他已合入的本地分支。

## 打包与发布

目标为 `dev` 或 `main` 的 PR 会自动执行 [CI](CI-CD.md)，执行完整验证时会上传通过校验的 Universal DMG 供检查。在本地可运行 `./scripts/package-release.sh vX.Y.Z` 构建同类候选。用 [Release 模板](RELEASE-TEMPLATE.md)准备版本说明、完成脱敏验收并授权公开发布。

## 项目文档

- [产品需求](01-PRODUCT.md) · [配置与运行技术契约](02-TECHNICAL.md) · [验收矩阵](04-ACCEPTANCE.md)
- [界面规格](design/UI-SPEC.md) · [设计系统](design/DESIGN-SYSTEM.md)
- [开发路线图](../.planning/ROADMAP.md) · [里程碑归档](../.planning/MILESTONES.md) · [协作约定](../AGENTS.md)
