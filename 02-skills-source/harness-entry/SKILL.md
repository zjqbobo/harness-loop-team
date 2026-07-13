---
name: harness-entry
description: Use when starting any conversation or receiving any task — establishes that all harness engineering disciplines apply, including mandatory brainstorming before implementation, template compliance for documents, and systematic debugging for bugs. This skill auto-loads at session start to set the discipline baseline.
---

# Harness Engineering — 入口

## 触发边界

harness-entry **仅在用户说了明确的工程动作词时触发**（见下方"自动触发的技能"表）。用户只是讨论想法、提问、澄清时，不进入 harness，直接回答。

**AI 不得自行将"讨论/想法"升级为"工程任务"。** 只有当用户明确说了动作词（"设计方案/写代码/修bug/写测试/写文档"等），才进入分诊流程。

## 🔴 会话恢复检查（每次进入 harness 时执行）

进入 harness 流程前，检查是否存在中断的任务：

1. **先查项目目录**：`<project>/.harness/04-changes/` 下查找 `pipeline-state.json`（`current_stage != "closed"`）
2. **再查全局目录**（兜底）：`~/.claude/harness/04-changes/` 下查找（仅限历史遗留变更，新变更不再写入此处）
3. 如找到进行中的变更 → 读取 `depth` 和 `demand_type` → 提示用户：
   ```
   ⚠️ 检测到进行中的变更 [change_id]，深度 [depth]，当前 [current_stage]，是否继续？
     - 继续 → 恢复 depth/demand_type，调用对应领域 skill 接续执行
     - 新建任务 → 正常分诊
   ```
4. 如无进行中的变更 → 正常分诊

## 核心纪律基线

<HARD-GATE>
以下纪律对所有任务生效，不可绕过。流程不可省，但深度可缩放（详见下方分诊表）：

1. 开发/设计 → 按分诊矩阵深度档位路由：🔵快速通道跳过 brainstorming 直接执行；🟡标准/🟢完整需对应的分析或设计环节。**多角色移交场景**：如上游角色已交付 spec/PRD，从当前阶段接续，不重复设计
2. 任何文档生成 → 必须先 Read 模板 → 逐节匹配 → MD 草稿 → 用户审阅 → 转换交付
3. 任何 bug → 必须先找根因 → 稳定复现 → 才修
4. 禁止临时写脚本代替标准工具脚本（mermaid-render.sh / md2docx.sh / svg2png.sh）
5. 禁止凭印象生成代替读模板
6. 🔴 **知识沉淀**（覆盖全流程）：
   - **触发场景**：a) 修复错误后（debug/implementation/testing/code-review/document-generation/brainstorming）、b) 方案设计结束时（brainstorming 产出中有非显而易见的架构取舍或设计决策）、c) 用户显式表达踩坑耗时（如"这个坑花了我半天""这次花了太长时间"等）
   - **评估步骤**：输出沉淀判断（类型+严重度+摘要，或"无需沉淀：原因"）→ 向用户展示并请确认——如判断值得沉淀，用户确认后执行；如判断无需沉淀，用户确认跳过（用户可 override 强制沉淀）
   - **沉淀执行**：查 `00-harness-core/knowledge-index.yaml` 判重 → 同类合并/新类新建 → 写入文件并更新索引
   - 设计决策沉淀写入 `docs/patterns/recommended.md`，反模式写入 `docs/patterns/anti-patterns.md`
   - 与测试门禁同构：AI 必须问，用户可以说不沉淀，但 AI 不能不问
   - 🔴 **触发时机判定细化**：用户在对话中表达对 AI 行为的批评、质疑、纠正时（如"你怎么就直接实施了""为什么没有触发XX流程""你应该先XX再XX"），这属于流程违规触发条件，必须立即执行沉淀评估，不得先补救再评估。补救行为和沉淀评估应并行，或者先评估再补救，但不得跳过评估直接补救

7. 🔴 **流程恢复门禁**：用户指出流程违规、工具使用错误、跳过步骤、或 AI 自行结束时，AI 必须先执行沉淀评估与补救；补救完成后必须输出 `恢复点：<skill> Step X / Phase Y`，并继续执行原 pipeline。禁止把“修正该错误”当作会话终点。
8. 🔴 **结构化交互门禁**：所有”是否继续/下一步/二选一/多选/确认执行/是否提交/是否测试/是否审查”等决策，必须使用 `AskUserQuestion` 或 `PromptForUserInput`。禁止用普通文本让用户输入 `1/2/继续/是/否`。
9. 🔴 **图片识别降级**：当前会话模型不支持图片输入时（如 DeepSeek 系列），禁止调用 `Read` 读取截图/图片文件。截图照常捕获嵌入（Playwright/screenshot 脚本服务端执行），AI 跳过看图验证，标明”请人工检查截图”，流程继续不阻断。

反模式：”这个太简单了，不用走流程”——简单任务的设计可以是一句话，但不能跳过。
反模式：”我先把用户指出的问题修了，然后总结结束”——必须恢复到原流程恢复点继续执行。
反模式：”请选择 1/2”——必须使用结构化交互工具。
反模式：”用 Read 打开截图检查一下”——当前模型不支持图片输入时，Read 图片文件会直接报错阻断会话。
</HARD-GATE>

---

## 任务分诊（每次收到任务时展示）

当用户描述需求后，**先从自然语言提取已明确信息，仅对缺失部分使用 `AskUserQuestion`**。同一场景，同一条纪律链路，但深度不同。

### 分诊交互规范

**原则：能推断的不问，只问缺失的。**

#### 信息可推断性

| 维度 | 可推断关键词 | 示例 |
|------|------------|------|
| 需求类型 | "写/改文档"→✍️；"开发/实现/加个"→💻；"修/报错/bug"→🔧；"写测试/跑测试/测一下"→🧪；"review/审查/看下代码"→👀 | "加个导出按钮"→💻 |

| 新建/存量 | "写/新建/加/做/创建"→🆕；"改/修改/更新/变更/重构"→🔄 | "改下设计文档"→🔄 |
| 深度 | 极少在自然语言中明确，默认需要提问 | "随便扫一眼"→🔵（少数例外） |

#### 交互规则

1. **信息齐全**（需求类型+深度+新建/存量均已明确）→ 直接执行，不提问
2. **仅深度缺失**（最常见，占 80%）→ 只问深度档位，1 轮
3. **需求类型模糊**（如"帮我出个方案"）→ 问需求类型 → 深度，2 轮
4. **全模糊**（如"帮我搞一下"）→ 需求类型 → 深度 → 新建/存量，最多 3 轮

#### 各步骤选项定义（仅在缺失时展示对应步骤）

**需求类型（仅模糊时问）：**
- ✍️ 写文档: 内容已写好/给了要点/从0到1
- 💻 开发功能: 改配置修typo/新接口新页面/新系统架构变更
- 🔧 修 bug: 一眼能看出原因/需要定位修复/完全不知道原因
- 🧪 写测试: 加关键路径用例/标准覆盖/全量覆盖
- 👀 做审查: 快速扫一眼/逐文件检查/正式评审

**深度档位（几乎必问）：**
- 🔵 快速通道: 这个我完全想清楚了，快速执行即可
- 🟡 标准流程: 需求清楚但要规范，走标准流程
- 🟢 完整工程: 重要功能不容有失，走完整工程流程

**新建/存量（仅 🟡/🟢 且用户未指明时问）：**
- 🆕 新建: 从零开始创建，走 brainstorming 流程
- 🔄 存量变更: 基于已有文档/代码增量变更，检索现有产出物后定位修改

> 🔵 快速通道不追问新建/存量——快速通道本身就在现有文件上操作，无需区分。
> 🔧 修 bug 不追问新建/存量——bug 总是在已有代码上修复。

### 分诊矩阵详情（Agent 内部参考，不直接展示给用户）

| 需求类型 | 🔵 快速通道 | 🟡 标准流程 | 🟢 完整工程 |
|---------|-----------|-----------|-----------|
| ✍️ 写文档 | 内容已写好，排版+配图+转格式。跳过 brainstorming → Read 模板 → 生成 → md2docx | 给了要点和方向，展开+配图+交付。简版 brainstorming(3问) → 生成 MD 草稿 → 用户审阅 → docx | 只有一个想法，从0到1出完整方案。完整 9 步 brainstorming → Read 模板 → 逐节生成 → 图表 → 审阅 → docx |
| 💻 开发功能 | 改配置、修 typo、调样式、单行 bugfix、无文档的一句話小需求（加按钮/改校验/小调整）。1问问清 → 直接改 → 确认结果 → commit | 新接口、新页面、中等功能、重构。3-5问问清 → 设计文档(半页) → TDD → review → commit | 新系统、新模块、架构变更、安全相关。完整 9 步 brainstorming → plan → TDD → testing → 独立评审 → commit |
| 🔧 修 bug | 一眼能看出原因，改完即可验证。说清现象 → 直接改 → 验证 → commit | 知道大概范围，需要定位和修复。systematic-debugging 精简版(1-2阶段) | 完全不知道原因，需要完整排查。完整四阶段根因分析 + 三次失败规则 |
| 👀 做审查 | 快速扫一眼，看出明显问题。指出明显问题即可 | 逐文件检查，关注规范和隐患。规范 + 安全 + 性能 | 正式评审，有评审结论和记录。角色分离 + 三阶段评审 + 输出评审结论 |
| 🧪 写测试 | 给关键路径加几个用例，验证核心逻辑。Happy path 用例即可 | 标准覆盖，有 mock 和边界测试。单测: mock+边界+异常，E2E: 核心流程截图 | 全量覆盖，有截图报告。单测(≥80%覆盖) + E2E + 截图报告 |

> ✍️写文档的"Read 模板"：从用户描述中提取**领域词**（系统设计/接口/物理模型/测试用例/PRD 等），忽略格式词（方案/文档/报告），在 `09-templates/` 中匹配模板文件名。领域词匹配到即用对应模板（如"系统设计方案"→系统设计文档模板.md，"接口方案"→接口设计文档模版.md）；领域词无匹配（如"技术方案"中"技术"无对应模板、或仅说"出方案"无领域词）→ 按方案类自由生成，不套模板。多个候选或不确定时，列出可用模板让用户选。

### 存量变更行为表（Agent 内部参考）

当用户选择 🔄 存量变更 时，brainstorming 切换为**存量分析模式**——从现有产出物出发进行变更影响分析，而非从零发散。核心差异：起点是 Read（现有文档/代码），而非从需求描述开始发散：

| 需求类型 | 🟡 存量标准 | 🟢 存量完整 |
|---------|-----------|-----------|
| ✍️ 写文档 | 检索知识库 → Read 现有文档 → Diff 变更分析 → 增量更新章节 → 版本标注 → 审阅 | 检索知识库 → Read 现有文档 → 完整影响分析 → 逐章更新 → 版本记录+Changelog → 一致性校验 → 审阅 |
| 💻 开发功能 | 检索关联 spec/设计文档 → Read → 变更影响分析 → 增量编码 → TDD → review | 检索知识库全量关联文档 → Read → 完整影响分析 → 增量编码+TDD → 回归测试 → 关联文档回写 |
| 🔧 修 bug | 直接读代码 → 聚焦排查 → 修复 | 检索历史变更(git log/blame) → Read 相关代码 → 完整根因分析 → 修复 → 必要时回写文档 |
| 👀 做审查 | 确认审查目的→按需检索。代码质量审查：读 diff+代码 → 逐文件检查 → 规范/安全/性能。变更一致性审查：检索关联文档 → Read → 变更范围审查 → 一致性检查 | 确认审查目的→按需检索。代码质量审查：完整代码审查+安全+性能分析 → 评审结论。变更一致性审查：检索关联+依赖文档 → Read → 完整变更审查 → 一致性+兼容性校验 → 评审结论 |
| 🧪 写测试 | 检索关联 spec → Read → 针对变更范围补充用例 | 检索全量关联文档 → Read → 变更范围+回归范围分析 → 全量补充用例+回归执行 |

### 知识库检索决策（存量 + 新建均适用）

> 新建检索目的是找到**参考/输入文档**，存量检索目的是找到**待修改文档**。
> 检索路径与优先级由 harness 路径解析规则统一处理，此处不重复定义。

检索关联文档**并非对所有需求类型生效**，按需求类型区分：

| 需求类型 | 是否需要检索 | 说明 |
|---------|:---:|---------|
| ✍️ 写文档 | ✅ 是 | 存量：找待变更文档；新建：找参考/输入文档（如写设计文档需读 PRD） |
| 💻 开发功能 | ✅ 是 | 找关联 spec/设计文档，分析变更影响面 |
| 🔧 修 bug | ⚠️ 按深度 | 🟡：不检索，直接读代码；🟢：检索 git log/blame + 关联代码 |
| 👀 做审查 | ⚠️ 按目的 | 代码质量审查：不检索。变更一致性审查：检索关联文档 |
| 🧪 写测试 | ⚠️ 按深度 | 🟡：检索关联 spec；🟢：检索全量关联文档 |

**选错可以随时升级。** 快速通道改不动了 → 切标准流程。标准流程发现复杂度超预期 → 切完整工程。

---

### 分诊完成后：写入初始 pipeline-state

分诊确认（需求类型 + 深度 + 新建/存量）后，在调用领域 skill 前，**必须**在变更目录写入 `pipeline-state.json`：

🔴 **变更目录路径约束**：变更目录必须写入 **项目根目录** 下的 `.harness/04-changes/<YYYYMMDD-需求名>/`。项目根目录通过 `git rev-parse --show-toplevel` 获取，非 git 项目通过 `AskUserQuestion` 确认。禁止写入 `~/.claude/harness/04-changes/`（全局目录）。详见 CLAUDE.md "04-changes/ 写入约束"。

```json
{
  "change_id": "<YYYYMMDD-需求名>",
  "depth": "quick | standard | full-engineering",
  "demand_type": "document | development | bugfix | testing | review",
  "created_at": "<ISO 8601>",
  "updated_at": "<ISO 8601>"
}
```

> ⚠️ 分诊不是正式工作阶段，**不设 `current_stage`**（留空）。`depth` 和 `demand_type` 由分诊结果填入，下游 skill 必须继承，禁止自行修改。下游 skill 完成第一阶段工作后才写入第一个 `current_stage`（如 `brainstorming-complete` 或 `document-complete`）。

---

## 多角色入口路由

harness 支持不同角色从不同阶段进入，分诊矩阵定义的是**完整链路**，实际起点按上游产出物决定。

### 角色入口映射

| 角色 | 典型入口 | 前置条件 | 实际链路 |
|---|---|---|---|
| PM/产品经理 | `✍️ 写文档` | 需求想法已成型 | brainstorming → PRD 草稿 → 审阅 → 交付(docx) |
| 架构师/tech lead | `✍️ 写文档` | PM 已交付 PRD | Read PRD → 系统设计文档 → 审阅 → 移交开发 |
| 后端/前端开发 | `💻 开发功能` | spec/PRD 已交付 | 从 spec 接续 → TDD 编码 → testing |
| 测试工程师 | `🧪 写测试` 或 `💻 开发功能` | 代码已提交，pipeline-state 在 implementation-complete | 从 testing 接续 → 补充用例 → E2E |
| reviewer | `👀 做审查` | 代码+测试已完成 | 独立评审 → 输出结论 → 移交提交 |

### 上游移交检测

无论新建还是存量变更，进入 domain skill 前，AI 必须先按知识库检索决策表检查是否需要检索上游关联文档。检索路径由 harness 路径解析规则处理。判定依据为实际检索结果，不依赖"已批准"等需人工判断的状态。

> 兜底：harness 知识库中未找到时，使用 `AskUserQuestion` 询问用户提供：① 本地文件路径、② 文档 URL、③ 确认跳过。
> 用户提供 **本地路径** 时：直接 `Read` 文件。
> 用户提供 **URL**（飞书/Confluence/语雀/Notion 等内部平台）时，通过 `agent-browser --profile "Default"` 打开链接（复用用户 Chrome 登录态），`snapshot` 读取内容，`screenshot` 捕获图片/图表。
> 
> ### 外部文档写入策略
> 
> 写入外部文档时，API MCP 方案 token 消耗过大（需读全量 block tree + JSON 解析 + 索引计算），不推荐。使用降级策略：
> 
> 1. **首选：`@playwright/mcp` + clipboard paste** — 打开文档编辑页 → 定位 contenteditable → 剪贴板注入内容 → 截图验证
> 2. **兜底：手工粘贴 markdown** — AI 备好内容，用户 Ctrl+V 完成（30 秒，零风险）

| 当前选择的流程 | 检测条件 | 路由调整 |
|---|---|---|
| `✍️ 写文档` + 🆕新建（文档涉及系统设计/技术方案，且存在上游 PRD/设计文档） | 按检索规则找到关联 PRD/设计文档 | Read 关联文档作为输入 → 从既有文档接续设计，不重复 brainstorming |
| `💻 开发功能` + 🟡/🟢 + 🆕新建 | 按检索规则找到关联 spec/设计文档 | Read 关联文档作为输入 → 不重复设计阶段，从 implementation 接续 |
| `💻 开发功能` + 🟡/🟢 + 🔄存量变更 | 按检索规则找到关联文档 | 从变更影响分析开始 |
| `💻 开发功能` + 🟡/🟢 | 无上游关联产出物 | 从 brainstorming 开始，产出 spec 后移交 implementation |
| `🧪 写测试` | pipeline-state 显示 `implementation-complete` | 提示"检测到编码已完成，是否接续测试？" → 用户确认后从 testing 开始 |
| `🧪 写测试` | 无 pipeline-state 或无 `implementation-complete` 记录 | 直接作为独立测试任务执行，不拦截 |
| `👀 做审查` | pipeline-state 显示 `testing-complete` | 提示"检测到测试已完成，是否接续审查？" → 用户确认后从 review 开始 |
| `👀 做审查` | 无 pipeline-state 或无 `testing-complete` 记录 | 直接作为独立审查任务执行，不拦截 |

### 流水线阶段衔接

```
[文档] document-complete → [编码] implementation → implementation-complete → [测试] testing → testing-complete → [审查] code-review → code-review-complete → commit
   ↑ 写文档角色交付                                 ↑ 测试角色可接续                        ↑ reviewer可接续
```

每个 domain skill 完成后写入 `pipeline-state.json`，下游角色通过读取该文件确认接续点。

---

## 自动触发的技能

| 当你收到... | 自动触发 |
|------------|---------|
| "设计/方案/分析需求/架构/选型" | `harness-brainstorming` |
| "审核方案/review设计/方案评审" | `harness-design-review` |
| "拆任务/排期/分任务/里程碑/用户故事/需求拆解" | `harness-pmo` |
| "写文档/出方案/生成 PRD/写设计文档" | `harness-document-generation` |
| "修 bug/调试/报错/不工作" | `harness-systematic-debugging` |
| "review/审查/检查代码" | `harness-code-review` |
| "实现/开发/写代码" | `harness-implementation` |
| "写测试/跑测试/端到端/测覆盖率" | `harness-testing` |
| "初始化项目规范/生成项目约定/harness-init" | `harness-init` |

触发方式：**自然语言**，无需 `/` 命令。用户无需知道技能名称。

---

## 详细规则位置

按 CLAUDE.md「路径解析规则」查找（项目 `.harness/` > `~/.claude/harness.local/` > `~/.claude/harness/`）：

| 类别 | 相对路径 |
|------|---------|
| 核心流水线 | `00-harness-core/` |
| **知识索引** | **`00-harness-core/knowledge-index.yaml`**（错误沉淀判重 + 知识资产清单，**按需加载**，不在启动时读取） |
| 开发流程规范 | `01-rules/02-development-workflow/` |
| 分诊矩阵详情 | `01-rules/02-development-workflow/03-triage-matrix.md` |
| 文档生成规范 | `01-rules/04-document-standards/` |
| 测试规范 | `01-rules/02-development-workflow/01-testing-standards.md` |
| 编码规范 | `docs/coding-standards/` |
| 架构与业务知识 | `docs/architecture/`、`docs/business/` |
| 项目工程约定 | `docs/architecture/project-conventions.md` |
| 编码模式与反模式 | `docs/patterns/` |
| 文档模板 | `09-templates/` |
| 工具脚本 | `scripts/doc/` |

### 知识索引

`00-harness-core/knowledge-index.yaml` 用于错误沉淀判重。**按需加载**：仅在用户确认沉淀教训时读取，不在 harness-entry 启动时加载，避免浪费 token。

---

## 关于 Harness

Harness Engineering 是一套开源 AI Agent 工程纪律体系。
与 Superpowers 同源的设计哲学：AI 编程缺的不是智力，是纪律，而纪律可以用纯文本分发。

- 安装: `git clone <repo> ~/.claude/harness && cd ~/.claude/harness && ./install.sh`

---

## 🔴 与 Superpowers 的优先级声明

Harness 和 Superpowers 同时安装时，部分 skill 触发词重叠。以下规则明确分工和优先级：

### 分工

| 领域 | Superpowers | Harness |
|------|------------|---------|
| 方案设计 | `superpowers:brainstorming`（通用探索） | `harness-brainstorming`（9步流程 + 精益需求 + 链式移交） |
| 调试 | `superpowers:systematic-debugging`（四阶段根因） | `harness-systematic-debugging`（同上 + 沉淀评估 + 流水线衔接） |
| TDD | `superpowers:test-driven-development`（红绿重构） | `harness-implementation`（TDD + 编码规范 + 技术栈检测 + 流水线衔接） |
| 代码审查 | `superpowers:requesting-code-review` | `harness-code-review`（三阶段 + 多维度对照表 + 流水线衔接） |
| 方案审核 | — | `harness-design-review`（四检查面 + 循环至零阻断） |
| 文档生成 | — | `harness-document-generation`（模板遵循 + 图表渲染 + MD→DOCX） |
| 项目管理 | — | `harness-pmo`（里程碑→史诗→用户故事→任务） |
| Git worktree | `superpowers:using-git-worktrees` | — |
| 子代理调度 | `superpowers:subagent-driven-development` | — |
| 计划执行 | `superpowers:executing-plans` | — |

### 优先级规则

1. **Harness 优先**：当触发词同时命中 Superpowers 和 Harness 的 skill 时，**优先使用 Harness 的对应 skill**。Harness skill 是 Superpowers skill 的企业级增强版，包含额外的流水线衔接、知识沉淀、结构化交互等能力。

2. **Harness 未覆盖的领域**：直接使用 Superpowers（如 `using-git-worktrees`、`subagent-driven-development`、`executing-plans`）。

3. **harness-implementation 内部**：编码执行模式选择中，`subagent-driven-development`（Superpowers）和 `executing-plans`（Superpowers）是推荐选项。Harness 做纪律约束，Superpowers 做执行调度——两者协作而非互斥。

4. **不重复执行**：如果已通过 Harness skill 完成了某个阶段（如 brainstorming），不要再调用 Superpowers 的同名 skill 重复执行。
