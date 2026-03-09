# Full Plugin 行为规则

> 此文件在会话开始时自动加载。

## 核心约束

1. **Manifest 隔离** `[IR-1]`：`.claude-plugin/` 仅放 manifest，组件在 Plugin 根目录
2. **路径规范** `[IR-5]`：所有路径相对且以 `./` 开头
3. **同步要求** `[IR-8]`：新增/删除组件后立即更新 plugin.json

## 安全规则

- 不写入 `.env`、`credentials` 等敏感文件（由 Hook 强制执行）
- 不在 `.claude-plugin/` 内创建非 manifest 文件（由 Hook 强制执行）
