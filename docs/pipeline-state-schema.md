# 流水线状态文件规范

> 路径查找: 按三层覆盖规则，存入 `<project>/.harness/04-changes/{YYYYMMDD-需求名}/pipeline-state.json`
> 作用: 跨会话追踪流水线阶段，解决链路中断和上下文丢失问题

## 状态机

```
brainstorming-complete → document-complete → implementation-complete → testing-complete → code-review-complete → closed
  ↑ 方案设计完成            ↑ 文档交付          ↑ 编码完成              ↑ 测试完成           ↑ 审查完成           ↑ 关闭
```

## Schema

```json
{
  "change_id": "20260518-需求编号-需求名称",
  "current_stage": "implementation-complete",
  "depth": "quick | standard | full-engineering",
  "demand_type": "document | development | bugfix | testing | review",
  "stages": {
    "brainstorming-complete": {
      "status": "COMPLETED | SKIPPED",
      "timestamp": "ISO 8601",
      "deliverables": [".harness/04-changes/xxx/00-design.md"]
    },
    "document-complete": {
      "status": "COMPLETED | SKIPPED | IN_PROGRESS",
      "timestamp": "ISO 8601",
      "file": ".harness/04-changes/xxx/00-design.md   ← 相对于项目根目录"
    },
    "implementation-complete": {
      "status": "COMPLETED | SKIPPED",
      "timestamp": "ISO 8601",
      "changed_files": ["路径列表"],
      "test_case_doc_generated": false,
      "testing_skipped": false,
      "skip_reason": null
    },
    "testing-complete": {
      "status": "COMPLETED | SKIPPED",
      "timestamp": "ISO 8601",
      "test_result": {
        "total": 0,
        "passed": 0,
        "failed": 0,
        "coverage_statement": 0,
        "coverage_branch": 0,
        "result": "PASSED | FAILED | PARTIAL | NOT_EXECUTED"
      },
      "test_report_generated": false
    },
    "code-review-complete": {
      "status": "COMPLETED | SKIPPED",
      "timestamp": "ISO 8601",
      "review_result": {
        "conclusion": "APPROVED | CHANGES_REQUESTED | REJECTED",
        "issues_found": 0,
        "issues_resolved": 0
      }
    },
    "closed": {
      "status": "COMPLETED",
      "timestamp": "ISO 8601"
    }
  },
  "created_at": "ISO 8601",
  "updated_at": "ISO 8601"
}
```

## 使用规则

| 规则 | 说明 |
| --- | --- |
| 写入时机 | 每个阶段完成时，由对应 skill 写入 |
| 读取时机 | 下一阶段启动时，检查前置阶段是否 COMPLETED |
| 缺文件处理 | 如无 pipeline-state.json，视为独立任务直接执行，不拦截。pipeline-state 是辅助加速器（检测到前置完成可接续），非准入门禁 |
| skip 处理 | 任何阶段标记为 SKIPPED 需写 reason 字段，如 `"skip_reason": "用户选择跳过测试用例文档生成"` |
| 🔴 路径约束 | 所有交付物路径必须**相对于项目根目录**（如 `docs/PRD.md`、`.harness/04-changes/xxx/00-design.md`）。禁止使用绝对路径（`/Users/...`）或跨出项目根目录的相对路径（`../../other-project/...`）。项目根目录通过 `git rev-parse --show-toplevel` 获取，非 git 项目通过 `AskUserQuestion` 确认 |
| 🔴 存储位置 | pipeline-state.json **必须**写入项目目录 `<project>/.harness/04-changes/<变更名>/pipeline-state.json`，**禁止**写入 `~/.claude/harness/04-changes/`（全局目录）。详见 CLAUDE.md "04-changes/ 写入约束" |
| 并发保护 | 同一 change_id 不可并行写入 |

## 与 harness-entry 的集成

harness-entry 在分诊后，检查 `<project>/.harness/04-changes/` 下是否有进行中的变更（`current_stage != 'closed'`）：

- 有 → 提示用户"检测到进行中的变更 [{change_id}]，当前处于 [{current_stage}] 阶段，是否继续？"
- 无 → 按正常流程新建变更目录
