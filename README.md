# claude-code-dev-guide

Claude Code 组件开发规范——覆盖 Plugin、Skill、Hook、Agent、Command、MCP 六大组件的即插即用参考指南。

## 这是什么

一套面向 **Claude Code（LLM）** 的 Markdown 知识库，而非面向人类的教程。当 Claude 在你的 Plugin 项目中工作时，它会读取这些文件来理解正确的开发规范，从而避免常见陷阱（如把组件放在 `.claude-plugin/` 内导致不被发现、`description` 写成行为摘要导致 Skill 跳步等）。

## 快速使用

将本目录复制到你的 Plugin 项目中：

```bash
# 方式 1：放在项目根目录
cp -r claude-code-dev-guide/ your-plugin-project/claude-code-dev-guide/

# 方式 2：放在 .claude/ 目录
cp -r claude-code-dev-guide/ your-plugin-project/.claude/claude-code-dev-guide/
```

Claude Code 会自动发现并加载 `CLAUDE.md`，按需读取其余文件。

## 目录结构

```
claude-code-dev-guide/
├── CLAUDE.md                  # 入口（41 行）——文件索引 + 铁律索引 + 架构概览
│
├── common/                    # 跨组件通用层
│   ├── rules.md               #   铁律 IR-3,5,7,8,9 + 命名/隔离/Token 预算
│   ├── principles.md          #   P1-P10 信息架构原则
│   ├── anti-patterns.md       #   8 个跨组件反模式 + 诊断决策树
│   └── quality.md             #   验证清单 + 命令库 + RED-GREEN-REFACTOR
│
└── components/                # 按组件类型
    ├── plugin.md              #   IR-1 + 目录布局 + plugin.json 规格
    ├── skill.md               #   IR-2/CSO + frontmatter + 分拆模式
    ├── hook.md                #   IR-4,6 + 事件表 + 脚本模板
    ├── agent.md               #   frontmatter + memory + Task 调用
    ├── command.md             #   frontmatter + 与 Skill 的区别
    └── mcp.md                 #   .mcp.json + 环境变量 + Plugin 内嵌
```

## 信息架构

采用三维模型组织信息，确保 Claude 在正确的时机加载最少量的上下文：

| 维度 | 说明 |
|------|------|
| **维度 1 — 通用 vs 专用** | `common/` 放跨组件共享内容，`components/` 放组件专属内容 |
| **维度 2 — 抽象层级** | 每个组件文件内部分为 Part 1: Rules（WHY/WHAT）和 Part 2: Spec（HOW） |
| **维度 3 — 组件类型** | plugin, skill, hook, agent, command, mcp 各自独立 |

**依赖方向**：`components/` -> `common/`（单向），`common/` 不引用 `components/`。

## 9 条铁律（Iron Rules）

开发 Claude Code 组件时不可违反的硬约束：

| IR | 约束 | 所在文件 |
|----|------|---------|
| IR-1 | `.claude-plugin/` 仅放 manifest，组件在根目录 | plugin.md |
| IR-2 | Skill description 只写触发条件，不写行为 | skill.md |
| IR-3 | 仅使用官方 frontmatter 字段 | rules.md |
| IR-4 | 安全约束必须 Hook exit 2 强制执行 | hook.md |
| IR-5 | 所有路径相对且以 `./` 开头 | rules.md |
| IR-6 | Hook 事件名严格 PascalCase | hook.md |
| IR-7 | Skill 产出符合 Schema 契约 | rules.md |
| IR-8 | plugin.json 与文件系统保持同步 | rules.md |
| IR-9 | 不确定的 API/字段必须查证，禁止猜测 | rules.md |

## Token 效率

整套规范 11 文件共 **1331 行**，其中自动加载的 `CLAUDE.md` 仅 41 行。设计原则：

- **自动加载最小化**：仅 CLAUDE.md（导航）在会话开始时加载
- **按需加载**：组件文件在 Claude 实际开发该组件时才读取
- **零信息重复**：每条规则有且仅有一个权威定义点
- **单向依赖**：组件引用通用层，通用层不反向引用组件

## License

MIT
