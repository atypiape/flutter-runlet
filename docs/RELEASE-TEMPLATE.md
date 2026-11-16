# FlutterRunlet Release 模板

## 打包与发布

1. 在发布 PR 中提交 `docs/releases/vX.Y.Z.md`，按下方模板写入相对上一版本的中英文变更说明。经用户授权合入 `main` 后，等待实际提交的 CI 通过。使用 [公开前脱敏记录](PUBLIC-RELEASE-AUDIT.md)复核拟发布提交、可达历史、远端留存及 Figma 共享范围；未签核时保留候选，不公开发布。
2. 在 **Actions → macOS Prerelease → Run workflow** 选 `main`，填未使用的 `vX.Y.Z`。只打包时保持 `publish` 未勾选；准备审核这一次运行的产物时勾选。也可从完整、干净的 Git 检出运行 `./scripts/package-release.sh vX.Y.Z` 进行本地验证；浅克隆先运行 `git fetch --unshallow`。
3. 从本次运行下载 DMG 和同名 `.sha256`，记录版本、提交、运行链接和摘要。在产物目录执行 `shasum -a 256 -c FlutterRunlet-vX.Y.Z-macOS-universal.dmg.sha256`，并复核包内容、安装、启动和版本。脚本已挂载 DMG，检查主程序、会话 worker 和更新助手的双架构、临时签名和构建机路径；实机兼容性按实际测试记录。
4. 用户确认脱敏审计和本次产物后，由 [`release` 环境的审核人](CI-CD.md#设置发布环境)在运行详情选择 **Review deployments → release**。在评论中填入 `audit-approved vX.Y.Z <SHA-256>`，把版本和摘要替换为实际值，然后点 **Approve and deploy**。批准包含创建此 Tag 与公开 Prerelease 的授权；不要批准未通过审计或摘要不一致的产物。
5. 自动发布成功后，核对标签指向和两个下载项，从发布页下载并复验 SHA-256。在 [版本说明](RELEASE-NOTES.md)记录该版本和下载链接。当前预发布包为临时签名、未经 Apple 公证，需手动安装。

## GitHub 更新说明

中英文各保留 2 至 4 条同义条目，优先写用户可见的变化。发布流程会附上架构、最低部署目标、校验和签名状态；如需说明实际验证过的系统，补在对应语言的段落中。发布前替换所有占位符。

```markdown
## 简体中文

- <新增或改进的功能及用户如何使用>
- <修复的可见问题及恢复的行为>

## English

- <New or improved feature and how to use it>
- <User-visible fix and the behavior it restores>
```
