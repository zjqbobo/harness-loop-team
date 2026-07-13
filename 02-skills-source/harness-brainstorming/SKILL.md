---
name: harness-brainstorming
description: Use when user asks to 设计, 做方案, 分析需求, 技术选型, 架构设计,
  方案设计, system design, design architecture, make a plan for — ensures mandatory
  brainstorming → spec → writing-plans pipeline is followed before any code is written.
  PRD tasks use 纲举目张法 as thinking backbone (AI drives, human confirms only at key points).
  Triggers on: 帮我设计, 设计一个, 分析一下, 怎么做, 选什么技术, 架构怎么, 方案.
---

# Harness — 方案设计

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project,
or take any implementation action until:
1. Brainstorming is complete
2. Design spec is written and committed
3. User has approved the spec
4. 🔴 Step 8 询问已执行：用户确认"生成文档"/"直接编码"/"暂不继续"后，才调用对应 skill
This applies to EVERY task regardless of perceived simplicity.

🔴 用户说"可以，继续吧"/"继续"等确认词后，必须执行 Step 8 的三选一询问，禁止跳过。
禁止将用户确认 spec 的话语等同于"同意直接实施"。

🔴 **Step 8 链式移交询问不可跳过**。

方案设计完成后，必须向用户展示四选一询问：
- 审核方案 → harness-design-review
- 生成文档 → harness-document-generation
- 直接编码 → harness-implementation
- 暂不继续 → 记录 pipeline-state

AI 不得自行跳过询问并结束会话。

🔴 **纠错恢复门禁**：若用户在方案设计过程中指出流程违规、工具使用错误、图表/文档脚本使用错误，AI 完成沉淀评估与补救后，必须输出 `恢复点：harness-brainstorming Step X`，并从该步骤继续执行。禁止把补救完成当作方案设计完成或会话终点。

🔴 **结构化交互门禁**：Step 7 审阅确认、Step 8 下一步选择、图表工具选择、文档工具选择等所有决策必须使用 `AskUserQuestion` / `PromptForUserInput`，禁止普通文本要求用户输入编号或“继续”。
</HARD-GATE>

## 流程（9 步，必须按序执行）

### Step 0: 加载领域知识（方案设计前必读）

#### 0.0 存量设计文档按需加载（新增）

**触发条件**：任务涉及修改现有设计方案，且变更目录存在存量设计文档

检测存量设计文档（按优先级）：
- 00-design.md
- *设计方案.md
- *设计文档.md

若存量设计文档存在：

1. **检测索引文件**：`*.manifest.json`
   - 不存在或失效 → 调用 `harness-design-indexer` 生成
   - 存在且有效 → 使用现有索引

2. **AI 自行判断加载章节**：
   - 根据任务描述和章节关键词，AI 决定加载哪些章节
   - 使用 `Read(offset, limit)` 按需加载

3. **建议优先按需加载**：若 AI 判断需要全局视图（如全量重构、架构调整）可全量加载

透明化提示：
```
📋 存量设计文档按需加载：
   - 设计文档：00-design.md（共 N 行）
   - 已加载章节：概览、架构、消息模块等
   📊 已加载约 X 行（节省 Y%）
```

#### 0.1 加载知识库（原有流程）

按路径解析规则（项目 `.harness/` > `~/.claude/harness.local/` > `~/.claude/harness/`）依次查找，找到即停。

| 知识类型 | 文件路径 | 何时加载 |
|---------|---------|---------|
| 技术架构现状 | `docs/architecture/00-overview.md` | **始终加载**（TODO 则跳过，告知用户补充） |
| 技术栈与版本 | `docs/architecture/tech-stack.md` | 涉及技术选型时（TODO 则跳过） |
| 系统集成关系 | `docs/architecture/integration-map.md` | 涉及外部系统交互时（TODO 则跳过） |
| 业务现状 | `docs/business/00-overview.md` | **始终加载**（TODO 则跳过，告知用户补充） |
| 领域术语表 | `docs/business/domain-glossary.md` | **始终加载**（TODO 则跳过，告知用户补充） |
| 核心业务流程 | `docs/business/core-flows.md` | 涉及业务流程变更时（TODO 则跳过） |
| 推荐编码模式 | `docs/patterns/recommended.md` | 设计落地方案时（TODO 则跳过） |
| 常见反模式 | `docs/patterns/anti-patterns.md` | 方案评审时（TODO 则跳过） |
| 需求分析方法论 | `01-rules/04-document-standards/03-requirements-methods.md` | 分诊结果为 PRD 时 |

> 注意：以上文件为知识模板，初始内容为占位符。如文件内容仍为 TODO，跳过该文件，告知用户需要补充。

### 🔴 知识库加载验证（必须展示）

完成知识加载后，必须输出已加载文件清单：

```
📚 已加载知识库：
  ✅ docs/architecture/00-overview.md
  ✅ docs/business/00-overview.md
  ✅ docs/business/domain-glossary.md
  ...（根据实际加载情况列出）
```

**禁止在未输出加载清单前开始方案设计。**

### Step 1: 探索项目现状
- 读取相关文件、目录结构
- 检查 git log 了解最近的变更
- 理解现有架构和约束

### Step 2: 精益需求驱动设计（PRD 专用，替代开放式提问）

<HARD-GATE>
分诊结果为 PRD 时，Step 2-4 必须按纲举目张法驱动设计思考，禁止使用通用开放式提问流程。
非 PRD 任务走原有 Step 2-4（逐条问澄清问题 → 提出方案 → 分节展示）。
</HARD-GATE>

#### 核心原则：AI 自主推演，只在关键节点确认

纲举目张法五步中，AI 自主完成角色梳理、术语定义、主业务流程、七大思维推演。
**真正必问的只有两类**：
1. **业务价值确认**（1 次，一句话确认，不是开放式提问）
2. **AI 无法自行判断的关键决策点**（0-2 个，如存在两种合理架构方向或用户未说明的硬约束）

#### Step 2.1: 业务价值确认（必问）

AI 从用户描述中提取核心业务价值、识别利益相关者，用一句话总结后请用户确认：

```
🎯 我理解的核心业务价值：
   [一句话：为谁解决什么问题，创造什么价值]
   利益相关者：[企业/用户/业务方/...]

   这个理解对吗？
```

使用 `AskUserQuestion` 确认，选项：**对，继续** / **需要修正**。

#### Step 2.2: 角色梳理（AI 自主）

AI 根据业务场景穷举所有角色（含间接角色），按以下维度分类：

| 角色类型 | 说明 |
|---------|------|
| 直接使用者 | 直接操作系统的人 |
| 受益者 | 不操作系统但享受结果的人 |
| 管理者 | 配置、审核、监控的人 |
| 外部系统 | 集成的第三方系统/服务 |

输出角色清单，不提问。仅当角色间存在权限冲突或职责模糊时才向用户确认。

#### Step 2.3: 术语定义（AI 自主）

AI 建立领域术语表，统一语言：

| 术语 | 定义 | 备注 |
|-----|------|------|
| ... | ... | ... |

覆盖：核心业务对象、关键操作、状态值、度量指标。
仅当存在行业特定术语无法从上下文推断时才向用户确认。

#### Step 2.4: 主业务流程（AI 自主）

AI 用泳道图描画主流程，包含：
- 参与者（角色维度）
- 阶段（时间维度）
- 关键决策点
- 跨系统交互

#### Step 2.5: 七大思维推演（AI 自主，结果显性化）

AI 逐项推演，**推演过程写入方案章节，用户可见**：

| 思维方式 | AI 推演内容 | 产出 |
|---------|-----------|------|
| **对称思维** | 每个正向操作的反向场景 | 撤销/回退/取消操作清单 |
| **边界思维** | 所有数值、时间、数量的上下限 | 边界值定义表 |
| **多样性思维** | 枚举所有变化维度（方式/渠道/类型/状态） | 变化维度枚举表 |
| **生命周期思维** | 核心对象从创建到销毁的完整状态流转 | 对象生命周期图 |
| **异常思维** | 所有可能失败场景及处理方式 | 异常场景处理矩阵 |
| **并发思维** | 多用户/多设备同时操作场景 | 并发冲突场景清单 |
| **安全思维** | 权限边界、数据暴露面、攻击面 | 安全风险点清单 |

推演结果**直接作为方案章节内容**，不藏起来。每项不适用则标注"不适用"并说明原因。

### Step 3: 提出 2-3 个方案（PRD 时精简）
- PRD 任务：基于 Step 2 的推演结果，提出 1-2 个方案方向（通常主推 1 个），给 trade-off
- 非 PRD 任务：按原有流程，提出 2-3 个方案
- 先说你推荐的方案及原因

### Step 4: 分节展示设计方案
- 每个章节按复杂度缩放（简单→几句话，复杂→200-300 词）
- 覆盖：架构、组件、数据流、错误处理、测试策略
- 🔴 **架构图/流程图/组件图/数据流图禁止使用 ASCII 线框图（┌┐└┘├┤│─ 等制表符），必须询问用户选择图表工具后绘制：技术文档 → mermaid / fireworks-tech-graph**
- 🔴 **路由矩阵/对比表等表格数据使用 Markdown 表格，禁止包在 ASCII 框里**
- 每段展示后确认是否正确

**PRD 专用：Step 2.5 七大思维推演结果融入方案章节**

Step 2.5 的推演结果**已经作为方案内容展示给用户**，Step 4 直接引用。在方案末尾追加一段精益需求自检总结：

```
📋 精益需求自检总结：
  ✅ 对称思维：[发现了 X 个反向操作，已纳入方案]
  ✅ 边界思维：[定义了 Y 个边界值]
  ✅ 多样性思维：[枚举了 Z 个变化维度]
  ✅ 生命周期思维：[覆盖了核心对象 A、B 的完整生命周期]
  ✅ 异常思维：[识别了 W 个异常场景]
  ✅ 并发思维：[识别了 V 个并发冲突点]
  ✅ 安全思维：[识别了 U 个安全风险点]
  ⚠️ 待确认：[仅列出需要用户决策的点]
```

### Step 5: 设计写入 spec 文件
- 路径：按 CLAUDE.md「路径解析规则」查找 `04-changes/` 目录 → `<project>/.harness/04-changes/YYYYMMDD-<主题>/00-design.md`
- 🔴 写入前检查：spec 中是否存在 ASCII 线框图？如有，必须先替换为 Mermaid 代码块或 fireworks-tech-graph 代码（取决于用户选择）
- 提交到 git

### Step 5.5: 图表渲染（方案输出类任务必经）

- 🔴 如产出含架构图/流程图 → **必须渲染为 PNG 嵌入 spec**，禁止在审阅时留下未渲染的图表代码块或 ASCII 线框图
- 确认图表工具（mermaid / fireworks-tech-graph），不重新询问
- Mermaid 图表 → 用 `mermaid-render.sh` 渲染 PNG
- fireworks 图表 → 用 `svg2png.sh` 转换 SVG → PNG
- 渲染后的 PNG 存入 `images/` 目录，在 spec 中引用
- 🔴 此步骤仅负责图表渲染，**不链入 `harness-document-generation`**。完整文档交付（模板+格式+DOCX）由 Step 8 询问用户后决定

### Step 6: Spec 自检
- 扫描 TBD/TODO、不完整章节
- 🔴 扫描 ASCII 图表残留：检查 `┌┐└┘` 四角符号（框线图表标志）和 `┼` 交叉符。仅阻断用制表符绘制的架构图/流程图/组件图/结构框图，不阻断列表树形（`├──`）、表格分隔线（`───`）等合法文本排版
- 检查内部矛盾
- 确认范围明确、无歧义
- **PRD 专用 CRARE 自检（仅在分诊结果为 PRD 时执行）**：
  - 完整性：是否有未定义的部分（可能产生 bug）？
  - 正确性：是否有未正确定义的内容（可能被错误实现）？
  - 精确性：是否有模糊词汇让开发人员武断做决定？
  - 可测性：需求描述是否可通过测试验证（有验收标准）？

### Step 7: 用户审阅 spec
- 请用户审阅 spec 文件（含渲染后的图表 PNG 截图）
- 用户确认后才进入下一步

### ✅ Step 7 完成标准

用户审阅通过后才算 Step 7 完成。判断依据：
- 用户明确说"通过"/"可以"/"没问题"等确认词
- 或用户提出修改意见后已完成修改

用户确认后进入 Step 8。

### Step 8: 询问是否继续下一步

方案设计完成后，**必须**询问用户：

> "方案设计完成。是否继续下一步？"
> - **审核方案** → 进入 `harness-design-review`（独立审核，审核通过后回到此步骤重新选择）
> - **生成文档** → 进入 `harness-document-generation`（文档完成后会询问是否编码）
> - **直接编码** → 进入 `harness-implementation`
> - **暂不继续** → 结束，记录 pipeline-state

用户确认后再调用对应 skill，不自动移交。

#### 🔴 Step 8.1: 移交前写入 pipeline-state（HARD RULE）

**在调用下游 skill 之前**，必须先将当前深度和阶段信息写入 `pipeline-state.json`，确保下游 skill 能正确继承：

```json
{
  "change_id": "<YYYYMMDD-需求名>",
  "depth": "<🔵quick / 🟡standard / 🟢full-engineering>",
  "demand_type": "<document / development / bugfix / testing / review>",
  "current_stage": "brainstorming-complete",
  "stages": {
    "brainstorming-complete": {
      "timestamp": "<ISO 8601>",
      "deliverables": ["<spec文件路径>"]
    }
  }
}
```

**移交上下文声明**：调用下游 skill 时，必须在 prompt 中明确传递：

```
📋 移交上下文：
  change_id: <YYYYMMDD-需求名>
  depth: <🔵quick / 🟡standard / 🟢full-engineering>
  demand_type: <document / development / ...>
  spec_path: <方案文档路径>
```

下游 skill 启动后第一件事就是读取 `pipeline-state.json` 继承 depth。

## 反模式

> "这个太简单了，不需要设计"

简单项目里的隐含假设是浪费工作的最大来源。
设计可以短（几句话），但不能省。

## 错误沉淀评估

→ 按路径解析规则加载 `01-rules/02-development-workflow/02-error-precipitation.md`，按其中的评估步骤执行。

## 🔴 会话结束门禁

AI 不得自行跳过 Step 8 询问并结束会话。

必须满足以下条件才能结束：
1. Step 1-7 已执行完成
2. Step 8 链式移交询问已向用户展示
3. 用户明确选择"暂不继续"或"结束"

如用户长时间未回复，AI 应提示：
> "方案设计已完成。请选择：审核方案 / 生成文档 / 直接编码 / 暂不继续"

## 与 Superpowers 对齐

此 skill 是对 Superpowers `brainstorming` 的 harness 增强版：
- 同样的 9 步流程
- 同样的 `<HARD-GATE>` 约束
- 同样的 spec → plan → execute 链路
- 额外：精益需求方法（纲举目张法）、七大思维推演、链式移交（设计→文档/编码/审核）、pipeline-state 衔接

**优先级**：触发词重叠时，优先使用本 skill（而非 `superpowers:brainstorming`）。详见 `harness-entry` SKILL.md 中的"与 Superpowers 的优先级声明"。
