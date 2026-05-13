---
name: harness-brainstorming
description: Use when user asks to 设计, 做方案, 分析需求, 技术选型, 架构设计,
  方案设计, system design, design architecture, make a plan for — ensures mandatory
  brainstorming → spec → writing-plans pipeline is followed before any code is written.
  Triggers on: 帮我设计, 设计一个, 分析一下, 怎么做, 选什么技术, 架构怎么, 方案.
---

# Harness — 方案设计

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project,
or take any implementation action until:
1. Brainstorming is complete
2. Design spec is written and committed
3. User has approved the spec
This applies to EVERY task regardless of perceived simplicity.
</HARD-GATE>

## 流程（9 步，必须按序执行）

### Step 1: 探索项目现状
- 读取相关文件、目录结构
- 检查 git log 了解最近的变更
- 理解现有架构和约束

### Step 2: 逐条问澄清问题
- 一次只问一个问题
- 优先多选问题，开放式也可
- 厘清：目的、约束、成功标准

### Step 3: 提出 2-3 个方案
- 每个方案给 trade-off 和推荐理由
- 先说你推荐的方案及原因

### Step 4: 分节展示设计方案
- 每个章节按复杂度缩放（简单→几句话，复杂→200-300 词）
- 覆盖：架构、组件、数据流、错误处理、测试策略
- 每段展示后确认是否正确

### Step 5: 设计写入 spec 文件
- 路径：`~/.claude/harness/04-changes/YYYYMMDD-<主题>/00-design.md`
- 提交到 git

### Step 6: Spec 自检
- 扫描 TBD/TODO、不完整章节
- 检查内部矛盾
- 确认范围明确、无歧义

### Step 7: 用户审阅 spec
- 请用户审阅 spec 文件
- 用户确认后才进入下一步

### Step 8: 移交 writing-plans
- 终态：移交 `harness-implementation`（执行计划阶段）
- 不直接调用编码相关 skill

## 反模式

> "这个太简单了，不需要设计"

简单项目里的隐含假设是浪费工作的最大来源。
设计可以短（几句话），但不能省。

## 与 Superpowers 对齐

此 skill 是对 Superpowers `brainstorming` 的 harness 实现：
- 同样的 9 步流程
- 同样的 `<HARD-GATE>` 约束
- 同样的 spec → plan → execute 链路
