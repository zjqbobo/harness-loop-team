# Claude Code 全局配置 — Harness Engineering

> 📌 生效范围: 所有项目
> 📌 仓库: https://github.com/<org>/harness-engineering
> 📌 安装: `git clone https://github.com/<org>/harness-engineering.git ~/.claude/harness && cd ~/.claude/harness && ./install.sh`

---

## <HARD-GATE> 任务入口：分诊矩阵必须先于一切

收到用户任何任务请求后，**第一步必须 invoke ****`harness-entry`**** skill**，展示分诊矩阵（快速/标准/完整三档），让用户选择深度后，再进入对应的领域 skill。

```
执行顺序（不可跳过）：
  用户任务 → ① harness-entry（分诊矩阵，用户选档） → ② 对应领域 skill（按选定的深度执行）
```

禁止行为：跳过 harness-entry 直接调用 harness-brainstorming / harness-document-generation / harness-implementation 等。
</HARD-GATE>

---

## 自动触发的能力（自然语言，无需记忆命令）

| 你说... | 自动触发 | 强制执行 |
| --- | --- | --- |
| "帮我设计/分析/方案..." | `harness-brainstorming` → **文档类产出必须链入 ****`harness-document-generation`** | spec → 图表渲染(PNG) → DOCX，不跳过 |
| "写文档/出方案/生成PRD..." | `harness-document-generation` | 模板遵循 + 图表工具选择(mermaid/fireworks) + PNG截图 + md→docx |
| "修bug/报错/不工作..." | `harness-systematic-debugging` | 四阶段根因分析，不猜 |
| "review/审查代码..." | `harness-code-review` | 独立评审，禁止自审 |
| "实现/开发/写代码..." | `harness-implementation` | TDD + 编码规范 |
| "写测试/跑测试/端到端..." | `harness-testing` | 单测(mock+coverage) + E2E(Playwright) |

触发方式：**自然语言**，无需 `/` 命令。

## 核心纪律（harness-entry 常驻加载）

1. 任何功能开发必须先 brainstorming → 产出 spec → 用户确认 → 才写代码
2. 任何文档必须先读模板 → 逐节匹配 → MD草稿 → 用户审阅 → 转换交付
3. 🔴 **任何含架构图/流程图的方案/设计文档，brainstorming 结束后必须链入 ****`harness-document-generation`**** 完成图表渲染（询问用户选 mermaid 或 fireworks-tech-graph → 渲染 PNG 截图 → 嵌入 DOCX），禁止文档中出现 ASCII 线框图（┌┐└┘）或未渲染的图表代码块**
4. 任何 bug 必须先找根因 → 稳定复现 → 才修
5. 禁止临时写脚本代替标准工具脚本
6. 禁止凭印象生成代替读模板
7. 编码完成后必须走测试 → 单测覆盖 ≥80% + E2E 截图验证。**编码的终点是测试通过，不是写完代码。** 禁止在未执行测试前声称"编码完成"或将编码完成作为会话终点。编码完成后必须 invoke `harness-testing`，并写入 `pipeline-state.json` 状态文件。

## 路径解析规则（三层覆盖）

查找任何模板、规则、脚本、知识库文件时，按以下优先级依次查找，**找到即停**：

```
1. <project>/.harness/        ← 项目覆盖（最高优先级）
2. ~/.claude/harness.local/   ← 公司/组织覆盖
3. ~/.claude/harness/         ← Harness 默认（兜底）
```

| 内容 | 相对路径 | 覆盖语义 |
| --- | --- | --- |
| 核心流水线 | `00-harness-core/` | 同名文件覆盖（通常不覆盖） |
| 详细规则 | `01-rules/` | 同名文件覆盖 |
| 文档模板 | `09-templates/` | 同名文件覆盖 |
| 工具脚本 | `scripts/` | 同名文件覆盖 |
| 变更记录 | `04-changes/` | 项目级独立，不覆盖 |
| 知识库 | `docs/` | 三层叠加，按优先级查找 |

**示例**：查找 `PRD标准模板_v2.0.md` → 先找 `<project>/.harness/09-templates/PRD标准模板_v2.0.md`，没有则找 `~/.claude/harness.local/09-templates/PRD标准模板_v2.0.md`，最后回退 `~/.claude/harness/09-templates/PRD标准模板_v2.0.md`。

**公司定制**：将自定义模板和知识库放入 `~/.claude/harness.local/`（建议独立 git 仓库管理），无需修改 harness 源码，上游更新不冲突。

**项目定制**：在项目根目录创建 `.harness/`，放入项目专属模板和知识库，优先级最高。
