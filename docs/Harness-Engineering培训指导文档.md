# Harness Engineering 培训指导文档

> **版本**: v1.1.0
> **日期**: 2026-05-13
> **受众**: 研发中心全体成员
> **前置要求**: 已安装 Claude Code，了解基本对话操作

---

## 目录

1. [项目概述](#1-项目概述)
2. [背景与动机](#2-背景与动机)
3. [核心原理](#3-核心原理)
4. [安装与更新](#4-安装与更新)
5. [能力全景](#5-能力全景)
6. [项目实操指引](#6-项目实操指引)
7. [自动化测试](#7-自动化测试)
8. [与 Superpowers 的关系](#8-与-superpowers-的关系)
9. [常见问题](#9-常见问题)
10. [附录](#10-附录)

---

## 1. 项目概述

### 1.1 Harness Engineering 是什么

Harness Engineering 是一套**开源 AI Agent 工程纪律体系**，通过纯文本 Markdown 技能文件（SKILL.md）为 Claude Code 注入工程纪律。

核心口号：**AI 编程缺的不是智力，是纪律，而纪律可以用纯文本分发。**

### 1.2 解决什么问题

当你和 Claude Code 协作时，是否遇到这些情况：

- 让它帮你加一个功能，代码写出来了，但里面混入了它自己"发明"的需求
- 让它修一个 bug，它说"可能是这里"，改了没好，又说"那可能是那里"，反复横跳
- 让它写个方案文档，章节结构对不上模板，漏了关键字段
- 长会话中，Claude 逐渐"忘记"该走的流程，开始跳过测试、直接猜 bug
- 写完代码后不知道测试写得对不对，覆盖率够不够
- 端到端页面测试需要手动点点点

**Harness Engineering 解决的就是这些问题。** 不是给 Claude 加能力，而是给 Claude 加纪律。

### 1.3 核心特色

| 特性 | 说明 |
|------|------|
| **自然语言触发** | 无需记忆 `/` 命令，说"帮我写个方案"即可自动触发完整文档流程 |
| **HARD GATE 强制执行** | 关键步骤不可跳过——没经过设计审批，一行代码都不许写 |
| **链式移交** | 多个 skill 自动衔接：brainstorming → writing-plans → implementation → review |
| **一键安装** | `git clone + ./install.sh` 两分钟完成部署 |
| **团队自动同步** | `git pull` 即可更新所有 skill（基于 symlink 架构） |

### 1.4 架构总览

![图1：Harness Engineering 架构总览](images/01-architecture.png)

---

## 2. 背景与动机

### 2.1 AI Agent 协作的"纪律鸿沟"

Claude Code 本身具有强大的代码生成、分析和调试能力，但存在一个根本性问题：

> Claude 知道该写测试，但在"快速给我跑一遍看看"的语境下，它会跳过。
> Claude 知道 debug 要找根因，但你说"快帮我改一下"，它就直接猜着改了。

这不是能力问题，是**语境驱动下的纪律缺失**。人类工程师有代码审查、测试覆盖、设计评审等流程约束，AI Agent 默认没有。

### 2.2 Superpowers 的启示

[Superpowers](https://github.com/anthropics/superpowers) 是一个 GitHub 上 185,000+ stars 的 Claude Code 插件，其核心设计哲学是：

- 每一个 skill 本质上是一个 Markdown 文件
- 文件内容不是代码，不是工具调用，就是**纯文本的行为约束**
- 用 `<HARD-GATE>` 强制执行工程师该有的纪律
- 不管用户怎么催，都不会绕过应走的流程

文章《185000 星的 Superpowers 插件，90% 的人只用了它 10% 的功能》详细拆解了这套系统的核心价值和执行流程。Harness Engineering 正是基于这一设计哲学，结合企业级全流程需求（文档生成、模板遵循、评审轮次、部署门禁）构建的。

### 2.3 从个人到团队的诉求

Superpowers 解决了个体 AI 协作的纪律问题，但团队场景需要更多：

| 需求 | Superpowers | Harness Engineering |
|------|------------|-------------------|
| 自然语言触发 | 英文描述 | 中英双语触发词 |
| 文档生成流程 | 无 | 模板遵循 + 图表 + md→docx |
| 团队分发 | 个人安装 | 一键安装 + git pull 同步 |
| 定制能力 | writing-skills | writing-skills + 模板扩展 |

---

## 3. 核心原理

### 3.1 瘦 Skill + 胖 Harness 架构

Harness Engineering 的核心架构设计：**Skill 文件只做三件事——触发匹配、纪律强制、规则引用。详细规则留在 Harness 目录中按需加载。**

```
~/.claude/
├── skills/                              ← Claude Code 自动扫描
│   ├── harness-entry/ → (symlink)
│   ├── harness-brainstorming/ → (symlink)
│   ├── harness-document-generation/ → (symlink)
│   ├── harness-systematic-debugging/ → (symlink)
│   ├── harness-code-review/ → (symlink)
│   └── harness-implementation/ → (symlink)
│
└── harness/                              ← GitHub 仓库（单一真相源）
    ├── CLAUDE.md
    ├── install.sh
    ├── 00-harness-core/                  ← 中枢流水线定义
    ├── 01-rules/                         ← 详细规则（Skill 按需 Read）
    ├── 02-skills-source/                 ← Skill 源文件
    ├── 09-templates/                     ← 文档模板
    └── scripts/                          ← 工具脚本
```

**精妙之处**：`install.sh` 将 `~/.claude/skills/harness-*` 做成指向 `~/.claude/harness/02-skills-source/` 的 symlink。这样 `git pull` 即可更新所有 Skill。

### 3.2 自然语言触发机制

每个 Skill 的 YAML 前置元数据中包含 `description` 字段，这是自然语言触发器的核心：

```yaml
---
name: harness-document-generation
description: Use when user asks to 生成文档, 写方案, 出文档, 写设计文档, 写PRD,
  写接口文档, 写物理模型, 产出文档, generate document, write proposal, create doc
  — ensures brainstorming → template compliance → diagrams → md draft → user review
  → docx pipeline.
---
```

Claude 在收到每条消息时，会扫描所有已注册 Skill 的 `description` 字段，匹配后自动 invoke 对应 Skill。用户完全不需要知道技能名称。

**效果：**

| 用户说 | Claude 自动做 |
|--------|-------------|
| "帮我设计一个用户中心" | → 走 brainstorming 全流程 |
| "帮我写个技术方案文档" | → 读模板 → 逐节生成 → 配图 → md转docx |
| "这个接口报 500 了帮我看看" | → 系统调试四阶段 → 找根因 → 修复 |
| "帮我 review 这段代码" | → 独立评审 → 规范检查 → 安全扫描 |
| "帮我实现这个功能" | → TDD → 红绿重构 → commit |

### 3.3 HARD GATE 强制执行

每个 Skill 包含 `<HARD-GATE>` 标签定义不可绕过的约束。这是**程序化规则**，不是"建议"。

harness-brainstorming 的 HARD GATE 示例：

```markdown
<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project,
or take any implementation action until:
1. Brainstorming is complete
2. Design spec is written and committed
3. User has approved the spec
This applies to EVERY task regardless of perceived simplicity.
</HARD-GATE>
```

harness-document-generation 的 HARD GATE 示例：

```markdown
<HARD-GATE>
生成任何文档前必须：
1. 触发 brainstorming → 用户确认方案
2. Read 对应模板 → 逐节匹配
3. 生成 MD 草稿 → 用户审阅
4. 图表嵌入 + 所有 .md 转 .docx
跳过任意一步 = 违规。
</HARD-GATE>
```

### 3.4 链式移交

Skill 之间通过明确的"移交规则"实现端到端流程链路：

![图3：Skill 触发关系与链式移交](images/03-skill-chaining.png)

**两条主要链路：**

1. **开发链路**：harness-entry → harnessing-brainstorming → harnessing-implementation → harness-code-review
2. **文档链路**：harness-entry → harnessing-brainstorming → harness-document-generation

**三条应急链路：**

3. **调试链路**：harness-entry → harnessing-systematic-debugging（独立执行，不触发其他链路）
4. **评审链路**：harness-entry → harnessing-code-review（可独立调用，也可从 implementation 移交）
5. **入口常驻**：harness-entry 在所有会话中自动加载，建立纪律基线

---

## 4. 安装与更新

### 4.1 前置条件

- macOS / Linux 环境
- 已安装 [Claude Code](https://claude.ai/code) CLI
- 已安装 Git
- （可选）pandoc — 用于 md2docx.sh 文档转换
- （可选）mmdc（@mermaid-js/mermaid-cli）— 用于 Mermaid 图表渲染

### 4.2 一键安装

```bash
# 克隆仓库到 ~/.claude/harness/
git clone https://github.com/<org>/harness-engineering.git ~/.claude/harness

# 进入目录并执行安装
cd ~/.claude/harness && ./install.sh
```

**install.sh 做了什么：**

1. 将 `02-skills-source/` 中的 7 个 Skill 通过 **symlink** 注册到 `~/.claude/skills/`
2. 将 `CLAUDE.md` symlink 到 `~/.claude/CLAUDE.md`
3. 验证安装完整性（Skill 数量、模板、脚本）

**安装输出示例：**

```
╔══════════════════════════════════════════╗
║   Harness Engineering — 安装中...         ║
╚══════════════════════════════════════════╝

📦 注册自然语言触发 skills...
   ✅ harness-brainstorming
   ✅ harness-code-review
   ✅ harness-document-generation
   ✅ harness-entry
   ✅ harness-implementation
   ✅ harness-systematic-debugging
   ✅ harness-testing

📋 安装全局 CLAUDE.md...
   ✅ CLAUDE.md

🔍 验证安装...
   Harness skills 注册: 7 个
   ✅ CLAUDE.md
   ✅ Harness 目录
   ✅ 文档模板
   ✅ 工具脚本

╔══════════════════════════════════════════╗
║  ✅ Harness Engineering 安装完成         ║
║                                           ║
║  现在你可以用自然语言触发所有能力：          ║
║  • "帮我设计..." → brainstorming          ║
║  • "帮我写方案..." → 文档生成全流程         ║
║  • "帮我修bug..." → 系统调试               ║
║  • "帮我review..." → 代码审查              ║
║  • "帮我实现..." → TDD + 编码规范          ║
║  • "帮我写测试..." → 单测 + E2E             ║
╚══════════════════════════════════════════╝
```

### 4.3 更新流程

Harness Engineering 通过 **symlink** 架构实现零摩擦更新：

```bash
cd ~/.claude/harness && git pull
```

因为 `~/.claude/skills/harness-*` 是 symlink 指向 `~/.claude/harness/02-skills-source/`，`git pull` 更新源文件后，所有 Skill 自动生效。

**无需重新运行 install.sh**（除非新增了 Skill 需要创建新的 symlink）。

### 4.4 卸载

```bash
# 删除 Skill symlink
rm -rf ~/.claude/skills/harness-*

# 恢复原始 CLAUDE.md（如需要）
# 备份文件在 ~/.claude/CLAUDE.md.bak.*

# 删除仓库（可选）
rm -rf ~/.claude/harness
```

---

## 5. 能力全景

### 5.1 7 个 Skill 一览

| Skill | 自然语言触发词 | 核心能力 | 移交目标 |
|-------|-------------|---------|---------|
| **harness-entry** | 会话启动自动加载 | 建立纪律基线，声明所有能力 | — （常驻） |
| **harness-brainstorming** | 设计 · 方案 · 分析需求 · 架构 · 选型 | 9步方案设计，产出 committed spec | implementation / document-generation |
| **harness-document-generation** | 写文档 · 出方案 · 生成 PRD · 写设计文档 | 模板遵循 + 配图 + md 转 docx | — （交付完成） |
| **harness-systematic-debugging** | 修 bug · 调试 · 报错 · 不工作 · 异常 | 四阶段系统调试，三次失败规则 | — （修复完成或架构讨论） |
| **harness-code-review** | review · 审查 · 检查代码 · 审计 | 三阶段独立评审，角色分离 | — （评审结论） |
| **harness-implementation** | 实现 · 开发 · 写代码 · 编码 | TDD + 8层模板 + subagent 调度 | testing / code-review |
| **harness-testing** | 写测试 · 跑测试 · 单测 · E2E · 测覆盖率 | 后端单测 (mock + coverage) + E2E (Playwright) | code-review（通过）/ implementation（失败） |

### 5.2 完整工作流

![图2：完整工作流——从自然语言到交付](images/02-workflow.png)

---

## 6. 项目实操指引

### 6.1 场景一：开发一个新功能

**用户说**："帮我设计一个用户积分系统"

**系统自动执行：**

1. **harness-entry 加载** → 建立纪律基线
2. **description 匹配** → "设计"触发 harness-brainstorming
3. **Brainstorming 9 步流程：**
   - 探索项目现状（读文件、commits）
   - 逐条问澄清问题（积分规则？兑换比例？过期策略？）
   - 提出 2-3 个方案（数据库方案 vs 缓存方案 vs 混合方案）
   - 分节展示设计（架构、数据模型、API、错误处理）
   - 设计写入 spec 文件并 commit
   - ➡️ Spec 自检 → 用户审阅 → 确认
4. **移交 harness-implementation** → TDD 红绿重构
5. **移交 harness-code-review** → 三阶段评审
6. **完工**

**全程用户只需：** 说一句话 → 回答问题 → 确认审批。无需知道任何命令。

### 6.2 场景二：写一个方案文档

**用户说**："帮我写一个库存管理系统的接口设计文档"

**系统自动执行：**

1. **harness-entry 加载** → 建立纪律基线
2. **description 匹配** → "写设计文档"触发 harness-document-generation
3. **文档生成流程：**
   - Read `09-templates/系统接口设计文档模版.md`
   - 触发 brainstorming 确认接口范围
   - 逐节按模板生成内容（服务端点、请求参数表、返回码说明、数据字典、范例）
   - 询问图表工具（mermaid / fireworks-tech-graph）
   - 生成 MD 草稿，图表以代码块/PNG 嵌入
4. **用户审阅** → 确认后
5. **批量转换：**
   - `mermaid-render.sh` 提取 .mmd + 渲染 PNG + 替换代码块
   - `md2docx.sh` 生成 .docx 交付
6. **交付完成**

**全程用户只需：** 说一句话 → 选图表工具 → 审阅确认 → 拿到 .docx。

### 6.3 场景三：修复一个 Bug

**用户说**："创建订单的接口返回 500 了，帮我看看"

**系统自动执行：**

1. **harness-entry 加载** → 建立纪律基线
2. **description 匹配** → "报错"触发 harness-systematic-debugging
3. **Phase 1: 根因调查**
   - 完整读取错误日志
   - 稳定复现步骤
   - 检查最近 git 变更
   - 打诊断日志 → 收集证据
4. **Phase 2: 模式分析**
   - 找能跑通的类似代码
   - 逐项对比差异
5. **Phase 3: 单假设验证**
   - 写下具体假设 → 最小变更验证 → 不叠加改动
6. **Phase 4: 实现修复**
   - 先写复现测试 → 只改一处 → 如三次未修复则停，讨论架构
7. **验证修复** → 提交

**全程用户只需：** 说一句话 → 提供复现步骤 → 确认修复。

### 6.4 场景四：做一次代码审查

**用户说**："帮我看一下这段代码"

**系统自动执行：**

1. **harness-entry 加载** → 建立纪律基线
2. **description 匹配** → "审查"触发 harness-code-review
3. **Phase 1: 计划评审** — 检查 spec 是否完整、范围是否明确
4. **Phase 2: 代码评审** — 编码规范、安全问题、性能关注、可维护性评分
5. **Phase 3: 测试评审** — 覆盖率、边界条件、全绿通过
6. **输出评审结论** — APPROVED / CHANGES_REQUESTED / REJECTED

### 6.5 场景五：团队自定义新 Skill

**为团队添加新的 Skill（例如：数据库迁移检查）**

1. 在 `02-skills-source/` 下创建新目录：
   ```bash
   mkdir -p ~/.claude/harness/02-skills-source/harness-db-migration/
   ```

2. 创建 `SKILL.md` 文件，包含：
   ```markdown
   ---
   name: harness-db-migration
   description: Use when user asks to 数据库迁移, 改表结构, 加字段,
     database migration, alter table — ensures backward compatibility
     check and rollback plan.
   ---
   
   # Harness — 数据库迁移检查
   
   <HARD-GATE>
   执行任何数据库变更前必须：
   1. 检查向后兼容性
   2. 生成回滚脚本
   3. 用户确认
   </HARD-GATE>
   
   ## 执行流程
   ...
   ```

3. 重新运行 `install.sh` 注册新 Skill：
   ```bash
   cd ~/.claude/harness && ./install.sh
   ```

4. 团队成员执行 `git pull` 即可自动获取新 Skill。

5. **提 PR 回馈社区**：如果这个 Skill 对其他人也有用，欢迎提 Pull Request。

### 6.6 场景六：写测试用例并自动执行

#### 后端单元测试

**用户说**："帮我给 UserService 写个单测"

**系统自动执行：**

1. **harness-entry 加载** → 建立纪律基线
2. **description 匹配** → "写单测"触发 harness-testing → Path A（后端单测）
3. **Step 1: 分析被测代码**
   - 读取 `UserService` 源码
   - 识别依赖：数据库 DAO、外部 API 调用
   - 确定需要 mock 的层
4. **Step 2: 识别测试场景**
   - Happy Path：正常创建用户
   - 边界：空 name、超长 name、null 参数
   - 异常：数据库连接失败、外部 API 超时
5. **Step 3: 生成测试文件**
   - 自动检测项目测试框架（Jest / pytest / Go testing）
   - 生成 mock 和测试用例（Given/When/Then 结构）
   - 写入 `__tests__/` 目录
6. **Step 4: 执行测试**
   ```bash
   npm test -- --coverage    # 自动检测项目命令
   ```
7. **Step 5: 报告**
   - 通过/失败/跳过数量
   - 覆盖率数据（statement ≥ 80%, branch ≥ 70%）
   - 失败分类：代码 bug / 环境问题 / 测试用例问题

#### E2E 页面测试

**用户说**："帮我测一下登录页面的完整流程"

**系统自动执行：**

1. **description 匹配** → "帮我测"+"登录页面"触发 harness-testing → Path B（E2E）
2. **Step 1: 分析页面操作流**
   - 读取前端代码 → 识别登录流程步骤
   - 打开浏览器 → 导航到页面
   - 识别 selector：`input[name="email"]`、`button[type="submit"]`
3. **Step 2: 写 Playwright 脚本**
   - 使用 webapp-testing skill 的 `with_server.py`
   - 生成 Playwright Python 脚本
4. **Step 3: 启动服务并执行**
   ```bash
   python ~/.claude/skills/webapp-testing/scripts/with_server.py \
     --server "npm run dev" --port 5173 \
     -- python test_e2e_login.py
   ```
5. **Step 4: 验证与报告**
   - 每个关键步骤截图
   - 模拟错误输入验证错误提示
   - 失败时保留页面状态截图
   - 输出：通过步骤数 / 失败步骤数 / 截图清单

#### 测试失败的后续处理

```
harness-implementation → harness-testing
                            ↓
                         全部通过？
                      ↙           ↘
                    是              否
                    ↓               ↓
            harness-code-review   分类失败原因
                                  ↙        ↘
                            代码bug       环境问题
                               ↓            ↓
                    harness-implementation  报告用户
                    修复后重跑              暂停流水线
```

---

## 7. 自动化测试

### 7.1 测试能力概述

Harness Engineering 的 `harness-testing` skill 覆盖两条测试路径：

| 路径 | 触发词 | 技术栈 | 产出 |
|------|--------|--------|------|
| **后端单测** | 写单测、跑单测、测覆盖率 | Jest / pytest / Go testing | 测试文件 + 覆盖率报告 |
| **E2E 测试** | 端到端测试、页面测试、UI测试 | Playwright v1.59+ + webapp-testing | 测试脚本 + 截图报告 |

### 7.2 后端单测标准

→ Read `~/.claude/harness/01-rules/02-development-workflow/01-testing-standards.md`

核心要求：
- Mock 外部依赖（数据库、API、文件系统），禁止 mock 被测代码
- 覆盖：Happy Path + 边界条件 + 异常路径
- Given/When/Then 结构
- 覆盖率门禁：statement ≥ 80%, branch ≥ 70%

### 7.3 E2E 测试标准

- 使用 Playwright（v1.59+，已通过 `npx playwright` 可用）
- 调用 `webapp-testing` skill 的 `scripts/with_server.py` 管理服务生命周期
- 每个关键步骤截图
- 失败时保留页面状态截图

### 7.4 链式移交

测试是 implementation 的下一站：

```
harness-implementation 编码完成
    ↓
harness-testing 执行测试
    ↓
  ├─ 全部通过 → harness-code-review（三阶段评审）
  ├─ 失败 (代码 bug) → 返回 harness-implementation 修复
  └─ 失败 (环境问题) → 报告用户，暂停流水线
```

### 7.5 Playwright 安装验证

```bash
# 确认 Playwright 可用
npx playwright --version    # 应输出 v1.59.1 或更高

# 首次使用需安装浏览器
npx playwright install chromium
```

---

## 8. 与 Superpowers 的关系

### 7.1 两者是互补关系

| 维度 | Superpowers | Harness Engineering |
|------|------------|-------------------|
| **定位** | 通用开发纪律 | 企业级全流程（文档+编码+评审+部署） |
| **Skill 数量** | 14 个 | 6 个复合 Skill（含链式移交） |
| **文档体系** | 无 | 完整模板 + 图表 + md2docx 工具链 |
| **质量门禁** | HARD GATE（文本约束） | 5 个程序化门禁（JSON）+ HARD GATE（文本约束） |
| **评审机制** | requesting-code-review（自检） | 3 阶段评审 + 角色分离 |
| **流水线** | brainstorming → plan → execute | 10 阶段流水线 + 部署 + 知识库 |
| **语言** | 英文 | 中英双语触发词 |
| **分发方式** | npm 插件 | git clone + install.sh |

### 7.2 推荐使用方式

**同时安装两者**，不冲突：
- Superpowers 覆盖通用开发纪律（writing-skills、dispatching-parallel-agents、verification-before-completion 等）
- Harness Engineering 覆盖企业级全流程（文档生成、模板遵循、批量转换、评审轮次、部署门禁）

两个系统的 Skill 并存于 `~/.claude/skills/` 目录，Claude 自动根据 context 选择最匹配的 Skill。

---

## 9. 常见问题

### Q1：Harness Engineering 适合小项目吗？感觉流程太重了。

brainstorming 的 spec 可以很短——一个改动只需要几句话的设计文档。流程轻重是相对的，问题不是"项目大不大"，而是"你能不能接受返工"。很多"5 分钟小改动"，因为没有设计直接上手，结果改了三轮花了两小时。

### Q2：必须走完全部流程吗？能不能跳过某些步骤？

HARD GATE 约束下的步骤不可跳过。但简单任务的流程执行很快——例如一个配置文件修改的 brainstorming 可能只需要 2-3 分钟。流程时长的伸缩性由任务复杂度决定。

### Q3：安装后需要重启 Claude Code 吗？

是的。Claude Code 在会话启动时扫描 `~/.claude/skills/` 目录，新的 Skill symlink 需要新会话才能被加载。建议安装后开启一个新会话验证。

### Q4：如何验证安装成功？

新会话中尝试说"帮我设计一个测试功能"，如果 Claude 自动进入 brainstorming 模式（提问澄清、展示方案），即表示安装成功。也可以检查 `~/.claude/skills/` 中是否有 `harness-*` 目录。

### Q5：可以只安装部分 Skill 吗？

可以。不需要的 Skill 在安装前从 `02-skills-source/` 中删除对应目录，再运行 `install.sh`。或者安装后手动删除 `~/.claude/skills/harness-<name>` symlink。

### Q6：模板可以自定义吗？

可以。修改 `~/.claude/harness/09-templates/` 中的模板文件，`git commit && git push` 后团队 `git pull` 即可同步。新增模板后需更新 `CLAUDE.md` 和 `harness-document-generation` 中的引用。

### Q7：工具脚本（md2docx.sh 等）的依赖如何安装？

```bash
# pandoc（md → docx 转换）
brew install pandoc

# mmdc（Mermaid → PNG 渲染）
npm install -g @mermaid-js/mermaid-cli

# rsvg-convert（SVG → PNG 转换）
brew install librsvg
```

### Q8：更新后旧版本的规则会被覆盖吗？

不会。Harness 更新采用 `git pull` 方式，Git 会正常处理合并。如果本地修改了模板或规则，需要先 commit 本地改动或 stash。推荐团队 fork 仓库后使用自己的版本。

---

## 10. 附录

### 10.1 完整目录结构

```
~/.claude/harness/
├── install.sh                         # 一键安装脚本
├── CLAUDE.md                          # 全局 Claude Code 配置
├── README.md                          # 项目说明
├── .gitignore
├── 00-harness-core/                   # 中枢定义
│   └── 00-application-owner-agent.md  # 10阶段流水线 + 5质量门禁 + 角色分离
├── 01-rules/                          # 详细规范
│   ├── 02-development-workflow/       # 编码开发规范
│   │   └── 00-overview.md             # TDD + 8层编码模板
│   └── 04-document-standards/         # 文档生成规范
│       ├── 01-docs-workflow.md        # 文档生成全流程（图表+模板+转换）
│       ├── 02-prd-standards.md        # PRD 标准
│       ├── 03-requirements-methods.md # 需求分析方法
│       └── 04-prototype-workflow.md   # 原型生成工作流
├── 02-skills-source/                  # ★ Skill 源文件
│   ├── harness-entry/SKILL.md
│   ├── harness-brainstorming/SKILL.md
│   ├── harness-document-generation/SKILL.md
│   ├── harness-systematic-debugging/SKILL.md
│   ├── harness-code-review/SKILL.md
│   ├── harness-implementation/SKILL.md
│   └── harness-testing/SKILL.md
├── 09-templates/                      # 文档模板
│   ├── 系统设计文档模板.md
│   ├── 系统接口设计文档模版.md
│   ├── 系统物理模型设计文档模版.md
│   ├── 系统物理模型设计文档模版.docx
│   └── PRD标准模板_v2.0.md
├── scripts/doc/                       # 工具脚本
│   ├── mermaid-render.sh              # Mermaid→PNG 渲染
│   ├── md2docx.sh                     # MD→Word 转换
│   └── svg2png.sh                     # SVG→PNG 导出
└── docs/                              # 项目文档（本文件所在目录）
    ├── Harness-Engineering培训指导文档.md
    └── images/
        ├── 01-architecture.png
        ├── 02-workflow.png
        └── 03-skill-chaining.png
```

### 10.2 7 个 Skill 触发词速查

| 你想做什么 | 可以这样说 |
|-----------|-----------|
| 设计新功能/系统/架构 | "帮我设计..." · "分析一下..." · "怎么做..." · "技术选型..." |
| 写文档/方案/PRD | "帮我写..." · "生成文档..." · "出个方案..." · "写个PRD..." |
| 修 bug/排查问题 | "帮我修..." · "报错了..." · "不工作了..." · "调试一下..." |
| 代码审查 | "帮我 review..." · "审查一下..." · "检查代码..." |
| 实现功能/写代码 | "帮我实现..." · "开发这个..." · "写代码..." |
| 写测试/跑测试/E2E | "帮我写测试..." · "跑一下测试..." · "测覆盖率..." · "端到端测试..." |

### 10.3 相关资源

- **Superpowers GitHub**：https://github.com/anthropics/superpowers
- **Superpowers 深度解析**：参考文章《185000 星的 Superpowers 插件，90% 的人只用了它 10% 的功能》
- **Harness Engineering GitHub**：https://github.com/&lt;org&gt;/harness-engineering（替换为实际仓库地址）

---

> **文档生成信息**
> - 本文档遵循 Harness Engineering 文档生成规范
> - 图表使用 fireworks-tech-graph 生成，Style 1 (Flat Icon)
> - 完成后执行 mermaid-render.sh + md2docx.sh 生成 Word 版本
