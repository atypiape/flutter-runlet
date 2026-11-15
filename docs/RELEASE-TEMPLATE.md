# FlutterRunlet Release 模板

## 打包与发布

1. 从完整 Git 检出中选定已合入 `main` 的发布提交，确认工作区干净。浅克隆先运行 `git fetch --unshallow`。按本轮改动完成[测试](DEVELOPMENT.md#测试与本地取证)，并按[公开发布脱敏记录](PUBLIC-RELEASE-AUDIT.md)复核发布内容。更新说明以相对上一发布版本的实际改动为准。
2. 将下方的版本标签替换为本次的实际版本，在仓库根目录执行。

   ```sh
   release_tag=vX.Y.Z
   git rev-parse HEAD
   git rev-list --count HEAD
   ./scripts/package-release.sh "$release_tag"
   ```

   记录源码提交和构建号。脚本在 `.build/release/` 的独立目录输出 `FlutterRunlet-vX.Y.Z-macOS-universal.dmg` 及同名 `.sha256` 文件，并核对主程序、会话 worker 和更新助手的双架构、签名和构建机路径。
3. 切到脚本打印的产物目录，复验摘要，并使用该 DMG 验证安装、启动及版本信息。

   ```sh
   shasum -a 256 -c "FlutterRunlet-${release_tag}-macOS-universal.dmg.sha256"
   ```

4. 创建 GitHub Release 草稿，标题用 `FlutterRunlet vX.Y.Z`，标签指向刚才构建的提交。填写下方的中英文说明，复核文字与文件名的脱敏，上传 DMG 和 SHA-256 文件。当前脚本生成临时签名的包，发布时标为预发布，并说明未经 Apple 公证、需手动安装。正式发行和应用内更新需使用受信发行签名、完成公证并校验 Release 元数据与资产。
5. 发布后核对标签指向和两个下载项，从发布页下载并复验 SHA-256。在[版本说明](RELEASE-NOTES.md)记录该版本和下载链接。

## GitHub 更新说明

中英文各保留 2 至 4 条同义条目，优先写用户可见的变化。安装段落填写实际验证的兼容性和签名状态。发布前替换所有占位符。

```markdown
## 简体中文

- <新增或改进的功能及用户如何使用>
- <修复的可见问题及恢复的行为>

<最低 macOS 版本、支持的架构及适用的安装方式。请用配套 SHA-256 文件校验下载。>

## English

- <New or improved feature and how to use it>
- <User-visible fix and the behavior it restores>

<Minimum macOS version, supported architectures, and installation method. Verify the download using the accompanying SHA-256 file.>
```
