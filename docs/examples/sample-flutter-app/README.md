# sample-flutter-app · VS Code 兼容示例

这些示例用于复现 [配置与任务契约](../../02-TECHNICAL.md)及[验收矩阵](../../04-ACCEPTANCE.md)中的启动、退出与恢复流程。脚本用本地 `.runlet-fixture/firebase-environment` 文件模拟 Firebase 环境切换，无需 Firebase 项目、SDK、凭据或网络。

1. 创建一个独立的 Flutter 测试项目。在测试项目内，将 [launch.jsonc](launch.jsonc) 和 [tasks.jsonc](tasks.jsonc) 分别复制为 `.vscode/launch.json` 和 `.vscode/tasks.json`，将[示例脚本](scripts/simulate-firebase-switch.sh)复制到 `scripts/`。由 `/bin/sh` 调用脚本，项目目录可含空格。
2. 选择 dev、test 或 prod，核对调试启动前的任务顺序、Dart Define 的值与顺序及实际设备选择。dev、physical、prod 覆盖旧 `args`，test 覆盖 `toolArgs`。physical 与 dev 参数相同，设备仍由用户选择。prod 额外覆盖 `osx.env.PATH` 的继承。
3. 正常停止 prod，等 Flutter 进程退出后，核对 `sample:select-test` 执行成功、标记变为 `test`，且风险记录清除。
4. 用下表中的故障标记复现失败。标记是测试项目内 `.runlet-fixture/` 下的空文件。每种场景从已知的 test 状态开始。恢复失败后，移除故障标记，再从应用的恢复入口重试。

| 标记 | 操作 | 预期 |
|---|---|---|
| `fail-before-dev` | 启动 dev | 前置任务失败，Flutter 不启动，原环境标记不变 |
| `fail-before-test` | prod 运行后停止 | 后置恢复失败，保留 prod 标记和风险记录。移除故障标记后重试，成功恢复 test |
| `fail-after-prod` | 启动 prod | 前置任务写入后失败，Flutter 不启动，进入需恢复状态。重试恢复后标记变为 test |

强退验收在隔离样例中使用 `pause-after-prod` 或 `pause-after-test`。脚本写入目标环境并通过故障检查后，创建对应的 `paused-after-prod` 或 `paused-after-test`，此时任务仍在运行。移除本轮 `pause-after-*` 可放行任务，等待约 30 秒仍未移除则任务以退出码 1 结束。每轮开始前清除本轮使用的旧就绪文件，结束后清理本轮暂停和就绪文件。强退后从应用的恢复入口重试原任务。

单独运行 `/bin/sh scripts/simulate-firebase-switch.sh test --quiet` 可在测试项目目录核对本地脚本。Flutter Debug、设备、DevTools 及应用重启后的风险检测仍按验收矩阵实测。
