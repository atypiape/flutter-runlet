# Phase 03 · 外部接口覆盖

| capability | decision | reason |
| --- | --- | --- |
| Flutter CLI · 查询版本与机器设备清单 | INTEGRATE | 03-01、03-02 验证 SDK 版本并发现 iOS、Android 和真机。 |
| Flutter CLI · Debug run --machine | INTEGRATE | 03-01 连接用户指定设备并使用受管进程。 |
| Flutter 机器协议 · app.start、app.started、app.debugPort、app.devTools、app.log、app.stop | INTEGRATE | 03-01、03-03 绑定当前 Flutter 会话、输出、VM Service 与 DevTools，区分停止通知与真实退出。 |
| Flutter 机器协议 · app.restart、app.stop 请求 | INTEGRATE | 03-01、03-03 使用已验证会话的停止、热重载与热重启响应。 |
| Flutter CLI · doctor | OPT-OUT | 完整环境诊断在 Phase 04。 |
| Flutter CLI · profile、release、DAP、attach、远程调试与设备管理 | OPT-OUT | 本阶段只管理用户发起的本地 Flutter Debug 和适用设备。 |
| FVM · 本地项目约束和已安装 SDK 解析 | INTEGRATE | 03-02 解析有效项目 SDK，并报告明确约束失效。 |
| FVM · install、use、配置写入、升级或缓存管理 | OPT-OUT | 工具仅使用已安装 SDK 与只读配置。 |
| macOS Simulator · 发现可启动设备、启动选定 iOS 模拟器 | INTEGRATE | 03-02 按用户操作启动并等待 Flutter 发现。 |
| 模拟器管理 · 安装、擦除、强制关闭、创建 Android AVD | OPT-OUT | 本阶段选择可用设备并启动 iOS 模拟器，系统维护独立处理。 |
| Dart VM Service · 当前本地连接、有效 RPC、断线和重连 | INTEGRATE | 03-01、03-03 校验当前会话就绪与动作门槛。 |
| Dart VM Service · 通用调试 RPC、性能分析、远程连接 | OPT-OUT | 具体检查交给 DevTools，完整 IDE 能力不在当前产品范围。 |
| DevTools · 当前连接、默认浏览器、Inspector 直达或已连接回退 | INTEGRATE | 03-03、03-04 验证真实可用路径、Widget 选取和会话更替。 |
| DevTools · 内嵌、独立 UI 或自行实现检查器 | OPT-OUT | 采用系统默认浏览器与现有 DevTools。 |

## 需求边界核对

无独立 SPEC 的自动探针将 RUN-01–RUN-06 全部标为 unclassified。六项保留自动分类未决标记。依据中文契约人工补出每项的具体执行断言。

| 探针标记 | 人工核对的边界 | 计划 |
| --- | --- | --- |
| RUN-01 · 自动分类未决 | 零／一／多台、明确冲突、扫描失败、同 ID 重连、项目切换隔离 | 03-02 |
| RUN-02 · 自动分类未决 | 有效优先级、明确 SDK 缺失、候选验证失败、激活重检、会话期间只读 | 03-02 |
| RUN-03 · 自动分类未决 | 60 秒起点、当前命令响应、VM 暂断、设备确断、已确认退出才恢复 | 03-01、03-03 |
| RUN-04 · 自动分类未决 | 当前地址、旧连接作废、目标版本支持的 Inspector 路径、真实 Widget 选择 | 03-03、03-04 |
| RUN-05 · 自动分类未决 | 主窗关闭再开、两处共享动作、重复运行和终止竞态 | 03-01、03-03、03-04 |
| RUN-06 · 自动分类未决 | 实时输出与分片、清空后追加、失败和成功切换、日志与恢复相互独立 | 03-03 |

计划保留产品特有的执行意图边界。命令执行来源、过期会话冒用、进程组退出和令牌披露属于安全审查，见各计划 STRIDE 登记。普通状态与错误回归由任务验证覆盖。
