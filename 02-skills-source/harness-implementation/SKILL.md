---
name: harness-implementation
description: Use when user asks to 实现, 开发, 写代码, 实现功能, 编码,
  implement, develop, code, build — enforces TDD (test-driven development)
  and 8-layer coding template. Must be preceded by brainstorming + writing-plans.
  Triggers on: 帮我写, 实现这个, 开发, 写代码, 编码实现.
---

# Harness — 编码实现

<HARD-GATE>
编码前必须确认：
1. Brainstorming 已完成，spec 已获用户批准
2. Implementation plan 已编写，每步 2-5 分钟粒度
3. 当前环境已隔离（git worktree 或新分支）
缺失任意一项 → 退回 brainstorming 或 writing-plans
</HARD-GATE>

## TDD 流程（强制执行）

```
RED → GREEN → REFACTOR
  ↓                ↓
  写失败测试    重构优化
  ↓                ↓
  确认失败      确认仍绿
  ↓                ↓
  最小实现 → COMMIT
```

## 编码规范

→ Read `~/.claude/harness/01-rules/02-development-workflow/00-overview.md`

## 执行模式选择

| 场景 | 模式 |
|------|------|
| Claude Code / 支持 subagent 的平台 | `subagent-driven-development`（推荐） |
| 不支持 subagent 的环境 | `executing-plans`（串行执行） |
| 任务多、上下文易漂移 | `subagent-driven-development` |
| 简单小任务 | `executing-plans` |

## 每个步骤的标准粒度

```markdown
- [ ] Step 1: 写一个失败的测试
- [ ] Step 2: 跑一下，确认它确实失败了
- [ ] Step 3: 写最小实现让测试通过
- [ ] Step 4: 跑测试，确认通过
- [ ] Step 5: Commit
```

## 完工标准

→ 移交 `harness-code-review` 进行独立评审
