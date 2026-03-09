# Plugin 模式选择指南

> **职责**：根据需求选择正确的组件组合模式。按需加载——规划新 Plugin 时阅读。

## 速查卡片

| 目标 | 推荐模式 | 核心组件 |
|------|---------|---------|
| 注入领域知识 | 模式 1：单 Skill 知识库 | `skills/` + `knowledge/` |
| 给 LLM 加工具 + 判断力 | 模式 2：MCP + Skill 引导 | `.mcp.json` + `skills/` |
| 一组实用命令 | 模式 3：Command 集合 | `commands/` |
| 自动化质量门禁 | 模式 4：Hook 增强工作流 | `hooks/` + `rules/` |
| 完整开发平台 | 模式 5：完整平台插件 | 全部组件类型 |
| 可复用规则包 | 模式 6：Skill + 资源包 | `skills/` + `rules/` + `knowledge/` |

---

## 模式 1：单 Skill 知识库

**适用场景**：需要让 Claude 掌握特定领域的规范、流程或决策框架。

**核心结构**：
```
my-plugin/
├── .claude-plugin/plugin.json
├── skills/domain-expert/
│   ├── SKILL.md              # 触发条件 + 路由
│   └── domain-procedures.md  # 详细规则和步骤
└── knowledge/                # 参考资料（按需加载）
```

**选择信号**：用户说"帮我按 XX 规范做"、"检查是否符合 XX 标准"。

**案例**：代码规范检查器、API 设计指南、安全审查助手。

---

## 模式 2：MCP + Skill 引导

**适用场景**：MCP Server 提供外部能力（搜索、数据库、API），Skill 提供何时/如何使用这些能力的判断力。

**核心洞察**：MCP 给 Claude 工具，Skill 给 Claude 判断力。没有 Skill 引导的 MCP 工具容易被误用或闲置。

**核心结构**：
```
my-plugin/
├── .claude-plugin/plugin.json
├── .mcp.json                     # 或 plugin.json mcpServers 内嵌
├── skills/smart-search/
│   └── SKILL.md                  # 引导何时/如何调用 MCP 工具
└── rules/mcp-usage-rules.md      # MCP 工具使用约束
```

**选择信号**：需要连接外部系统、已有 MCP Server 但 Claude 不会正确使用。

---

## 模式 3：Command 集合

**适用场景**：一组明确的、用户手动触发的操作，不需要 Claude 自动判断何时执行。

**核心结构**：
```
my-plugin/
├── .claude-plugin/plugin.json
└── commands/
    ├── init.md
    ├── validate.md
    └── report.md
```

**选择信号**：操作由用户主动发起、每个操作是独立的一次性动作、不需要自动触发。

**与 Skill 的区别**：Command 只能用户手动 `/plugin:cmd` 触发；Skill 可被 Claude 自动激活。

---

## 模式 4：Hook 增强工作流

**适用场景**：需要确定性地拦截、审查或增强 Claude 的操作，尤其是安全关键场景。

**核心结构**：
```
my-plugin/
├── .claude-plugin/plugin.json
├── hooks/
│   ├── hooks.json
│   └── check-safety.sh
└── rules/safety-rules.md        # 文本层补充说明
```

**选择信号**：有不可绕过的安全约束、需要自动化审查门禁、要拦截特定工具调用。

**关键设计**：三重保险——Hook exit 2 阻断（确定性）+ rules 声明（声明性）+ Skill 说明（指令性）。

---

## 模式 5：完整平台插件

**适用场景**：面向特定开发场景的完整解决方案，覆盖从规范到执行到验证的全流程。

**核心结构**：
```
my-plugin/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── skills/          # 复杂工作流
├── commands/        # 快捷操作
├── agents/          # 专业化子 Agent
├── hooks/           # 安全和质量门禁
├── rules/           # 行为约束（自动加载）
├── knowledge/       # 参考资料
└── .mcp.json        # 外部工具集成
```

**选择信号**：需要多种组件协同、有复杂的多步工作流、需要专业化的子 Agent。

**注意**：从简单模式演进而来，不建议一开始就用模式 5。

---

## 模式 6：Skill + 资源包

**适用场景**：提供可复用的规则和知识体系，Skill 负责路由和应用这些资源。

**核心结构**：
```
my-plugin/
├── .claude-plugin/plugin.json
├── skills/apply-standards/
│   └── SKILL.md
├── rules/                    # 自动加载的行为规则
│   ├── coding-standards.md
│   └── review-checklist.md
└── knowledge/                # 按需加载的参考资料
    └── style-guide.md
```

**选择信号**：团队规范统一、跨项目复用标准、需要 rules 自动加载 + knowledge 按需加载。

---

## 决策树

```
你的需求是什么？
├── 让 Claude 掌握领域知识？
│   └── 模式 1：单 Skill 知识库
├── 连接外部系统/工具？
│   └── 模式 2：MCP + Skill 引导
├── 一组用户手动操作？
│   └── 模式 3：Command 集合
├── 拦截/审查 Claude 操作？
│   └── 模式 4：Hook 增强工作流
├── 统一团队规范？
│   └── 模式 6：Skill + 资源包
└── 以上多项组合？
    └── 模式 5：完整平台插件
```

## 模式组合演进

**从简单开始，按需增长**：

```
模式 1（知识库）
  + 安全门禁需求 -> 加 Hook（模式 1+4）
  + 外部工具需求 -> 加 MCP（模式 1+2）
  + 快捷操作需求 -> 加 Command（模式 1+3）
  + 专业分工需求 -> 加 Agent（-> 模式 5）
```

**反模式**：一开始就选模式 5，组件过多但大部分空壳。先用最简模式验证核心价值，再按需增长。
