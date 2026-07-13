# 错误沉淀流程规范

> 本文件为所有 domain skill 提供统一的错误沉淀评估流程。
> 各 SKILL.md 中的"错误沉淀评估"章节统一引用本文件，避免重复。

## 评估步骤（必须执行）

1. **输出沉淀判断**：列出本次涉及的教训评估
   - 值得沉淀：[类型|严重度|摘要]
   - 无需沉淀：[原因]（如"拼写修正"/"已有规则覆盖"/"修复成本<5min"）
2. **向用户展示判断并请确认**：使用 `AskUserQuestion` 展示评估结果
   - 如判断值得沉淀 → 用户确认后进入沉淀流程
   - 如判断无需沉淀 → 用户确认跳过（用户可 override 强制沉淀）
3. **用户确认沉淀后**：读取 `00-harness-core/knowledge-index.yaml` → 按 tags 计算重叠度（>50% 视为同类）→ 判重 → 同类合并/新类新建 → 写入文件 → 更新索引 → 告知用户沉淀完成

评估步骤本身不可跳过。即使判断结果为"无需沉淀"，也必须向用户展示并确认。
这与测试门禁同构：AI 必须问，用户可以说不沉淀，但 AI 不能不问。

## 触发场景

a) 修复错误后（debug/implementation/testing/code-review/document-generation/brainstorming）
b) 方案设计结束时（有非显而易见的架构取舍或设计决策）
c) 用户显式表达踩坑耗时（如"这个坑花了我半天""这次花了太长时间"等）
d) 用户对 AI 行为的批评、质疑、纠正（流程违规触发条件，不得先补救再评估）

## 沉淀路径（按 type × severity）

| type | severity | 写入位置 | 生效方式 |
|---|---|---|---|
| process | high | 对应 SKILL.md | HARD-GATE 检查点 |
| process | medium | `01-rules/` | 路径解析自动命中 |
| rule | high | `01-rules/` | 路径解析 + SKILL 引用 |
| rule | medium | `01-rules/` | 路径解析自动命中 |
| anti-pattern | any | `docs/patterns/anti-patterns.md` | brainstorming Step 0 加载 |
| knowledge | any | `docs/` 对应子目录 | 按需加载 + 索引发现 |

## 三层归属判断

- 项目特有约束 → 项目 `.harness/`
- 公司/团队通用 → `~/.claude/harness.local/`
- 通用工程教训 → `~/.claude/harness/`

AI 建议归属层，用户最终确认。
