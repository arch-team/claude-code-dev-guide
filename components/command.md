# Command 开发指南

> **职责**：斜杠命令（Slash Command）的创建、frontmatter 配置和内容组织。按需加载——创建或修改 Command 时阅读。

## 文件结构

Command 文件放在 `commands/` 目录，每个 `.md` 文件定义一个命令：

```
commands/
+-- validate.md          # /plugin-name:validate
+-- analyze.md           # /plugin-name:analyze
+-- quick-check.md       # /plugin-name:quick-check
```

**命名规则**：文件名即命令名，使用 kebab-case。用户通过 `/plugin-name:command-name` 调用。

## Frontmatter 字段完整表

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `description` | string | 推荐 | 命令描述（推荐 < 60 字符） |
| `allowed-tools` | string | 否 | 允许的工具，逗号分隔 |
| `model` | string | 否 | `sonnet` / `opus` / `haiku` |
| `argument-hint` | string | 否 | 参数提示（如 `[file-path]`） |
| `disable-model-invocation` | boolean | 否 | `true` = 禁止自动调用 |

**铁律提醒** `[IR-3]`：Command 的 frontmatter **没有 `name` 字段**——命令名由文件名决定。在 frontmatter 中添加 `name` 会导致命令无法加载。

## 内容组织

Command 文件的 body 是发送给 Claude 的完整 prompt。典型结构：

```markdown
---
description: Design optimal context configuration
allowed-tools: AskUserQuestion, Write, Read, Glob
argument-hint: [project-path]
---

你是一个上下文配置专家。根据用户提供的项目路径，执行以下步骤：

## 输入
- `$ARGUMENTS`：项目路径

## 步骤
1. 读取项目结构
2. 分析文件组织
3. 生成配置建议

## 输出
- 配置文件内容
- 优化建议
```

## 与 Skill 的区别

| 维度 | Command | Skill |
|------|---------|-------|
| 触发方式 | 仅用户手动 `/plugin:command` | 用户手动或 Claude 自动触发 |
| 自动触发 | 不支持 | 支持（通过 description 匹配） |
| 内容结构 | 单文件 prompt | 可拆分为 SKILL.md + procedures |
| 典型用途 | 简单、明确的操作 | 复杂、多步骤的工作流 |
| frontmatter | 无 `name` 字段 | 有 `name` 字段 |

**选择建议**：
- 简单的一次性操作 -> Command
- 需要 Claude 自动识别并触发的复杂流程 -> Skill

## 参数替换

与 Skill 相同，Command 内容中可使用参数变量：

| 变量 | 说明 |
|------|------|
| `$ARGUMENTS` | 全部参数 |
| `$0` | 第一个参数 |
| `$1` | 第二个参数 |
| `` !`command` `` | 预处理器 shell 执行 |

