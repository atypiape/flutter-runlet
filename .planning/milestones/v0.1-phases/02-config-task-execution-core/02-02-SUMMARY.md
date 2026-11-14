---
phase: 02-config-task-execution-core
plan: "02"
subsystem: configuration
tags: [swift, jsonc, argv, preferences]
requires:
  - phase: 02-config-task-execution-core
    provides: 02-01 的会话控制器与真实受管进程
provides: [可定位 JSONC, 启动和任务参数校验, 配置重读和最近项目]
affects: [02-03, 03]
tech-stack:
  added: []
  patterns: [只读配置, 不可变执行计划, 有效定义二次确认]
key-files:
  created: [FlutterRunlet/JSONCReader.swift, FlutterRunletTests/ProjectConfigurationTests.swift, FlutterRunletTests/ProjectSelectionTests.swift]
  modified: [FlutterRunlet/ProjectConfiguration.swift, FlutterRunlet/SessionController.swift, FlutterRunlet/MainWindowView.swift, FlutterRunlet/AuxiliaryWindows.swift]
requirements-completed: [CONF-01, CONF-02, CONF-03, CONF-04, CONF-05, TASK-01, TASK-02]
coverage:
  - id: read-only-config
    description: 公开配置、原文诊断、参数及任务环境保真
    verification:
      - kind: integration
        ref: FlutterRunletTests/ProjectConfigurationTests.swift
        status: pass
    human_judgment: false
  - id: project-selection
    description: 项目重读、启动前确认和最近项目
    verification:
      - kind: integration
        ref: FlutterRunletTests/ProjectSelectionTests.swift
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-11-12
status: complete
---

# 02-02 · 配置解析、重读和最近项目

- JSONC 预处理保留原始字节坐标，使用系统 JSON 解析处理字符串和结构。启动项独立显示错误，重复名称保留并禁用。任务文件缺失或损坏只阻断引用任务的配置。
- 公开样例的四个名称、旧 define、新工具参数和 macOS PATH 有回归断言。真实进程验证工作目录、退出码和 argv 字节，包含空串、引号、Unicode 和 shell 元字符。命令向量与显式 shell 字符串均经过独立校验。
- 重读失败保留过期选择。运行前比较有效定义，变化时要求再次 Run。通用设置接入默认开启的最近项目偏好，重启只读，验收和普通启动使用各自偏好。

## 验证

共享 scheme 全量 Debug XCTest 通过，共 20 项。仅接受已验证可保留 Debug、入口和设备语义的工具参数形式。未支持的 VS Code 扩展、后台及依赖任务会显示原因。
