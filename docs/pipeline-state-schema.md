# 流水线状态文件规范

> 路径查找: 按三层覆盖规则，存入 `04-changes/{YYYYMMDD-需求名}/pipeline-state.json`
> 作用: 跨会话追踪流水线阶段，解决链路中断和上下文丢失问题

## 状态机

```
00-requirements → 01-plan-approved → 02-implementation-complete → 03-code-review-complete → 04-testing-complete → 05-ci-complete → 09-closed
```

## Schema

```json
{
  "change_id": "20260518-需求编号-需求名称",
  "current_stage": "02-implementation-complete",
  "stages": {
    "00-requirements": {
      "status": "COMPLETED | SKIPPED | IN_PROGRESS",
      "timestamp": "ISO 8601",
      "file": "00-requirements.md"
    },
    "01-plan-approved": {
      "status": "COMPLETED | SKIPPED",
      "timestamp": "ISO 8601",
      "file": "01-plan.md"
    },
    "02-implementation-complete": {
      "status": "COMPLETED",
      "timestamp": "ISO 8601",
      "changed_files": ["路径列表"],
      "test_case_doc_generated": false,
      "testing_skipped": false,
      "skip_reason": null
    },
    "03-code-review-complete": {
      "status": "COMPLETED | SKIPPED",
      "timestamp": "ISO 8601"
    },
    "04-testing-complete": {
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
    }
  },
  "created_at": "ISO 8601",
  "updated_at": "ISO 8601"
}
```

## 使用规则

| 规则 | 说明 |
|------|------|
| 写入时机 | 每个阶段完成时，由对应 skill 写入 |
| 读取时机 | 下一阶段启动时，检查前置阶段是否 COMPLETED |
| 缺文件处理 | 如无 pipeline-state.json，询问用户"未检测到前置阶段记录，是否跳过状态校验继续？" |
| skip 处理 | 任何阶段标记为 SKIPPED 需写 reason 字段，如 `"skip_reason": "用户选择跳过测试用例文档生成"` |
| 并发保护 | 同一 change_id 不可并行写入 |

## 与 harness-entry 的集成

harness-entry 在分诊后，检查 `04-changes/` 下是否有进行中的变更（`current_stage != '09-closed'`）：

- 有 → 提示用户"检测到进行中的变更 [{change_id}]，当前处于 [{current_stage}] 阶段，是否继续？"
- 无 → 按正常流程新建变更目录
