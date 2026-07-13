# Claude Code 全局配置 — Harness Engineering

> 📌 生效范围: 所有项目
> 📌 仓库: https://github.com/<org>/harness-engineering
> 📌 安装: `git clone https://github.com/<org>/harness-engineering.git ~/.claude/harness && cd ~/.claude/harness && ./install.sh`

---

## <HARD-GATE> 任务入口：触发边界

Harness **仅在有明确的工程动作词时触发**，AI 不替用户决定是否进入流程。

| 用户说了... | 触发 | 进入 |
| --- | --- | --- |
| "设计/方案/分析/架构/选型" | ✅ | harness-entry → 分诊 → brainstorming |
| "审核方案/review设计/方案评审" | ✅ | harness-entry → 分诊 → design-review |
| "写文档/出方案/生成PRD/写设计文档" | ✅ | harness-entry → 分诊 → document-generation |
| "拆任务/排期/里程碑/用户故事" | ✅ | harness-entry → 分诊 → pmo |
| "修bug/调试/报错/不工作" | ✅ | harness-entry → 分诊 → systematic-debugging |
| "review/审查代码" | ✅ | harness-entry → 分诊 → code-review |
| "实现/开发/写代码" | ✅ | harness-entry → 分诊 → implementation |
| "写测试/跑测试/端到端" | ✅ | harness-entry → 分诊 → testing |
| "初始化项目规范/分析工程约定" | ✅ | harness-entry → 分诊 → init |
| 讨论想法/提问/澄清/闲聊 | ❌ | 直接回答，不进 harness |

**关键规则**：用户没说动作词，AI 不得自行启动 harness 流程。

> 触发后的分诊协议（检查 pipeline-state → 分诊/恢复 → 路由领域 skill）、深度档位选择、核心纪律、详细禁止行为，见 `harness-entry` SKILL.md。
</HARD-GATE>

---

## 路径解析规则（三层覆盖）

查找任何模板、规则、脚本、知识库文件时，按以下优先级依次查找，**找到即停**：

```
1. <project>/.harness/        ← 项目覆盖（最高优先级）
2. ~/.claude/harness.local/   ← 公司/组织覆盖
3. ~/.claude/harness/         ← Harness 默认（兜底）
```

| 内容 | 相对路径 | 覆盖语义 |
| --- | --- | --- |
| 核心流水线 | `00-harness-core/` | 同名文件覆盖（通常不覆盖） |
| 详细规则 | `01-rules/` | 同名文件覆盖 |
| 文档模板 | `09-templates/` | 同名文件覆盖 |
| 工具脚本 | `scripts/` | 同名文件覆盖 |
| 变更记录 | `04-changes/` | 🔴 **项目级强制**：变更目录和 pipeline-state.json **必须**写入 `<project>/.harness/04-changes/`，禁止写入 `~/.claude/harness/04-changes/`（全局目录）。详见下方"04-changes/ 写入约束" |
| 知识库 | `docs/` | 三层叠加，按优先级查找 |

---

### 🔴 04-changes/ 写入约束（HARD RULE）

变更目录和 pipeline-state.json **必须写入项目目录**，理由：

1. **多人协作**：pipeline-state 和交付物随 git 仓库共享，团队成员 clone 后即可看到完整流水线状态
2. **跨机器可移植**：换一台机器 clone 项目后，pipeline-state 仍在，可以继续工作
3. **历史归档**：变更记录随项目一起归档，不会因为换电脑丢失

**写入规则**：

| 操作 | 目标路径 |
|---|---|
| 新建变更目录 | `<project>/.harness/04-changes/<YYYYMMDD-需求名>/` |
| 写入 pipeline-state | `<project>/.harness/04-changes/<YYYYMMDD-需求名>/pipeline-state.json` |
| 写入设计文档 | `<project>/.harness/04-changes/<YYYYMMDD-需求名>/00-design.md` |
| 写入项目计划 | `<project>/.harness/04-changes/<YYYYMMDD-需求名>/01-plan.md` |

**项目根目录确定规则**：
1. 通过 `git rev-parse --show-toplevel` 自动获取
2. 非 git 项目 → 通过 `AskUserQuestion` 让用户确认项目根目录

**🔴 禁止**：
- 将变更目录写入 `~/.claude/harness/04-changes/`（全局目录）
- 将变更目录写入 `~/.claude/harness.local/04-changes/`
- 使用绝对路径写入 pipeline-state 中的 file 字段

**已有全局变更迁移**：`~/.claude/harness/04-changes/` 中的历史变更目录为**只读存档**。新变更一律写入项目目录。

---

## 图表验证规则（Token 优化）

- 所有阶段验证/查阅图表：同名 SVG 存在时只 Read SVG，禁止 Read PNG
- PNG 仅在用户明确要求查看截图时 Read
- 图片元数据检查（分辨率、存在性）用 Bash 命令完成，不 Read
