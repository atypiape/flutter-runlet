# Roadmap: FlutterRunlet

## v0.1 — FlutterRunlet

## Overview

沿用 [开发路线](../docs/03-ROADMAP.md)的五个实施阶段。G0 最终视觉验收已通过。依次达到 G1 原生骨架、G2 调试闭环和 G3 最终验收。每个阶段按 [验收矩阵](../docs/04-ACCEPTANCE.md)保留适用的自动测试、人工验证、截图和提交记录。G2 之后由用户决定是否做额外视觉精修。

## Phases

- [ ] **Phase 1: 上游审计与原生 UI 骨架** - 完成上游审计，交付可启动的原生 App 骨架并通过 G1。
- [ ] **Phase 2: 配置和任务执行内核** - 建立只读项目配置、任务与恢复内核，让启动和环境切换具备可测试的行为。
- [ ] **Phase 3: Flutter 调试闭环** - 使用真实 Flutter 工程完成从选择设备到 Debug、浏览器检查及环境恢复的流程并通过 G2。
- [ ] **Phase 4: macOS 界面与双语设置** - 按 G0 基线完成原生界面、本地化、设置与图标。
- [ ] **Phase 5: 稳定性、异常恢复与最终验收** - 验证异常与恢复行为、目标系统和发布准备，通过 G3。

## Phase Details

### Phase 1: 上游审计与原生 UI 骨架

**Goal**: 完成上游审计，交付可启动的原生 App 骨架并通过 G1。
**Depends on**: 无
**Requirements**: BASE-01, BASE-02, BASE-03
**Success Criteria**:
  1. 审计记录列明 Flutter GUI Runner 可复用能力、应隐藏的超范围入口、依赖及许可证。已导入部分的许可与版权可核查。
  2. 在 macOS 打开主窗口、菜单栏、设置和关于窗口，验证窗口尺寸与原生结构，记录适用截图和偏差。（A01、A02）
  3. 构建验证暂定 macOS 15 部署目标，记录实际 API 可用性和需要的替代路径。（A31）

**Plans**: 2/3 plans executed
**Wave 1**
- [x] 01-01-PLAN.md

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 01-02-PLAN.md

**Wave 3** *(blocked on Wave 2 completion)*
- [ ] 01-03-PLAN.md

**UI hint**: yes

### Phase 2: 配置和任务执行内核

**Goal**: 建立只读项目配置、任务与恢复内核，让启动和环境切换具备可测试的行为。
**Depends on**: Phase 1
**Requirements**: CONF-01, CONF-02, CONF-03, CONF-04, CONF-05, TASK-01, TASK-02, SAFE-01, SAFE-02, SAFE-03, SAFE-04
**Success Criteria**:
  1. 能打开、切换并重读项目配置。公开样例四套配置原样可选，JSONC、旧 Dart define、macOS PATH、工作目录和任务参数均按契约解析，源文件保持原样。（A07–A11）
  2. 非 Debug、不支持或缺失任务、无效参数和前置失败都有明确原因，执行层阻断相应的任务或 Flutter 启动。（A12、A32）
  3. 公开 prod 样例在进程退出后恢复 test。部分写入、异常退出及恢复失败保留可见风险，重试成功后清除。（A13–A15）
  4. 重复 Run 或切换项目时，项目锁及会话终止规则阻止冲突的环境切换。（A16）

**Plans**: TBD

### Phase 3: Flutter 调试闭环

**Goal**: 使用真实 Flutter 工程完成从选择设备到 Debug、浏览器检查及环境恢复的流程并通过 G2。
**Depends on**: Phase 2
**Requirements**: RUN-01, RUN-02, RUN-03, RUN-04, RUN-05, RUN-06
**Success Criteria**:
  1. SDK、FVM 和设备选择均反映实际运行环境。iOS 模拟器可启动，Android 模拟器及真机按可用情况实测或记录不适用原因。（A17、A18、A24）
  2. 用户能运行、停止、热重载及热重启当前会话。主窗口关闭后仍能在菜单栏管理，进程退出或断线后能及时看到正确状态。（A19、A21、A22）
  3. 默认浏览器打开当前会话 DevTools 和可用的 Inspector，重新启动后连接更新，并验证 Inspector 的可用路径。（A20）
  4. 公开 dev/test/prod 样例验证前后置顺序和正常停止恢复。日志清空后折叠、展开保持清空并接收新输出。（A13、A30）

**Plans**: TBD
**UI hint**: yes

### Phase 4: macOS 界面与双语设置

**Goal**: 按 G0 基线完成原生界面、本地化、设置与图标。
**Depends on**: Phase 3
**Requirements**: UI-01, UI-02, UI-03, UI-04, UI-05, UI-06
**Success Criteria**:
  1. 主窗和菜单栏展示一致的关键状态，恢复提示及重试在日志外。双语、系统深浅色及长名称操作均有截图或实测记录。（A03、A05、A21、A23）
  2. 通用与 Flutter 设置分工符合规格，Flutter 设置展示实际版本和 FVM 状态，环境检测支持摘要与完整输出。（A04、A24、A25）
  3. 关于窗口显示真实版本、构建号和许可，链接按确认状态呈现。Dock 与菜单栏图标在两种外观下验证并记录必要原生差异。（A06、A26）

**Plans**: TBD
**UI hint**: yes

### Phase 5: 稳定性、异常恢复与最终验收

**Goal**: 验证异常与恢复行为、目标系统和发布准备，通过 G3。
**Depends on**: Phase 4
**Requirements**: REL-01, REL-02, REL-03, REL-04
**Success Criteria**:
  1. 启动失败、设备断线、重复运行、任务失败、运行中退出及强制终止都有复验记录。prod 环境恢复的正常、失败与重试路径全部通过。（A14–A16、A22、A28）
  2. 长时间运行及高频日志下界面可响应，记录内存观察结果，回归清空、折叠和新输出。（A27、A30）
  3. 在获授权的真实工程复验 dev/test/prod 和 VS Code 的可观察结果，并在 macOS 15 实机复验适用窗口、控件及关键流程。（A29、A31）
  4. G3 记录所有适用验收项和用户确认的视觉差异。Release 构建、文档、许可证和发布说明齐备。

**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|---|---|---|---|
| 1. 上游审计与原生 UI 骨架 | 2/3 | In Progress | - |
| 2. 配置和任务执行内核 | 0/TBD | Not started | - |
| 3. Flutter 调试闭环 | 0/TBD | Not started | - |
| 4. macOS 界面与双语设置 | 0/TBD | Not started | - |
| 5. 稳定性、异常恢复与最终验收 | 0/TBD | Not started | - |
