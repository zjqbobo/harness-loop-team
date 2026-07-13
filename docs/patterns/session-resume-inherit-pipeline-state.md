# 会话恢复时必须继承 pipeline-state 的 depth/demand_type

- **类型**: process
- **严重度**: high
- **溯源变更**: 20260615-store-training-platform

## 问题

恢复进行中变更时，AI 读取了 pipeline-state.json 获取到 `depth` 和 `demand_type`，却未继承这些已有决策，仍然重新执行分诊提问（如重新询问深度档位），导致用户重复确认。

## 规则

harness-entry 的会话恢复路径明确规定：**继续 → 恢复 depth/demand_type，调用对应领域 skill 接续执行**。读取 pipeline-state 后，depth 和 demand_type 必须直接继承，禁止重新分诊。

**Why**: pipeline-state 的核心目的就是持久化决策，会话恢复时继承是基本契约。重新提问等于否定已有决策，破坏流水线连续性。

**How to apply**: 检测到 current_stage != "closed" 且用户选择"继续"时，直接从 pipeline-state.json 读取 depth 和 demand_type，跳过分诊交互，立即路由到对应领域 skill 的接续点。
