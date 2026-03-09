# Hook 规范

> **职责**：Hook 事件、类型、exit code 协议、脚本开发、配置和调试。按需加载——添加或调试 Hook 时阅读。

## 速查卡片

| 任务 | 章节 |
|------|------|
| 了解可用事件 | Part 2 > 事件完整表 |
| 选择 Hook 类型 | Part 2 > Hook 类型 |
| 编写 Hook 脚本 | Part 2 > 脚本开发 |
| 配置 Hook | Part 2 > 配置文件 |
| Skill 级 Hook | Part 2 > Skill 级 Hook |
| 调试 Hook 问题 | Part 2 > 调试技巧 |

---

## Part 1: Rules（WHY / WHAT）

### IR-4：安全约束必须 Hook 强制执行

**规则**：安全关键约束不能仅靠文本规则。必须配合 Hook（exit 2 阻断）实现确定性执行。

**原理**：LLM 有"合理化绕过"倾向——当规则复杂或模糊时，Claude 会构造听起来合理的理由跳过规则。

**三重保险模式（推荐）**：
```
第 1 层（确定性）：Hook PreToolUse -> 检测违规操作 -> exit 2 阻断
第 2 层（声明性）：rules.md 声明铁律 -> 明确不可绕过
第 3 层（指令性）：Skill procedures 说明规则 + 反合理化清单
```

### IR-6：Hook 事件名大小写敏感

**规则**：Hook 事件名使用精确的 PascalCase。拼写或大小写错误会导致 Hook 静默不触发，不会报错。

**常见错误**：`pretooluse`、`preToolUse`、`pre_tool_use` -> 全部无效

### 确定性分级

| 级别 | 标记 | 执行机制 | 适用场景 |
|------|------|---------|---------|
| 最高 | MUST / iron rule | Hook command + exit 2 | 安全关键操作、不可逆操作 |
| 高 | MUST | Hook prompt/agent | 需要语义理解的检查 |
| 中 | SHOULD | Skill 指令 + 铁律标记 | 工作流约束 |
| 基线 | RECOMMENDED | Rules 文本建议 | 行为规范、风格指引 |

### AP-4：纸板门禁 `违反 IR-4`

- **症状**：安全规则被 Claude 绕过，关键操作未被拦截
- **根因**：关键约束仅靠 rules 文本声明，无 Hook 确定性执行层
- **修复**：添加 Hook exit 2 确定性阻断。推荐三重保险模式
- **检测**：列出所有安全铁律，检查每条是否有对应 Hook

### AP-8：大小写盲 Hook `违反 IR-6`

- **症状**：Hook 配置存在但从不触发，无任何错误提示
- **根因**：事件名大小写错误（如 `pretooluse`、`preToolUse`）
- **修复**：使用精确 PascalCase（完整事件列表见 Part 2 事件表）
- **检测**：对照事件完整表逐一比对

### AP-12：纯文本安全 `违反 IR-4`

- **症状**：Claude 在复杂推理链中合理化绕过安全规则
- **根因**：多条文本安全规则，但无确定性执行层
- **修复**：Hook command + exit 2 作为最后防线。文本规则作为辅助说明
- **检测**：审查安全相关 rules，确认每条关键约束有对应 Hook

---

## Part 2: Spec（HOW）

### 事件完整表

| 事件名 | 触发时机 | 可阻断 | 典型用途 |
|--------|---------|--------|---------|
| `PreToolUse` | 工具执行前 | 是（exit 2） | 阻止危险操作、验证参数 |
| `PostToolUse` | 工具执行成功后 | 否 | 记录操作日志、触发后续动作 |
| `PostToolUseFailure` | 工具执行失败后 | 否 | 错误追踪、重试逻辑 |
| `UserPromptSubmit` | 用户提交 prompt | 是 | 输入过滤、上下文注入 |
| `PreCompact` | 上下文压缩前 | 否 | 保存关键上下文 |
| `Stop` | Claude 完成响应 | 是 | 质量检查、自动后处理 |
| `SessionStart` | 会话开始 | 否 | 环境初始化、状态加载 |
| `SessionEnd` | 会话结束 | 否 | 清理、状态保存 |
| `SubagentStart` | 子 agent 启动 | 部分 | 子 agent 环境准备 |
| `SubagentStop` | 子 agent 停止 | 部分 | 子 agent 结果处理 |
| `TeammateIdle` | 队友空闲 | 是（exit 2） | 任务调度 |
| `TaskCompleted` | 任务完成 | 是（exit 2） | 任务验收 |

**铁律提醒** `[IR-6]`：事件名严格 PascalCase 大小写敏感。

### Hook 类型

#### command 类型

执行 shell 命令，通过 stdin 接收 JSON 输入。最常用的类型。

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": { "tool_name": "Write|Edit" },
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/check-write.sh"
          }
        ]
      }
    ]
  }
}
```

支持 `"async": true`（后台执行，不阻塞主流程）。

#### prompt 类型

LLM 评估 prompt 内容决定是否放行（超时默认 30s）。适合语义理解检查：`{"type": "prompt", "prompt": "验证此操作是否安全...", "timeout": 15}`

#### agent 类型

LLM agent 执行，有工具访问权限（超时默认 60s）。比 prompt 更强大——可读取文件、搜索代码：`{"type": "agent", "prompt": "检查此修改是否符合架构规范...", "timeout": 30}`

### 脚本开发

#### Exit Code 协议

| Exit Code | 含义 | 行为 |
|-----------|------|------|
| 0 | 成功（放行） | 操作继续 |
| 2 | 阻断（确定性拒绝） | 操作被阻止，stderr 信息显示给 Claude |
| 其他 | 非阻断错误 | 操作继续，错误信息记录 |

#### 脚本模板

```bash
#!/bin/bash
# Hook: PreToolUse - 检查写入安全性

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ "$FILE_PATH" == *".env"* ]] || [[ "$FILE_PATH" == *"credentials"* ]]; then
  echo "BLOCKED: 不允许写入敏感文件: $FILE_PATH" >&2
  exit 2
fi

exit 0
```

#### 必要条件

1. **Shebang**：首行必须有 `#!/bin/bash` 或 `#!/usr/bin/env node` 等
2. **执行权限**：`chmod +x hooks/check-write.sh`
3. **路径引用**：使用 `${CLAUDE_PLUGIN_ROOT}` 引用 Plugin 根目录 `[IR-5]`

### 配置文件

hooks.json 结构与上方 command 类型示例相同：`{ "hooks": { "EventName": [{ "matcher": {...}, "hooks": [...] }] } }`。

配置优先级见 `common/rules.md` 配置优先级节。各层级的 Hook 互相补充，不覆盖。

### Skill 级 Hook

在 SKILL.md frontmatter 的 `hooks` 字段中定义，仅在该 Skill 激活时生效。完整 YAML 示例见 `skill.md` Skill Hooks 节。

**设计模式**：全局 hooks.json 做通用安全检查；Skill 级 hooks 做 Skill 特定的精细控制。

### 调试技巧

| 问题 | 可能原因 | 排查方法 |
|------|---------|---------|
| Hook 不触发 | 事件名大小写错误 | 检查是否精确匹配 PascalCase |
| Hook 不触发 | 脚本无执行权限 | `chmod +x script.sh` |
| Hook 不触发 | 缺少 shebang | 添加 `#!/bin/bash` |
| Hook 不触发 | matcher 不匹配 | 检查 `tool_name` 正则是否正确 |
| Hook 阻断无效 | 使用了 exit 1 而非 exit 2 | 阻断必须用 exit 2 |
| Hook 报错但不阻断 | 非 exit 2 的错误码 | 仅 exit 2 是确定性阻断 |

### 跨平台 Hook（polyglot 包装器）

#### 问题

Windows CMD 无法直接执行 `.sh` 脚本，导致 Hook 静默失效——无报错但不执行。macOS/Linux 用户不受影响，但分发给团队时需要兼容 Windows。

#### 解决方案：run-hook.cmd

使用 CMD + bash 双语法同一文件（polyglot）。CMD 执行上半部分，bash 执行下半部分：

```cmd
: ; # polyglot wrapper -- CMD runs the top half, bash runs the bottom half
: ; # Usage: run-hook.cmd <script-name> [args...]
: ; exec bash "${CLAUDE_PLUGIN_ROOT}/hooks/$1.sh" "${@:2}" <&0 ; exit $?
@echo off
setlocal
set "SCRIPT=%CLAUDE_PLUGIN_ROOT%\hooks\%1.sh"
bash "%SCRIPT%" %2 %3 %4 %5 %6 %7 %8 %9
exit /b %ERRORLEVEL%
```

**执行路径**：
- **bash**（macOS/Linux）：执行 `: ;` 开头的行（`: ;` 是 bash 空操作），`exec bash` 转入目标脚本
- **CMD**（Windows）：跳过 `: ;` 行（`: ` 是 CMD 标签语法，被忽略），执行 `@echo off` 后续部分

#### 文件结构

```
hooks/
├── hooks.json          # command 指向 run-hook.cmd
├── run-hook.cmd        # polyglot 包装器
├── check-write.sh      # 实际 Hook 逻辑
└── check-safety.sh     # 更多 Hook 脚本...
```

**hooks.json 配置**（指向包装器）：
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": { "tool_name": "Write|Edit" },
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd check-write"
      }]
    }]
  }
}
```

#### 跨平台脚本编写规则

Hook 脚本（`.sh`）应遵循以下规则确保跨平台兼容：

| 规则 | 说明 |
|------|------|
| 纯 bash 内建优先 | 避免依赖 `sed`、`awk` 等外部工具（Windows bash 可能缺失） |
| 使用 `jq` 解析 JSON | `jq` 是唯一推荐的外部依赖（需在系统要求中说明） |
| 路径用 `/` 分隔 | bash 环境下统一使用 POSIX 路径 |
| 避免 `readlink -f` | macOS 不支持，使用 `cd "$(dirname "$0")" && pwd` 替代 |

#### 系统要求

| 平台 | 要求 |
|------|------|
| macOS/Linux | bash（系统自带）、jq（需安装） |
| Windows | Git Bash 或 WSL（提供 bash）、jq（需安装） |

#### 常见问题

| 症状 | 原因 | 修复 |
|------|------|------|
| Windows 上 Hook 不执行 | hooks.json 直接指向 .sh 文件 | 改为指向 run-hook.cmd |
| `exec bash` 报错 | Windows 无 bash 环境 | 安装 Git for Windows（自带 Git Bash） |
| 参数传递丢失 | CMD 参数格式差异 | 确保 .sh 脚本通过 `cat` 读取 stdin 而非参数传递 JSON |

### 验证清单

```
[ ] 安全铁律有对应 Hook 强制执行（exit 2 阻断）                       [IR-4]
[ ] 事件名精确 PascalCase                                             [IR-6]
[ ] 脚本文件有 shebang 行 + 执行权限                                  [IR-6]
[ ] exit 2 用于阻断，exit 0 用于放行                                  [P7]
[ ] 人工审批门禁用 Hook exit 2 而非仅文本规则                          [IR-4]
[ ] 跨平台分发时使用 run-hook.cmd 包装器                              [跨平台]
[ ] Hook 脚本仅依赖 bash 内建 + jq                                   [跨平台]
```
