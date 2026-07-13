# Harness Engineering

一套开源 AI Agent 工程纪律体系，通过纯文本 Markdown 技能文件为 Claude Code 注入工程纪律。

**与 [Superpowers](https://github.com/anthropics/superpowers) 同源的设计哲学**：AI 编程缺的不是智力，是纪律，而纪律可以用纯文本分发。

## 快速开始

```bash
git clone https://github.com/<org>/harness-engineering.git ~/.claude/harness
cd ~/.claude/harness
./install.sh
```

安装完成后，直接用自然语言和 Claude 对话，无需记忆任何命令：

| 你说 | Claude 自动做 |
|------|-------------|
| "帮我设计一个用户中心" | 走 brainstorming → spec → plan → 实现 |
| "帮我写个技术方案文档" | 读模板 → 逐节生成 → 配图 → md转docx |
| "这个接口报 500 了帮我看看" | 系统调试四阶段 → 找根因 → 修 |
| "帮我 review 这段代码" | 独立评审 → 规范检查 → 安全扫描 |
| "帮我实现这个功能" | TDD → 红绿重构 → commit |
| "帮我写个测试/测一下这个页面" | 单测 mock+覆盖 / E2E Playwright 截图 |

## Skill 列表

| Skill | 触发词 | 描述 |
|-------|--------|------|
| `harness-entry` | 会话启动时自动加载 | 建立纪律基线，任务分诊 |
| `harness-brainstorming` | 设计、方案、分析需求、架构 | 9步方案设计流程 |
| `harness-design-review` | 审核方案、review设计、方案评审 | 四检查面，循环至零阻断 |
| `harness-document-generation` | 写文档、出方案、生成PRD | 模板遵循 + 配图 + 转换 |
| `harness-pmo` | 拆任务、排期、里程碑 | 里程碑→史诗→用户故事→任务 |
| `harness-systematic-debugging` | 修bug、报错、不工作 | 四阶段根因调试 |
| `harness-code-review` | review、审查、检查代码 | 三阶段独立评审 |
| `harness-implementation` | 实现、开发、写代码 | TDD + 动态编码规范 |
| `harness-testing` | 写测试、跑测试、E2E | 单测 + E2E + 压测 |
| `harness-init` | 初始化项目规范、分析工程约定 | 扫描代码 → 生成约定 |
| `harness-design-indexer` | 自动调用 | 设计文档章节索引生成 |

## 目录结构

```
harness-engineering/
├── install.sh                     # 一键安装
├── CLAUDE.md                      # 全局 Claude Code 配置
├── README.md                      # 本文件
├── 00-harness-core/               # 中枢定义（流水线、知识索引）
├── 01-rules/                      # 详细规则
│   ├── 02-development-workflow/   # 开发流程、测试、沉淀、分诊、压测规范
│   └── 04-document-standards/     # 文档生成规范（PRD/系统设计/原型）
├── 02-skills-source/              # 技能源文件（11个skill）
│   ├── harness-entry/
│   ├── harness-brainstorming/
│   ├── harness-design-review/
│   ├── harness-document-generation/
│   ├── harness-pmo/
│   ├── harness-systematic-debugging/
│   ├── harness-code-review/
│   ├── harness-implementation/
│   ├── harness-testing/
│   ├── harness-init/
│   └── harness-design-indexer/
├── 09-templates/                  # 文档模板
├── docs/                          # 知识库（架构/业务/编码规范/模式）
└── scripts/                       # 工具脚本
    ├── doc/                       # 文档工具链
    └── generate-design-manifest.py
```

## 架构设计

**瘦 Skill + 胖 Harness**：技能文件（SKILL.md）只做三件事——触发匹配、纪律强制、规则引用。详细规则保留在 `01-rules/` 中按需加载。

- `02-skills-source/` 中的 skill 通过 symlink 注册到 `~/.claude/skills/`
- 更新只需 `git pull`，symlink 自动生效
- 卸载只需删除 symlink

## 与 Superpowers 的关系

两者是**互补**关系，不是替代：

| | Superpowers | Harness Engineering |
|---|---|---|
| 定位 | 通用开发纪律 | 企业级全流程（文档+编码+测试+评审） |
| 能力范围 | 14 个 skill | 11 个复合 skill（含链式移交） |
| 文档体系 | 无 | 完整模板 + 图表 + 转换工具链 |
| 质量门禁 | HARD GATE | 覆盖率+测试+评审三重门禁 |
| 语言 | 英文 | 中英双语触发词 |

**推荐同时安装**，Superpowers 覆盖开发纪律，Harness 覆盖文档/编码/测试/评审全流程。

## 自定义

1. 在 `02-skills-source/` 下创建新目录 `harness-<name>/SKILL.md`
2. 编写 YAML frontmatter（name + description 触发词）+ `<HARD-GATE>` + 流程步骤
3. 重新运行 `./install.sh` 注册

详见 `~/.claude/harness/02-skills-source/harness-entry/SKILL.md` 中的说明。

## License

MIT
