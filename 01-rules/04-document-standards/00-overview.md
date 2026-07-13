# 04-Document-Standards: 文档生成全套规范

> 📌 从旧配置包 (`team-claude-config`) 迁移而来，现已按 Harness 架构重新组织

---

## 规范索引

| 文件 | 说明 |
|------|------|
| [01-docs-workflow.md](./01-docs-workflow.md) | 文档生成通用工作流（强制配图、自动生成正式文档） |
| [02-prd-standards.md](./02-prd-standards.md) | PRD 产品需求文档标准（8大章节 + 全子章节） |
| [03-requirements-methods.md](./03-requirements-methods.md) | 需求分析方法论（纲举目张法、七大思维方式、业务建模四大方法） |
| [04-prototype-workflow.md](./04-prototype-workflow.md) | 原型生成工作流（自动截图、自动填充文档、禁止用文字代替截图） |
| [06-system-design-standards.md](./06-system-design-standards.md) | 系统设计文档标准（总体设计、物理模型、接口设计三模板） |

---

## 流水线对应

文档规范在以下 Harness 阶段被激活：

| 阶段 | 加载文件 |
|------|---------|
| brainstorming | `03-requirements-methods.md`（需求分析方法论） |
| document-generation（PRD） | `01-docs-workflow.md` + `02-prd-standards.md` + `04-prototype-workflow.md` |
| document-generation（系统设计） | `01-docs-workflow.md` + `06-system-design-standards.md` |
| 任何生成文档时 | `01-docs-workflow.md`（图表规则 + 模板遵循） |
