# FlutterRunlet Release 模板

## 打包与发布

1. 在用户可见改动的源 PR 填写发布类型和中英文说明。经用户授权合入 `main` 后，等 CI 通过。`macOS Prerelease` 会自动计算版本并上传说明和 DMG。按 [公开前脱敏记录](PUBLIC-RELEASE-AUDIT.md)复核拟发布提交、可达历史、远端留存及 Figma 共享范围。
2. 需要人工指定版本时，在发布 PR 提交 `docs/releases/vX.Y.Z.md`，按下方模板填写。合入并通过 CI 后，从 **Actions → macOS Prerelease → Run workflow** 选 `main`，填未使用的版本号。勾选 `publish` 可请求审批，保持未勾选时仅打包。也可从完整 Git 检出运行 `./scripts/package-release.sh vX.Y.Z` 进行本地验证。
3. 从本次运行下载更新说明、DMG 和同名 `.sha256`，记录版本、提交、运行链接和摘要。在 DMG 所在目录执行 `shasum -a 256 -c FlutterRunlet-vX.Y.Z-macOS-universal.dmg.sha256`，并复核包内容、安装、启动和版本。打包脚本验证主程序、会话 worker 和更新助手的双架构、临时签名和构建机路径。
4. 用户确认脱敏审计、说明和产物后，在运行详情选择 **Review deployments → release**。在评论中填入 `audit-approved vX.Y.Z <SHA-256>`，替换为本次实际值，再点 **Approve and deploy**。批准包含创建此 Tag 与公开 Prerelease 的授权。审计未通过时保留候选并拒绝发布。
5. 自动发布成功后，核对标签指向和两个下载项，从发布页下载并复验 SHA-256。在 [版本说明](RELEASE-NOTES.md)记录该版本和下载链接。当前预发布包为临时签名、未经 Apple 公证，需手动安装。

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
