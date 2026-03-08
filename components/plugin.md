# Plugin 规范

> **职责**：Plugin 目录布局、Manifest 规格、设置和 marketplace 参考。按需加载——创建或重构 Plugin 时阅读。

## 速查卡片

| 任务 | 章节 |
|------|------|
| 创建新 Plugin | Part 2 > 目录布局 |
| 配置 plugin.json | Part 2 > Manifest 字段 |
| 配置 Plugin 默认设置 | Part 2 > settings.json |
| 定义输出风格 | Part 2 > output-styles/ |
| 发布到 Marketplace | Part 2 > marketplace.json |
| 排查加载失败 | Part 2 > 已知问题 |

---

## Part 1: Rules（WHY / WHAT）

### IR-1：Manifest 隔离

**规则**：`.claude-plugin/` 目录仅存放 `plugin.json` 和 `marketplace.json`。所有组件目录（`commands/`、`agents/`、`skills/`、`hooks/`、`rules/`、`output-styles/`）必须位于 Plugin 根目录。

**原理**：Claude Code 在 Plugin 根目录自动扫描组件。放在 `.claude-plugin/` 内的组件不会被发现。

- **正确**：`skills/`、`hooks/`、`rules/` 在 Plugin 根目录（与 `.claude-plugin/` 同级）
- **错误**：`skills/`、`hooks/` 放在 `.claude-plugin/` 内部 -> 不会被发现

### AP-13：无文档契约 `违反 P10, IR-7`

- **症状**：Skill A 修改输出格式后，Skill B 读取该文件时静默失败
- **根因**：无独立 Schema 定义共享状态文件的格式
- **修复**：定义独立 Schema 文件（如 `knowledge/_schema/record-format.md`），写方和读方都依赖 Schema
- **检测**：列出所有 Skill 间的共享文件，确认每个有对应 Schema

### AP-14：Manifest 塞满 `违反 IR-1`

- **症状**：新增的 Skill 或 Hook 不被发现
- **根因**：组件文件放在 `.claude-plugin/` 目录内而非 Plugin 根目录
- **修复**：仅 `plugin.json` + `marketplace.json` 在 `.claude-plugin/`，所有组件移到 Plugin 根目录
- **检测**：`ls .claude-plugin/` 除 manifest 外应无其他文件

### 安全与信任规则

| # | 规则 | 优先级 |
|---|------|--------|
| S1 | **人类审批门** — 不可逆操作需要人类明确确认，不可通过程序绕过 | 铁律 |
| S2 | **权限分层** — 破坏性操作默认 deny，状态变更默认 ask，只读操作才 allow | 推荐 |
| S3 | **模式保护** — 使用 Hook 执行模式边界 | 推荐 |
| S4 | **沙箱兼容** — 不假设可访问项目目录之外的系统 | 推荐 |

---

## Part 2: Spec（HOW）

### 目录布局

```
my-plugin/
├── .claude-plugin/          # 仅 manifest
│   ├── plugin.json          # 必需（唯一必需文件）
│   └── marketplace.json     # 可选（marketplace 发布时）
├── commands/                # 斜杠命令（文件名 = 命令名）
├── agents/                  # Agent 定义（文件名含 name frontmatter）
├── skills/                  # Skill 目录（目录名 = Skill 名）
│   └── my-skill/
│       ├── SKILL.md         # Skill 入口（必需）
│       └── *-procedures.md  # 详细步骤（可选）
├── hooks/                   # Hook 脚本和配置
│   └── hooks.json           # Hook 事件配置
├── rules/                   # 行为规则（会话开始自动加载）
├── knowledge/               # 参考知识（按需加载）
│   └── _schema/             # 数据格式契约（可选）
├── output-styles/           # 输出风格定义（可选）
├── settings.json            # Plugin 默认配置（可选）
└── .mcp.json                # MCP Server 配置（可选）
```

**关键规则**：
1. **命名空间**：`plugin.json` 中的 `name` 字段同时作为 Skill 命名空间前缀（例如 `name: "devpace"` -> Skill 调用为 `devpace:pace-init`）
2. **自动发现**：`commands/`、`agents/`、`skills/`、`rules/` 等标准目录会被自动扫描
3. **rules/ 自动加载**：`rules/` 目录下的文件在会话开始时自动加载
4. **knowledge/ 按需加载**：`knowledge/` 目录下的文件不会自动加载

### plugin.json 字段规格

#### 必填字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | string | Plugin 名称，同时作为 Skill 命名空间前缀 |

#### 可选字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `version` | string | 语义化版本号 |
| `description` | string | Plugin 功能描述 |
| `author` | object | 作者信息，包含 `name` 字段 |
| `homepage` | string | 项目主页 URL |
| `repository` | string | 仓库地址（**必须为字符串**，不可用 object 格式） |
| `license` | string | 开源协议 |
| `keywords` | array | 关键词列表（见下方已知问题） |
| `commands` | array | 额外 commands 路径（补充自动发现） |
| `agents` | array | 额外 agents 路径（补充自动发现） |
| `skills` | array | 额外 skills 路径（补充自动发现） |
| `hooks` | array | 额外 hooks 路径（补充自动发现） |
| `mcpServers` | object | MCP Server 内联定义 |
| `outputStyles` | array | 输出风格文件路径 |
| `lspServers` | object | LSP Server 定义 |

**路径规则** `[IR-5]`：所有路径必须为相对路径且以 `./` 开头。

#### 最小示例

```json
{
  "name": "my-plugin"
}
```

#### 完整示例

```json
{
  "name": "my-plugin",
  "description": "A comprehensive example plugin",
  "version": "1.0.0",
  "author": {
    "name": "Developer"
  },
  "skills": ["./skills/extra-skill"],
  "hooks": ["./hooks"],
  "mcpServers": {
    "my-server": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/my-server.js",
      "args": ["--port", "3000"]
    }
  }
}
```

#### 已知问题

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| `keywords` 含特殊字符 | 如 `CLAUDE.md` 中的 `.` 可能触发解析异常 | 避免含 `.` 的字符串 |
| `repository` 使用 object 格式 | `{"type": "git", "url": "..."}` 不被支持 | 改为纯字符串 |
| 路径未以 `./` 开头 | 相对路径规则要求 | 所有路径加 `./` 前缀 |

### settings.json

Plugin 默认配置文件，放在 Plugin 根目录。格式与 `.claude/settings.json` 相同。

配置优先级见 `common/rules.md` 配置优先级节。

### output-styles/

输出风格定义目录。包含 Markdown 格式的风格文件，用于定义 Claude 的输出格式偏好。

**使用方式**：需在 `plugin.json` 的 `outputStyles` 字段中显式声明，不会自动发现。

```json
{
  "name": "my-plugin",
  "outputStyles": ["./output-styles/concise.md"]
}
```

### marketplace.json

Marketplace 发布时的补充元数据文件，放在 `.claude-plugin/` 目录内。仅在发布到 Marketplace 时需要。

### 验证清单

```
[ ] 目录布局符合标准结构                                               [IR-1]
[ ] plugin.json 仅含合法字段                                          [IR-3]
[ ] 所有路径以 ./ 开头                                                 [IR-5]
[ ] plugin.json 与文件系统同步                                         [IR-8]
[ ] 共享状态文件有对应 Schema                                          [P10]
```
