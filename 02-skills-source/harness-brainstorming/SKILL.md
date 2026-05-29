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

### Step 0: 加载领域知识（方案设计前必读）

按路径解析规则（项目 `.harness/` > `~/.claude/harness.local/` > `~/.claude/harness/`）依次查找，找到即停。

| 知识类型 | 文件路径 | 何时加载 |
|---------|---------|---------|
| 技术架构现状 | `docs/architecture/00-overview.md` | **始终加载**（方案必须兼容现有架构） |
| 技术栈与版本 | `docs/architecture/tech-stack.md` | 涉及技术选型时 |
| 系统集成关系 | `docs/architecture/integration-map.md` | 涉及外部系统交互时 |
| 业务现状 | `docs/business/00-overview.md` | **始终加载**（方案必须符合业务语义） |
| 领域术语表 | `docs/business/domain-glossary.md` | **始终加载**（命名必须与术语表一致） |
| 核心业务流程 | `docs/business/core-flows.md` | 涉及业务流程变更时 |
| 推荐编码模式 | `docs/patterns/recommended.md` | 设计落地方案时 |
| 常见反模式 | `docs/patterns/anti-patterns.md` | 方案评审时 |
| 需求分析方法论 | `01-rules/04-document-standards/03-requirements-methods.md` | 分诊结果为 PRD 时 |

> 注意：以上文件为知识模板，初始内容为占位符。如文件内容仍为 TODO，跳过该文件，告知用户需要补充。

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
- 🔴 **架构图/流程图/组件图/数据流图禁止使用 ASCII 线框图（┌┐└┘├┤│─ 等制表符），必须询问用户选择图表工具后绘制：技术文档 → mermaid / fireworks-tech-graph**
- 🔴 **路由矩阵/对比表等表格数据使用 Markdown 表格，禁止包在 ASCII 框里**
- 每段展示后确认是否正确

**PRD/需求文档专用：精益需求自检（仅在分诊结果为 PRD 时执行）**

按七大思维检查需求是否有遗漏——不适用则跳过，但必须过一遍：
- 对称思维：正向/反向操作是否都覆盖？
- 边界思维：上下限是否明确？
- 多样性思维：所有变化维度是否枚举？
- 生命周期思维：核心对象的完整生命周期？
- 异常思维：所有失败场景是否有处理？
- 并发思维：多用户同时操作是否有冲突？
- 安全思维：是否存在安全风险？

自检结果不展示给用户，发现遗漏时直接补充到方案章节中，仅在方案完成后简要说明"已按精益需求七大思维检查，补充了XXX"。

### Step 5: 设计写入 spec 文件
- 路径：按 CLAUDE.md「路径解析规则」查找 `04-changes/` 目录 → `YYYYMMDD-<主题>/00-design.md`
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

### Step 8: 询问是否继续下一步

方案设计完成后，**必须**询问用户：

> "方案设计完成。是否继续下一步？"
> - **编码实现** → 进入 `harness-implementation`
> - **生成文档** → 进入 `harness-document-generation`
> - **暂不继续** → 结束，记录 pipeline-state

用户确认后再调用对应 skill，不自动移交。

## 反模式

> "这个太简单了，不需要设计"

简单项目里的隐含假设是浪费工作的最大来源。
设计可以短（几句话），但不能省。

## 错误沉淀评估（方案设计中触发）— <HARD-GATE> 必须执行，不可静默跳过

brainstorming 过程中发现架构盲区、隐含约束、或违反设计原则时，**必须执行沉淀评估步骤**：

### 评估步骤（必须执行）
1. **输出沉淀判断**：列出本次设计涉及的教训评估
   - 值得沉淀：[类型|严重度|摘要]
   - 无需沉淀：[原因]（如"格式调整"/"已有规则覆盖"/"问题简单无隐含约束"）
2. **向用户展示判断并请确认**：使用 AskUserQuestion 展示评估结果
   - 如判断值得沉淀 → 用户确认后进入沉淀流程
   - 如判断无需沉淀 → 用户确认跳过（用户可 override 强制沉淀）
3. **用户确认沉淀后**：读取 `00-harness-core/knowledge-index.yaml` → 按 tags 计算重叠度（>50% 视为同类）→ 判重 → 同类合并/新类新建 → 写入文件 → 更新索引 → 告知用户沉淀完成

### 不再适用"静默跳过"
评估步骤本身不可跳过。即使判断结果为"无需沉淀"，也必须向用户展示并确认。
这与测试门禁同构：AI 必须问，用户可以说不沉淀，但 AI 不能不问。

### 沉淀路径
| type | severity | 写入位置 | 生效方式 |
|---|---|---|---|
| process | high | 对应 SKILL.md | HARD-GATE 检查点 |
| process | medium | 01-rules/ | 路径解析自动命中 |
| rule | high | 01-rules/ | 路径解析 + SKILL 引用 |
| rule | medium | 01-rules/ | 路径解析自动命中 |
| anti-pattern | any | docs/patterns/anti-patterns.md | Step 0 加载 |
| knowledge | any | docs/architecture/ 或 docs/business/ | 按需加载 + 索引发现 |

### 三层归属判断
- 项目特有约束 → 项目 `.harness/`
- 公司/团队通用 → `~/.claude/harness.local/`
- 通用工程教训 → `~/.claude/harness/`

AI 建议归属层，用户最终确认。

## 与 Superpowers 对齐

此 skill 是对 Superpowers `brainstorming` 的 harness 实现：
- 同样的 9 步流程
- 同样的 `<HARD-GATE>` 约束
- 同样的 spec → plan → execute 链路
