# Claude Code 组件开发规范

> 独立、通用、即插即用的 Claude Code 组件开发指南。
> 将此目录复制到任何 Plugin 项目的根目录或 `.claude/` 目录中即可使用。

## 快速导航

| 任务 | 阅读 |
|------|------|
| 创建新 Plugin | `components/plugin.md` |
| 开发 Skill | `components/skill.md` |
| 定义 Agent | `components/agent.md` |
| 开发 Command | `components/command.md` |
| 添加 Hook | `components/hook.md` |
| 配置 MCP Server | `components/mcp.md` |
| 排查问题 | `common/anti-patterns.md` |
| 发布前检查 | `common/quality.md` |
| 理解设计理念 | `common/principles.md` |

## 铁律索引（IR-1 ~ IR-9）

| IR | 约束 | 定义位置 |
|----|------|---------|
| IR-1 | Manifest 隔离 | `components/plugin.md` |
| IR-2 | Description=触发条件（CSO） | `components/skill.md` |
| IR-3 | 仅用官方字段 | `common/rules.md` |
| IR-4 | 安全必须 Hook 强制执行 | `components/hook.md` |
| IR-5 | 路径必须相对 | `common/rules.md` |
| IR-6 | Hook 事件名大小写敏感 | `components/hook.md` |
| IR-7 | 产出符合契约 | `common/rules.md` |
| IR-8 | plugin.json 同步 | `common/rules.md` |
| IR-9 | 禁止猜测 | `common/rules.md` |

## 按需文件索引

### 通用层 common/

| 文件 | 内容 | 加载时机 |
|------|------|---------|
| `rules.md` | 跨组件铁律 IR-3,5,7,8,9 + 共享约束 | 自动加载 |
| `principles.md` | P1-P10 信息架构原则 + 实践指南 | 理解设计决策 |
| `anti-patterns.md` | 8 个跨组件反模式 + 诊断决策树 | 故障排查 |
| `quality.md` | 验证框架 + 验证命令库 + 官方工具 | 发布前验证 |

### 组件层 components/

| 文件 | 内容 | 加载时机 |
|------|------|---------|
| `plugin.md` | IR-1 + 目录布局 + manifest + settings | 创建/重构 Plugin |
| `skill.md` | IR-2/CSO + frontmatter + 分拆 + 反模式 | 创建/修改 Skill |
| `hook.md` | IR-4,6 + 事件表 + 脚本 + 反模式 | 添加/调试 Hook |
| `agent.md` | frontmatter + memory + Task + worktree | 创建/修改 Agent |
| `command.md` | frontmatter + 命名 + 与 Skill 区别 | 创建/修改 Command |
| `mcp.md` | .mcp.json + 环境变量 + 内嵌 MCP | 配置 MCP Server |

## 三维架构

- **维度 1** `common/`：跨组件通用（rules 自动加载，其余按需）
- **维度 2** 每个组件文件内部：Part 1 Rules（WHY/WHAT）+ Part 2 Spec（HOW）
- **维度 3** `components/`：按组件类型（plugin, skill, hook, agent, command, mcp）

**依赖方向**：components/ -> common/（单向）。
