---
name: harness-implementation
description: Use when user asks to 实现, 开发, 写代码, 实现功能, 编码,
  implement, develop, code, build — enforces TDD (test-driven development)
  with dynamic tech stack detection and coding standards. Must be preceded by brainstorming + design docs.
  Triggers on: 帮我写, 实现这个, 开发, 写代码, 编码实现.
---

# Harness — 编码实现

<HARD-GATE>
## 🔴 编码开始前必须回答（强制检查点）

在写第一行代码前，必须**先输出以下检查结果**，缺一不可：

```
📋 编码前检查：
  ✅/❌ 深度档位：[从 Phase -2 继承: 🔵/🟡/🟢，禁止自行降级]
  ✅/❌ 设计输入就绪：[方案文档路径 + 用户审阅状态]
  ✅/❌ 技术栈检测结果：[技术栈名称]
  ✅/❌ 已加载规范文件：[列出文件路径]
  ✅/❌ Implementation plan：[已编写/待编写 + 是否包含规范对照/例外说明]
```

**任一项为 ❌ 时禁止编码**，先完成对应步骤。**深度档位不可自行修改**，如需降级必须通过 `AskUserQuestion` 获得用户确认。

---

## 🔴 MVP 语义澄清

PRD 中的 MVP / V1.0 / 试点范围仅代表**业务功能范围**，不代表**工程质量降级**。

若深度档位为 🟢 完整工程：
- 可以实现业务上的 MVP 范围
- 但代码质量、分层、规范遵守、测试、审查必须按完整工程标准执行

任何"先做骨架 / demo / 快速跑通 / 后面再补规范"的实现方式，必须先用 `AskUserQuestion` 明确征得用户确认。未经确认，禁止自行降级。

---

## 🔴 编码完成后询问不可跳过

编码完成后，必须依次询问：
1. 是否执行测试套件？
2. 是否生成测试用例文档？
3. 是否进行代码审查？

AI 不得在未询问用户的情况下声称"编码完成"或结束会话。

---

## 🔴 流程恢复门禁

用户在流程中指出错误、违规或跳过步骤后，AI 完成补救和沉淀评估后，必须：
1. 输出 `恢复点：harness-implementation Step X`
2. 从该恢复点继续执行原 pipeline
3. 禁止把补救完成当作编码完成或会话终点

若无法判断恢复点，必须使用 `AskUserQuestion` 询问用户恢复到哪一步。

---

## 🔴 结构化交互门禁

所有"是否继续/下一步/确认执行/跳过/提交/测试/审查"等决策，必须使用 `AskUserQuestion` 或 `PromptForUserInput`。

禁止使用普通文本让用户输入 `1/2/继续/是/否`。

---

## 编码前必须确认设计输入就绪（按深度档位判定）

- 🔵快速通道：1问问清即可，无需 spec，直接编码
- 🟡标准/🟢完整：需 design spec 或 PRD 已通过用户审阅
- **多角色移交**：上游角色（PM/架构师）已交付 spec/PRD → 直接接续编码，不重复设计
- **方案文档实现场景**：用户提供方案文档 → 先 Read 方案 → 提取技术栈信息 → 执行 Step 0 技术栈检测 → 加载知识库 → 编码

若设计输入缺失 → 确认深度：完整/标准→退回 brainstorming，快速→直接执行

---

## 编码前环境确认

- Implementation plan 已编写，每步 2-5 分钟粒度。最小结构：
  1. **目标**：1 句话描述本次实现的目标
  2. **范围**：本次改动的文件/模块清单
  3. **步骤**：每个步骤 TDD 红-绿-重构循环
  4. **规范对照**：已加载规范 → 落实方式 → 例外说明（见下方）
  5. **风险点**：如有
- 🔴 Implementation plan 必须包含“规范对照”章节：列出已加载规范如何落实到目录结构、分层、DTO/VO/Entity隔离、异常、配置、安全、测试；如 MVP 阶段有意不完全遵守某条规范，必须写明例外、原因、风险、后续补齐阶段，并获得用户确认
- 当前环境已隔离（git worktree 或新分支）
</HARD-GATE>

## TDD 流程

> 🔵快速通道无需完整红-绿-重构循环，1问问清后直接改。🟡/🟢强制执行以下 TDD 流程：

```
RED → GREEN → REFACTOR
  ↓                ↓
  写失败测试    重构优化
  ↓                ↓
  确认失败      确认仍绿
  ↓                ↓
  最小实现 → COMMIT
```

## 知识加载（编码前必读）

<HARD-GATE>
设计文档存在时，强制执行以下流程：
1. 先检测/生成索引
2. AI 自行判断加载哪些章节
3. 按需加载（使用 Read offset + limit）
4. 禁止全量加载设计文档
</HARD-GATE>

### 🔴 知识加载深度控制（HARD RULE，Step 0-1 执行前必须判定）

知识加载**必须先按深度档位裁剪**，再执行具体步骤。不同深度加载不同量的知识：

| 加载项 | 🔵 quick | 🟡 standard | 🟢 full-engineering |
|-------|----------|-------------|---------------------|
| 设计文档按需加载（Step 0） | 最多加载 2 个章节 | AI 自行判断 | AI 自行判断 + 全局视图评估 |
| 技术栈检测（Step 1） | 仅检测信号 + 读 `00-index.md` 通用纪律 | 完整检测 + 栈规范速查 | 🟡 全部 |
| 始终加载（知识库） | 仅 `00-index.md` | `00-index.md` + `<stack>/00-index.md` + 项目约定 | 🟡 全部 |
| 按场景深入（<stack>/...） | **跳过** | 匹配场景后只读该场景的索引摘要 | **逐文件 Read** 每个匹配的规范文件 |
| 后端共享跨栈规范 | **跳过**（仅涉及安全编码时加载安全规范） | 仅加载与任务相关的 | **全部加载**（REST API + 配置 + 缓存 + 幂等 + 安全） |
| 存量工程约定扫描 | 跳过（使用现有扫描结果） | Read `project-conventions.md`（如存在） | Read 或扫描推断，输出完整约定清单 |
| Reuse Before Create | 快速 grep 检查 | 完整检索现有实现 | 🟡 全部 + 输出检索报告 |

**执行规则**：在 Step 0 开始前，先输出裁剪结果：

```
📋 深度档位知识加载裁剪：
  深度：[🔵 quick / 🟡 standard / 🟢 full-engineering]
  裁剪结果：
    ✅ 将加载：[列出加载项]
    ⏭️ 将跳过：[列出跳过项]
```

**禁止在未输出裁剪结果前开始 Step 0。**

### Step 0: 设计切片按需加载（优先执行）

执行顺序（不可跳过）：
  0.1 检测设计文档 → 0.2 检测索引文件 → 0.3 生成/更新索引（如需要）
  → 0.4 AI 自行判断加载章节 → 0.5 按需加载 → 0.6 透明化提示

#### 0.1 检测设计文档

查找变更目录下的设计文档（按优先级）：
- 00-design.md
- *设计方案.md
- *设计文档.md

若无设计文档 → 跳过 Step 0，进入 Step 1

#### 0.2 检测索引文件

查找：`<设计文档名>.manifest.json`

判断逻辑（文件大小 + 修改时间）：
| 条件 | 动作 |
|------|------|
| 不存在 | 调用 harness-design-indexer 生成 |
| 存但大小/时间变化 | 调用 harness-design-indexer 更新 |
| 存且有效 | 跳过生成 |

#### 0.3 调用索引生成 skill（如需要）

```
Skill("harness-design-indexer", args="--doc-path <设计文档路径>")
```

等待索引生成完成。

#### 0.4 AI 自行判断加载章节

**用户说**："实现用户登录"

AI 根据任务描述和索引文件中的章节关键词，自行判断需要加载哪些章节：
- 可根据关键词匹配相关章节
- 可加载概览/架构章节理解整体设计
- 可加载依赖模块章节理解关联关系

**索引文件只提供章节位置，不定义加载规则。**

#### 0.5 按需加载章节

使用 `Read(file_path, offset=start-1, limit=end-start+1)`：
- 根据判断结果，只加载对应的行号范围
- 多个章节可多次调用 Read

**建议**：优先按需加载，若 AI 判断需要全局视图（如全量重构、架构调整）可全量加载

#### 0.6 透明化提示

```
📋 设计章节按需加载：
   - 设计文档：00-design.md（共 5972 行）
   - 已加载章节：
     ✅ 项目概览（1-150行）
     ✅ 系统架构设计（151-650行）
     ✅ 用户模块设计（1200-1850行）
   📊 已加载约 1300 行（节省 78%）
```

### Step 1: 技术栈检测（编码前必须执行）

分析项目根目录，按以下信号确定技术栈（命中第一个即停）：

| 检测信号 | 技术栈 | 规范目录 |
|---|---|---|
| `pom.xml` / `build.gradle` / `build.gradle.kts`（无 AndroidManifest.xml） | Java | `docs/coding-standards/java/` |
| `build.gradle.kts` + `AndroidManifest.xml` | Android/Kotlin | `docs/coding-standards/android/` |
| `*.xcodeproj` / `*.xcworkspace` | iOS/Swift | `docs/coding-standards/ios/` |
| `pyproject.toml` / `setup.py` / `requirements.txt` / `Pipfile` | Python | `docs/coding-standards/python/` |
| `go.mod` | Go | `docs/coding-standards/go/` |
| `package.json` + `tsconfig.json` | TypeScript | `docs/coding-standards/typescript/` |
| `package.json`（无 tsconfig.json） | JavaScript | `docs/coding-standards/typescript/`（忽略类型条目） |
| `.csproj` / `.sln` / `Directory.Build.props` | .NET/C# | `docs/coding-standards/dotnet/` |
| 未命中 | 通用 | 仅加载 `docs/coding-standards/00-index.md` 通用纪律 |

### 🔴 技术栈检测输出（必须展示）

完成技术栈检测后，必须输出以下信息：

```
🔍 技术栈检测结果：
  - 检测信号：[如 pom.xml / package.json + tsconfig.json]
  - 命中技术栈：[Java/TypeScript/Python/Go/...]
  - 规范目录：[docs/coding-standards/java/]
```

### 始终加载
1. 读取 `docs/coding-standards/00-index.md`（技术栈路由索引 + 通用纪律）
2. 读取 `docs/coding-standards/<stack>/00-index.md`（栈规范速查索引）
3. 读取 `01-rules/02-development-workflow/00-overview.md`（开发流程规范）
4. 🔴 **项目知识（三层查找，找到即停）**：
   - `docs/architecture/00-overview.md`（全局架构约束）— 先查项目 `.harness/`，再查 `harness.local`，最后查 harness 默认。三层均为 TODO 则跳过
   - `docs/business/domain-glossary.md`（命名宪法）— 同上

### 按需加载
- 涉及新领域模块 → 读取 `docs/business/00-overview.md`
- 涉及核心业务流程 → 读取 `docs/business/core-flows.md`

### 🔴 知识库加载验证（必须展示）

完成知识加载后，必须输出已加载文件清单：

```
📚 已加载知识库：
  ✅ docs/coding-standards/00-index.md
  ✅ docs/coding-standards/java/00-index.md
  ✅ 01-rules/02-development-workflow/00-overview.md
  ✅ docs/architecture/00-overview.md（如存在）
  ✅ docs/business/domain-glossary.md（如存在）
  ✅ docs/coding-standards/rest-api-design.md（如涉及接口）
  ✅ docs/architecture/project-conventions.md（如存在）
  ...
```

**禁止在未输出加载清单前开始编码。**

### 后端项目额外必加载（共享跨栈规范）🔴
> 以下为与编程语言无关的通用规范，所有后端项目（Java/TS/Go/Python/.NET）编码前必须加载：

| 规范 | 文件 | 触发条件 |
|------|------|---------|
| REST API 设计 | `docs/coding-standards/rest-api-design.md` | 新增/修改接口时 |
| 配置管理 | `docs/coding-standards/configuration-management.md` | 任何涉及配置/密钥的编码 |
| 缓存策略 | `docs/coding-standards/cache-strategy.md` | 涉及缓存读写时 |
| 幂等性设计 | `docs/coding-standards/idempotency-design.md` | 涉及支付/订单/消息队列消费时 |
| 安全编码 | 从 `<stack>/00-index.md` 速查表"规范"列找"安全编码"行 → "详情文件"列取文件名 → 拼接路径加载 | 任何编码任务 |

### 存量工程约定加载 🔴

按路径解析规则查找 `docs/architecture/project-conventions.md`：

1. `<project>/.harness/docs/architecture/project-conventions.md`
2. `~/.claude/harness.local/docs/architecture/project-conventions.md`
3. `~/.claude/harness/docs/architecture/project-conventions.md`

若找到且内容不是 TODO：必须 Read，并优先遵守其中的项目工程约定。
若未找到或仍为 TODO：必须扫描现有代码临时归纳项目约定，至少包括返回包装、分页对象、DTO/VO/Entity、异常体系、枚举、常量、工具类、Converter/Mapper、测试风格。

**Reuse Before Create**：新增任何包装类、枚举、常量、工具方法、异常类、Converter、测试基类前，必须先检索现有实现；找不到才能新建。

### 存量编码分层规则 🔴

存量工程中编码时，按维度分层决定跟谁：

| 决策维度 | 跟谁 | 依据 |
|---------|------|------|
| 放哪个包/目录、文件命名 | **项目现有约定** | `project-conventions.md` 或扫描结果 |
| 复用哪些公共类（Result/Page/DTO/Entity/Enum/Constant/Util/Exception/Converter/测试基类） | **项目现有实现** | Reuse Before Create |
| **方法体内的实现质量（全部）** | **harness 已加载的全部规范** | 上方"始终加载"+"按场景深入"已加载的所有规范文件 |

即：
- **放哪、叫什么、复用谁** → 查项目约定（代码看起来像同一个人写的）
- **怎么写** → 查 harness 已加载的全部规范，不只是某几条"底线"（分层/DTO隔离/安全/数据库/并发/事务/日志/基础规范/注释 + REST API/配置/缓存/幂等共享规范）

不可因"项目旧代码也这样写"而绕过 harness 规范。

### 按场景选择性深入

<HARD-GATE>
读完 `<stack>/00-index.md` 后，必须：

1. 根据当前任务类型在速查表的"按场景选择深入阅读"列表中匹配场景
2. 列出该场景对应的**所有规范文件路径**
3. **逐文件 Read** 每个规范文件

禁止仅凭 `00-index.md` 表格的摘要印象编码。索引表格的一行摘要（如"Controller→Service→DAO，禁止跨层调用"）不能替代读完整规范文件（如分层规范中的 DTO 隔离/Converter/横切关注点等细则）。

**示例（新增接口场景，以 Java 为例，其他栈同理）**：
```
📋 场景匹配: "新增 REST 接口" →
   从 00-index 场景表拿到文件列表 →
   逐文件 Read，全部完成后才能写代码
```

**兜底规则**：无法匹配以上场景时，至少 Read `<stack>/00-index.md` 中"通用编码"行列出的文件 + `docs/coding-standards/configuration-management.md`。
</HARD-GATE>

> 以下为各技术栈通用的场景→规范映射示例。实际必读文件以 `<stack>/00-index.md` 中的"按场景选择深入阅读"表为准。

| 任务类型 | 动作 |
|---------|------|
| 新增接口/API/页面 | 读取 `<stack>/00-index.md` → 查对应场景 → 读取列出的规范文件 + `docs/coding-standards/rest-api-design.md` |
| 数据库读写操作 | 读取 `<stack>/00-index.md` → 查对应场景 → 读取列出的规范文件（含数据库访问 + 事务处理条目） |
| 重构现有代码 | 读取 `<stack>/00-index.md` → 查对应场景 → 读取列出的规范文件 |
| 修复 Bug | 读取 `<stack>/00-index.md` → 查对应场景 → 读取列出的规范文件 |
| 涉及外部系统调用 | 读取 `<stack>/00-index.md` → 查对应场景 → 读取列出的规范文件 + `docs/architecture/integration-map.md` |
| 其他/通用编码 | 🔴 兜底：无法匹配以上场景时，至少读取 `<stack>/00-index.md` 中"通用编码"行列出的文件 + `docs/coding-standards/configuration-management.md` |

### 按需加载（非强制）
- 涉及新领域模块 → 读取 `docs/business/00-overview.md`（理解业务语义）
- 涉及核心业务流程 → 读取 `docs/business/core-flows.md`
- 涉及外部系统调用 → 读取 `docs/architecture/integration-map.md`
- 新增依赖或使用陌生 API → 读取 `docs/architecture/tech-stack.md`
- 需要参考推荐模式 → 读取 `docs/patterns/recommended.md`

## 执行模式选择

| 场景 | 模式 |
|------|------|
| Claude Code / 支持 subagent 的平台 | `subagent-driven-development`（推荐） |
| 不支持 subagent 的环境 | `executing-plans`（串行执行） |
| 任务多、上下文易漂移 | `subagent-driven-development` |
| 简单小任务 | `executing-plans` |

**subagent 拆分原则**：
- 多个**互不依赖**的任务 → dispatch 多个 subagent 并行（`superpowers:dispatching-parallel-agents`）
- 有依赖的任务链 → 主 agent 串行执行，**不要**用 subagent 串行（subagent 之间不共享上下文，传递成本大于收益）

## 每个步骤的标准粒度

```markdown
- [ ] Step 1: 写一个失败的测试
- [ ] Step 2: 跑一下，确认它确实失败了
- [ ] Step 3: 写最小实现让测试通过
- [ ] Step 4: 跑测试，确认通过
- [ ] Step 5: Commit
```

## 错误沉淀评估

→ 按路径解析规则加载 `01-rules/02-development-workflow/02-error-precipitation.md`，按其中的评估步骤执行。

## 完工标准

### <HARD-GATE> 编码完成后必须执行，不可静默结束

编码完成后，你**必须依次执行**以下步骤。**禁止**在未完成这些步骤前声称"编码完成"或将会话结束。

#### Step 1: 写入流水线状态

在变更目录下写入当前阶段状态：

按路径解析规则查找 `04-changes/` 目录，找到当前需求的变更目录，写入或更新 `pipeline-state.json`：

```json
{
  "current_stage": "implementation-complete",
  "timestamp": "<ISO 8601>",
  "changed_files": ["<变更文件相对路径，相对于项目根目录>"],
  "test_case_doc_generated": false
}
```

状态文件模板按路径解析规则查找 `docs/pipeline-state-schema.md`。

#### Step 2: 测试文件告知与确认（必须询问用户）

TDD 编码完成后，**必须**列出测试文件并询问用户是否执行：

1. **列出所有测试文件路径**：
```
📋 本次生成的测试文件：
  src/test/java/.../XxxTest.java       (N 用例)
  src/test/java/.../YyyTest.java       (M 用例)
  ...
```

2. **询问用户是否执行完整测试套件**（使用 `AskUserQuestion`）：
```
全部测试文件已生成。是否执行完整测试套件（含覆盖率）？
  [执行] / [跳过]
```

3. 用户选"执行" → 进入 `harness-testing`
4. 用户选"跳过" → 直接询问"是否进行代码审查？" → 进入 `harness-code-review`

#### Step 3: 测试用例文档决策点（可选，测试前询问）

> 编码完成。是否生成测试用例文档？
> - **是** → 按路径解析规则查找 `09-templates/测试用例文档模板.md` → Read 模板 → 按需求/功能维度生成测试用例文档(MD) → 用户审阅 → 可选转DOCX
> - **否** → 跳过

如选择"是"，生成完成后将 `pipeline-state.json` 中 `test_case_doc_generated` 更新为 `true`。

#### Step 4: 移交测试环节

> ⚠️ 编码完成后必须询问用户是否继续测试（见 Step 2），不得静默结束。

如用户在 Step 2 选择执行测试，则调用 `Skill("harness-testing")`，在 prompt 中明确传递：

```
📋 移交上下文：
  change_id: <YYYYMMDD-需求名>
  depth: <从编码前检查继承的深度>
  demand_type: <需求类型>
  changed_files: [<变更文件路径>]
```

如用户选择跳过测试，则直接询问"是否进行代码审查？"（见 Step 2）。

---

## 🔴 TDD 完成标准（🟡/🟢档位强制）

TDD 循环完成后，必须输出以下检查结果：

```
📋 TDD 完成检查：
  ✅/❌ 测试用例编写完成：[数量 + 覆盖场景]
  ✅/❌ 所有测试通过：[执行结果]
  ✅/❌ 代码覆盖率达标：[statement ≥80%, branch ≥70%]
  ✅/❌ 重构优化完成：[如有]
  ✅/❌ Commit 已创建：[commit hash]
```

**任一项为 ❌ 时**：分析原因，继续迭代直到满足标准。

---

## 🔴 会话结束门禁

在结束会话前，必须完成以下检查：

```
📋 会话结束检查：
  ✅/❌ 链式移交询问已完成（Step 2-4 询问）
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
