# 跨组件铁律与共享约束

> **职责**：跨组件通用的铁律（IR-3,5,7,8,9）和所有组件共享的通用约束。会话开始时**自动加载**。
> 组件专属铁律：IR-1（plugin.md）、IR-2（skill.md）、IR-4,6（hook.md）——位于各组件文件。

## IR-3：仅使用官方 Frontmatter 字段

**规则**：SKILL.md、Agent 定义、Command 文件的 frontmatter 中，仅使用官方文档明确记录的字段。未记录的字段被静默忽略，开发者以为字段生效，实际上无任何效果。

**查证**：不确定时使用 `Task(subagent_type="claude-code-guide", prompt="查询 [具体字段]")` 或查阅官方文档。各组件合法字段列表见对应组件文件 Spec 层。

## IR-5：路径必须相对

**规则**：`plugin.json` 和 Hook 配置中的所有路径必须使用相对路径，且以 `./` 开头。Hook 脚本中使用 `${CLAUDE_PLUGIN_ROOT}` 引用 Plugin 根目录。

**正确**：`"./skills/my-skill"`, `"./hooks/check.sh"`
**错误**：`"/Users/dev/project/skills/"`, `"skills/"`, `"hooks/check.sh"`

## IR-7：产出必须符合契约

**规则**：当 Plugin 定义了 Schema 文件（如 `_schema/` 目录），Skill 输出必须严格符合 Schema 定义。写方不遵守契约，读方解析失败，数据链断裂。

## IR-8：plugin.json 必须与文件系统同步

**规则**：新增或删除 Skill、Agent、Hook 后，必须立即更新 `plugin.json`。文件系统中不存在的组件不得出现在 plugin.json 中。新增组件不被加载，删除组件残留幽灵引用。

## IR-9：禁止猜测，必须查证

**规则**：对不确定的 API、frontmatter 字段、机制行为，必须通过以下方式查证：

1. `Task(subagent_type="claude-code-guide", prompt="查询 [具体问题]")`
2. 官方文档：`https://code.claude.com/docs/en/`
3. `claude --debug` 查看加载日志

---

## 跨组件共享约束

### 命名规范

| 组件 | 命名规则 | 示例 |
|------|---------|------|
| Skill 目录 | kebab-case | `skills/my-feature/` |
| SKILL.md | 固定文件名（大写） | `skills/my-feature/SKILL.md` |
| Procedures 文件 | `*-procedures.md` | `skills/my-feature/main-procedures.md` |
| Agent 文件 | kebab-case `.md` | `agents/code-reviewer.md` |
| Hook 脚本 | kebab-case，带扩展名 | `hooks/check-safety.sh` |
| Command 文件 | kebab-case `.md` | `commands/validate.md` |
| Rules 文件 | kebab-case `.md` | `rules/main-rules.md` |
| Knowledge 文件 | kebab-case `.md` | `knowledge/theory.md` |

**一致性要求**：同一项目内不混合命名风格。Skill 目录名即 Skill 名称，也用于命名空间（`plugin-name:skill-name`）。

### 分层隔离

| 层次 | 典型目录 | 分发 |
|------|---------|------|
| 运行时层 | `rules/`、`skills/`、`knowledge/`、manifest 目录 | 随 Plugin 分发 |
| 开发层 | `.claude/`、`docs/`、`tests/`、`scripts/` | 不分发 |

**强制约束**：运行时层文件不得引用开发层路径。

### 同步要求

新增或删除任何组件后，必须立即同步 `plugin.json` `[IR-8]`。当同一信息在多个文件中出现时：明确声明一个文件为**权威来源**，其他文件标注为**派生**。

### Token 预算

| 文件类型 | 预算建议 |
|---------|---------|
| 单个 rules 文件 | < 200 行 |
| rules/ 目录总计 | < 600 行 |
| SKILL.md | < 500 行 |
| Skill description | < 300 字符 |
| 单次 Skill 加载总量 | < 800 行 |

### 配置优先级

```
managed settings（最高）
  -> .claude/settings.json（项目共享，提交到 git）
      -> .claude/settings.local.json（项目本地，不提交）
          -> ~/.claude/settings.json（全局）
              -> Plugin hooks/hooks.json（最低）
```
