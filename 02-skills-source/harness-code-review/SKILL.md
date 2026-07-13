---
name: harness-code-review
description: Use when user asks to review, 审查, 检查代码, code review, 审计,
  audit code — ensures independent review with 3-phase process: design input check → code review → test review.
  Reviewer must be independent from coder (strict separation of roles).
  After PR creation, chains to code-review plugin for 5-agent parallel deep review.
  Triggers on: 帮我review, 审查一下, 检查这段代码, code review, 审计.
---

# Harness — 代码审查

<HARD-GATE>
Reviewer 和 Coder 角色必须严格分离。
Reviewer 只能评审，不能改代码。
评审发现严重问题 → 退回编码阶段。

---

## 🔴 审查完成后询问不可跳过

审查完成后，必须询问用户：
1. 是否提交代码？
2. 如提交，是否触发代码深度审查（code-review 插件）？

AI 不得在未询问用户的情况下声称"审查完成"或结束会话。

---

## 🔴 流程恢复门禁

用户在流程中指出错误、违规或跳过步骤后，AI 完成补救和沉淀评估后，必须：
1. 输出 `恢复点：harness-code-review Phase X`
2. 从该恢复点继续执行原 pipeline
3. 禁止把补救完成当作审查完成或会话终点

若无法判断恢复点，必须使用 `AskUserQuestion` 询问用户恢复到哪一步。

---

## 🔴 结构化交互门禁

所有"是否继续/提交/触发深度审查/跳过"等决策，必须使用 `AskUserQuestion` 或 `PromptForUserInput`。

禁止使用普通文本让用户输入 `1/2/继续/是/否`。
</HARD-GATE>

## Phase 0: 改动展示（审查前必须执行）

### Phase -2: Pipeline Context Recovery（🔴 HARD RULE，Phase 0 之前必须执行）

审查开始前，先从 pipeline-state 继承深度档位：

#### Step 1: 读取 pipeline-state.json

按路径解析规则查找 `<project>/.harness/04-changes/<change_id>/pipeline-state.json`，读取 `depth` 字段。

独立触发 → 默认按 🟡 standard 执行。

#### Step 2: 输出深度确认

```
📋 Pipeline Context Recovery：
  ✅ 深度档位：[从 pipeline-state 继承: 🟢 完整工程]
```

#### Step 3: 深度驱动审查行为

| 深度 | 审查行为 |
|------|---------|
| 🔵 quick | 快速扫描：检查明显 bug、安全漏洞、代码风格问题 |
| 🟡 standard | 逐文件审查 + 规范对照 + 测试覆盖检查 |
| 🟢 full-engineering | 🟡 全部 + 角色严格分离（审查者≠编码者）+ 5-agent 并行深度审查 + 审查报告 docx |

**禁止在未完成 Pipeline Context Recovery 前开始审查。**

---

审查开始前，**必须**展示本次改动摘要：

```
📊 代码审查 — 改动概要
  分支: <branch-name>
  新增: N 文件, +X 行
  修改: M 文件, +Y / -Z 行
  
📋 变更清单:
  [A/M/D] <文件路径> — 一句话说明
  [A/M/D] <文件路径> — 一句话说明
```

## 知识加载（评审前必读）🔴

按路径解析规则（项目 `.harness/` > `~/.claude/harness.local/` > `~/.claude/harness/`）依次查找，找到即止。

### Step 1: 技术栈检测
根据变更文件所在项目的构建文件确定技术栈（同 harness-implementation 检测表）。

### 🔴 知识库加载验证（必须展示）

完成知识加载后，必须输出已加载文件清单：

```
📚 已加载审查知识库：
  ✅ docs/coding-standards/00-index.md
  ✅ docs/coding-standards/<stack>/00-index.md
  ✅ docs/architecture/00-overview.md（如存在）
  ✅ docs/business/domain-glossary.md（如存在）
  ✅ docs/architecture/project-conventions.md（如存在）
  ...（根据变更文件所在层加载对应规范）
```

**禁止在未输出加载清单前开始评审。**

### Step 2: 始终加载 🔴

1. 读取 `docs/coding-standards/00-index.md`（通用纪律 + 共享跨栈规范索引）
2. 读取 `docs/coding-standards/<stack>/00-index.md`（栈规范速查索引）
3. 🔴 **项目知识（三层查找，找到即停）**：
   - `docs/architecture/00-overview.md`（全局架构约束）— 先查项目 `.harness/`，再查 `harness.local`，最后查 harness 默认。三层均为 TODO 则跳过
   - `docs/business/domain-glossary.md`（命名宪法）— 同上
4. 🔴 **栈内规范文件的查找方式**：每个栈的 `00-index.md` 中"规范速查表"的**"规范"列是条目名，"详情文件"列是文件名**。后续所有步骤需加载栈内规范时，从速查表找到对应条目名行 → 取详情文件列的文件名 → 拼接 `docs/coding-standards/<stack>/<文件名>` → 加载。速查表是各栈自己的数据，不同栈的文件名、编号均不同。

### Step 2.5: 项目工程约定加载 🔴

按路径解析规则查找 `docs/architecture/project-conventions.md`：

1. `<project>/.harness/docs/architecture/project-conventions.md`
2. `~/.claude/harness.local/docs/architecture/project-conventions.md`
3. `~/.claude/harness/docs/architecture/project-conventions.md`

若找到且内容不是 TODO：必须 Read，并检查代码是否复用现有返回包装、分页对象、DTO/VO/Entity、异常体系、枚举、常量、工具类、Converter/Mapper、测试风格。
若未找到或仍为 TODO：根据变更文件附近同类代码临时归纳项目约定。

### 存量审查分层规则 🔴

审查存量工程代码时，按维度分层判断是否合规：

| 决策维度 | 判断标准 | 依据 |
|---------|------|------|
| 文件位置、命名风格、是否复用公共类 | **项目现有约定** | `project-conventions.md` 或同类代码 |
| **方法体内的实现质量（全部）** | **harness 已加载的全部规范** | Phase 2 评审对照表中的所有维度 |

即：
- **放哪、叫什么、复用谁** → 对照项目约定审查（不一致即为不合规）
- **怎么写** → 对照 harness 全部已加载规范审查（不可因"项目旧代码也这样"而放行）

### Step 3: 根据变更文件所在层加载对应规范 🔴

> 栈内规范：从 `<stack>/00-index.md` 速查表"规范"列找条目名 → "详情文件"列取文件名 → 拼接路径加载。**条目存在则加载，不存在则跳过。**
> 固定路径文件（`rest-api-design.md` / `configuration-management.md` / `cache-strategy.md` / `idempotency-design.md`）：直接按路径加载。

| 变更文件所在目录 | 需加载的规范 | 备注 |
|---------|---------|------|
| `controller/` / `handler/` / `api/` / `routes/` / `router/` / `views/` | 速查表：工程分层, 异常处理 + `rest-api-design.md` | 接口层 |
| `service/` / `usecase/` / `domain/` | 速查表：工程分层, 基础规范, 安全编码 | 业务层 |
| `repository/` / `dao/` / `mapper/` / `data/` | 速查表：数据库访问, 事务处理 | 数据层 |
| `consumer/` / `scheduler/` / `job/` / `backgroundjobs/` | 速查表：工程分层（横切关注点）, 并发编程 + `idempotency-design.md` | 横切入口 |
| `components/` / `ui/` / `Presentation/` / `Views/` | 速查表：UI 规范 | 移动端/前端 UI |
| `types/` / `model/` / `schemas/`（类型定义文件） | 速查表：类型安全 | TS/Python 类型 |
| `di/`（依赖注入模块） | 速查表：依赖注入 | DI 容器、生命周期 |
| `config/` / `.env` / `application.yml` / `appsettings.json` | `configuration-management.md`（固定路径） | 配置 |
| 代码中包含缓存读写 | `cache-strategy.md`（固定路径） | 缓存 |
| 代码中包含支付/退款/订单创建/MQ 消费 | `idempotency-design.md`（固定路径）, 速查表：事务处理 | 写操作 |
| **任何目录任何文件** | 速查表：基础规范, 安全编码 | **兜底，不可跳过** |

### Step 4: 从栈 00-index 场景表补充
查看 `<stack>/00-index.md` 中"按场景选择深入阅读"表，根据变更类型匹配对应场景（"新增 REST 接口"/"数据库读写操作"等），额外加载场景行列出的文件。

### Phase 2 评审对照表

> 🔴 **栈内规范**：从 `<stack>/00-index.md` 速查表"规范"列找条目名 → "详情文件"列取文件名 → 拼接路径加载。条目存在则审查，不存在则跳过。
> **固定路径**（`rest-api-design.md` / `configuration-management.md` / `cache-strategy.md` / `idempotency-design.md` / `docs/patterns/anti-patterns.md`）：直接按路径加载，不查速查表。

| 检查维度 | 加载方式 | 检查要点 |
|---------|---------|---------|
| 分层合规 | 速查表：工程分层 | 跨层调用、DTO 隔离、接口化、Converter |
| 异常处理 | 速查表：异常处理 | 是否吞异常、全局异常处理是否完整 |
| 安全编码 | 速查表：安全编码 | SQL 注入、XSS、敏感信息脱敏、硬编码密钥 |
| 数据库访问 | 速查表：数据库访问 | N+1 查询、分页、连接池、迁移 |
| 入参校验 | 速查表：入参校验 | Controller/Service 两层校验、JSR303/Assert 分工 |
| 类型安全 | 速查表：类型安全 | any 禁用、strict 模式、类型标注完整性 |
| 依赖注入 | 速查表：依赖注入 | 构造函数注入、生命周期管理、禁止 Service Locator |
| UI 规范 | 速查表：UI 规范 | 组件职责单一、状态管理、Preview 覆盖 |
| 事务/并发 | 速查表：事务处理, 并发编程 | 事务边界、异步超时 |
| 日志规范 | 速查表：日志打印 | 级别是否正确、是否脱敏 |
| 基础规范 | 速查表：基础规范 | 方法行数、圈复杂度、魔法值、命名、注释 |
| 命名一致性 | `docs/business/domain-glossary.md`（三层查找，TODO 则跳过） | 类名/变量名/方法名/API路径是否使用术语表中的英文，是否使用了禁止同义词 |
| REST API 设计 | `rest-api-design.md`（固定路径） | URL 命名、HTTP method、状态码、响应格式、分页 |
| 配置管理 | `configuration-management.md`（固定路径） | 密钥是否硬编码、`.env` 是否提交 Git |
| 缓存策略 | `cache-strategy.md`（固定路径） | 缓存穿透/击穿/雪崩防护、TTL |
| 幂等性 | `idempotency-design.md`（固定路径） | 支付/订单/MQ 是否幂等 |
| 测试规范 | 速查表：测试规范 | 覆盖率、边界条件、mock 策略 |
| 反模式 | `docs/patterns/anti-patterns.md`（固定路径） | 是否触犯已知反模式 |
| 存量一致性 | `docs/architecture/project-conventions.md`（三层查找，TODO 则跳过） | 是否复用了现有包装/枚举/常量/工具类，是否避免了项目已知坏味道（见"待改善项"） |

## 三阶段评审

### Phase 1: 设计输入完整性检查（轻量）

检查实现是否基于充分的设计输入，不替代 `harness-design-review` 的深度审核：

- 本次实现是否有对应的设计文档/PRD/spec？
  - 有 → 快速检查无明显范围漏洞（无 TBD/TODO 占位、无"后续补充"标记）
  - 无 → 标记为 **WARNING**（不阻断，但需记录为"无设计输入直接编码"）
- 若实现与设计文档有明显偏差（范围溢出、遗漏关键模块）→ 标记为 **CHANGES_REQUESTED**

> 此阶段是防御性检查，防止"无设计直接编码"或"设计与实现脱节"的情况漏过。
> 设计方案的深度审核应在编码前由 `harness-design-review` 完成。

### Phase 2: 代码评审
- 按上述「评审对照表」逐项检查编码规范合规性
- 🔴 必须输出“已加载规范复核表”，逐项给出：Java分层/DTO隔离、异常处理、入参校验、REST规范、安全；Python目录结构/类型标注/错误处理/安全/异步；TypeScript项目结构/类型安全/测试；配置管理；E2E可移植性
- 🔴 如实现计划声明 MVP 阶段性例外，Reviewer 必须检查例外是否已在计划中写明并经用户确认；未经确认的规范偏离必须标为 CHANGES_REQUESTED
- 安全问题扫描
- 性能关注点
- 可维护性评分（≥ 8.0 通过）

### Phase 3: 测试评审
- 测试覆盖率（statement ≥ 80%, branch ≥ 70%）
- 测试用例是否覆盖边界条件
- 全部测试绿通过

## 评审结论

- `APPROVED` — 无问题，可推进
- `CHANGES_REQUESTED` — 有改进建议，修改后重新评审
- `REJECTED` — 严重问题，需重写方案

## 审查后移交

### 🔴 写入 pipeline-state（HARD RULE，移交前必须执行）

审查完成后，**无论用户下一步选什么**，必须先更新 `pipeline-state.json`：

```json
{
  "current_stage": "code-review-complete",
  "stages": {
    "code-review-complete": {
      "status": "COMPLETED",
      "timestamp": "<ISO 8601>",
      "review_result": {
        "conclusion": "APPROVED | CHANGES_REQUESTED | REJECTED",
        "issues_found": <N>,
        "issues_resolved": <N>
      }
    }
  }
}
```

### 审查后询问（必须按顺序）

```
评审结论为 APPROVED 或 CHANGES_REQUESTED（已修复）
    ↓
📢 必须询问用户："审查通过。是否提交代码？"
    ↓
  ├─ 是 → 进入 finishing-a-development-branch（commit/PR 选项）
  │        ↓
  │   用户选择 "Push + 创建 PR" → 创建成功后
  │        ↓
  │   🔴 depth 检查：Phase -2 继承的深度是否为 🟢 full-engineering？
  │        ↓
  │     ├─ 🟢 full-engineering → 📢 强制询问（不可跳过）："完整工程要求触发 /code-review 插件进行 5 Agent 并行深度审查。是否触发？"
  │     │         ↓
  │     │     ├─ 是 → invoke Skill: code-review:code-review
  │     │     │         → 5 Agent 并行审查 → Haiku 置信度过滤(≥80分) → gh CLI 评论到 PR
  │     │     └─ 否 → ⚠️ 提示用户"跳过深度审查可能遗漏潜在问题"，确认后继续
  │     │
  │     └─ 🔵/🟡 → 📢 建议询问（可跳过）："是否触发 /code-review 插件？"
  │              ↓
  │          ├─ 是 → invoke Skill: code-review:code-review
  │          └─ 否 → 完成
  │
  └─ 否 → 保持现状
```

### code-review 插件对接规则

| 规则 | 说明 |
|------|------|
| **触发时机** | 仅在 PR 创建成功后，询问用户是否触发 |
| **适用范围** | 仅 GitHub PR（需 `gh` CLI + remote），本地仓库跳过 |
| **与 harness-code-review 分工** | harness 做提交前把关(本地代码)，插件做提交后深度审查(PR) |
| **不可替代** | code-review 插件**不替代** harness-code-review，两者是上下游关系 |

## 错误沉淀评估

→ 按路径解析规则加载 `01-rules/02-development-workflow/02-error-precipitation.md`，按其中的评估步骤执行。

## 质量门禁

| 门禁 | 要求 |
|------|------|
| 代码评审 | 多维度规范对照审查，无严重安全漏洞，可维护性评分 ≥ 8.0 |
| 测试覆盖率 | statement ≥ 80%, branch ≥ 70%（见 `01-rules/02-development-workflow/01-testing-standards.md`） |

---

## 🔴 审查完成标准

审查完成后，必须输出以下检查结果：

```
📋 审查完成检查：
  ✅/❌ 改动展示已输出
  ✅/❌ 知识库已加载
  ✅/❌ 三阶段评审已完成：[Phase 1/2/3 结果]
  ✅/❌ 审查结论已输出：[APPROVED/CHANGES_REQUESTED/REJECTED]
```

**任一项为 ❌ 时**：完成对应阶段后再进入下一阶段。

---

## 🔴 会话结束门禁

在结束会话前，必须完成以下检查：

```
📋 会话结束检查：
  ✅/❌ 链式移交询问已完成（提交代码询问）
  ✅/❌ 用户已明确下一步选择
```

**禁止以下行为**：
- 在未完成链式移交询问的情况下结束会话
- 用户未明确选择就自行判断"任务完成"

会话只能在以下情况结束：
1. 用户明确选择"暂不继续"→ 记录状态 → 结束
2. 用户选择继续 → 调用下一个 skill → 会话移交
