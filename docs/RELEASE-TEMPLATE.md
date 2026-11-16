# FlutterRunlet Release 模板

## 打包与发布

1. 在用户可见改动的源 PR 填写发布类型。中英文说明可留空交给 Copilot 补齐。需要指定版本时，在发布 PR 提交 `docs/releases/vX.Y.Z.md`。
2. 合入 `main` 前，按 [公开前脱敏记录](PUBLIC-RELEASE-AUDIT.md)复核提交、可达历史、PR 公开文案、远端留存及 Figma 共享范围。审计通过后，仓库所有者在目标为 `main` 的 PR 留下独立一行评论：

   ```text
   release-approved <PR 源分支完整 SHA> <当前 main 完整 SHA> auto
   ```

   在 GitHub PR 中核对最新提交，也可运行 `git fetch origin` 后用 `git rev-parse origin/dev origin/main` 获取两个 SHA。热修复时把 `origin/dev` 改为对应的 `origin/hotfix/...`。指定版本时将 `auto` 换成具体的 `vX.Y.Z`。任一提交变化后，复核变化并重新授权。
3. 按 [Git 规范](GIT-WORKFLOW.md#分支与-pr)授权并合入 `main`。同一提交的 CI 通过后，`macOS Prerelease` 自动计算版本、打包、校验并公开。在 Actions 下载说明和产物。如授权了具体版本，从 **Actions → macOS Prerelease → Run workflow** 选 `main`、填入授权版本并勾选 `publish`。保持未勾选时只打包。
4. 发布后核对标签指向和两个下载项。下载到同一目录后运行 `shasum -a 256 -c FlutterRunlet-vX.Y.Z-macOS-universal.dmg.sha256`，并在 [版本说明](RELEASE-NOTES.md)记录版本和下载链接。预发布使用临时签名，未经 Apple 公证，需手动安装。

## GitHub 更新说明

手动指定版本的说明可用下方模板，中英文对应并优先写用户可见的变化。发布流程会附上架构、最低部署目标、校验和签名状态；如需说明实际验证过的系统，补在对应语言的段落中。发布前替换所有占位符。

```markdown
## 简体中文

- <新增或改进的功能及用户如何使用>
- <修复的可见问题及恢复的行为>

## English

- <New or improved feature and how to use it>
- <User-visible fix and the behavior it restores>
```
