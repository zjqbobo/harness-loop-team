# Java/Spring 编码规范速查索引

> AI 编码前必须先读本文件。以下为摘要，完整规则见各子文件。

## 规范速查表

| 规范 | 核心规则（一句话） | 详情文件 |
|------|-------------------|---------|
| 工程分层 | Controller→Service→DAO，禁止跨层调用；每层职责单一 | [01-layering.md](01-layering.md) |
| 异常处理 | 业务异常抛 BizException，框架异常不吞；全局兜底用 @RestControllerAdvice | [02-exception-handling.md](02-exception-handling.md) |
| 事务处理 | @Transactional 只在 Service 层，只读方法加 readOnly；禁止嵌套事务 | [03-transaction.md](03-transaction.md) |
| 入参校验 | Controller 入参用 JSR303 注解，Service 入参用 Assert/手动校验 | [04-input-validation.md](04-input-validation.md) |
| 日志打印 | 入参用 DEBUG，业务关键节点用 INFO，异常用 ERROR 带堆栈；禁止 System.out | [05-logging.md](05-logging.md) |
| 基础规范 | 方法≤80行，圈复杂度≤10，魔法值必须常量化 | [06-basic-rules.md](06-basic-rules.md) |
| 安全编码 | SQL 参数化、XSS 防护、敏感信息脱敏、禁止硬编码密钥、JWT 安全 | [07-security.md](07-security.md) |
| 数据库访问 | N+1 预防、分页必须、连接池配置、Flyway 迁移 | [08-database-access.md](08-database-access.md) |
| 并发编程 | @Async 配置线程池、CompletableFuture 超时、ThreadLocal 清理、分布式锁 | [09-concurrency.md](09-concurrency.md) |
| 测试规范 | JUnit 5 + Mockito + AssertJ、Given/When/Then、mock 策略、覆盖率 ≥80% statement + 70% branch | [10-testing.md](10-testing.md) |

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
| 新增 REST 接口 | 01-layering + 04-input-validation + 02-exception-handling + [REST API](../rest-api-design.md) |
| 数据库读写操作 | 01-layering + 03-transaction + 08-database-access + 05-logging |
| 重构现有代码 | 06-basic-rules + 01-layering |
| 修复 Bug | 02-exception-handling + 05-logging |
| 涉及外部系统调用 | 02-exception-handling + 09-concurrency + 05-logging |
| 安全敏感功能 | 07-security + 04-input-validation |
| 编写测试 | [10-testing.md](10-testing.md) |
| 支付/订单/消息队列 | 01-layering + 03-transaction + 07-security + [幂等性](../idempotency-design.md) |
| 通用编码 | 本文件已覆盖 80% 约束，按需深入。<br>必读：06-basic-rules + 07-security + [配置管理](../configuration-management.md) |
