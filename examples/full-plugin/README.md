# full-plugin

完整平台插件示例（模式 5），展示所有组件类型的协同工作。

## 展示重点

- **IR-1**：Manifest 隔离（`.claude-plugin/` 仅含 plugin.json + marketplace.json）
- **IR-2 (CSO)**：Skill description 仅写触发条件
- **IR-4**：三重保险——Hook exit 2 阻断 + rules 声明 + Skill 约束
- **IR-5**：所有路径使用 `${CLAUDE_PLUGIN_ROOT}` 或 `./` 前缀
- **跨平台 Hook**：`run-hook.cmd` polyglot 包装器（Windows + macOS/Linux）
- **Agent 配置**：工具限制（只读）+ 项目级 memory

## 安装测试

```bash
/plugin marketplace add /path/to/full-plugin
/plugin install full-plugin@full-plugin-dev
# 重启 Claude Code

# 测试 Skill
# 输入 "show me what this plugin can do"

# 测试 Command
/full-plugin:check

# 测试 Hook（尝试写入 .env 文件应被阻断）
```

## 目录结构

```
full-plugin/
├── .claude-plugin/
│   ├── plugin.json          # [IR-1] Manifest
│   └── marketplace.json     # dev marketplace 测试用
├── skills/demo-workflow/
│   └── SKILL.md             # [IR-2] CSO 合规 description
├── commands/
│   └── check.md             # 无 name 字段（文件名即命令名）
├── agents/
│   └── reviewer.md          # tools 白名单 + memory 配置
├── hooks/
│   ├── hooks.json           # PreToolUse 事件 [IR-6] PascalCase
│   ├── run-hook.cmd          # 跨平台 polyglot 包装器
│   └── check-write.sh       # exit 2 阻断 [IR-4]
├── rules/
│   └── main-rules.md        # 自动加载的行为约束
└── README.md
```
