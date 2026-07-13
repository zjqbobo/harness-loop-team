# Go 编码规范速查索引

> AI 编码前必须先读本文件。以下为摘要，完整规则见各子文件。

## 规范速查表

| 规范 | 核心规则（一句话） | 详情文件 |
|------|-------------------|---------|
| 工程分层 | cmd/ 放入口，internal/ 放私有包，pkg/ 放可复用库 | [01-project-structure.md](01-project-structure.md) |
| 异常处理 | 错误必须处理不忽略，用 fmt.Errorf 包装上下文，不裸抛 error | [02-error-handling.md](02-error-handling.md) |
| 并发编程 | goroutine 用 context 控制生命周期，channel 明确方向，用 sync 包保护共享状态 | [03-concurrency.md](03-concurrency.md) |
| 测试规范 | 用 testing 标准库 + testify，mock 用接口，覆盖率 ≥80% | [04-testing.md](04-testing.md) |
| 日志打印 | 用 slog/logrus，结构化日志，禁止 fmt.Println | [05-logging.md](05-logging.md) |
| 基础规范 | 函数≤80行，圈复杂度≤10，用 gofmt/goimports 格式化，golangci-lint 检查 | [06-basic-rules.md](06-basic-rules.md) |
| 安全编码 | SQL 参数化、XSS 防护、bcrypt 存密码、禁止硬编码密钥、JWT 中间件 | [07-security.md](07-security.md) |
| 数据库访问 | N+1 预防、分页必须、连接池配置、golang-migrate 迁移 | [08-database-access.md](08-database-access.md) |
| 事务处理 | database/sql Tx、Repository WithTx 接口、事务边界 | [09-transaction.md](09-transaction.md) |

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
| 新增 HTTP/gRPC 接口 | 01-project-structure + 02-error-handling + 05-logging + [REST API](../rest-api-design.md) |
| 数据库读写操作 | 01-project-structure + 08-database-access + 09-transaction + 02-error-handling |
| 并发/后台任务 | 03-concurrency + 02-error-handling |
| 重构现有代码 | 06-basic-rules + 01-project-structure |
| 修复 Bug | 02-error-handling + 05-logging |
| 涉及外部系统调用 | 02-error-handling + 05-logging |
| 安全敏感功能 | 07-security |
| 编写测试 | testing 标准库 + testify、mock 接口、Given/When/Then 结构、覆盖要求 |
| 支付/订单/消息队列 | 01-project-structure + 07-security + [幂等性](../idempotency-design.md) |
| 通用编码 | 本文件已覆盖 80% 约束，按需深入。<br>必读：06-basic-rules + 07-security + [配置管理](../configuration-management.md) |
