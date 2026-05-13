# Claude Code 全局配置 — Harness Engineering

> 📌 生效范围: 所有项目
> 📌 仓库: https://github.com/<org>/harness-engineering
> 📌 安装: `git clone https://github.com/<org>/harness-engineering.git ~/.claude/harness && cd ~/.claude/harness && ./install.sh`

---

## 自动触发的能力（自然语言，无需记忆命令）

| 你说... | 自动触发 | 强制执行 |
|---------|---------|---------|
| "帮我设计/分析/方案..." | `harness-brainstorming` | spec → plan → execute，不跳过 |
| "写文档/出方案/生成PRD..." | `harness-document-generation` | 模板遵循 + 配图 + md→docx |
| "修bug/报错/不工作..." | `harness-systematic-debugging` | 四阶段根因分析，不猜 |
| "review/审查代码..." | `harness-code-review` | 独立评审，禁止自审 |
| "实现/开发/写代码..." | `harness-implementation` | TDD + 编码规范 |
| "写测试/跑测试/端到端..." | `harness-testing` | 单测(mock+coverage) + E2E(Playwright) |

触发方式：**自然语言**，无需 `/` 命令。

## 核心纪律（harness-entry 常驻加载）

1. 任何功能开发必须先 brainstorming → 产出 spec → 用户确认 → 才写代码
2. 任何文档必须先读模板 → 逐节匹配 → MD草稿 → 用户审阅 → 转换交付
3. 任何 bug 必须先找根因 → 稳定复现 → 才修
4. 禁止临时写脚本代替标准工具脚本
5. 禁止凭印象生成代替读模板
6. 编码完成后必须走测试 → 单测覆盖 ≥80% + E2E 截图验证

## 文档路径

| 内容 | 位置 |
|------|------|
| 核心流水线 | `~/.claude/harness/00-harness-core/` |
| 详细规则 | `~/.claude/harness/01-rules/` |
| 文档模板 | `~/.claude/harness/09-templates/` |
| 工具脚本 | `~/.claude/harness/scripts/` |
| 变更记录 | `~/.claude/harness/04-changes/` |
