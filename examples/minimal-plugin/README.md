# minimal-plugin

最小可运行的 Plugin 示例（模式 1：单 Skill 知识库）。

## 展示重点

- **IR-1**：`.claude-plugin/` 仅含 `plugin.json`，Skill 在 Plugin 根目录
- **IR-2 (CSO)**：`description` 仅写触发条件（"Use when user wants a greeting"）
- **IR-3**：frontmatter 仅使用官方字段（`name`、`description`）

## 安装测试

```bash
/plugin marketplace add /path/to/minimal-plugin
/plugin install minimal-plugin@minimal-plugin-dev
# 重启 Claude Code
# 输入 "hello" 或 "/minimal-plugin:hello" 验证
```

## 目录结构

```
minimal-plugin/
├── .claude-plugin/
│   └── plugin.json      # [IR-1] 仅 manifest
├── skills/
│   └── hello/
│       └── SKILL.md     # [IR-2] CSO 合规 description
└── README.md
```
