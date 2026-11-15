---
phase: "07"
slug: settings-about-updates
status: verified
threats_open: 0
asvs_level: 1
created: "2026-11-15"
---

# 阶段 07 安全复核

## 信任边界

| 边界 | 验证范围 |
| --- | --- |
| Figma 和本机证据 | 原图身份、派生依据、候选签核、脱敏及版本控制边界 |
| GitHub 和应用 | 匿名正式发布、固定来源、资产上限、重定向、冻结发行状态与签名 |
| 更新助手和安装目录 | 签名实物、同卷原子交换、受限试运行、退出证明和回退 |
| 多实例和受管活动 | 恢复库、项目租约、Doctor、会话进程和旧版运行状态 |

## 威胁登记

| ID | STRIDE | 范围 | 严重度 | 处置 | 验证 | 状态 |
| --- | --- | --- | --- | --- | --- | --- |
| T-07-01 | Tampering | Figma 源节点、浅色变量及英文派生 | medium | mitigate | [Figma 取证](07-FIGMA-EVIDENCE.md)保留节点、导出与参考类型，视觉验证器校验原始导出索引和逐例引用 | closed |
| T-07-02 | Information Disclosure | 私有 Figma 原图与本机信息 | medium | mitigate | 原图和清单留在忽略目录，提交只包含脱敏节点引用；本阶段 Git 提交范围核对 | closed |
| T-07-03 | Tampering | 演示和隔离安装入口 | high | mitigate | 普通 Release 去掉 DEBUG 视觉入口和 PHASE07_UPDATE 配置，普通两入口实际拒绝测试参数并保留真实来源 | closed |
| T-07-04 | Tampering | 设置与生产行为 | medium | mitigate | 原生同窗、实际语言与登录偏好、SDK 和恢复由宿主测试与同候选实测覆盖 | closed |
| T-07-05 | Spoofing | 冒用视觉签核 | high | mitigate | 视觉验收核查唯一判定、提交祖先、产物、索引和工作区、受保护源码精确摘要及 512 条实物。自测包含提交、产物和签核篡改 | closed |
| T-07-06 | Tampering | 修图、串用和错误派生 | high | mitigate | [验证器](../../../../scripts/verify-phase-07-visual-gate.rb)核对原生元数据、不同采集事件、参考类型和原图摘要。接线后的 88 对有单独复核 | closed |
| T-07-07 | Spoofing | Release、资产、跳转与 404 辨认 | high | mitigate | 固定匿名来源，数字版本、正式状态与 404 交叉验证；受控 HTTP 拒绝错误 host、ID 和矛盾结果 | closed |
| T-07-08 | Tampering | DMG、摘要、发行身份 | critical | mitigate | 发布不可变、固定签名要求、双架构及嵌套助手验证。拒绝换包换摘要、wrong signer、缺助手和版本不符。正式 Team ID 未配置时安全拒绝安装 | closed |
| T-07-09 | Denial of Service | 网络、限量与挂载 | high | mitigate | 有界 HTTPS 下载、限量和跳转策略。当前用户私有目录，只读挂载、实际挂载归属核对、取消和清理负例 | closed |
| T-07-10 | Tampering | 交换目标、目录和安装对象 | critical | mitigate | 文件描述符锚定目录、复验设备/inode 和签名、APFS 原子交换。目录被替换和保留物被移动时保留实物且报告失败 | closed |
| T-07-11 | Elevation of Privilege | 跨实例活动及退出交接 | critical | mitigate | 共享活动租约传至 worker、旧启动/项目锁和同产品进程核对、助手启动前与磁盘操作前再核对。真实旧版/孤立 worker/跨项目竞态 | closed |
| T-07-12 | Spoofing | A 已退出和 B 健康应答 | critical | mitigate | 命名空间、套接字 peer UID/PID、进程启动时间、签名和带界限的双向握手。真实超时、错误应答、提交前退出 | closed |
| T-07-13 | Tampering | 中断、回退和过早副作用 | high | mitigate | 最小试运行、持久事务及实物复验。交换前、交换后、提交后强制中断并真实重入，切换前旧版保留 | closed |
| T-07-14 | Denial of Service | 恢复后无旧 App 窗口 | high | mitigate | 独立原生助手等待最多 30 秒，并实测中英文恢复位置、访达和发布页；未确认时独立显示保留状态 | closed |
| T-07-15 | Spoofing | 普通候选与隔离候选的证据漂移 | high | mitigate | 最终常规构建锁源和签名、逐组合现场窗口身份，A/B 相同源码另行记录和重放 | closed |
| T-07-16 | Information Disclosure | 运行日志及发布凭据进入共享验收 | high | mitigate | 私有原图、样例、VM 地址、签发和真实日志不入 Git。复核阶段新增和待推送范围 | closed |

## 安全复核记录

| 日期 | 威胁总数 | 已关闭 | 开放 | 参考 |
| --- | ---: | ---: | ---: | --- |
| 2026-11-15 | 16 | 16 | 0 | [视觉签核](07-VISUAL-GATE.md)、[正式查询](07-04-SUMMARY.md)、[更新证据](07-UPDATE-EVIDENCE.md)、[最终验收](07-ACCEPTANCE.md) |

## 签核

- [x] 规划阶段的 16 条威胁均有实际控制或验证记录。
- [x] 关闭判定对应已执行的宿主测试及原生验证。
- [x] 高及以上未处置威胁为 0。
- [x] 无新增接受风险。当前未配置公开发行信任时保持安全拒绝。

最终回归覆盖助手迟到写待定记录、写入后目录同步失败、放行前后中断、连续提交中断、进程标记跨启动过期、错误验收清单及静止按钮的负例。实际校验和处置见[审阅处置](07-REVIEW-DISPOSITION.md)。
