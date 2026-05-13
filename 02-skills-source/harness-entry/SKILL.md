---
name: harness-entry
description: Use when starting any conversation or receiving any task — establishes that all harness engineering disciplines apply, including mandatory brainstorming before implementation, template compliance for documents, and systematic debugging for bugs. This skill auto-loads at session start to set the discipline baseline.
---

# Harness Engineering — 入口

## 核心纪律基线

<HARD-GATE>
以下纪律对所有任务生效，不可绕过：

1. 任何功能开发/设计 → 必须先 brainstorming → 产出 spec → 用户确认 → 才写代码
2. 任何文档生成/写方案 → 必须先 Read 模板 → 逐节匹配 → MD 草稿 → 用户审阅 → 转换交付
3. 任何 bug/报错 → 必须先找根因 → 稳定复现 → 才修
4. 禁止临时写脚本代替标准工具脚本（mermaid-render.sh / md2docx.sh / svg2png.sh）
5. 禁止凭印象生成代替读模板
</HARD-GATE>

## 自动触发的技能

| 当用户说... | 自动触发 |
|------------|---------|
| "设计/方案/分析需求/架构/选型" | `harness-brainstorming` |
| "写文档/出方案/生成 PRD/写设计文档" | `harness-document-generation` |
| "修 bug/调试/报错/不工作" | `harness-systematic-debugging` |
| "review/审查/检查代码" | `harness-code-review` |
| "实现/开发/写代码" | `harness-implementation` |

触发方式：自然语言，无需 `/` 命令。

## 详细规则位置

| 类别 | 路径 |
|------|------|
| 核心流水线 | `~/.claude/harness/00-harness-core/00-application-owner-agent.md` |
| 文档生成规范 | `~/.claude/harness/01-rules/04-document-standards/01-docs-workflow.md` |
| 编码开发规范 | `~/.claude/harness/01-rules/02-development-workflow/00-overview.md` |
| 文档模板 | `~/.claude/harness/09-templates/` |
| 工具脚本 | `~/.claude/harness/scripts/doc/` |

## 关于 Harness

Harness Engineering 是一套开源 AI Agent 工程纪律体系。
与 Superpowers 同源的设计哲学：AI 编程缺的不是智力，是纪律，而纪律可以用纯文本分发。

- GitHub: https://github.com/<org>/harness-engineering
- 安装: `git clone && cd harness-engineering && ./install.sh`
