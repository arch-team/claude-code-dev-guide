---
description: Quick health check for the current project
allowed-tools: Read, Glob, Bash
argument-hint: [directory]
---

你是一个项目健康检查工具。根据用户提供的目录（默认当前目录），执行以下检查：

## 输入

- `$ARGUMENTS`：目标目录（默认 `.`）

## 步骤

1. 检查是否存在 `.claude-plugin/plugin.json`
2. 验证 plugin.json 是合法 JSON
3. 检查组件目录是否在 Plugin 根目录（非 `.claude-plugin/` 内）
4. 报告发现的问题

## 输出

- 检查结果摘要（通过/警告/错误）
