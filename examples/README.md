# 示例 Plugin 索引

可运行的示例 Plugin，展示 DevGuide 规范的实际应用。

## 示例列表

| 示例 | 模式 | 展示重点 |
|------|------|---------|
| `minimal-plugin/` | 模式 1：单 Skill 知识库 | 最小可运行结构、CSO description、IR 合规 |
| `full-plugin/` | 模式 5：完整平台插件 | 全组件协同、跨平台 Hook、Agent 配置 |

## 安装测试

```bash
# 最小示例
/plugin marketplace add /path/to/examples/minimal-plugin
/plugin install minimal-plugin@minimal-plugin-dev

# 完整示例
/plugin marketplace add /path/to/examples/full-plugin
/plugin install full-plugin@full-plugin-dev
```

## 注意事项

- 示例从零编写，展示 DevGuide 特有约定（IR 注释、CSO description、三重保险）
- 每个示例可通过 dev marketplace 直接安装测试
- 修改示例后参照 `common/workflow.md` 阶段 4 的变更生效规则
