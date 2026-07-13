# 自动化测试规范

> 📌 范围: 后端单元测试 + 端到端 (E2E) 测试 + 测试文档沉淀
> 📌 门禁: Gateway 3 — coverage ≥ 80% statement, ≥ 70% branch

---

## 1️⃣ 后端单元测试规范

### 测试文件位置

与被测代码同目录或镜像目录，具体遵循各技术栈约定：

| 技术栈 | 约定 | 示例 |
|--------|------|------|
| Java | 镜像目录，`src/test/java/` 对应 `src/main/java/` | `service/OrderServiceTest.java` |
| TypeScript | 同级 `__tests__/` 或镜像目录 | `__tests__/userService.test.ts` |
| Go | 同包同级 `_test.go` | `user_service_test.go` |
| Python | 项目 `tests/` 目录镜像 | `tests/unit/test_user_service.py` |
| .NET | 独立测试项目 | `Project.Tests/OrderServiceTests.cs` |

> 各栈详细约定见 `docs/coding-standards/<stack>/xx-testing.md`。

### Mock 规范
- 外部 API → Mock HTTP 响应
- 数据库 → Mock DAO/Repository 层
- 文件系统 → Mock fs 模块
- 时间 → Mock Date / setTimeout
- **禁止**：Mock 被测代码本身

### 测试用例覆盖要求

| 类型 | 最低要求 | 示例 |
|------|---------|------|
| Happy Path | 所有公开方法的主流程 | 正常输入 → 预期输出 |
| 边界条件 | 空/null/0/负数/最大/最小 | `null`, `""`, `0`, `-1`, `INT_MAX` |
| 异常路径 | 所有 try/catch 分支 | 依赖失败、超时、资源不存在 |
| 状态转换 | 有状态的对象 | 创建→激活→暂停→删除 |

### 测试结构（Given/When/Then）

```
Given  — 准备输入和 mock
When   — 执行被测方法
Then   — 断言输出和副作用
```

### 覆盖率门禁

```json
{
  "coverage_statement": 85,  // ≥ 80% 通过
  "coverage_branch": 75,     // ≥ 70% 通过
  "total_tests": 42,
  "passed": 42,
  "failed": 0
}
```

---

## 2️⃣ E2E 测试规范

### 技术栈
- **Playwright** (v1.59+)
- `webapp-testing` skill 的 `scripts/with_server.py`

### 测试场景识别

| 页面操作 | 测试要点 |
|---------|---------|
| 导航 | URL 正确跳转 + 页面加载完成 |
| 表单提交 | 输入 → 提交 → 成功提示 → 数据正确 |
| 错误处理 | 非法输入 → 错误提示 → 状态不变 |
| 登录态 | 登录→操作→登出→未登录无法操作 |

### 截图要求
- 每个关键步骤截图（命名：`{序号}-{步骤名}.png`）
- 失败时保留失败页面截图
- 图片宽度 ≥ 1200px

### 服务管理

```bash
# 单服务
python ~/.claude/skills/webapp-testing/scripts/with_server.py \
  --server "npm run dev" --port 5173 -- python test_e2e.py

# 前后端联调
python ~/.claude/skills/webapp-testing/scripts/with_server.py \
  --server "cd backend && python server.py" --port 3000 \
  --server "cd frontend && npm run dev" --port 5173 \
  -- python test_e2e.py
```

### 浏览器路径可移植性 🔴

- E2E 脚本禁止硬编码本机浏览器绝对路径。
- 如需指定浏览器二进制，必须通过环境变量传入，例如 `PLAYWRIGHT_CHROMIUM_EXECUTABLE`。
- 默认优先使用 Playwright 自身发现机制或 webapp-testing/Playwright MCP 的浏览器预检结果。
- 本机缓存路径只能出现在命令行环境变量中，不能写入仓库脚本。

---

## 3️⃣ 测试文档规范

### 测试用例文档

- 模板路径: 按三层覆盖规则查找 `09-templates/测试用例文档模板.md`
  - `<project>/.harness/09-templates/测试用例文档模板.md` (项目覆盖)
  - `~/.claude/harness.local/09-templates/测试用例文档模板.md` (公司覆盖)
  - `~/.claude/harness/09-templates/测试用例文档模板.md` (默认兜底)
- 组织方式: 按需求/功能维度，每个需求下按场景分组
- 用例要素: ID、标题、优先级(P0/P1/P2)、前置条件、操作步骤、预期结果
- 产出流程: Read 模板 → 生成 MD → 用户审阅 → 可选转 DOCX

### 测试报告文档

- 模板路径: 按三层覆盖规则查找 `09-templates/测试报告文档模板.md`
  - `<project>/.harness/09-templates/测试报告文档模板.md` (项目覆盖)
  - `~/.claude/harness.local/09-templates/测试报告文档模板.md` (公司覆盖)
  - `~/.claude/harness/09-templates/测试报告文档模板.md` (默认兜底)
- 核心内容: 执行概况、按需求维度的执行明细、缺陷清单、风险与遗留问题、测试结论
- 产出流程: Read 模板 → 生成 MD → 用户审阅 → 可选转 DOCX

---

## 4️⃣ 流水线状态管理

### 状态文件

每个变更目录下维护 `pipeline-state.json`，追踪完整的流水线阶段。详细 Schema 按路径解析规则查找 `docs/pipeline-state-schema.md`。

### 状态文件路径

```
<project>/.harness/04-changes/{YYYYMMDD-需求名}/pipeline-state.json
```

### 写入规则

| 阶段 | 写入方 | 写入时机 |
|------|--------|---------|
| `implementation-complete` | harness-implementation | 编码完成、测试用例文档决策点后 |
| `testing-complete` | harness-testing | 测试执行完毕、测试报告决策点后 |
| `code-review-complete` | harness-code-review | 审查完成 |

### 读取规则

- harness-testing 启动时：读取 pipeline-state.json，确认 `current_stage == "implementation-complete"`
- harness-entry 启动时：扫描 `04-changes/` 下是否有未关闭的变更（`current_stage != "closed"`），提示用户恢复

---

## 5️⃣ 链式移交规则

```
harness-implementation 编码完成
    ↓
    ❶ 写入 pipeline-state.json (current_stage=implementation-complete)
    ↓
    ❷ 是否生成测试用例文档?
    ├─ 是 → Read模板 → 生成MD → 用户审阅 → 可选转DOCX
    └─ 否 → 跳过
    ↓
    ❸ invoke harness-testing（禁止跳过）
    ↓
harness-testing 执行测试
    ↓
    ❹ 写入 pipeline-state.json (stage=testing-complete)
    ↓
    ❺ 是否生成测试报告?
    ├─ 是 → Read模板 → 生成MD → 用户审阅 → 可选转DOCX
    └─ 否 → 跳过
    ↓
  ├─ 全部通过 → harness-code-review
  ├─ 失败(代码bug) → 返回 harness-implementation 修复
  └─ 失败(环境) → 报告用户, 暂停流水线
```
