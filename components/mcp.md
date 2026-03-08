# MCP Server 配置指南

> **职责**：MCP Server 的配置格式、环境变量、Plugin 内嵌配置参考。按需加载——配置 MCP Server 时阅读。

## 速查卡片

| 任务 | 章节 | 要点 |
|------|------|------|
| 为项目配置 MCP Server | 配置文件位置 + .mcp.json 格式 | Plugin 根目录 `.mcp.json`，JSON 格式 |
| 使用环境变量 | 环境变量语法 | `${VAR}` 引用，`${VAR:-default}` 带默认值 |
| 在 Plugin 内嵌 MCP | Plugin 内嵌 MCP | plugin.json `mcpServers` 字段 + `${CLAUDE_PLUGIN_ROOT}` |
| 排查 MCP Server 问题 | 常见问题 | 变量语法、路径格式、执行权限 |

---

## 配置文件位置

| 方式 | 文件 | 适用场景 |
|------|------|---------|
| 项目级配置 | Plugin 根目录 `.mcp.json` | 项目专用的 MCP Server |
| Plugin 内嵌配置 | `.claude-plugin/plugin.json` 的 `mcpServers` 字段 | 随 Plugin 分发的 MCP Server |

**优先级**：项目级 `.mcp.json` 与 Plugin 内嵌配置合并生效。同名 Server 时项目级配置优先。

---

## .mcp.json 格式

```json
{
  "mcpServers": {
    "server-name": {
      "command": "path/to/server",
      "args": ["--flag"],
      "env": { "KEY": "${ENV_VAR}", "KEY2": "${VAR:-default}" }
    }
  }
}
```

**字段说明**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `command` | string | 是 | 可执行文件路径或命令名 |
| `args` | string[] | 否 | 命令行参数 |
| `env` | object | 否 | 环境变量键值对，支持变量展开 |

**多 Server 示例**：

```json
{
  "mcpServers": {
    "database": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": { "DATABASE_URL": "${DB_CONNECTION_STRING}" }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "./data"],
      "env": {}
    }
  }
}
```

---

## 环境变量语法

| 语法 | 说明 | 示例 |
|------|------|------|
| `${ENV_VAR}` | 引用环境变量（不存在时为空字符串） | `${API_KEY}` |
| `${VAR:-default}` | 带默认值（不存在时使用默认值） | `${PORT:-3000}` |
| `${CLAUDE_PLUGIN_ROOT}` | Plugin 根目录的绝对路径（特殊变量） | `${CLAUDE_PLUGIN_ROOT}/bin/server` |

**注意事项**：
- 仅 `env` 字段和 `command`/`args` 字段支持变量展开
- 变量名区分大小写
- `${CLAUDE_PLUGIN_ROOT}` 在 Plugin 上下文中可用，在项目级 `.mcp.json` 中不可用
- 不支持 shell 命令替换（如 `$(command)` 无效）

---

## Plugin 内嵌 MCP

在 `plugin.json` 中直接定义 MCP Server，随 Plugin 一起分发：

```json
{
  "name": "my-plugin",
  "mcpServers": {
    "my-server": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/my-mcp.js",
      "args": ["--port", "3000"],
      "env": { "API_KEY": "${MY_API_KEY}" }
    }
  }
}
```

**路径规则** `[IR-5]`：路径必须使用 `${CLAUDE_PLUGIN_ROOT}` 前缀，不可用绝对路径。Server 脚本需执行权限（`chmod +x`）。

**与项目级配置的区别**：

| 维度 | 项目级 `.mcp.json` | Plugin 内嵌 `mcpServers` |
|------|-------------------|------------------------|
| 分发 | 不随 Plugin 分发 | 随 Plugin 分发 |
| 路径基准 | 项目根目录 | `${CLAUDE_PLUGIN_ROOT}` |
| 适用场景 | 项目特定 Server | Plugin 自带 Server |
| 用户覆盖 | 用户直接编辑 | 项目级配置可覆盖 |

---

## 常见问题

| 症状 | 可能原因 | 修复方案 |
|------|---------|---------|
| 环境变量不展开 | 语法错误（如 `$VAR` 缺少花括号） | 使用 `${VAR}` 格式 |
| Server 启动后立即退出 | `command` 路径不正确 | 确认可执行文件存在且路径正确 |
| 权限被拒绝 | 脚本无执行权限 | `chmod +x path/to/server` |
| Plugin 内路径断裂 | 使用了绝对路径或相对路径 | 改用 `${CLAUDE_PLUGIN_ROOT}/...` |
| Server 找不到依赖 | `env` 中未传递必要变量 | 补充 `env` 字段或使用 `${VAR:-default}` |
| 配置未生效 | `.mcp.json` 不在 Plugin 根目录 | 确认文件位置正确 |
| 同名 Server 冲突 | 项目级和 Plugin 内嵌同名 | 项目级优先；重命名以避免冲突 |

**调试方法**：
1. `claude --debug` 查看 MCP Server 加载日志
2. 检查 Server 进程：`ps aux | grep server-name`
3. 手动运行 `command` + `args` 验证 Server 可否独立启动
