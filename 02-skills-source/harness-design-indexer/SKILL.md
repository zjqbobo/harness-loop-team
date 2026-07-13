---
name: harness-design-indexer
description: 自动分析设计文档结构，生成章节定位索引。由 harness-document-generation
  和 harness-implementation 自动调用。索引文件仅提供章节位置，由 AI 自行判断加载哪些章节。
---

# Harness — 设计文档索引生成

## 触发时机

- **设计阶段结束后**：`harness-document-generation` 自动调用
- **编码/方案设计前**：`harness-implementation` / `harness-brainstorming` 检测到索引不存在或失效时调用

## 执行流程

### Step 1: 接收参数

参数：
- `--doc-path`：设计文档路径（必需）
- `--output`：输出路径（可选，默认与设计文档同目录）

### Step 2: 检测索引文件是否存在/有效

查找索引文件：`<设计文档同目录>/<设计文档名>.manifest.json`

**有效性判断（文件大小 + 修改时间）**：

```python
def is_valid(doc_path, manifest_path):
    if not manifest_path.exists():
        return False

    manifest = json.loads(manifest_path.read_text())
    doc_stat = doc_path.stat()

    # 大小变化 → 失效
    if doc_stat.st_size != manifest['source_size']:
        return False

    # 修改时间更新 → 失效
    doc_mtime = datetime.fromtimestamp(doc_stat.st_mtime)
    manifest_mtime = datetime.fromisoformat(manifest['source_mtime'])
    if doc_mtime > manifest_mtime:
        return False

    return True
```

### Step 3: 调用脚本生成索引

执行（本地运行，不消耗 AI token）：

```bash
python ~/.claude/harness/scripts/generate-design-manifest.py \
    "<设计文档路径>" \
    --output "<索引文件路径>"
```

### Step 4: 输出结果

返回：
```json
{
  "status": "generated" | "skipped" | "error",
  "manifest_path": "<索引文件路径>",
  "sections_count": 12,
  "total_lines": 5972,
  "message": "索引已生成"
}
```

### Step 5: 透明化提示

```
✅ 设计文档索引已生成：
   - 文档：00-design.md（共 5972 行）
   - 章节：12 个
   - 索引：00-design.manifest.json

📋 章节列表：
   - 项目概览（1-150行，150行）
   - 系统架构设计（151-650行，500行）
   - 用户模块设计（1200-1850行，650行）
   ...
```

## 索引文件格式

```json
{
  "source_file": "00-design.md",
  "source_size": 156789,
  "source_mtime": "2026-05-14T10:30:00Z",
  "manifest_mtime": "2026-05-14T10:35:00Z",
  "total_lines": 5972,
  "sections": {
    "项目概览-1": {
      "title": "项目概览",
      "line_range": [1, 150],
      "keywords": ["背景", "目标", "范围", "AI技术体系"]
    },
    "系统架构设计-151": {
      "title": "系统架构设计",
      "line_range": [151, 650],
      "keywords": ["架构", "层次", "模块依赖", "技术栈"]
    },
    "用户模块设计-1200": {
      "title": "用户模块设计",
      "line_range": [1200, 1850],
      "keywords": ["用户", "登录", "注册", "认证", "权限"]
    }
  }
}
```

## 注意事项

- **索引用途**：仅提供章节位置信息（标题、行号、关键词），不定义加载规则
- **加载判断**：由 AI 根据任务描述自行判断加载哪些章节
- **不包含**：不包含章节分类（essential/module/cross-cutting）、不包含依赖关系（depends）
- **原则**：索引简单，判断灵活
