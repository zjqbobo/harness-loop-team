# Python 编码规范速查索引

> AI 编码前必须先读本文件。以下为摘要，完整规则见各子文件。

## 规范速查表

| 规范 | 核心规则（一句话） | 详情文件 |
|------|-------------------|---------|
| 工程分层 | src/ 放源码，tests/ 放测试，依赖用 pyproject.toml 管理 | [01-project-structure.md](01-project-structure.md) |
| 异常处理 | 业务异常自定义异常类，外部调用 try/except 包裹，不裸抛 Exception | [02-error-handling.md](02-error-handling.md) |
| 类型安全 | 所有函数签名必须有类型标注，用 mypy 检查 | [03-type-hints.md](03-type-hints.md) |
| 测试规范 | pytest 框架，mock 外部依赖，覆盖率 ≥80% | [04-testing.md](04-testing.md) |
| 日志打印 | 用 logging 模块，DEBUG/INFO/WARNING/ERROR 分级，禁止 print | [05-logging.md](05-logging.md) |
| 基础规范 | 函数≤80行，圈复杂度≤10，遵循 PEP 8，用 ruff/black 格式化 | [06-basic-rules.md](06-basic-rules.md) |
| 安全编码 | SQL 参数化、XSS 防护（Bleach）、bcrypt 存密码、禁止硬编码密钥、FastAPI Depends 认证 | [07-security.md](07-security.md) |
| 数据库访问 | N+1 预防（selectinload）、分页必须、连接池配置、Alembic 迁移 | [08-database-access.md](08-database-access.md) |
| 并发编程 | async/await 非阻塞、asyncio.gather 并行、GIL 约束（CPU 用多进程） | [09-concurrency.md](09-concurrency.md) |
| 事务处理 | SQLAlchemy session.begin()、Django transaction.atomic()、行级锁 | [10-transaction.md](10-transaction.md) |

### 共享跨栈规范（后端通用）

| 规范 | 核心规则（一句话） | 详情文件 |
|------|-------------------|---------|
| REST API 设计 | URL 名词复数、HTTP method 语义、统一 `{code,message,data}` 响应、分页必须 | [../rest-api-design.md](../rest-api-design.md) |
| 配置管理 | 配置与代码分离、敏感配置禁止提交 Git、环境变量命名规范 | [../configuration-management.md](../configuration-management.md) |
| 缓存策略 | Cache-Aside 模式、穿透/击穿/雪崩防护、TTL 随机偏移 | [../cache-strategy.md](../cache-strategy.md) |
| 幂等性设计 | 支付/订单/MQ 消费必须幂等、Idempotency-Key | [../idempotency-design.md](../idempotency-design.md) |

## 按场景选择深入阅读

| 场景 | 必读规范 |
|------|---------|
| 新增 API 接口（FastAPI/Flask/Django） | 01-project-structure + 02-error-handling + 03-type-hints + [REST API](../rest-api-design.md) |
| 数据库读写操作（SQLAlchemy/Django ORM） | 08-database-access + 10-transaction + 09-concurrency |
| 重构现有代码 | 06-basic-rules + 03-type-hints |
| 修复 Bug | 02-error-handling + 04-testing + 05-logging |
| 涉及外部系统调用 | 02-error-handling + 09-concurrency + 05-logging |
| 安全敏感功能 | 07-security + 03-type-hints |
| 编写测试 | pytest 框架、mock 策略、Given/When/Then 结构、覆盖要求 |
| 支付/订单/消息队列 | 01-project-structure + 07-security + [幂等性](../idempotency-design.md) |
| 通用编码 | 本文件已覆盖 80% 约束，按需深入。<br>必读：06-basic-rules + 07-security + [配置管理](../configuration-management.md) |
