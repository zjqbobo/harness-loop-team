---
name: harness-systematic-debugging
description: Use when user reports 修bug, 调试, 报错, 不工作, 出问题, 异常,
  debug, fix bug, error, broken, not working, crash, exception
  — enforces 4-phase systematic debugging: root cause investigation → pattern analysis
  → single hypothesis testing → minimal fix. NO FIXES WITHOUT ROOT CAUSE FIRST.
  Triggers on: 帮我修, 报错了, 不工作, 出bug了, 调试一下, 这个错误, 挂了.
---

# Harness — 系统调试

<HARD-GATE>
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.
Do NOT guess. Do NOT try random fixes.
Follow the 4 phases in order. Previous phase must complete before next begins.

---

## 🔴 修复完成后询问不可跳过

修复完成并验证通过后，必须询问用户：
1. 是否需要回归测试？

AI 不得在未询问用户的情况下声称"修复完成"或结束会话。

---

## 🔴 流程恢复门禁

用户在流程中指出错误、违规或跳过步骤后，AI 完成补救和沉淀评估后，必须：
1. 输出 `恢复点：harness-systematic-debugging Phase X`
2. 从该恢复点继续执行原 pipeline
3. 禁止把补救完成当作修复完成或会话终点

若无法判断恢复点，必须使用 `AskUserQuestion` 询问用户恢复到哪一步。

---

## 🔴 结构化交互门禁

所有"是否继续/是否回归测试/是否提交"等决策，必须使用 `AskUserQuestion` 或 `PromptForUserInput`。

禁止使用普通文本让用户输入 `1/2/继续/是/否`。
</HARD-GATE>

## 按需加载（根据问题范围决定）

调试环节**不需要硬性加载知识**，但根据问题类型可按需读取：

| 问题类型 | 建议加载 | 原因 |
|---------|---------|------|
| 单模块内逻辑问题 | 无需加载 | 直接读代码即可 |
| 跨模块调用问题 | `docs/architecture/00-overview.md` | 理解模块间依赖 |
| 违反项目约定 | `docs/architecture/project-conventions.md` | 对比差异时参考 |
| 业务逻辑错误 | `docs/business/domain-glossary.md` | 理解术语和流程 |

**Phase 1 根因调查** 时根据问题范围判断是否需要加载，不强制。

**Phase 4 修复代码前** 必须遵守已加载的编码规范（如有），或遵循项目现有代码风格。

## 铁律

> 猜测模式调试平均耗时 2-3 小时；系统调试平均 15-30 分钟。

## Phase 1: 根因调查

- [ ] 完整读取错误信息（不是"看一眼"，是"读完整"）
- [ ] 稳定复现步骤
- [ ] 检查最近的 git 变更（`git log --oneline -10`, `git diff HEAD~1`）
- [ ] 对多组件系统，在每个边界打诊断日志，先跑一次收集证据

## Phase 2: 模式分析

- [ ] 找到同一个 codebase 里类似的、能跑通的代码
- [ ] 和坏的代码逐项对比差异——每一个差异，不管多小，都列出来
- [ ] 理解依赖和假设条件

## Phase 3: 单假设验证

- [ ] 写下具体假设："我认为 X 是根因，因为 Y"
- [ ] 做最小变更验证
- [ ] 不对的话：换新假设，不要叠加改动

## Phase 4: 实现修复

- [ ] 先写能复现问题的测试
- [ ] 只改一处
- [ ] **三次失败规则**：如果试了 3 次还没有解决 → 停下来讨论是不是架构问题，不继续猜

## 修复后询问下一步

修复完成并验证通过后，**必须**询问用户：

> "Bug 已修复。是否需要回归测试？"
> - **是** → 进入 `harness-testing`
> - **否，直接提交** → commit
> - **否，先审查** → 进入 `harness-code-review`

## 错误沉淀评估

→ 按路径解析规则加载 `01-rules/02-development-workflow/02-error-precipitation.md`，按其中的评估步骤执行。

## 常见借口 vs 真相

| 借口 | 真相 |
|------|------|
| "这个 issue 很简单，不用走流程" | 简单的 bug 也有根因，流程对简单问题反而更快 |
| "紧急情况，没时间调查" | 系统性调试比猜测快多了，"紧急"不是理由 |
| "先试一下再说" | 第一次就确立猜测模式，后面就一直猜 |
| "我已经大概知道问题在哪了" | 知道症状不等于知道根因 |

---

## 🔴 Phase 完成标准

每个 Phase 完成后，必须输出以下检查结果：

```
📋 Phase 完成检查：
  ✅/❌ Phase 1 根因调查完成：[错误信息已完整读取 + 复现步骤已稳定]
  ✅/❌ Phase 2 模式分析完成：[对比差异已列出]
  ✅/❌ Phase 3 假设验证完成：[假设已验证]
  ✅/❌ Phase 4 修复实施完成：[测试已通过]
```

**任一项为 ❌ 时**：继续当前 Phase 直到满足标准。

---

## 🔴 会话结束门禁

在结束会话前，必须完成以下检查：

```
📋 会话结束检查：
  ✅/❌ 链式移交询问已完成（回归测试询问）
  ✅/❌ 用户已明确下一步选择
```

**禁止以下行为**：
- 在未完成链式移交询问的情况下结束会话
- 用户未明确选择就自行判断"任务完成"

会话只能在以下情况结束：
1. 用户明确选择"暂不继续"→ 记录状态 → 结束
2. 用户选择继续 → 调用下一个 skill → 会话移交

## 与 Superpowers 对齐

此 skill 是对 Superpowers `systematic-debugging` 的 harness 增强版：
- 同样的四阶段根因分析
- 额外：沉淀评估 + 流水线衔接 + 结构化交互门禁

**优先级**：触发词重叠时，优先使用本 skill（而非 `superpowers:systematic-debugging`）。详见 `harness-entry` SKILL.md 中的"与 Superpowers 的优先级声明"。
