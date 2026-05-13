---
name: harness-testing
description: Use when user asks to 写测试, 跑测试, 测一下, 写单测, 端到端测试,
  自动化测试, 测试用例, 测覆盖率, 写集成测试, write test, run test, e2e test,
  unit test, test coverage, 帮我测 — enforces automated testing with two paths:
  backend unit test (mock + coverage) and E2E test (Playwright + screenshot).
  Triggers on: 帮我写测试, 跑一下测试, 测一下这个, 写个单测, 端到端测试.
---

# Harness — 自动化测试

<HARD-GATE>
测试执行前必须：
1. 确认被测试代码的范围和依赖
2. 后端单测：mock 外部依赖，覆盖正常路径 + 边界 + 异常
3. E2E 测试：先确认服务运行中，再执行
4. 测试失败 ≠ 跳过，必须在报告中记录并分类（代码 bug / 环境问题 / 测试用例问题）
</HARD-GATE>

## 测试类型决策树

```
用户请求 →
├─ "单测" / "单元测试" / "测覆盖率" / 后端代码测试
│   → Path A: 后端单元测试
│
├─ "端到端" / "页面测试" / "UI测试" / "浏览器测试" / 前端页面测试
│   → Path B: E2E 测试 (Playwright)
│
└─ "帮我测" / 没有明确指定类型
    → 分析代码：后端代码 → Path A / 前端页面 → Path B
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
npm test -- --coverage    # Node.js 项目
pytest --cov              # Python 项目
go test -coverprofile=    # Go 项目
```

### Step 5: 报告
- 通过数 / 失败数 / 跳过数
- **覆盖率**：statement ≥ 80%, branch ≥ 70%
- 失败分类：代码 bug / 环境问题 / 测试用例问题

### 代码模板示例（以 Jest 为例）

```javascript
describe('UserService.create()', () => {
  // Setup mock
  const mockDb = { save: jest.fn() };
  const service = new UserService(mockDb);

  it('should create user with valid input', async () => {
    // Given
    mockDb.save.mockResolvedValue({ id: 1, name: 'test' });
    // When
    const result = await service.create({ name: 'test' });
    // Then
    expect(result.id).toBe(1);
  });

  it('should throw error when name is empty', async () => {
    await expect(service.create({ name: '' }))
      .rejects.toThrow('ValidationError');
  });

  it('should handle database failure gracefully', async () => {
    mockDb.save.mockRejectedValue(new Error('DB down'));
    await expect(service.create({ name: 'test' }))
      .rejects.toThrow('DatabaseError');
  });
});
```

---

## Path B: E2E 测试 (Playwright)

### 流程

```
分析页面操作流 → 识别 selector → 写 Playwright 脚本 → 启动服务 → 执行 → 截图/报告
```

### Step 1: 分析页面操作流
- 了解用户操作路径
- 识别每个步骤的 UI 元素（按钮/输入框/表单/弹窗）
- 确认预期行为

### Step 2: 写 Playwright 脚本

**静态 HTML 页面**：直接读取 HTML 文件获取 selector
**动态 Webapp**：
- 服务未运行 → 使用 `webapp-testing` skill 的 `scripts/with_server.py`
- 服务已运行 → 直接导航 + 操作

### Step 3: 启动服务并执行

```bash
# 单服务
python ~/.claude/skills/webapp-testing/scripts/with_server.py \
  --server "npm run dev" --port 5173 \
  -- python test_e2e.py

# 多服务（前后端）
python ~/.claude/skills/webapp-testing/scripts/with_server.py \
  --server "cd backend && python server.py" --port 3000 \
  --server "cd frontend && npm run dev" --port 5173 \
  -- python test_e2e.py
```

### Step 4: 验证与报告
- 每个关键步骤截图
- 失败时保留页面状态截图
- 输出：通过步骤数 / 失败步骤数 / 截图清单

### Playwright 脚本模板

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()

    # 1. 导航
    page.goto('http://localhost:5173')
    page.wait_for_load_state('networkidle')
    page.screenshot(path='screenshots/01-homepage.png')

    # 2. 操作
    page.click('button:has-text("登录")')
    page.fill('input[name="email"]', 'test@example.com')
    page.fill('input[name="password"]', 'password123')
    page.click('button[type="submit"]')
    page.wait_for_url('**/dashboard')
    page.screenshot(path='screenshots/02-logged-in.png')

    print('✓ 登录流程通过')
    browser.close()
```

---

## 与现有基础设施集成

### 调用 webapp-testing skill
E2E 路径下自动使用 `webapp-testing` 的 `with_server.py` 管理服务器生命周期。

### 门禁标准
→ Read `~/.claude/harness/00-harness-core/00-application-owner-agent.md` Gateway 3:
```json
{
  "coverage_statement": 85,  // ≥ 80%
  "coverage_branch": 75,     // ≥ 70%
  "total_tests": 42,
  "passed": 42,
  "failed": 0
}
```

### 链式移交
- 后端单测路径：harness-testing → 完成后返回 harness-implementation（如测试失败）
- E2E 路径：harness-testing → harness-code-review（如测试通过）

---

## 禁止行为

- ❌ 跳过 mock 直接连真实数据库写测试
- ❌ 只写 happy path，不覆盖边界和异常
- ❌ E2E 测试不保留截图
- ❌ 测试失败不分类直接报"失败"
- ❌ 不检查服务运行状态就直接跑 E2E
