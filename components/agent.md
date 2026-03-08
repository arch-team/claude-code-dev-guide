# Agent 定义开发指南

> **职责**：Agent 文件的创建、frontmatter 配置、memory 作用域和调用方式。按需加载——创建或修改 Agent 时阅读。

## 速查卡片

| 任务 | 章节 |
|------|------|
| 创建新 Agent | 文件结构 + Frontmatter |
| 配置 Agent 权限 | 工具限制 |
| 使用 Agent 记忆 | Memory 作用域 |
| 调用 Agent | Task 工具调用 |
| Agent 隔离执行 | Worktree 隔离 |

## 文件结构

Agent 文件放在 `agents/` 目录，每个 `.md` 文件定义一个 Agent：

```
agents/
+-- code-reviewer.md
+-- test-runner.md
+-- security-auditor.md
```

文件内容：frontmatter（配置）+ body（系统 prompt / 行为描述）。

## Frontmatter 字段完整表

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | **是** | Agent 名称，用于 Task 工具调用时的 `subagent_type` |
| `description` | string | **是** | Agent 能力描述——Claude 据此决定何时委派任务 |
| `tools` | string[] | 否 | 允许使用的工具列表 |
| `disallowedTools` | string[] | 否 | 禁止使用的工具列表 |
| `model` | string | 否 | `sonnet` / `opus` / `haiku` |
| `color` | string | 否 | UI 背景色：`blue`/`cyan`/`green`/`yellow`/`red`/`magenta` |
| `permissionMode` | string | 否 | 权限模式 |
| `maxTurns` | number | 否 | 最大交互轮次 |
| `skills` | string[] | 否 | Agent 可使用的 Skill 列表 |
| `mcpServers` | string[] | 否 | Agent 可访问的 MCP Server |
| `memory` | object | 否 | 记忆配置 |
| `hooks` | object | 否 | Agent 级 Hook 配置 |
| `isolation` | string | 否 | `worktree` = 在独立 git worktree 中运行 |

**注意**：`name` 和 `description` 是仅有的两个必填字段 `[IR-3]`。

## 工具限制

通过 `tools` 和 `disallowedTools` 控制 Agent 权限：

- `tools`：白名单模式，仅列出的工具可用
- `disallowedTools`：黑名单模式，列出的工具被禁止

**最小权限原则**：按 Agent 角色限制工具访问。例如：
- 只读分析 Agent -> 禁止 Write、Edit、Bash
- 测试 Agent -> 仅允许 Read、Bash（运行测试命令）
- 代码审查 Agent -> 仅允许 Read、Grep、Glob

```yaml
---
name: code-analyzer
description: Static code analysis agent, read-only access
tools: ["Read", "Grep", "Glob"]
---
```

## Memory 作用域

Agent 记忆通过 `memory` 字段配置，自动持久化到文件系统：

| 作用域 | 存储位置 | 适用场景 |
|--------|---------|---------|
| `project` | `.claude/agent-memory/<name>/` | 仓库特定上下文（架构决策、代码模式） |
| `user` | `~/.claude/agent-memory/<name>/` | 跨仓库通用模式（编码偏好、常用工具） |
| `local` | 本地临时存储 | 会话内临时数据 |

```yaml
---
name: architect
description: System architecture analysis agent
memory:
  project: true
  user: true
---
```

下次 fork 该 Agent 时，之前保存的记忆会自动加载。

## Task 工具调用

通过 Task 工具调用 Agent：

```
Task(
  subagent_type="agent-name",
  prompt="执行的具体任务描述",
  description="简短任务摘要"
)
```

**关键限制**：子 Agent 不能再嵌套调用 Task 工具（不允许 Agent 递归调用）。

## Worktree 隔离

设置 `isolation: worktree` 时，Agent 在独立的 git worktree 中运行：
- 拥有仓库的独立工作副本
- 变更不影响主工作区
- 无变更时自动清理 worktree

适用场景：可能产生破坏性变更的操作（大规模重构、实验性修改）。

## Agent 操作规则

| # | 规则 | 优先级 |
|---|------|--------|
| 13.1 | **单一职责** — 一个 Agent = 一个决策视角或领域专长 | 推荐 |
| 13.2 | **工具限制** — 按角色限制 tools/disallowedTools | 推荐 |
| 13.3 | **优雅降级** — context: fork 不可用时静默回退内联执行 | 推荐 |
| 13.4 | **执行透明** — 分叉 Agent 完成后输出变更摘要 | 必须 |
| 13.5 | **记忆范围** — 有意识地选择 project/user 记忆范围 | 推荐 |

## 完整 Agent 示例

```yaml
---
name: code-reviewer
description: Use when code changes need quality review, focusing on correctness, style, and security
model: sonnet
color: green
tools: ["Read", "Grep", "Glob"]
memory:
  project: true
---
```

你是一个代码审查专家。审查时关注以下方面：

1. **正确性**：逻辑错误、边界条件、异常处理
2. **安全性**：注入漏洞、敏感数据暴露
3. **风格**：命名规范、代码组织、注释质量
4. **性能**：不必要的循环、内存泄漏
