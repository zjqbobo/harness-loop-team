---
name: harness-document-generation
description: Use when user asks to 生成文档, 写方案, 出文档, 写设计文档, 写PRD,
  写接口文档, 写物理模型, 产出文档, generate document, write proposal, create doc
  — ensures brainstorming → template compliance → diagrams → md draft → user review → docx pipeline.
  Triggers on: 帮我写, 生成文档, 出个方案, 写个PRD, 写设计文档, 产出, 输出文档.
---

# Harness — 文档生成

<HARD-GATE>
生成任何文档前必须：
1. 触发 brainstorming → 用户确认方案
2. Read 对应模板（`~/.claude/harness/09-templates/`）→ 逐节匹配
3. 生成 MD 草稿 → 用户审阅
4. 图表嵌入 + 所有 .md 转 .docx
跳过任意一步 = 违规。
</HARD-GATE>

## 执行流程

### Phase 1: 模板遵循
→ Read `~/.claude/harness/01-rules/04-document-standards/01-docs-workflow.md#5️⃣`
→ Read 对应模板文件
→ 逐节匹配，禁止凭印象生成

### Phase 2: 图表生成
→ Read `~/.claude/harness/01-rules/04-document-standards/01-docs-workflow.md#1️⃣`
→ 询问工具选择：技术文档 → mermaid / fireworks-tech-graph；产品文档 → Figma / Frontend Design

### Phase 3: 生成 MD 草稿 + 图表嵌入
→ Mermaid 代码块必须以 .mmd 源文件保存并渲染 PNG
→ fireworks 图表生成 SVG → PNG（1920px）
→ 图片引用：`![图注](images/xxx.png)`

### Phase 4: 用户审阅
→ 展示 MD 草稿
→ 用户确认后继续

### Phase 5: 批量转换交付
→ 执行 `mermaid-render.sh`（如含 Mermaid 图表）
→ 对每个 .md 文档执行 `md2docx.sh`
→ 列出清单逐项检查，不得遗漏任何 .md 文件

## 标准工具脚本

```bash
# Mermaid → PNG 渲染
~/.claude/harness/scripts/doc/mermaid-render.sh ./方案.md

# MD → DOCX 转换
~/.claude/harness/scripts/doc/md2docx.sh ./方案.md

# SVG → PNG 导出
~/.claude/harness/scripts/doc/svg2png.sh ./images/
```

## 禁止行为

- ❌ 不读模板直接写
- ❌ 漏 tenant_id、漏请求参数表、漏返回码说明、漏数据字典
- ❌ 接口用表格罗列代替逐接口独立子章节
- ❌ 物理模型审计字段未用"其他信息"分隔
- ❌ 只生成 md 不转 docx
- ❌ 临时写 Python/Node.js 脚本代替标准工具脚本
- ❌ 生成无图纯文本文档
