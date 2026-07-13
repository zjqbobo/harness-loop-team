# 开发流程规范总览

> 📌 本节规范开发全生命周期流程，对应 Harness Engineering 的 8 个 SKILL 链式移交体系。

---

## 🔹 核心流程

```
harness-entry（入口分诊）
  → brainstorming（方案设计）
    → document-generation（文档交付）        ← 文档链
    → implementation（TDD 编码）             ← 开发链
      → testing（单测+E2E+压测）
        → code-review（三阶段评审）
```

项目的具体规范和加载顺序见 `docs/coding-standards/00-index.md`。

---

## 🔹 阶段定义

| 阶段 | 对应 Harness SKILL | 关键检查点 |
|------|-------------------|-----------|
| 需求分析 / 方案设计 | `harness-brainstorming` | 方案已 commit、用户已确认 |
| 文档交付 | `harness-document-generation` | 模板遵循、图表渲染、MD→DOCX |
| 编码实现 | `harness-implementation` | TDD、编码规范合规（见 `docs/coding-standards/`）、项目约定复用 |
| 自动化测试 | `harness-testing` | 单测覆盖率 ≥ 80%、E2E 截图、压测（按需） |
| 代码评审 | `harness-code-review` | 多维度规范对照审查、无安全漏洞 |
| 项目初始化 | `harness-init` | 存量工程扫描、生成 project-conventions.md |

---

## 🔹 分支策略

| 分支类型 | 命名规则 | 用途 |
|---------|---------|------|
| 主干分支 | main / master | 生产代码，受保护 |
| 开发分支 | develop | 日常开发集成 |
| 功能分支 | feature/{需求编号}-{描述} | 新功能开发 |
| 修复分支 | bugfix/{问题编号}-{描述} | bug 修复 |
| 热修复 | hotfix/{问题编号}-{描述} | 生产紧急修复 |
| 发布分支 | release/{版本号} | 版本发布准备 |

---

## 🔹 代码提交规范

```
<type>(<scope>): <subject>

type: feat|fix|refactor|docs|test|style|chore|ci
scope: 模块名
subject: 50字内的简要描述
```
