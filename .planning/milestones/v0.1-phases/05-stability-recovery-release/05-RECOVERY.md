# Phase 05 · 会话退出与恢复验收

| ID | 场景 ID | 判定 | 候选与证据 |
|---|---|---|---|
| A13 | normal-stop | 通过 | `36916dd` · 候选 tracer.json，真实模拟器进程组退出后原后置任务恢复 test。证据 `候选 a13`。 |
| A14 | post-failure-retry | 通过 | `c80ec88` · 后置任务退出 1 后保留 prod 风险，手动重试成功。证据 `running-controls-1794591751764039000`。 |
| A15 | pre-failure-before-write | 通过 | `c80ec88` · dev 前置失败阻断启动，保持 test。证据 `pre-failure-before-write-1794591526112380000`。 |
| A15 | pre-failure-after-write | 通过 | `c80ec88` · prod 写入后失败，重启风险仍在，手动恢复。证据 `pre-failure-after-write-1794591547480692000`。 |
| A15 | launch-failure-after-pre | 通过 | `c80ec88` · 前置成功后真实 Flutter 编译失败，原后置恢复。证据 `launch-failure-after-pre-1794591578245090000`。 |
| A15 | debug-pre-kill | 通过 | `36916dd` · Debug 前置写入 prod 后强退，重启仍有风险，手动恢复。证据 `debug-pre-kill-1794593616957881000`。 |
| A15 | debug-post-kill | 通过 | `36916dd` · Debug 后置已写入 test 时强退，重启仍需重试。证据 `debug-post-kill-1794593619389975000`。 |
| A15 | release-running-kill | 通过 | `36916dd` · 关闭两项启动偏好后运行中强退，重启自动显示恢复入口。证据 `release-running-kill-1794593622118728000`。 |
| A16 | repeat-run | 通过 | `c80ec88` · 启动和运行时重复 Run 仅保留原进程组。证据 `running-controls-1794591751764039000`。 |
| A16 | switch-project | 通过 | `c80ec88` · 活动期拒绝切换项目，原会话持续。证据 `running-controls-1794591751764039000`。 |
| A16 | second-instance | 通过 | `c80ec88` · 同项目的第二实例因租约被拒绝。证据 `running-controls-1794591751764039000`。 |
| A22 | debug-exit | 通过 | `c80ec88` · 真实 iOS 样例进程终止，调试组退出后恢复 test。证据 `debug-exit-1794591926764984000`。 |
| A22 | device-disconnect | 通过 | `c80ec88` · 模拟器关机后不再显示 Running，原后置恢复 test。证据 `device-disconnect-1794592352963563000`。 |
| A28 | quit-cancel | 通过 | `c80ec88` · 取消退出保留原 VM 会话。证据 `running-controls-1794591751764039000`。 |
| A28 | stop-and-quit | 通过 | `c80ec88` · 确认后等待进程退出与恢复完成才退出应用。证据 `stop-and-quit-1794592072232944000`。 |
| A28 | quit-post-failure | 通过 | `c80ec88` · 恢复失败时阻止退出，并提供原任务重试。证据 `running-controls-1794591751764039000`。 |

环境为 macOS 26.7.1、Xcode 27.1、Flutter 3.47.4 和 iOS 27.0 模拟器。私有记录含辅助功能、样例环境、风险及相关进程证据。每次使用独立样例，结束核对配置和脚本摘要。Debug 两个强退场景使用固定验收入口的专用命名空间及本轮独立项目，核对既有记录未被改写。

16 个场景均在 `c80ec88` 通过。当前 `36916dd` 复验 A13 和三个强退边界，恢复与调试协议未随 Unicode 日志修复改变。旧候选的原始记录留在私有目录。
