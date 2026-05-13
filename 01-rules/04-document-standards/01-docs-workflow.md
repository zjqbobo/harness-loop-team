# 文档生成工作流规范
> 📌 **强制规范：所有方案文档必须包含可视化图表。**

---

## 🔴 强制执行规则
1. **不得生成纯文本文档作为最终交付物
2. **生成图表前必须询问工具选择
3. **脑爆方案确认后自动生成正式文档

---

## 1️⃣ 图表强制规则

### 最低要求
每篇文档至少包含**至少包含一张：
- 总体架构图
- 业务流程图

### 按需附加图表
- 数据流图：跨系统数据流转
- 部署图：服务器、基础设施
- 组件图：模块划分
- 时序图：分步交互、调用链路
- ER图：数据库 schema

### 工具选择（生成前必须询问）
| 文档类型 | 工具选项 | 询问话术 |
|---------|---------|
| 技术文档 | claude-mermaid / fireworks-tech-graph | "需要生成架构图/流程图，claude-mermaid / fireworks-tech-graph？" |
| 产品文档 | Figma / Frontend Design / ui-ux-pro-max | "需要生成原型，Figma / Frontend Design / ui-ux-pro-max？" |

---

## 2️⃣ 脑爆方案 → 正式文档工作流

### 触发时机
用户确认 Brainstorming / 执行计划 / 方案时，按以下流程执行：

1. **第一步：询问格式**
   > "方案已确认，生成什么格式的文档？Word (.docx) 还是 PPT (.pptx)？"

2. **第二步：生成 MD 草稿供用户审核确认

3. **第三步：用户确认后生成最终格式
   - docx 需嵌入对应位置插入图表
   - pptx 按幻灯片布局插入图表

### 禁止行为
❌ 跳过 MD 草稿直接生成最终格式
❌ 不询问格式直接生成最终格式
❌ 确认方案后，无需用户再次指令再生成文档

---

## 3️⃣ 图表嵌入规范

### fireworks-tech-graph 生成流程
1. 生成 SVG 源文件
2. 导出 PNG（宽度 1920px
3. 在 markdown 中使用 `![图注](images/xxx.png)`
4. 在 docx 中嵌入 PNG，宽度 6.2 英寸，图题居中

### Mermaid 生成流程

**⚠️ 强制规范：Mermaid 图表必须同时保存 .mmd 源文件并渲染为 PNG 嵌入文档，禁止仅保留文字代码块！**

#### 标准工具脚本

```bash
# 用法：一键提取+渲染+替换
~/.claude/harness/scripts/doc/mermaid-render.sh ./方案.md
```

**特性：**
1. 自动提取 Markdown 中所有 ` ```mermaid ` 代码块
2. 保存为 `images/mermaid-{type}-{序号}.mmd` 源文件（方便后续修改）
3. 渲染为 `images/mermaid-{type}-{序号}.png`（1920px宽度，白色背景）
4. 自动替换 Markdown 中的代码块为 `![图注](images/xxx.png)`
5. 依赖：mmdc（@mermaid-js/mermaid-cli）+ Chrome（PUPPETEER_EXECUTABLE_PATH）

#### 产物
- `images/mermaid-*.mmd` — 源文件，用户可直接编辑后重新渲染
- `images/mermaid-*.png` — 渲染后的 PNG 图片
- Markdown 文档 — 代码块已自动替换为图片引用

#### 执行时机
在 `md2docx.sh` **之前**执行，确保 docx 中嵌入的是渲染后的 PNG 图片而非代码文字。

```bash
# 完整流程
~/.claude/harness/scripts/doc/mermaid-render.sh ./方案.md   # Step 1: Mermaid → PNG
~/.claude/harness/scripts/doc/md2docx.sh ./方案.md          # Step 2: MD → DOCX
```

---

## 4️⃣ 标准工具脚本（禁止每次临时写脚本！）

### Mermaid → PNG 渲染

**✅ 必须使用 harness 通用脚本，禁止每次临时写 Python 提取/渲染代码！**

```bash
# 用法：mermaid-render.sh <md文件路径>
~/.claude/harness/scripts/doc/mermaid-render.sh ./方案.md
```

### MD → DOCX 标准转换

**✅ 必须使用 harness 通用脚本，禁止每次临时写 docx-js 代码！**

```bash
# 用法：md2docx.sh <md文件路径> [输出docx路径]
~/.claude/harness/scripts/doc/md2docx.sh ./方案.md
```

**特性：**
- 自动识别并嵌入 markdown 中的相对路径图片
- 自动验证图片嵌入数量
- 依赖：pandoc（已预置）

**规范：**
- 所有图片放在 markdown 同级的 `images/` 目录下
- markdown 中使用相对路径引用：`![图注](images/xxx.png)`
- 图表宽度统一为 6.5 英寸（1920px 导出）

### 生成流程（强制执行）
```
用户确认方案 → 生成所有 MD 草稿（含 Mermaid 代码块 + fireworks 图表）
→ 用户审阅通过
→ 对每个 .md 输出文档执行 mermaid-render.sh（保存 .mmd 源文件 + 渲染 PNG + 替换代码块）
→ 对每个 .md 输出文档执行 md2docx.sh 生成最终 docx
```

**⚠️ 强制规则：所有输出的 .md 文档都必须执行 md2docx.sh 转换，不得遗漏任何一个！**

**检查清单（md2docx.sh 执行前逐项确认）：**
- [ ] 主设计文档 .md → .docx
- [ ] 物理模型文档 .md → .docx（如独立输出）
- [ ] 接口设计文档 .md → .docx（如独立输出）
- [ ] 其他引用/附录文档 .md → .docx（如有）

### 物理模型 → DOCX 直接生成

**✅ 物理模型文档必须使用此脚本，禁止走 md→pandoc 流程！**

```bash
# 用法：gen-physical-model.py <input.json> [output.docx]
python3 ~/.claude/harness/scripts/doc/gen-physical-model.py ./tables.json
```

### SVG → PNG 标准导出

```bash
# 用法：svg2png.sh <svg目录或文件>
~/.claude/harness/scripts/doc/svg2png.sh ./images/
```

❌ **禁止行为：**
- 每次临时写 node/docx-js 代码生成 docx
- 手动复制粘贴图片到 Word
- 生成无图的纯文本文档

---

## 5️⃣ 模板强制遵循

### 规则

**⚠️ 生成任何文档时，如 Harness `09-templates/` 中存在对应模板，必须在生成前先 Read 模板，并逐节匹配模板结构，禁止凭印象自由发挥。**

### 模板与文档映射

| 文档类型 | 模板 | 生成方式 | 关键遵循要求 |
|---------|------|---------|------------|
| 系统总体设计方案 | `09-templates/系统设计文档模板.md` | **md → mermaid-render → md2docx** | 按章节结构输出，含架构图/ER图/时序图/类图 |
| 物理模型设计文档 | `09-templates/系统物理模型设计文档模版.docx` (格式权威) / `.md` (内容参考) | **python-docx 直出 docx，不走 md 中间层** | 每表含：字段表 + "其他信息"分隔行(合并单元格) + tenant_id + 索引(合并单元格) + 数据增量 + 数据存储时效 |
| 接口设计文档 | `09-templates/系统接口设计文档模版.md` | **md → md2docx** | 每个接口独立子章节，含：服务端点(多环境) + 请求参数表(字段/类型/必填/说明) + 返回码说明 + 数据字典 + 范例请求+响应 |
| PRD文档 | `09-templates/PRD标准模板_v2.0.md` | **md → md2docx** | 按模板结构输出 |

### 执行要求

1. **生成前**：Read 模板文件，确认各节结构和必填要素
2. **生成中**：模板有定义过的字段/格式不得省略（如 `tenant_id`、`其他信息` 分隔行、`数据增量` 等）
3. **生成后**：对照模板逐项自检，确认无遗漏

### 常见遗漏（禁止发生）

| 文档类型 | 常见遗漏项 |
|---------|----------|
| 物理模型 | ❌ 漏 tenant_id ❌ 审计字段未用"其他信息"分隔 ❌ 漏数据增量 ❌ 漏归档规则 ❌ 合并单元格格式丢失（走pandoc） |
| 接口设计 | ❌ 接口用表格罗列而非独立子章节 ❌ 漏请求参数表 ❌ 漏返回码说明 ❌ 漏数据字典 ❌ 漏范例请求 |

### 物理模型特殊说明

**物理模型文档禁止通过 md→pandoc→docx 生成**，因为 Markdown 表格无法表达模板中的合并单元格（"其他信息""索引""数据量级""归档规则"跨6列合并）。

必须使用通用脚本 `gen-physical-model.py`：

```bash
# 1. 准备表结构 JSON 数据文件
# 2. 执行脚本直接生成 .docx
python3 ~/.claude/harness/scripts/doc/gen-physical-model.py ./tables.json ./物理模型.docx
```

JSON 数据格式见脚本注释。字段名/类型/索引/数据量级对应 `.md` 模板内容，表格样式对齐 `.docx` 模板。生成时只读 `.md` 了解字段结构，**不需要加载 `.docx` 模板到上下文**。

### 犯错记录

| 日期 | 错误 | 根因 |
|------|------|------|
| 2026-05-12 | 物理模型漏 tenant_id、审计字段未分隔 | 凭印象生成，未逐项对照模板 |
| 2026-05-12 | 接口文档用表格罗列代替逐接口展开 | 扫一眼模板就写，结构大幅偏离 |
