# FlutterRunlet Release 模板

## 打包与发布

1. 在用户可见改动的源 PR 填写发布类型。中英文说明可留空交给 Copilot 补齐。需要指定版本时，在发布 PR 提交 `docs/releases/vX.Y.Z.md`。
2. 合入前按 [公开前脱敏记录](PUBLIC-RELEASE-AUDIT.md)复核提交、可达历史、PR 公开文案和远端留存。必需检查通过后，由仓库所有者在 GitHub 按 [Git 规范](GIT-WORKFLOW.md#分支与-pr)合入发布 PR。GitHub 的合并记录即为发布授权。
3. 同一 `main` 提交的完整 CI 通过后，`macOS Prerelease` 才能公开发布。PR 新增 `docs/releases/vX.Y.Z.md` 时，从 **Actions → macOS Prerelease → Run workflow** 选 `main`，填写相同版本并勾选 `publish`。自动定版沿用 CI 触发流程，具体触发条件见 [CI/CD 指南](CI-CD.md#运行与排查)。保持 `publish` 未勾选时只打包。
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
