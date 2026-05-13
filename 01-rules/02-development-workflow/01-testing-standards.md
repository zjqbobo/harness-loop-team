# 自动化测试规范

> 📌 范围: 后端单元测试 + 端到端 (E2E) 测试
> 📌 门禁: Gateway 3 — coverage ≥ 80% statement, ≥ 70% branch

---

## 1️⃣ 后端单元测试规范

### 测试文件位置
```
src/
├── services/
│   ├── UserService.js
│   └── __tests__/           ← 与源码同级
│       └── UserService.test.js
└── utils/
    ├── format.js
    └── __tests__/
        └── format.test.js
```

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

---

## 3️⃣ 链式移交规则

```
harness-implementation 编码完成
    ↓
harness-testing 执行测试
    ↓
  ├─ 全部通过 → harness-code-review
  ├─ 失败(代码bug) → 返回 harness-implementation 修复
  └─ 失败(环境) → 报告用户, 暂停流水线
```
