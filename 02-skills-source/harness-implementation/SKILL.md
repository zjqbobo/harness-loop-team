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

## 知识加载（编码前必读）

按路径解析规则（项目 `.harness/` > `~/.claude/harness.local/` > `~/.claude/harness/`）依次查找，找到即停。

### 始终加载
1. 读取 `docs/coding-standards/00-index.md`（编码规范速查索引，覆盖 80% 约束）
2. 读取 `01-rules/02-development-workflow/00-overview.md`（开发流程规范）

### 按场景选择性深入
根据当前任务，从速查索引中选择深入阅读的具体规范文件：

| 任务类型 | 必读规范文件 |
|---------|------------|
| 新增 REST 接口 | `docs/coding-standards/01-layering.md` + `04-input-validation.md` + `02-exception-handling.md` |
| 数据库读写操作 | `docs/coding-standards/01-layering.md` + `03-transaction.md` + `05-logging.md` |
| 重构现有代码 | `docs/coding-standards/06-basic-rules.md` + `01-layering.md` |
| 修复 Bug | `docs/coding-standards/02-exception-handling.md` + `05-logging.md` |
| 涉及外部系统调用 | `docs/coding-standards/02-exception-handling.md` + `05-logging.md` + `docs/architecture/integration-map.md` |

### 按需加载（非强制）
- 涉及领域术语命名 → 读取 `docs/business/domain-glossary.md`
- 涉及架构兼容性决策 → 读取 `docs/architecture/00-overview.md`
- 需要参考推荐模式 → 读取 `docs/patterns/recommended.md`

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

### <HARD-GATE> 编码完成后必须执行，不可静默结束

编码完成后，你**必须依次执行**以下步骤。**禁止**在未完成这些步骤前声称"编码完成"或将会话结束。

#### Step 1: 写入流水线状态

在变更目录下写入当前阶段状态：

按路径解析规则查找 `04-changes/` 目录，找到当前需求的变更目录，写入或更新 `pipeline-state.json`：

```json
{
  "stage": "02-implementation-complete",
  "timestamp": "<ISO 8601>",
  "changed_files": ["<文件路径列表>"],
  "test_case_doc_generated": false
}
```

状态文件模板按路径解析规则查找 `docs/pipeline-state-schema.md`。

#### Step 2: 测试用例文档决策点（必须询问用户）

使用以下话术询问用户：

> 编码完成。是否生成测试用例文档？
> - **是** → 按路径解析规则查找 `09-templates/测试用例文档模板.md` → Read 模板 → 按需求/功能维度生成测试用例文档(MD) → 用户审阅 → 可选转DOCX
> - **否** → 跳过，进入自动化测试

如选择"是"，生成完成后将 `pipeline-state.json` 中 `test_case_doc_generated` 更新为 `true`。

#### Step 3: 移交测试环节（必须执行）

> ⚠️ **禁止行为**：直接回复用户"代码写好了，你看一下"作为会话终点。编码的终点是测试通过，不是写完代码。

执行 `Skill("harness-testing")`，将当前变更目录路径传递给测试环节。

如用户明确拒绝测试，必须在 `pipeline-state.json` 中记录 `"testing_skipped": true, "skip_reason": "<用户理由>"`。
