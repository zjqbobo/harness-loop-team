---
name: harness-code-review
description: Use when user asks to review, 审查, 检查代码, code review, 审计,
  audit code — ensures independent review with 3-phase process: plan review → code review → test review.
  Reviewer must be independent from coder (strict separation of roles).
  Triggers on: 帮我review, 审查一下, 检查这段代码, code review, 审计.
---

# Harness — 代码审查

<HARD-GATE>
Reviewer 和 Coder 角色必须严格分离。
Reviewer 只能评审，不能改代码。
评审发现严重问题 → 退回编码阶段。
</HARD-GATE>

## 三阶段评审

### Phase 1: 计划评审
- 检查 spec 是否完整（无 TBD/TODO）
- 检查范围是否明确
- 检查风险点是否识别

### Phase 2: 代码评审
- 编码规范合规检查
- 安全问题扫描
- 性能关注点
- 可维护性评分（≥ 8.0 通过）

### Phase 3: 测试评审
- 测试覆盖率（statement ≥ 80%, branch ≥ 70%）
- 测试用例是否覆盖边界条件
- 全部测试绿通过

## 评审结论

- `APPROVED` — 无问题，可推进
- `CHANGES_REQUESTED` — 有改进建议，修改后重新评审
- `REJECTED` — 严重问题，需重写方案

## 详细规范

→ Read `~/.claude/harness/00-harness-core/00-application-owner-agent.md` 中的质量门禁定义（Gateway 2）
