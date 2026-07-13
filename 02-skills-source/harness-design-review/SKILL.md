---
name: harness-design-review
description: Use when user asks to 审核方案, review设计, 方案评审, 检查spec, or after brainstorming completes and user chooses design review — provides an independent design review gate with four check dimensions and mandatory review loop until zero blocking issues.
Triggers on: 审核方案, review设计, 方案评审, 检查spec, 看看方案有没有问题.
---

# Harness — 方案审核

<HARD-GATE>
Do NOT redesign or write new code. This is a REVIEW role, not a design role.
The review loop runs until zero blocking issues:
1. Read spec + project files → establish review baseline
2. Check all four dimensions → produce issue list
3. User reviews report → decides: revise / pass directly / reject
4. If revise → hand back to brainstorming → return to Step 1
5. Only EXIT when user explicitly confirms pass

---

## 🔴 审核完成后询问不可跳过

审核完成后，必须询问用户：
1. 直接通过？还是退回修改？

AI 不得在未询问用户的情况下声称"审核完成"或结束会话。

---

## 🔴 流程恢复门禁

用户在流程中指出错误、违规或跳过步骤后，AI 完成补救和沉淀评估后，必须：
1. 输出 `恢复点：harness-design-review Phase X`
2. 从该恢复点继续执行原 pipeline
3. 禁止把补救完成当作审核完成或会话终点

若无法判断恢复点，必须使用 `AskUserQuestion` 询问用户恢复到哪一步。

---

## 🔴 结构化交互门禁

所有"是否通过/退回修改/直接放行/拒绝"等决策，必须使用 `AskUserQuestion` 或 `PromptForUserInput`。

禁止使用普通文本让用户输入 `1/2/通过/退回`。

---

## 错误沉淀评估

→ 按路径解析规则加载 `01-rules/02-development-workflow/02-error-precipitation.md`，按其中的评估步骤执行。

审核中发现严重设计缺陷、架构漏洞或流程违规时，必须触发沉淀评估。
</HARD-GATE>

## 角色约束

此 skill 是独立审核者，与 brainstorming 的设计者角色分离。审核者不参与方案生成，只负责找到问题和遗漏。

### Phase -2: Pipeline Context Recovery（🔴 HARD RULE）

审核开始前，先从 pipeline-state 继承深度档位：

#### Step 1: 读取 pipeline-state.json

按路径解析规则查找 `<project>/.harness/04-changes/<change_id>/pipeline-state.json`，读取 `depth` 字段。

独立触发 → 默认按 🟡 standard 执行。

#### Step 2: 输出深度确认

```
📋 Pipeline Context Recovery：
  ✅ 深度档位：[从 pipeline-state 继承: 🟢 完整工程]
```

#### Step 3: 深度驱动审核行为

| 深度 | 审核行为 |
|------|---------|
| 🔵 quick | 四检查面快速扫描，仅阻断严重设计缺陷 |
| 🟡 standard | 完整四检查面，循环至零阻断 |
| 🟢 full-engineering | 🟡 全部 + 必须读取 PRD/需求文档对照审核 + 审核报告 docx |

**禁止在未完成 Pipeline Context Recovery 前开始审核。**

---

### 五大约束

| # | 约束 | 说明 |
|---|------|------|
| 1 | **只审核，不重新设计** | 发现问题标记出来，交给 brainstorming 修订，不替它改 |
| 2 | **审核到零阻断问题才放行** | 修订 → 再审核 → 再修订，直到本轮无新增阻断问题 |
| 3 | **对照项目文件检查** | 不凭印象，必须对照 spec、架构文档、规则文件逐项核对 |
| 4 | **不确定的说"待确认"** | 不猜、不推断。假问题标为"待确认"而非阻断 |
| 5 | **AI 提建议，用户决定放行** | 审核报告由用户审阅，用户确认通过后才放行 |

## 流程（4 步，循环直到通过）

### Step 1: 建立审核基线

读入以下文件建立审核参照系：

| 文件 | 用途 |
|------|------|
| `04-changes/<变更>/00-design.md` | 被审核的 spec（必读，相对于 `<project>/.harness/`） |
| `docs/architecture/00-overview.md` | 技术架构约束 |
| `docs/architecture/tech-stack.md` | 技术栈约束 |
| `docs/business/00-overview.md` | 业务背景（必须理解业务才能审核方案） |
| `docs/business/domain-glossary.md` | 领域术语（疑有术语歧义时） |
| `docs/patterns/anti-patterns.md` | 已知反模式 |
| `docs/patterns/review-checklist.md` | 四检查面清单（范围完整性/内部一致性/可行性/风险覆盖） |
| `01-rules/04-document-standards/` 下相关规范 | 文档标准 |

> 文件不存在或内容为 TODO 则跳过，在报告中标注"审核基线不完整：缺少 XXX"。

### 🔴 审核基线加载验证（必须展示）

完成审核基线建立后，必须输出已加载文件清单：

```
📚 已加载审核基线：
  ✅ .harness/04-changes/<变更>/00-design.md
  ✅ docs/architecture/00-overview.md（如存在）
  ✅ docs/business/00-overview.md（如存在）
  ✅ docs/patterns/anti-patterns.md（如存在）
  ...
```

**禁止在未输出加载清单前开始审核。**

### Step 2: 四检查面审核

逐检查面审视 spec，输出问题列表。每个问题标注严重度：

- **🔴 阻断**：方案有明显缺陷或遗漏，不改会导致实现出问题
- **🟡 警告**：有风险但不是致命问题，建议改进
- **🔵 待确认**：审核者不确定，需要用户判断

#### 检查面 1：范围完整性

- Scope IN 是否明确？是否覆盖了所有需求？
- Scope OUT（Non-goals）是否 ≥ 2 项？排除的是"别人可能会以为包含"的合理范围？
- 关键术语是否有定义？歧义词汇是否消除？
- 需求是否有遗漏维度？（对照七大思维快速扫描）

#### 检查面 2：内部一致性

- 不同章节对同一概念的描述是否一致？
- 数据流：输入 → 处理 → 输出是否前后对得上？
- 假设列表是否有自相矛盾？
- 约束是否与方案设计冲突？

#### 检查面 3：可行性

- 方案是否在技术栈约束内可实现？
- 外部依赖（API/服务/平台）是否可达？
- 关键假设是否标注了验证方式？
- 是否有"假设能跑通就完了"的未验证大跃进？

#### 检查面 4：风险覆盖

- 关键假设的失效条件是否分析过？
- 失效时的影响是什么？有缓解措施吗？
- 是否有明确的回滚/降级方案？（如有必要）

### Step 3: 输出审核报告

输出到 `.harness/04-changes/<变更>/01-design-review.md`：

```markdown
# 方案审核报告

**审核对象**：[spec 文件路径]
**审核时间**：[日期]
**审核轮次**：第 N 轮

## 审核基线

| 文件 | 状态 |
|------|------|
| ... | ✅ 已读 / ⚠️ 不存在 |

## 检查面 1：范围完整性

| # | 严重度 | 问题 | 建议 |
|---|--------|------|------|

## 检查面 2：内部一致性

| # | 严重度 | 问题 | 建议 |
|---|--------|------|------|

## 检查面 3：可行性

| # | 严重度 | 问题 | 建议 |
|---|--------|------|------|

## 检查面 4：风险覆盖

| # | 严重度 | 问题 | 建议 |
|---|--------|------|------|

## 汇总

| 严重度 | 数量 |
|--------|------|
| 🔴 阻断 | N |
| 🟡 警告 | N |
| 🔵 待确认 | N |

## 审核结论

[通过 / 需修订后重审 / 驳回]
```

### Step 4: 用户审阅 → 修订或放行

将审核报告展示给用户，用户决定：

- **修订** → 将阻断问题 + 警告项反馈给 brainstorming，修订 spec 后回到 Step 1
- **直接通过** → 记录结论，进入 Step 5 链式移交询问
- **驳回** → 放弃此方案或重新设计

修订循环直到**本轮无新增 🔴 阻断问题**，用户确认通过后放行。

### Step 5: 链式移交询问（审核通过后必须执行）

#### 🔴 Step 5.0: 写入 pipeline-state（HARD RULE，移交前必须执行）

审核完成后，**无论用户下一步选什么**，必须先更新 `pipeline-state.json`：

```json
{
  "current_stage": "design-review-complete",
  "stages": {
    "design-review-complete": {
      "status": "COMPLETED",
      "timestamp": "<ISO 8601>",
      "review_result": {
        "conclusion": "APPROVED | CHANGES_REQUESTED | REJECTED",
        "blocking_issues": <N>,
        "warnings": <N>,
        "rounds": <N>
      },
      "report_file": ".harness/04-changes/<change_id>/01-design-review.md"
    }
  }
}
```

#### Step 5.1: 根据触发来源分两条路径

审核通过后，**根据触发来源分两条路径**：

**路径 A：由 brainstorming Step 8 触发** → 回到 brainstorming Step 8，让用户重新四选一（审核方案/生成文档/直接编码/暂不继续）。传递给 brainstorming 的上下文必须包含：

```
📋 移交上下文（回到 brainstorming）：
  review_conclusion: <APPROVED / CHANGES_REQUESTED>
  issues_found: <N>
  修订建议：[列出关键修订建议]
```

**路径 B：独立触发**（用户直接说"审核方案/检查 spec"）→ 必须询问用户：

> "方案审核通过。是否继续下一步？"
> - **生成文档** → 进入 `harness-document-generation`（文档完成后会询问是否编码）
> - **直接编码** → 进入 `harness-implementation`
> - **暂不继续** → 结束，记录 pipeline-state

🔴 此询问不可跳过。AI 不得自行决定下一步。

## 反模式

- "这个方案看起来没问题，直接过" → 不审核就放行
- "这个点应该是这样设计的..." → 开始重新设计（越界了）
- "我觉得可能有问题，先标记阻断" → 不确定的应该标"待确认"，不是阻断

## 与 brainstorming 的关系

```
brainstorming（生成 spec）
    ↓
Step 8 四选一 → 用户选"审核方案"
    ↓
design-review（审核 spec）
    ↓ 有问题 → 修订 → 再审核 → ...
    ↓ 通过
    ├─ 路径 A（brainstorming 触发）→ 回到 brainstorming Step 8
    └─ 路径 B（独立触发）→ Step 5 链式移交询问（生成文档/直接编码/暂不继续）
```

这不是 brainstorming 的替代，而是在 brainstorming 产出后、进入下一阶段前的一道可选门禁。

## 触发方式

1. **brainstorming 内部触发**：Step 8 四选一 → "审核方案"
2. **独立触发**：用户直接说"审核方案/检查 spec"，由 harness-entry 分诊路由到此

---

## 🔴 Step 完成标准

每个 Step 完成后，必须输出以下检查结果：

```
📋 Step 完成检查：
  ✅/❌ Step 1 审核基线已建立
  ✅/❌ Step 2 四检查面审核已完成
  ✅/❌ Step 3 审核报告已输出
  ✅/❌ Step 4 用户已审阅决定
  ✅/❌ Step 5 链式移交询问已完成（独立触发时）
```

**任一项为 ❌ 时**：继续当前 Step 直到满足标准。

---

## 🔴 会话结束门禁

在结束会话前，必须完成以下检查：

```
📋 会话结束检查：
  ✅/❌ 审核结论已确定（通过/修订/驳回）
  ✅/❌ 链式移交询问已完成（独立触发时）
  ✅/❌ 用户已明确下一步选择
```

**禁止以下行为**：
- 在未完成链式移交询问的情况下结束会话（独立触发时）
- 用户未明确选择就自行判断"任务完成"

会话只能在以下情况结束：
1. 审核通过 + 用户选"暂不继续"→ 记录状态 → 结束
2. 审核通过 + 用户选继续 → 调用下一个 skill → 会话移交
3. 审核驳回 → 记录状态 → 结束
4. 退回修订 → 移交 brainstorming → 等待重审
