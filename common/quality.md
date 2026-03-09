# 验证框架与质量标准

> **职责**：Plugin 发布前的验证框架、验证命令库、RED-GREEN-REFACTOR 方法论和官方工具。按需加载——发布前验证时阅读。
> 组件专用验证清单见各组件文件。

## 结构验证（5 项）

```
[ ] .claude-plugin/ 仅含 plugin.json + marketplace.json              [IR-1]
[ ] 所有组件目录（skills/、agents/、hooks/、rules/）在 Plugin 根目录   [IR-1]
[ ] plugin.json 路径相对且以 ./ 开头                                  [IR-5]
[ ] plugin.json 与文件系统同步（无幽灵引用、无遗漏组件）               [IR-8]
[ ] 分发资产（rules/、skills/、knowledge/）不引用内部开发路径           [P1]
```

## 契约验证（4 项）

```
[ ] 共享状态文件有对应 Schema（knowledge/_schema/ 或类似目录）         [P10]
[ ] Schema 在独立目录，不嵌入 Skill 内容中                            [P10]
[ ] Skill 输出符合 Schema 定义（字段名、类型、必填项一致）             [IR-7]
[ ] Schema 变更时记录了受影响的 Skill 列表                            [P10]
```

## 质量验证（4 项）

```
[ ] rules/ 文件总计 < 600 行                                          [P5]
[ ] 铁律配有反合理化清单（列举常见绕过借口及回应）                      [P9]
[ ] 广泛引用的文件（theory、schema、rules）变更频率低                   [P3]
[ ] 自动化测试覆盖结构合规性（如有测试框架）                           [P7]
```

---

## 验证命令库

```bash
# [P1, IR-1] Manifest 隔离 + 分层隔离
ls .claude-plugin/                                        # 预期：仅 plugin.json / marketplace.json
grep -r "docs/\|\.claude/" rules/ skills/ knowledge/      # 预期：空结果

# [IR-5, IR-8] 路径 + 同步
grep -E '"\./' .claude-plugin/plugin.json                 # 所有路径应以 ./ 开头
diff <(jq -r '.skills[]?' .claude-plugin/plugin.json | sort) <(ls skills/ | sort)

# [P2] 抽象分层
wc -l skills/*/SKILL.md                                   # 单个 SKILL.md < 500 行

# [P3] 稳定性
git log --oneline --since="1 month" -- knowledge/_schema/ rules/

# [P5] Token 预算
wc -l rules/*.md | tail -1                                # 总计 < 600 行

# 验证回路：变更 -> claude --plugin-dir ./ -> 手动触发 -> /plugin validate -> git commit
```

---

## RED-GREEN-REFACTOR 验证方法论

Skill 内容质量的验证方法论，推荐在 Skill 新增或重大修改时使用。

1. **RED**（基线观测）：禁用目标 Skill（重命名 SKILL.md），用 2+ 场景记录无 Skill 时的行为偏差
2. **GREEN**（最小规则）：一条规则修正一个偏差，启用 Skill 重新验证
3. **REFACTOR**（漏洞补充）：S/M/L 三种复杂度场景测试，关注长会话中的"合理化"跳过

---

## 测试迭代流程

### Dev Marketplace 安装

本地开发测试的标准循环：

```bash
# 1. 注册到本地 dev marketplace（使用绝对路径）
/plugin marketplace add /absolute/path/to/my-plugin

# 2. 安装（格式：name@name-dev）
/plugin install my-plugin@my-plugin-dev

# 3. 重启 Claude Code 使变更生效

# 4. 测试 -> 修改 -> 按需重启 -> 重复
```

### 组件测试矩阵

| 组件 | 测试方法 | 验证标准 |
|------|---------|---------|
| Skill | 输入触发关键词 | description 匹配触发、步骤完整执行 |
| Command | `/plugin-name:cmd` 调用 | 出现在 `/` 菜单、执行正确 |
| Hook | 触发目标事件 | exit 2 阻断生效、exit 0 放行 |
| Agent | `Task(subagent_type="name")` | 响应正确、工具限制生效 |
| MCP | 调用 MCP 工具 | Server 启动、工具可用 |
| Rules | 新会话检查 | 规则自动加载、约束生效 |

### 变更生效规则

| 变更类型 | 是否需要重启 |
|---------|-------------|
| Skill / Command 内容 | 否（下次触发自动重载） |
| Hook 脚本内容 | 否（每次执行重新读取） |
| rules/ / hooks.json / plugin.json / Agent / .mcp.json | 是 |

---

## plugin-dev 官方工具（推荐）

Anthropic 官方 plugin-dev Plugin 提供综合验证能力：

| 工具 | 类型 | 用途 | 使用场景 |
|------|------|------|---------|
| plugin-validator | Agent | 10 步综合验证（Manifest/目录/Skills/Hooks/安全） | 任何 Plugin 结构变更后 |
| skill-reviewer | Agent | Skill 质量审查（description/内容/渐进披露） | Skill 新增或修改后 |
| agent-creator | Agent | AI 辅助 Agent 创建 | 新增 Agent 定义时 |
| `/plugin validate` | Command | 内置命令，验证 plugin.json 基本结构 | 快速检查 |

安装：`/plugin install plugin-dev@claude-plugins-official`。推荐顺序：通用清单 -> `/plugin validate` -> plugin-validator Agent -> skill-reviewer Agent。
