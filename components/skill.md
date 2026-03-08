# Skill 规范

> **职责**：SKILL.md 的创建、frontmatter 配置、CSO 规则、分拆模式和验证。按需加载——创建或修改 Skill 时阅读。

## 速查卡片

| 任务 | 章节 |
|------|------|
| 创建新 Skill | Part 2 > 目录结构 + Frontmatter + 内容组织 |
| 修改 description | Part 1 > IR-2（CSO 规则） |
| 拆分大 Skill | Part 2 > 分拆模式 |
| 添加 Skill 级 Hook | Part 2 > Skill Hooks |
| 配置子 Agent 执行 | Part 2 > Context Fork |
| 使用字符串替换 | Part 2 > 参数替换 |

---

## Part 1: Rules（WHY / WHAT）

### IR-2：Description = 触发条件（CSO 原则）

**规则**：SKILL.md 的 `description` 字段仅写"何时触发"，不写"做什么"。

**原理**：`description` 是 Claude 判断是否激活 Skill 的唯一依据。如果 description 摘要了完整工作流，Claude 可能根据摘要直接行动而跳过阅读完整 SKILL.md 内容。

**编写规则**：

| 规则 | 正确示例 | 错误示例 |
|------|---------|---------|
| 只写"何时触发" | `Use when user wants to track requirement changes` | `Analyzes impact, creates triage report, updates status` |
| 开头用 "Use when" | `Use when entering development mode for a CR` | `Development mode skill for CR lifecycle` |
| 包含具体触发关键词 | `Use when user says "开始做/帮我改/实现/修复"` | `Handles code implementation tasks` |
| 避免描述内部步骤 | `Use when CR needs quality review` | `Runs Gate 2 checks, generates diff summary` |
| 300 字符以内 | 简洁触发条件 | 长篇描述 |

### AP-1：全知 Description `违反 IR-2`

- **症状**：Claude 执行 Skill 但跳过关键步骤
- **根因**：`description` 摘要了完整工作流，Claude 据此直接行动而不加载完整 SKILL.md 内容
- **修复**：重写 `description` 为仅触发条件
- **检测**：检查 `description` 是否包含动词序列

### AP-2：巨石 Skill `违反 P2, P5`

- **症状**：上下文压力大，混淆理论与指令
- **根因**：单个 SKILL.md 800+ 行，混合多种内容
- **修复**：拆分为 SKILL.md（< 200 行）+ procedures + knowledge
- **检测**：`wc -l skills/*/SKILL.md` 超过 500 行需评估

### AP-3：幽灵 Frontmatter `违反 IR-3`

- **症状**：预期行为不生效（如 `priority: high` 无效果）
- **根因**：使用了未记录的 frontmatter 字段
- **修复**：仅使用官方合法字段。额外元数据放在内容体中
- **检测**：对照合法字段列表审查所有 frontmatter

---

## Part 2: Spec（HOW）

### 目录结构

每个 Skill 是 `skills/<name>/` 目录，目录名即 Skill 名称：

```
skills/
└── my-skill/
    ├── SKILL.md              # 入口文件（必需）
    ├── main-procedures.md    # 详细步骤（可选）
    ├── review-procedures.md  # 另一组步骤（可选）
    └── helper-script.sh      # 辅助脚本（可选）
```

### Frontmatter 字段完整表

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 否 | 显示名称（省略则用目录名） |
| `description` | string | 推荐 | 触发条件描述（见 IR-2 CSO 规则） |
| `argument-hint` | string | 否 | 自动补全时的参数提示 |
| `allowed-tools` | string | 否 | 激活时免确认的工具，逗号分隔 |
| `model` | string | 否 | `sonnet` / `opus` / `haiku` |
| `disable-model-invocation` | boolean | 否 | `true` = 仅用户可调用 |
| `user-invocable` | boolean | 否 | `false` = 从 `/` 菜单隐藏 |
| `context` | string | 否 | `fork` = 在子 agent 上下文中运行 |
| `agent` | string | 否 | 当 `context: fork` 时使用的 agent 类型 |
| `hooks` | object | 否 | 作用域为此 Skill 的 Hook 配置 |

**铁律提醒**：仅使用以上官方字段，禁止添加未记录字段 `[IR-3]`。

### 内容组织（章节顺序）

```
# /skill-name -- 标题
[1-2 行用途说明]

## 与现有机制的关系    <- 可选
## 推荐使用流程        <- 可选
## 输入
## 流程
## 输出
```

**内容类型原则**：SKILL.md 只放"做什么"（路由逻辑），不放"怎么做"（详细步骤）和"为什么"（背景知识）。

### 分拆模式

当详细规则超过 ~50 行时，拆分为：
- **SKILL.md**：输入/输出/高层步骤/路由表（"做什么"）
- ***-procedures.md**：详细步骤和规则（"怎么做"）

#### 按需加载路由

SKILL.md 中使用路由表按状态/子命令加载对应 procedures：

```markdown
## 流程

根据输入子命令加载对应 procedures：

| 子命令 | Procedures 文件 | 说明 |
|--------|----------------|------|
| start  | start-procedures.md | 启动开发模式 |
| review | review-procedures.md | 代码审查 |
| done   | done-procedures.md | 完成交付 |
```

#### Token 预算

Token 预算详见 `common/rules.md` Token 预算节。关键限制：description < 300 字符，SKILL.md < 500 行，单次加载总量 < 800 行。

### Skill 级 Hooks

SKILL.md frontmatter 的 `hooks` 字段支持仅在该 Skill 激活时生效的 Hook：

```yaml
hooks:
  PreToolUse:
    - matcher:
        tool_name: "Write|Edit"
      hooks:
        - type: prompt
          prompt: "验证此写入操作是否符合当前 Skill 的约束..."
          timeout: 15
```

Skill 级 Hook 与全局 hooks.json 互补——全局做通用检查，Skill 级做精细控制。

### Context Fork 模式

当 `context: fork` 设置时，Skill 在子 agent 上下文中执行：
- 子 agent 拥有独立的上下文窗口
- 执行完毕后返回变更摘要
- 通过 `agent` 字段指定使用的 agent 类型

```yaml
---
name: heavy-analysis
description: Use when deep code analysis is needed
context: fork
agent: code-analyzer
---
```

如果 fork 不可用，Skill 应静默回退到内联执行。

### 参数替换

SKILL.md 内容中可使用以下变量：

| 变量 | 说明 | 示例 |
|------|------|------|
| `$ARGUMENTS` | 全部参数 | `/skill arg1 arg2` -> `arg1 arg2` |
| `$0` | 第一个参数 | `/skill start` -> `start` |
| `$1` | 第二个参数 | `/skill start CR-01` -> `CR-01` |
| `` !`command` `` | 预处理器：执行 shell 命令替换输出 | `` !`date` `` -> `2025-01-15` |

### 验证清单

```
[ ] 每个 description 仅写触发条件，不写行为步骤                       [IR-2]
[ ] description < 300 字符                                           [P5]
[ ] SKILL.md < 500 行（超过则拆分 procedures）                       [P2]
[ ] 仅使用官方 frontmatter 字段                                       [IR-3]
[ ] 复杂 Skill 已拆分 SKILL.md + *-procedures.md                     [P2+P5]
[ ] allowed-tools 仅含该 Skill 实际需要的工具                         [P5]
```
