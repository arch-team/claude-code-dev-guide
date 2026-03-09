# Plugin 开发生命周期

> **职责**：从零到发布的 6 阶段开发流程。按需加载——首次开发或回顾流程时阅读。

## 速查卡片

| 阶段 | 关键动作 | 产出 |
|------|---------|------|
| 1. 规划 | 选模式、定组件清单 | 组件清单 + 模式选择 |
| 2. 骨架 | mkdir + plugin.json + marketplace.json | 可加载的空 Plugin |
| 3. 开发 | 逐组件实现 + 同步 plugin.json | 功能完整的 Plugin |
| 4. 测试 | marketplace add + install + 验证 | 通过测试的 Plugin |
| 5. 调试 | 诊断树 + 6 步调试法 | 修复所有问题 |
| 6. 发布 | 版本号 + git tag + 分发 | 可安装的 Plugin |

---

## 阶段 1：规划

**目标**：明确需要哪些组件、选择哪种模式。

**步骤**：
1. 阅读 `common/patterns.md` 选择 Plugin 模式
2. 列出需要的组件清单（Skill / Command / Hook / Agent / MCP）
3. 为每个 Skill 起草 description（仅触发条件）`[IR-2]`
4. 用 TodoWrite 记录组件清单，作为开发追踪基线

**产出**：组件清单表

| 组件 | 类型 | 名称 | 用途 |
|------|------|------|------|
| 示例 | Skill | `code-review` | 代码审查工作流 |
| 示例 | Hook | `check-write` | 写入安全检查 |

---

## 阶段 2：创建骨架

**目标**：创建最小可加载的 Plugin 结构。

**步骤**：
1. 创建目录结构：
```bash
mkdir -p my-plugin/.claude-plugin
mkdir -p my-plugin/skills my-plugin/commands  # 按需创建
```

2. 创建 `plugin.json`（最小版本）：
```json
{
  "name": "my-plugin"
}
```

3. 创建 `marketplace.json`（本地测试用）：
```json
{
  "name": "my-plugin",
  "description": "Plugin 描述",
  "authors": [{"name": "Developer"}],
  "marketplace": {"tags": ["development"]}
}
```

**验证**：此时 Plugin 应可被加载（虽然无功能）。

**关键约束**：
- `.claude-plugin/` 仅放 manifest 文件 `[IR-1]`
- 所有组件目录在 Plugin 根目录 `[IR-1]`

---

## 阶段 3：逐步开发

**目标**：逐组件实现功能，保持 plugin.json 同步。

**推荐顺序**：
1. `rules/` — 行为约束（会话开始自动加载，最先验证）
2. `skills/` — 核心工作流（Skill 是大多数 Plugin 的核心价值）
3. `commands/` — 快捷操作（独立性强，易于测试）
4. `hooks/` — 安全门禁（需要先有要保护的操作）
5. `agents/` — 专业分工（需要先有可委派的任务）
6. `knowledge/` — 参考资料（Skill 引用时按需添加）

**每个组件完成后**：
- 更新 `plugin.json` 保持同步 `[IR-8]`
- 运行组件级验证（见阶段 4 测试矩阵）
- TodoWrite 更新进度

**开发检查点**：
```
[ ] Skill description 仅写触发条件          [IR-2]
[ ] 所有路径以 ./ 开头                      [IR-5]
[ ] 仅使用官方 frontmatter 字段             [IR-3]
[ ] plugin.json 已更新                      [IR-8]
```

---

## 阶段 4：本地测试

**目标**：在本地完整验证 Plugin 功能。

### Dev Marketplace 安装循环

```bash
# 1. 注册到本地 dev marketplace
/plugin marketplace add /absolute/path/to/my-plugin

# 2. 安装（name@name-dev 格式）
/plugin install my-plugin@my-plugin-dev

# 3. 重启 Claude Code 使 Plugin 生效

# 4. 验证 -> 修改 -> 根据变更类型决定是否重启 -> 重复
```

### 组件测试矩阵

| 组件 | 测试方法 | 验证标准 |
|------|---------|---------|
| Skill | 输入触发关键词，观察是否激活 | description 匹配触发、完整步骤执行 |
| Command | `/plugin-name:cmd-name` 手动调用 | 命令出现在 `/` 菜单、执行正确 |
| Hook | 触发目标事件，观察 exit code | exit 2 阻断生效、exit 0 放行正确 |
| Agent | `Task(subagent_type="name")` 调用 | Agent 响应正确、工具限制生效 |
| MCP | 调用 MCP 工具 | Server 启动成功、工具可用 |
| Rules | 开始新会话，检查规则加载 | 规则自动加载、行为约束生效 |

### 变更生效规则

| 变更类型 | 是否需要重启 |
|---------|-------------|
| Skill 内容修改 | 否（下次触发时自动重新加载） |
| Command 内容修改 | 否（下次调用时自动重新加载） |
| rules/ 文件修改 | 是（会话开始时加载） |
| hooks.json 修改 | 是 |
| Hook 脚本内容修改 | 否（每次执行时重新读取） |
| plugin.json 修改 | 是 |
| Agent 定义修改 | 是 |
| .mcp.json 修改 | 是 |

---

## 阶段 5：调试

**目标**：定位和修复 Plugin 问题。

**首先**：参考 `common/anti-patterns.md` 诊断决策树定位问题类型。

**6 步调试法**：

1. **验证 JSON**：`jq . .claude-plugin/plugin.json` — 语法错误是最常见原因
2. **检查路径**：`grep -r "/Users/\|/home/" .` — 搜索绝对路径 `[IR-5]`
3. **验证权限**：`ls -la hooks/*.sh` — 脚本需要执行权限
4. **独立测试**：逐个组件测试，隔离问题范围
5. **干净重装**：卸载 -> 重新 marketplace add -> install -> 重启
6. **查看日志**：`claude --debug` 查看详细加载日志

**常见问题速查**：

| 症状 | 首先检查 |
|------|---------|
| Plugin 不被发现 | plugin.json 是否在 .claude-plugin/ 内 |
| Skill 不触发 | description 是否包含匹配的触发关键词 |
| Hook 静默失效 | 事件名 PascalCase 是否正确 `[IR-6]` |
| Command 不出现 | frontmatter 是否包含非法 `name` 字段 |

---

## 阶段 6：发布与分发

**目标**：将 Plugin 打包并分发给用户。

### 语义化版本

在 `plugin.json` 中设置版本号：
```json
{
  "name": "my-plugin",
  "version": "1.0.0"
}
```

版本约定：`MAJOR.MINOR.PATCH`（重大变更.新功能.修复）。

### Git Tag

```bash
git tag v1.0.0
git push origin v1.0.0
```

### 3 种分发方式

| 方式 | 安装命令 | 适用场景 |
|------|---------|---------|
| GitHub 直接安装 | `/plugin install gh:user/repo` | 开源 Plugin |
| Marketplace 发布 | `/plugin install name@marketplace` | 公开发布 |
| 团队私有分发 | `/plugin marketplace add /path` | 团队内部使用 |

**GitHub 直接安装**：用户通过 GitHub 仓库地址直接安装。

**Marketplace 发布**：需要 `marketplace.json` 元数据文件，提交到官方 Marketplace。

**团队私有分发**：通过本地路径或私有 Git 仓库共享。

### 发布前验证

```bash
# 结构验证
ls .claude-plugin/                                    # 仅 plugin.json + marketplace.json
jq . .claude-plugin/plugin.json                       # JSON 语法正确

# 路径验证
grep -r "/Users/\|/home/" .                           # 应返回空

# Token 预算
wc -l rules/*.md | tail -1                            # < 600 行

# 完整验证（如已安装 plugin-dev）
/plugin validate
```
