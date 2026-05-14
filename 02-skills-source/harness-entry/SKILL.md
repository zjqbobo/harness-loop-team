---
name: harness-entry
description: Use when starting any conversation or receiving any task — establishes that all harness engineering disciplines apply, including mandatory brainstorming before implementation, template compliance for documents, and systematic debugging for bugs. This skill auto-loads at session start to set the discipline baseline.
---

# Harness Engineering — 入口

## 核心纪律基线

<HARD-GATE>
以下纪律对所有任务生效，不可绕过。流程不可省，但深度可缩放（详见下方分诊表）：

1. 任何开发/设计 → 必须先 brainstorming → 产出设计文档 → 用户确认 → 才写代码
2. 任何文档生成 → 必须先 Read 模板 → 逐节匹配 → MD 草稿 → 用户审阅 → 转换交付
3. 任何 bug → 必须先找根因 → 稳定复现 → 才修
4. 禁止临时写脚本代替标准工具脚本（mermaid-render.sh / md2docx.sh / svg2png.sh）
5. 禁止凭印象生成代替读模板

反模式："这个太简单了，不用走流程"——简单任务的设计可以是一句话，但不能跳过。
</HARD-GATE>

---

## 任务分诊（每次收到任务时展示）

当用户描述需求后，按以下矩阵展示三档选项。**同一场景，同一条纪律链路，但深度不同。**

```
📋 请确认你的需求类型和深度：

┌────────────┬──────────────────────┬──────────────────────┬──────────────────────┐
│            │  🔵 快速通道          │  🟡 标准流程          │  🟢 完整工程          │
│            │  "这个我完全想清楚了"  │  "需求清楚但要规范"    │  "重要功能不容有失"    │
├────────────┼──────────────────────┼──────────────────────┼──────────────────────┤
│ ✍️ 写文档   │ 内容我已写好，        │ 我给了要点和方向，     │ 我只有一个想法，       │
│            │ 帮我排版+配图+转格式  │ 帮我展开+配图+交付    │ 从0到1出完整方案      │
│            │                      │                      │                      │
│            │ 跳过 brainstorming    │ 简版 brainstorming    │ 完整 9 步 brainstorming│
│            │ → 直接 Read 模板      │ (3问) → 生成 MD 草稿  │ → Read 模板 → 逐节生成 │
│            │ → 生成 → md2docx     │ → 用户审阅 → docx     │ → 图表 → 审阅 → docx  │
├────────────┼──────────────────────┼──────────────────────┼──────────────────────┤
│ 💻 开发功能  │ 改配置、修 typo、     │ 新接口、新页面、       │ 新系统、新模块、       │
│            │ 调样式、单行 bugfix   │ 中等功能、重构        │ 架构变更、安全相关     │
│            │                      │                      │                      │
│            │ 1问问清 → 直接改      │ 3-5问问清 → 设计文档   │ 完整 9 步 brainstorming│
│            │ → 确认结果 → commit  │ (半页) → TDD → review │ → plan → TDD → testing│
│            │                      │ → commit             │ → 独立评审 → commit   │
├────────────┼──────────────────────┼──────────────────────┼──────────────────────┤
│ 🔧 修 bug   │ 一眼能看出原因，       │ 知道大概范围，         │ 完全不知道原因，       │
│            │ 改完即可验证          │ 需要定位和修复        │ 需要完整排查          │
│            │                      │                      │                      │
│            │ 说清现象 → 直接改     │ systematic-debugging  │ 完整四阶段根因分析     │
│            │ → 验证 → commit      │ 精简版 (1-2 阶段)    │ + 三次失败规则        │
├────────────┼──────────────────────┼──────────────────────┼──────────────────────┤
│ 👀 做审查   │ 快速扫一眼，          │ 逐文件检查，           │ 正式评审，             │
│            │ 看出明显问题          │ 关注规范和隐患        │ 有评审结论和记录       │
│            │                      │                      │                      │
│            │ 指出明显问题即可      │ 规范 + 安全 + 性能    │ 角色分离 + 三阶段评审  │
│            │                      │                      │ + 输出评审结论        │
├────────────┼──────────────────────┼──────────────────────┼──────────────────────┤
│ 🧪 写测试   │ 给关键路径加几个用例， │ 标准覆盖，有 mock      │ 全量覆盖，有截图报告   │
│            │ 验证核心逻辑          │ 和边界测试            │                      │
│            │                      │                      │                      │
│            │ Happy path 用例即可  │ 单测: mock+边界+异常   │ 单测 (≥80%覆盖) +    │
│            │                      │ E2E: 核心流程截图     │ E2E + 截图报告       │
└────────────┴──────────────────────┴──────────────────────┴──────────────────────┘
```

**选错可以随时升级。** 快速通道改不动了 → 切标准流程。标准流程发现复杂度超预期 → 切完整工程。

---

## 自动触发的技能

| 当你收到... | 自动触发 |
|------------|---------|
| "设计/方案/分析需求/架构/选型" | `harness-brainstorming` |
| "写文档/出方案/生成 PRD/写设计文档" | `harness-document-generation` |
| "修 bug/调试/报错/不工作" | `harness-systematic-debugging` |
| "review/审查/检查代码" | `harness-code-review` |
| "实现/开发/写代码" | `harness-implementation` |
| "写测试/跑测试/端到端/测覆盖率" | `harness-testing` |

触发方式：**自然语言**，无需 `/` 命令。用户无需知道技能名称。

---

## 详细规则位置

| 类别 | 路径 |
|------|------|
| 核心流水线 | `~/.claude/harness/00-harness-core/` |
| 编码开发规范 | `~/.claude/harness/01-rules/02-development-workflow/` |
| 文档生成规范 | `~/.claude/harness/01-rules/04-document-standards/` |
| 测试规范 | `~/.claude/harness/01-rules/02-development-workflow/01-testing-standards.md` |
| 文档模板 | `~/.claude/harness/09-templates/` |
| 工具脚本 | `~/.claude/harness/scripts/doc/` |

---

## 关于 Harness

Harness Engineering 是一套开源 AI Agent 工程纪律体系。
与 Superpowers 同源的设计哲学：AI 编程缺的不是智力，是纪律，而纪律可以用纯文本分发。

- 安装: `git clone <repo> ~/.claude/harness && cd ~/.claude/harness && ./install.sh`
