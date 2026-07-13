# .NET/C# 编码规范速查索引

> AI 编码前必须先读本文件。以下为摘要，完整规则见各子文件。

## 规范速查表

| 规范 | 核心规则（一句话） | 详情文件 |
|------|-------------------|---------|
| 工程分层 | 按 Solution→Project 组织，遵循 Clean Architecture 分层（Domain/Application/Infrastructure/Presentation） | [01-project-structure.md](01-project-structure.md) |
| 异常处理 | 业务异常抛自定义 Exception，全局兜底用 ExceptionFilter/Middleware，不吞异常 | [02-exception-handling.md](02-exception-handling.md) |
| 并发编程 | I/O 操作用 async/await 到底，禁止 async void（除事件），用 ConfigureAwait(false) 在库代码 | [03-async-patterns.md](03-async-patterns.md) |
| 依赖注入 | 通过构造函数注入，按生命周期注册（Transient/Scoped/Singleton），不 new 具体类 | [04-dependency-injection.md](04-dependency-injection.md) |
| 测试规范 | xUnit/NUnit + Moq/NSubstitute，mock 外部依赖，覆盖率 ≥80% | [05-testing.md](05-testing.md) |
| 日志打印 | 用 ILogger 结构化日志，分级输出，禁止 Console.WriteLine 留在生产代码 | [06-logging.md](06-logging.md) |
| 基础规范 | 方法≤80行，圈复杂度≤10，用 .editorconfig + StyleCop 统一风格，命名：PascalCase 公共成员/camelCase 私有 | [07-basic-rules.md](07-basic-rules.md) |
| 安全编码 | SQL 参数化、XSS 防护（HtmlSanitizer）、禁止硬编码密钥、JWT Policy 授权 | [08-security.md](08-security.md) |
| 数据库访问 | N+1 预防（Include/ThenInclude）、分页必须、连接池配置、EF Core Migrations | [09-database-access.md](09-database-access.md) |
| 事务处理 | EF Core SaveChanges 事务、BeginTransactionAsync 跨多次提交、乐观并发 RowVersion | [10-transaction.md](10-transaction.md) |

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
| 新增 Web API（ASP.NET Core） | 01-project-structure + 02-exception-handling + 04-dependency-injection + [REST API](../rest-api-design.md) |
| 新增 Minimal API / gRPC | 01-project-structure + 02-exception-handling + 03-async-patterns |
| 数据库读写操作（EF Core/Dapper） | 09-database-access + 10-transaction + 03-async-patterns + 04-dependency-injection |
| 后台任务/消息队列 | 03-async-patterns + 04-dependency-injection + 02-exception-handling |
| 重构现有代码 | 07-basic-rules + 01-project-structure |
| 修复 Bug | 02-exception-handling + 05-testing + 06-logging |
| 涉及外部系统调用（HttpClient） | 03-async-patterns + 02-exception-handling + 06-logging |
| 安全敏感功能 | 08-security |
| 编写测试 | xUnit/NUnit + Moq、mock 策略、Given/When/Then 结构、覆盖要求 |
| 支付/订单/消息队列 | 01-project-structure + 08-security + [幂等性](../idempotency-design.md) |
| 通用编码 | 本文件已覆盖 80% 约束，按需深入。<br>必读：07-basic-rules + 08-security + [配置管理](../configuration-management.md) |
