---
status: testing
phase: 02-config-task-execution-core
source: [02-VERIFICATION.md]
started: 2026-11-12T08:29:47Z
updated: 2026-11-12T08:29:47Z
---

# P2 人工验收

使用 [P2 验收记录](02-P2-ACCEPTANCE.md) 的最终构建和隔离样例。三个测试由用户复核。

## Current Test

number: 1
name: 隔离项目与配置重读
expected: |
  四个配置名称原样显示。重读损坏文件会保留并禁用过期选择，有效定义变化要求再次 Run。根外项目及其符号链接被拒绝，两份配置字节不变。
awaiting: user response

## Tests

### 1. 隔离项目与配置重读

用最终 Debug 打开固定根内样例，核对四套配置。损坏并修复临时 `launch.json` 后重读。只在样例副本改变有效参数，核对首次 Run 和再次 Run，再测试根外目录及根内指向它的符号链接。

expected: 四套名称原样显示。损坏重读保留过期配置并禁用 Run，有效定义变化要求再点一次。越界项目均被拒绝，无任务副作用。复位后两份配置的 `cmp` 均通过。
result: [pending]

### 2. 菜单栏和主窗共用会话与恢复

从主窗运行 prod，打开菜单栏核对项目和 Run/Stop。关闭主窗后用菜单栏 Stop 或重新打开主窗。复验菜单栏退出、运行中切换、前置部分写入、后置失败后收起日志再重试，以及强制退出后重启。

expected: 两处项目与按钮同步。关闭主窗时会话继续，受管组静止后仅执行一次原后置。风险在日志外可见，任务成功且完成凭据持久后恢复为 test。恢复失败时取消退出，切换须在恢复后重新发起。
result: [pending]

### 3. 最终 Release 的验收参数隔离

使用 P2 验收记录的 Release 构建，同时传入 `--g1-ready` 和 `--phase-02-fixture`。打开或重开样例并选择 prod。

expected: 进入普通模式，Run 禁用，样例环境标记、调试启动标记和 Debug 验收存储均无任务副作用。
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
