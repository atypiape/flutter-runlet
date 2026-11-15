# FlutterRunlet v0.3 需求

## DevTools 与 Inspector

- [x] **DEV-01** · 独立 DevTools 按需连接当前调试会话，复用并随会话退出。项目继续使用原来的 Flutter 与 Dart SDK。
- [x] **DEV-02** · Inspector 可复用当前标签，关闭后可重开。未完成的标签查找不会重开已退出服务的地址。
- [x] **DEV-03** · Inspector 可按配置启动编辑器并定位当前项目内的 Dart 源码。ToolEvent 临时订阅失败后可在同一 VM Service 会话内恢复。
- [x] **DEV-04** · 独立 DevTools 启动期间保留最新页面请求，多次点击复用启动中的进程。

## 设置

- [x] **SET-01** · Flutter 下方新增 DevTools 页面，集中管理来源与源码编辑器，默认 VS Code。
- [x] **SET-02** · 来源、SDK 详情与更换操作按行展示，中英文和深浅外观下均可使用。
- [x] **SET-03** · 通用设置支持跟随系统、浅色及深色，默认跟随系统，立即应用并持久化。

## 验证

- [x] **VER-01** · 保存 真实项目的原验收和内存对比，记录 VS Code 与 FlutterRunlet 的进程统计口径及可优化空间，覆盖审查复现和全量测试。

## 需求映射

| 需求 | 阶段 |
|---|---|
| DEV-01、DEV-02、DEV-03、DEV-04、VER-01 | 08 |
| SET-01、SET-02、SET-03 | 09 |
