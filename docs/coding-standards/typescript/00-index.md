# TypeScript/JavaScript 编码规范速查索引

> AI 编码前必须先读本文件。以下为摘要，完整规则见各子文件。

## 规范速查表

| 规范 | 核心规则（一句话） | 详情文件 |
|------|-------------------|---------|
| 工程分层 | src/ 放源码，按 feature 或 layer 组织，用 ES Module 导入 | [01-project-structure.md](01-project-structure.md) |
| 异常处理 | 异步操作用 try/catch，API 层统一错误格式，不吞异常 | [02-error-handling.md](02-error-handling.md) |
| 类型安全 | 禁止 any（用 unknown 替代），interface 优于 type 用于公共 API，strict 模式开启 | [03-type-safety.md](03-type-safety.md) |
| 测试规范 | Jest/Vitest，mock 外部模块，覆盖率 ≥80%（JS 项目忽略类型覆盖） | [04-testing.md](04-testing.md) |
| 日志打印 | 用结构化 logger（pino/winston），分级输出，禁止 console.log 留在生产代码 | [05-logging.md](05-logging.md) |
| 基础规范 | 函数≤80行，圈复杂度≤10，用 ESLint + Prettier 格式化，命名：camelCase 变量/PascalCase 类 | [06-basic-rules.md](06-basic-rules.md) |
| 安全编码 | SQL/NoSQL 参数化、XSS 防护（DOMPurify）、敏感信息脱敏、禁止硬编码密钥、JWT httpOnly Cookie | [07-security.md](07-security.md) |
| 数据库访问 | N+1 预防（include/relations）、分页必须、连接池配置、Prisma/Drizzle 迁移 | [08-database-access.md](08-database-access.md) |
| 并发编程 | 事件循环非阻塞、Promise.all 并行、Worker Threads、竞态防护（AbortController） | [09-concurrency.md](09-concurrency.md) |
| 事务处理 | Prisma/Drizzle 交互式事务、事务边界、禁止事务中调外部 API | [10-transaction.md](10-transaction.md) |

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
| 新增 API 路由（Express/Fastify/NestJS） | 01-project-structure + 02-error-handling + 03-type-safety + [REST API](../rest-api-design.md) |
| 新增前端页面/组件（React/Vue/Next.js） | 01-project-structure + 03-type-safety + 04-testing |
| 数据库读写操作（Prisma/Drizzle/TypeORM） | 08-database-access + 10-transaction + 02-error-handling |
| 重构现有代码 | 06-basic-rules + 03-type-safety |
| 修复 Bug | 02-error-handling + 05-logging |
| 涉及外部 API 调用 | 02-error-handling + 09-concurrency + 05-logging |
| 安全敏感功能 | 07-security |
| 编写测试 | Jest/Vitest 框架、mock 策略、Given/When/Then 结构、覆盖要求 |
| 支付/订单/消息队列 | 01-project-structure + 07-security + [幂等性](../idempotency-design.md) |
| 通用编码 | 本文件已覆盖 80% 约束，按需深入。<br>必读：06-basic-rules + 07-security + [配置管理](../configuration-management.md) |
