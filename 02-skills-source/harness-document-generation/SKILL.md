---
name: harness-document-generation
description: Use when user asks to 生成文档, 写方案, 出文档, 写设计文档, 写PRD,
  写接口文档, 写物理模型, 产出文档, 输出文档, generate document, write proposal, create doc
  — ensures brainstorming → template/structure compliance → diagrams → md draft → user review → docx pipeline.
  Triggers on: 帮我写, 生成文档, 出个方案, 写个PRD, 写设计文档, 产出, 输出文档.
---

# Harness — 文档生成

<HARD-GATE>
生成任何文档前必须：
1. 🔴 Phase -2: Pipeline Context Recovery — 从 pipeline-state.json 继承 depth，输出深度确认
2. 触发 brainstorming → 用户确认方案
3. **判定文档子类型**（见下方分类表）→ 正式文档走模板硬匹配，方案类文档走轻量结构
4. 生成 MD 草稿 → 用户审阅
5. 架构图嵌入 + 原型生成（PRD/产品文档必须） + 所有 .md 转 .docx
跳过任意一步 = 违规。

---

## 🔴 文档生成完成后询问不可跳过

文档交付完成后，必须依次询问：
1. 是否生成本次项目迭代方案设计文档？
2. 后续是否需要编码实现？

AI 不得在未询问用户的情况下声称"文档生成完成"或结束会话。

---

## 🔴 流程恢复门禁

用户在流程中指出错误、违规或跳过步骤后，AI 完成补救和沉淀评估后，必须：
1. 输出 `恢复点：harness-document-generation Phase X`
2. 从该恢复点继续执行原 pipeline
3. 禁止把补救完成当作当前阶段完成或会话终点

若无法判断恢复点，必须使用 `AskUserQuestion` 询问用户恢复到哪一步。

---

## 🔴 结构化交互门禁

所有"是否继续/下一步/确认执行/跳过/生成/审阅/交付"等决策，必须使用 `AskUserQuestion` 或 `PromptForUserInput`。

禁止使用普通文本让用户输入 `1/2/继续/是/否`。
</HARD-GATE>

## 文档子类型分类

在 Phase 1 之前，必须先判定文档子类型，不同类型走不同流程深度：

| 子类型 | 触发词 | 流程 | 模板要求 |
| --- | --- | --- | --- |
| **正式文档** | 写设计文档/写接口文档/写物理模型/写测试文档 | 模板硬匹配：Read 模板 → 逐节匹配 → 不遗漏 | 必须，跳过模板=违规 |
| **方案类文档** | 写方案/出方案/技术方案/方案设计 | 自由结构：AI 根据实际内容自行组织章节，不套模板 | 无，按需自由生成 |
| **PRD/产品文档** | 写PRD/产品需求/需求文档 | 模板硬匹配 + 原型生成 | 必须 + 原型截图 |

**判定规则：**
- 用户说"方案"但指定了模板（如"按设计文档模板出"）→ 按用户指定的模板走
- 用户说"写文档"但内容是方案性质 → 按方案类走
- 无法判定时，用 `AskUserQuestion` 询问用户选择子类型

## 方案类文档自由生成规则

方案类文档不套模板，AI 根据实际内容自行决定章节结构和深度：
- 只写与当前方案相关的章节，不填无意义的占位内容
- 架构图/流程图仍然必须渲染为 PNG（禁止 ASCII 线框图）
- 仍然走 MD 草稿 → 用户审阅 → DOCX 的交付流程

## 执行流程

### Phase -2: Pipeline Context Recovery（🔴 HARD RULE，Phase -1 之前必须执行）

**下游 skill 启动后第一件事：从 pipeline-state 继承深度档位。**

#### Step 1: 读取 pipeline-state.json

按路径解析规则查找 `<project>/.harness/04-changes/<change_id>/pipeline-state.json`，读取 `depth` 和 `demand_type` 字段。

若无法定位 change_id（独立触发，无上游移交），则通过 `AskUserQuestion` 询问用户深度档位：
- 🔵 快速通道
- 🟡 标准流程
- 🟢 完整工程

#### Step 2: 输出深度确认

```
📋 Pipeline Context Recovery：
  ✅ 深度档位：[从 pipeline-state 继承: 🟢 完整工程]
  ✅ 需求类型：[development / document / ...]
  ✅ 当前阶段：[brainstorming-complete / document-complete / ...]
```

#### Step 3: 深度驱动行为差异

| 深度 | 文档生成行为 |
|------|------------|
| 🔵 quick | 方案类自由生成，不强制模板硬匹配，不强制逐节检查，不强制技术设计门禁 |
| 🟡 standard | 正式文档走模板硬匹配，方案类自由生成，PRD 后技术设计门禁可选 |
| 🟢 full-engineering | 🟡全部 + **Phase 0.5 技术设计增强**（架构选型 trade-off + 质量属性量化 + 技术风险识别）+ PRD 后强制技术设计门禁 + 物理模型两阶段生成 |

**禁止在未完成 Pipeline Context Recovery 前进入 Phase -1。**

---

### Phase -1: 存量设计文档按需加载（新增）

**触发条件**：任务涉及修改现有设计方案，且变更目录存在存量设计文档

#### Step 1: 检测存量设计文档

查找变更目录下的设计文档（按优先级）：
- 00-design.md
- *设计方案.md
- *设计文档.md

#### Step 2: 检测索引文件

若存量设计文档存在，查找 `*.manifest.json`：
- **不存在** → 调用 `harness-design-indexer` 生成
- **存在但失效**（文件大小或修改时间变化）→ 调用 `harness-design-indexer` 更新
- **存在且有效** → 跳过生成

#### Step 3: AI 自行判断加载章节

根据任务描述（如"修改消息发送模块"），AI 自行判断需要加载哪些章节：
- 读取索引文件，查看可用章节
- 根据任务关键词和章节关键词，决定加载哪些
- 使用 `Read(file_path, offset=start-1, limit=end-start+1)` 按行号范围加载

**建议**：优先按需加载，若 AI 判断需要全局视图（如全量重构、架构调整）可全量加载

#### Step 4: 透明化提示

```
📋 存量设计文档按需加载：
   - 设计文档：00-design.md（共 5972 行）
   - 已加载章节：
     ✅ 项目概览（1-150行）
     ✅ 系统架构设计（151-650行）
     ✅ 消息模块设计（2000-2800行）
   📊 已加载约 1450 行（节省 76%）
```

### Phase 0: 文档子类型判定 + 知识加载验证

→ 根据触发词和用户描述，判定文档子类型（正式文档 / 方案类 / PRD）
→ 无法判定时用 `AskUserQuestion` 询问
→ 子类型决定后续 Phase 1 的流程深度

**🔴 知识加载验证（必须展示）**

正式文档/PRD 在 Phase 1 读取模板前，必须先输出检查结果：

```
📋 文档生成前检查：
  ✅/❌ 深度档位：[从 Phase -2 继承: 🔵/🟡/🟢]
  ✅/❌ 文档子类型：[正式文档/方案类/PRD]
  ✅/❌ 模板已定位：[模板文件路径]
  ✅/❌ 文档规范已读：[01-rules/04-document-standards/01-docs-workflow.md]
```

### Phase 0.5: 完整工程-技术设计增强（🔴 HARD RULE，depth=full-engineering + 系统设计时强制）

**触发条件**：Phase -2 继承 depth=full-engineering **且** Phase 0 判定子类型为正式文档（系统设计/技术方案）

**不满足触发条件 → 跳过此 Phase，直接进入 Phase 1。**

#### 为什么需要这个 Phase

完整工程在 brainstorming 阶段对 PRD 执行了纲举目张法+七大思维推演，产出质量高。但链式移交到 document-generation 生成技术方案时，如果只读模板填内容，质量会断崖式下跌。此 Phase 确保技术方案也经过同等深度的分析。

#### 执行步骤

##### Step 1: 加载上游 PRD/需求文档

从变更目录查找 PRD 或 00-design.md，Read 核心章节（业务目标、功能需求、质量属性）。

```
📋 上游需求加载：
   ✅ PRD/需求文档：[文件路径]
   ✅ 已加载章节：业务目标、功能需求清单、质量属性指标
```

##### Step 2: 架构选型 Trade-off 分析

基于需求文档，对关键技术决策做 trade-off 分析：

| 决策点 | 候选方案 A | 候选方案 B | 推荐 | 理由 |
|-------|-----------|-----------|------|------|
| 框架选型 | ... | ... | ... | 与现有技术栈一致性/团队能力/性能指标 |
| 数据库选型 | ... | ... | ... | 数据量级/查询模式/事务要求 |
| 通信方式 | ... | ... | ... | 实时性/解耦程度/运维复杂度 |
| 部署策略 | ... | ... | ... | 可用性要求/成本/弹性需求 |

##### Step 3: 关键质量属性量化

针对需求文档中的质量属性，给出具体量化指标和实现策略：

| 质量属性 | 目标指标 | 实现策略 | 验证方式 |
|---------|---------|---------|---------|
| 性能 | P95 < 200ms / QPS > 1000 | 多级缓存 + 异步 + 连接池 | 压测验证 |
| 可用性 | 99.9% / RTO < 5min | 多副本 + 健康检查 + 自动故障转移 | 故障演练 |
| 安全性 | OWASP Top 10 全覆盖 | 输入校验 + 参数化查询 + 加密 + 权限控制 | 安全扫描 |
| ... | ... | ... | ... |

##### Step 4: 技术风险点识别

| 风险 | 严重程度 | 发生概率 | 缓解措施 | 兜底方案 |
|------|---------|---------|---------|---------|
| ... | 高/中/低 | 高/中/低 | ... | ... |

##### Step 5: 融入文档

将以上分析结果写入技术方案的对应章节：
- Trade-off 分析 → "三、架构设计 > 3.3 技术架构" 
- 质量属性量化 → "二、概述 > 2.4 质量属性识别"
- 技术风险 → "三、架构设计 > 3.2.3 高可用设计" 或独立风险章节

**禁止在未完成 Phase 0.5 四步分析前进入 Phase 1 模板填充。** 先分析，再填模板，分析结果直接成为文档内容。

---

### Phase 1: 结构遵循

→ 始终加载：`01-rules/04-document-standards/00-overview.md`（规范索引，帮助发现适用的规范文件） + `01-docs-workflow.md`
→ 按子类型额外加载：
  - **PRD** → `02-prd-standards.md` + `03-requirements-methods.md`
  - **系统设计** → `06-system-design-standards.md`
→ **正式文档/PRD**：Read 对应模板文件 → 逐节匹配，禁止凭印象生成
→ **方案类文档**：自由生成，AI 根据实际内容自行组织章节，不套模板

### Phase 2: 架构图生成
→ Read `01-rules/04-document-standards/01-docs-workflow.md`（重点读"1-图表强制规则"节，按 CLAUDE.md「路径解析规则」查找）
→ 询问工具选择：技术文档 → mermaid / fireworks-tech-graph；产品文档 → Figma / Frontend Design

### Phase 2.5: 原型生成（PRD/产品文档硬性要求）
→ 🔴 如文档类型为 PRD/产品方案 → 必须询问原型工具选择：Figma MCP / ui-ux-pro-max
→ 原型生成规范见 `01-rules/04-document-standards/04-prototype-workflow.md`
→ 🔴 生成真实原型 → Playwright 截图 → 嵌入 PNG → 替换文档中所有 ASCII 线框图
→ 🔴 禁止保留 ASCII 线框图（`┌───┐`）占位，禁止用文字描述代替截图
→ 原型截图宽度 ≥ 1200px，全流程自动化，无需用户干预

### Phase 3: 生成 MD 草稿 + 图表嵌入
→ Mermaid 代码块必须以 .mmd 源文件保存并渲染 PNG
→ fireworks 图表生成 SVG → PNG（1920px）
→ 图片引用：`![图注](images/xxx.png)`

### Phase 4: 用户审阅
→ 展示 MD 草稿
→ 用户确认后继续

### Phase 5: 批量转换交付

→ 🔴 **必须使用 `doc-pipeline.sh` 端到端脚本**，禁止手动逐个执行渲染和转换
→ 执行 `doc-pipeline.sh ./方案.md --mode <mermaid|fireworks>` 自动完成图表渲染+DOCX转换
→ 如图表已处理，使用 `doc-pipeline.sh ./方案.md --skip-render` 只转DOCX
→ 列出清单逐项检查，不得遗漏任何 .md 文件
→ 🔴 **交付物路径**：所有交付物路径以项目根目录为基准记录到 pipeline-state（如 `.harness/04-changes/<id>/00-design.md` 或 `docs/PRD.md`），确保多机器协作时可定位

### Phase 6: 自动生成设计索引（新增）

设计文档转换完成后，若生成了新的设计文档（Markdown 格式），自动执行：

#### Step 1: 调用索引生成 skill

```
设计文档已交付，正在生成章节索引...
```

调用 `Skill("harness-design-indexer", args="--doc-path <设计文档路径>")`

#### Step 2: 输出完成提示

```
✅ 设计文档索引已生成：
   - 设计文档：00-design.md（共 N 行）
   - 索引文件：00-design.manifest.json（M 个章节）
   
💡 后续编码时将自动按需加载相关章节，无需全量读取。
```

**例外**：索引生成失败不影响文档交付，编码时会重新生成。

### Phase 7: 询问下一步

交付完成后，**必须**依次询问用户：

> "文档已交付。是否需要生成本次项目迭代方案设计文档（改动汇总）？"
> - **是** → 基于已生成的系统设计文档/接口设计文档/物理模型设计文档，提取改动汇总 → 按 `09-templates/项目迭代方案设计文档模板.md` 生成 MD 草稿 → 用户审阅 → docx
> - **否** → 继续

#### 🔴 PRD 后技术设计门禁（深度驱动）

若本次交付物为 PRD/产品需求文档，且 Phase -2 继承的深度档位为 🟢 完整工程，**禁止**直接询问"后续是否需要编码实现"。必须先询问：

> "PRD 已交付。完整工程需要技术设计文档（系统设计/接口设计/组件设计等）作为编码输入。是否生成技术设计文档？"

选项：
- **生成技术设计文档** → 调用 `harness-document-generation`，根据需求类型生成对应的技术设计产物
- **跳过，直接编码** → 需用户明确确认（风险自负）

技术设计文档生成并审阅通过后，或用户明确跳过，才可进入下一步。

若已生成 PRD 后续技术设计文档（系统设计/接口设计/组件设计/物理模型等），不得只询问是否编码实现，必须询问：

> "技术设计文档已交付。下一步请选择："
> - **审核技术方案** → 进入 `harness-design-review`；审核通过后回到本步骤重新选择
> - **直接编码实现** → 用户明确确认风险后，进入 `harness-implementation`
> - **暂不继续** → 记录 pipeline-state 后结束

若未生成技术设计文档，才询问：

> "后续是否需要编码实现？"
> - **是** → 进入 `harness-implementation`
> - **否** → 结束

#### 🔴 Phase 7.1: 移交前写入 pipeline-state（HARD RULE）

**在调用下游 skill 之前**，必须更新 `pipeline-state.json`，记录当前阶段完成状态：

```json
{
  "current_stage": "document-complete",
  "stages": {
    "document-complete": {
      "timestamp": "<ISO 8601>",
      "deliverables": ["<文档文件路径>"]
    }
  }
}
```

**移交上下文声明**：调用下游 skill 时，必须在 prompt 中明确传递：

```
📋 移交上下文：
  change_id: <YYYYMMDD-需求名>
  depth: <从 Phase -2 继承的深度>
  demand_type: <从 Phase -2 继承的需求类型>
  deliverables: [<本次生成的文档路径>]
```

## 标准工具脚本

按 CLAUDE.md「路径解析规则」查找 `scripts/doc/` 目录：

```bash
# 🔴 端到端流水线（推荐，一条命令搞定）
doc-pipeline.sh ./方案.md --mode mermaid        # mermaid: 渲染+转换
doc-pipeline.sh ./方案.md --mode fireworks       # fireworks: SVG→PNG+转换
doc-pipeline.sh ./方案.md --skip-render          # 只转DOCX（图表已处理）
doc-pipeline.sh ./方案.md --skip-docx            # 只渲染图表

# 单独使用（doc-pipeline.sh 的拆分版）
render-diagrams.sh ./方案.md --mode mermaid      # Mermaid 代码块→PNG+替换
render-diagrams.sh ./方案.md --mode fireworks    # SVG→PNG+替换MD代码块
md2docx.sh ./方案.md                              # MD→DOCX
svg2png.sh ./images/                              # SVG→PNG（仅转换，不替换MD）
```

## 错误沉淀评估

→ 按路径解析规则加载 `01-rules/02-development-workflow/02-error-precipitation.md`，按其中的评估步骤执行。

## 禁止行为

- ❌ 正式文档不读模板直接写
- ❌ 方案类文档填无意义的占位章节（如 Demo 项目不需要部署架构、分库分表、高可用设计）
- ❌ 漏 tenant_id、漏请求参数表、漏返回码说明、漏数据字典（正式文档）
- ❌ 接口用表格罗列代替逐接口独立子章节（正式文档）
- ❌ 物理模型审计字段未用"其他信息"分隔（正式文档）
- ❌ 只生成 md 不转 docx
- ❌ 临时写 Python/Node.js 脚本代替标准工具脚本
- ❌ 生成无图纯文本文档
- ❌ PRD/产品文档用 ASCII 线框图代替真实UI原型截图
- ❌ PRD/产品文档不询问原型工具选择（Figma / ui-ux-pro-max）直接交付
- ❌ 手动逐个替换图表代码块（必须用 `render-diagrams.sh` 或 `doc-pipeline.sh`）
- ❌ 用户选了 fireworks-tech-graph 却跳过其脚本直接手写 SVG（必须按技能的 `generate-from-template.py` / `generate-diagram.sh` 生成）
- ❌ 跳过文档子类型判定直接进入模板硬匹配

---

## 🔴 文档生成完成标准（Phase 4）

文档生成完成（Phase 4 用户审阅通过）后，必须输出以下检查结果：

```
📋 文档生成完成检查：
  ✅/❌ 文档子类型已判定：[正式文档/方案类/PRD]
  ✅/❌ 模板节匹配完成：[正式文档/PRD]
  ✅/❌ 图表已渲染为PNG：[文件路径列表]
  ✅/❌ MD草稿已审阅通过
  ✅/❌ DOCX已生成：[文件路径]
```

**任一项为 ❌ 时**：完成对应步骤后再进入下一阶段。

---

## 🔴 会话结束门禁

在结束会话前，必须完成以下检查：

```
📋 会话结束检查：
  ✅/❌ 链式移交询问已完成（Phase 7 询问）
  ✅/❌ 用户已明确下一步选择
```

**禁止以下行为**：
- 在未完成链式移交询问的情况下结束会话
- 用户未明确选择就自行判断"任务完成"

会话只能在以下情况结束：
1. 用户明确选择"暂不继续"→ 记录状态 → 结束
2. 用户选择继续 → 调用下一个 skill → 会话移交
