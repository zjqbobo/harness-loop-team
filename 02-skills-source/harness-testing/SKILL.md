---
name: harness-testing
description: >
  PRIMARY TRIGGER — invoke this skill when user says ANY of:
  "写测试" "跑测试" "测一下" "写单测" "单元测试" "端到端测试" "E2E测试"
  "自动化测试" "测试用例" "测覆盖率" "写集成测试" "压测" "压力测试"
  "性能测试" "benchmark" "帮我做下压测" "帮我测" "write test" "run test"
  "e2e test" "unit test" "test coverage" "stress test" "perf test".

  Provides three paths:
  Path A: backend unit test (mock + coverage ≥80%, support Java/Python/JS/Go)
  Path B: E2E test (webapp-testing skill + Playwright MCP, frontend only)
  Path C: STRESS TEST — user picks modules from change list, configures mock
  latency, runs multi-round benchmarks with CPU/memory/GC metrics. Can be
  invoked standalone (no UT/E2E prerequisite) or as post-testing follow-up.
  After UT+E2E pass, MUST ask user whether to proceed to stress testing.
---

# Harness — 自动化测试

<HARD-GATE>
测试执行前必须：
1. 检查流水线状态：按路径解析规则查找 `04-changes/` 下的 `pipeline-state.json`。如检测到 `implementation-complete`，提示"检测到编码已完成，是否接续测试？"。无状态文件则直接作为独立测试任务执行，不拦截
2. 确认被测试代码的范围和依赖
3. 后端单测：mock 外部依赖，覆盖正常路径 + 边界 + 异常
4. E2E 测试：先确认服务运行中，再执行
5. 测试失败 ≠ 跳过，必须在报告中记录并分类（代码 bug / 环境问题 / 测试用例问题）

---

## 🔴 测试完成后询问不可跳过

测试执行完成后，AI 根据测试结果自行判断是否通过，然后必须按固定顺序询问：
1. **单测/覆盖率 + E2E 全部通过后，必须先询问是否压测**（Path C；用户可选择跳过，但 AI 不可跳过询问）
2. 压测完成或用户明确跳过后，询问是否生成测试报告
3. 测试报告完成或用户明确跳过后，询问是否进行代码审查

AI 不得在未完成以上链式询问的情况下声称"测试完成"或结束会话。

---

## 🔴 流程恢复门禁

用户在流程中指出错误、违规或跳过步骤后，AI 完成补救和沉淀评估后，必须：
1. 输出 `恢复点：harness-testing Path X Step Y`
2. 从该恢复点继续执行原 pipeline
3. 禁止把补救完成当作测试完成或会话终点

若无法判断恢复点，必须使用 `AskUserQuestion` 询问用户恢复到哪一步。

---

## 🔴 结构化交互门禁

所有"是否继续/下一步/执行/跳过/压测/报告/审查"等决策，必须使用 `AskUserQuestion` 或 `PromptForUserInput`。

禁止使用普通文本让用户输入 `1/2/继续/是/否`。
</HARD-GATE>

## 知识加载（测试前必读）🔴

### Phase -2: Pipeline Context Recovery（🔴 HARD RULE）

测试执行前，先从 pipeline-state 继承深度档位：

#### Step 1: 读取 pipeline-state.json

按路径解析规则查找 `<project>/.harness/04-changes/<change_id>/pipeline-state.json`，读取 `depth` 字段。

独立触发（无 pipeline-state）→ 默认按 🟡 standard 执行。

#### Step 2: 输出深度确认

```
📋 Pipeline Context Recovery：
  ✅ 深度档位：[从 pipeline-state 继承: 🟢 完整工程]
```

#### Step 3: 深度驱动测试行为（🔴 以下为可执行规则，非建议）

| 深度 | Path A 单测 | Path B E2E | Path C 压测 | 覆盖率门禁 | 测试报告 |
|------|-----------|-----------|-----------|-----------|---------|
| 🔵 quick | 仅 happy path，不 mock | **跳过** | **跳过询问** | 不强制 | 不生成 |
| 🟡 standard | mock + 正常 + 边界 + 异常 | 前端项目可选，后端跳过 | 必须询问用户 | statement≥80% branch≥70% | 可选(MD) |
| 🟢 full-engineering | 🟡全部 + 强制 mock 所有外部依赖 | 前端项目**强制执行** + Playwright截图 | 必须询问用户（不可跳过） | 🟡全部 + 不达标=阻断 | **强制**生成(MD+docx) |

**执行规则**：每个 Path 开始前必须先检查深度，决定执行范围。"

**禁止在未完成 Pipeline Context Recovery 前开始测试。**

按路径解析规则（项目 `.harness/` > `~/.claude/harness.local/` > `~/.claude/harness/`）依次查找，找到即停。

### 始终加载
1. 读取 `01-rules/02-development-workflow/01-testing-standards.md`（测试规范：mock 策略、覆盖要求、Given/When/Then 结构）

### 🔴 知识库加载验证（必须展示）

完成知识加载后，必须输出已加载文件清单：

```
📚 已加载测试知识库：
  ✅ 01-rules/02-development-workflow/01-testing-standards.md
  ✅ docs/coding-standards/<stack>/10-testing.md（如存在）
  ...
```

**禁止在未输出加载清单前开始写测试。**

### 技术栈检测（根据被测试代码的语言）
分析被测代码所在项目，按以下信号确定技术栈（命中第一个即停），**直接读取**对应栈的测试规范：

| 检测信号 | 技术栈 | 加载文件 |
|---|---|---|
| `pom.xml` / `build.gradle`（无 AndroidManifest.xml） | Java | `docs/coding-standards/java/10-testing.md` |
| `package.json` + `tsconfig.json` | TypeScript | `docs/coding-standards/typescript/04-testing.md` |
| `go.mod` | Go | `docs/coding-standards/go/04-testing.md` |
| `pyproject.toml` / `setup.py` | Python | `docs/coding-standards/python/04-testing.md` |
| `.csproj` / `.sln` | .NET | `docs/coding-standards/dotnet/05-testing.md` |
| `build.gradle.kts` + `AndroidManifest.xml` | Android | `docs/coding-standards/android/06-testing.md` |
| `*.xcodeproj` / `*.xcworkspace` | iOS | `docs/coding-standards/ios/07-testing.md` |

### 按需加载
- 涉及数据库层测试 → 读取被测代码的 `repository/` 层源码，了解数据模型

## 测试类型决策树

```
用户请求 →
├─ "单测" / "单元测试" / "测覆盖率" / 后端代码测试
│   → Path A: 后端单元测试 (JUnit/pytest/Jest/Go test)
│      → 通过后自动触发 Path C 询问
│
├─ "端到端" / "页面测试" / "UI测试" / "浏览器测试" / 前端页面测试
│   → Path B: E2E 测试 (webapp-testing skill + Playwright MCP)
│      → 通过后自动触发 Path C 询问
│
├─ "压测" / "压力测试" / "性能测试" / "benchmark"
│   → Path C: 压测（直接进入压测流程）
│
└─ "帮我测" / 没有明确指定类型
    → 自动分析项目类型决定路径:
      ├─ package.json 含 react/vue/next → Path B (前端)
      ├─ pom.xml / go.mod / Cargo.toml → Path A (后端)
      └─ 全栈 → Path A + Path B 都走
      所有路径通过后 → Path C 询问
```

---

## Path A: 后端单元测试

### 流程

```
分析被测代码 → 识别依赖 → 生成 Mock → 写测试用例 → 执行 → 报告
```

### Step 1: 分析被测代码
- 读取被测文件和依赖
- 识别需要 mock 的外部依赖（数据库、API、文件系统、外部服务）
- 识别测试边界

### Step 2: 识别测试场景
- **正常路径**（happy path）：输入正确 → 预期输出
- **边界条件**：空值、最大值、特殊字符、null/undefined
- **异常路径**：依赖失败、超时、资源不存在

### Step 3: 生成测试文件
- 遵循项目已有的测试框架（JUnit / pytest / Jest / Go testing）
- Mock 外部依赖
- 每个测试有明确的三段：Given / When / Then

### Step 4: 执行测试
```bash
# 自动检测项目测试命令
mvn test                  # Java 项目
npm test -- --coverage    # Node.js 项目
pytest --cov              # Python 项目
go test -coverprofile=    # Go 项目
```

### Step 5: 报告

- 通过数 / 失败数 / 跳过数
- 失败分类：代码 bug / 环境问题 / 测试用例问题

#### 🔴 覆盖率门禁（深度驱动）

| 深度 | 覆盖率要求 | 不达标处理 |
|------|-----------|-----------|
| 🔵 quick | 不检查 | 直接通过 |
| 🟡 standard | statement ≥ 80%, branch ≥ 70% | 警告，询问用户是否继续 |
| 🟢 full-engineering | statement ≥ 80%, branch ≥ 70% | **阻断**，返回 implementation 补充测试 |

```
🧪 覆盖率门禁检查：
  深度：[🔵 quick / 🟡 standard / 🟢 full-engineering]
  statement: X% / 80%
  branch: Y% / 70%
  结果：[✅ 达标 / ⚠️ 警告 / 🔴 阻断]
```

各语言测试代码模板见上方"技术栈检测"表中对应的测试规范文件。

---

## Path B: E2E 测试 (webapp-testing + Playwright MCP)

<CRITICAL>
Path B 仅适用于**前端/全栈 Web 项目**（React/Vue/Next.js/HTML 等）。
Java 后端库、CLI 工具、纯 API 项目**走 Path A**，跳过此路径。
项目类型由分析 `package.json`/`pom.xml`/目录结构自动判定。
</CRITICAL>

### 🔴 E2E 深度门控（Path B 入口，必须判定）

| 深度 | E2E 行为 |
|------|---------|
| 🔵 quick | **跳过 Path B**，不执行 E2E |
| 🟡 standard | 前端项目可选，询问用户是否执行 |
| 🟢 full-engineering | 前端项目**强制执行**（不可跳过），后端项目声明不适用后跳过 |

```
📋 Path B E2E 深度判定：
  深度：[🔵 quick / 🟡 standard / 🟢 full-engineering]
  项目类型：[前端 / 后端 / 全栈]
  判定结果：[⏭️ 跳过 / 📢 询问用户 / 🔴 强制执行]
```

**禁止在未输出 E2E 深度判定前进入 Step 0。**

### Step 0: 加载 E2E 工具链 🔴
1. 加载 `webapp-testing` skill（提供 `with_server.py` 服务管理脚本）
2. 确认 Playwright MCP 工具可用（`browser_navigate` / `browser_snapshot` / `browser_take_screenshot`）

### 流程

```
Step 0(加载工具链) → 分析项目类型 → 识别页面操作流 → 启动服务(webapp-testing) 
→ 写 Playwright 脚本(Playwright MCP) → 执行 → 截图/报告
```

### Step 1: 分析项目类型（自动路由）

| 检测到 | 路径 |
|--------|------|
| `package.json` 含 react/vue/next/svelte | → Path B |
| `pom.xml` 仅后端 / 纯 Java 项目 | → Path A（跳过 Path B） |
| 全栈（frontend/ + backend/ 目录） | → Path A + Path B 都走 |

### Step 2: 浏览器预检（必须在调用 Playwright MCP 前执行）

**每次**调用 Playwright MCP 前，先检查浏览器二进制是否已安装。避免 MCP 启动时自动触发 browser download。

```bash
# macOS
ls ~/Library/Caches/ms-playwright/ 2>/dev/null

# Linux
ls ~/.cache/ms-playwright/ 2>/dev/null
```

| 检测结果 | 行为 |
|---------|------|
| 缓存目录存在且有浏览器 | ✅ 直接调用 Playwright MCP |
| 缓存目录不存在 | ⚠️ 提示用户"Playwright 浏览器未安装，执行 `npx playwright install chromium` 安装后重试" → 跳过 Path B |
| 不确定 | 询问用户是否继续（可能触发浏览器下载） |

### Step 3: 分析页面操作流
- 了解用户操作路径
- 识别每个步骤的 UI 元素（按钮/输入框/表单/弹窗）
- 确认预期行为

### Step 4: 启动服务（调用 webapp-testing skill）

**必须** invoke `Skill: webapp-testing` 管理服务生命周期：

```
Skill: webapp-testing
→ 使用 with_server.py 启动前后端服务
→ 服务就绪后，Playwright 开始测试
→ 测试完成后，自动停止服务
```

### Step 5: 编写和执行 Playwright 测试（使用 Playwright MCP）

**必须**使用 Playwright MCP 工具执行浏览器操作，不手写 Python 脚本：

```
Playwright MCP 工具链:
  mcp__playwright__navigate        → 导航到 URL
  mcp__playwright__click           → 点击元素
  mcp__playwright__fill            → 填写表单
  mcp__playwright__screenshot      → 截图保存
  mcp__playwright__evaluate        → 执行 JS 验证状态
```

### Step 5: 验证与报告
- 每个关键步骤截图（宽度 ≥ 1200px）
- 失败时保留页面状态截图
- 输出：通过步骤数 / 失败步骤数 / 截图清单

---

## 错误沉淀评估

→ 按路径解析规则加载 `01-rules/02-development-workflow/02-error-precipitation.md`，按其中的评估步骤执行。

## 与现有基础设施集成

### Path B 依赖的外部插件

| 插件/技能 | 用途 | 调用方式 |
|-----------|------|---------|
| `webapp-testing` skill | 管理前后端服务生命周期（启动/停止/健康检查） | `Skill: webapp-testing` |
| `playwright` MCP | 浏览器自动化（导航/点击/填表/截图/JS验证） | MCP tools: `mcp__playwright__*` |
| E2E 截图 | 每个关键步骤截图存 `screenshots/` 目录 | Playwright MCP `screenshot` |

### Path A 工具链

| 工具 | 用途 | 适用项目 |
|------|------|---------|
| JaCoCo | Java 覆盖率 | Maven/Gradle Java 项目 |
| pytest-cov / coverage.py | Python 覆盖率 | Python 项目 |
| Jest --coverage | JS/TS 覆盖率 | Node.js 项目 |
| go test -coverprofile | Go 覆盖率 | Go 项目 |

### code-review 插件对接

→ 见 `harness-code-review` SKILL.md 审查后移交节

### 门禁标准

| 门禁 | 要求 |
|------|------|
| 单测覆盖率 | statement ≥ 80%, branch ≥ 70% |
| E2E | 核心流程截图通过 |
| 压测 | 按需，用户确认后执行 |

### 链式移交

#### 🔴 移交上下文（移交前必须输出）

```
📋 移交上下文：
  change_id: <YYYYMMDD-需求名>
  depth: <从 Phase -2 继承的深度>
  test_result: { total: N, passed: N, failed: N, coverage_statement: X%, coverage_branch: Y% }
  test_report_generated: true/false
```

```
测试全部通过 + 覆盖率达标（按深度门控判定）
    ↓
📢 Path C 压测询问（按深度门控：🔵跳过，🟡/🟢必须询问）
    ↓
  ├─ 用户选择压测 → 执行压测 → 根据结果继续/退回实现/暂停
  └─ 用户选择跳过 → 继续
    ↓
📢 测试报告询问（按深度门控）
    ├─ 🟢 full-engineering → 强制生成测试报告(MD+docx)，不询问
    ├─ 🟡 standard → 询问用户是否生成测试报告(MD)
    └─ 🔵 quick → 跳过，不询问
    ↓
📢 展示改动概要 + 测试结果，询问用户："测试全部通过（N/N，覆盖率 X%）。是否进行代码审查？"
    ↓
  ├─ 是 → 进入 harness-code-review
  └─ 否 → 保持现状
```

**询问前必须展示**：
```
📊 本次改动概要：
  新增文件: N 个
  修改文件: M 个
  总行数: +X / -Y
  
📋 关键改动:
  - [类名] — [一句话描述]

🧪 测试结果:
  用例数: N | 通过: N | 失败: 0 | 覆盖率: X% inst / Y% branch
```

- 测试失败（代码 bug）→ 返回 harness-implementation 修复
- 测试失败（环境问题）→ 报告用户，暂停流水线

### <HARD-GATE> 测试完成后更新流水线状态

测试执行完毕后，**必须**更新变更目录下的 `pipeline-state.json`：

```json
{
  "current_stage": "testing-complete",
  "timestamp": "<ISO 8601>",
  "test_result": {
    "total": N,
    "passed": N,
    "failed": N,
    "coverage_statement": N,
    "coverage_branch": N,
    "result": "PASSED | FAILED | PARTIAL"
  },
  "test_report_generated": true/false,
  "next_stage": "code-review-complete"
}
```

---

## Path C: 压测（Stress Test）

<HARD-GATE>
单元测试和 E2E 测试全部通过后，**根据深度决定是否询问压测**。

### 🔴 压测深度门控（Path C 入口）

| 深度 | 压测行为 |
|------|---------|
| 🔵 quick | **跳过询问**，不执行压测 |
| 🟡 standard | **必须询问**用户是否压测 |
| 🟢 full-engineering | **必须询问**用户是否压测（不可跳过询问环节） |

```
📋 Path C 压测深度判定：
  深度：[🔵 quick / 🟡 standard / 🟢 full-engineering]
  判定结果：[⏭️ 跳过压测询问 / 📢 必须询问用户]
```

**🔵 quick 直接跳过，不询问。🟡/🟢 必须展示询问。**
此环节不可跳过，但用户可以选择跳过压测本身。
</HARD-GATE>

详细流程见 `01-rules/02-development-workflow/04-stress-test-standards.md`，核心要点：

- **C1**：展示真实改动清单 → 用户勾选压测目标
- **C2**：压测配置（数据规模/并发度/mock/轮数），mock 列表从真实依赖中提取
- **C3-C4**：执行压测，项目工具自动检测
- **C5**：动态生成压测报告（指标根据被测功能类型选择）
- **C6**：通过→移交 / 回归→回 implementation / 环境问题→暂停

所有选项内容和报告指标必须从实际代码改动中动态生成。

---

## 禁止行为

- ❌ 跳过 mock 直接连真实数据库写测试
- ❌ 只写 happy path，不覆盖边界和异常
- ❌ E2E 测试不保留截图
- ❌ 测试失败不分类直接报"失败"
- ❌ 不检查服务运行状态就直接跑 E2E
- ❌ **压测选项和报告固化** — C1 候选清单、C2 mock 列表、C5 报告指标必须从实际代码改动中动态生成，禁止照抄 SKILL.md 中的示例内容

---

## 🔴 测试完成标准

测试执行完成后，必须输出以下检查结果：

```
📋 测试完成检查：
  ✅/❌ 单元测试通过：[通过数/总数]
  ✅/❌ E2E测试通过：[通过数/总数 或 不适用原因]
  ✅/❌ 代码覆盖率达标：[statement ≥80%, branch ≥70%]
  ✅/❌ 压测询问已执行：[执行/跳过/不适用原因]
  ✅/❌ 测试报告询问已执行：[生成/跳过]
  ✅/❌ 代码审查询问已执行：[进入/跳过]
  ✅/❌ pipeline-state.json 已更新：[current_stage=testing-complete]
```

**任一项为 ❌ 时**：分析原因，修复问题直到满足标准。

---

## 🔴 会话结束门禁

在结束会话前，必须完成以下检查：

```
📋 会话结束检查：
  ✅/❌ 链式移交询问已完成（审查询问）
  ✅/❌ 用户已明确下一步选择
  ✅/❌ pipeline-state.json 已更新
```

**禁止以下行为**：
- 在未完成链式移交询问的情况下结束会话
- 用户未明确选择就自行判断"任务完成"
- 未更新 pipeline-state.json 就结束会话

会话只能在以下情况结束：
1. 用户明确选择"暂不继续"→ 记录状态 → 结束
2. 用户选择继续 → 调用下一个 skill → 会话移交
