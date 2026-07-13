# iOS/Swift 编码规范速查索引

> AI 编码前必须先读本文件。以下为摘要，完整规则见各子文件。

## 规范速查表

| 规范 | 核心规则（一句话） | 详情文件 |
|------|-------------------|---------|
| 工程分层 | 按 feature 分组，MVVM/Clean Architecture 分层，Domain/Data/Presentation 三层 | [01-project-structure.md](01-project-structure.md) |
| 异常处理 | 用 Result 类型或 throws 传递错误，自定义 Error enum，禁止 try! 和 try? 吞错 | [02-error-handling.md](02-error-handling.md) |
| 并发编程 | async/await + Task 管理异步，@MainActor 标注 UI 代码，Actor 保护共享状态，Sendable 协议 | [03-concurrency.md](03-concurrency.md) |
| 依赖注入 | 构造函数注入（推荐），@Environment/@EnvironmentObject（SwiftUI），禁止全局单例容器 | [04-dependency-injection.md](04-dependency-injection.md) |
| UI 规范 | SwiftUI（推荐）声明式 UI，View 可组合，@State/@Binding/@Observable 状态管理，Preview 覆盖多状态/暗黑模式 | [05-ui-standards.md](05-ui-standards.md) |
| 数据库访问 | SwiftData（推荐 iOS 17+）/ Core Data / GRDB，@ModelActor 线程隔离，Migration 版本管理 | [06-data-persistence.md](06-data-persistence.md) |
| 测试规范 | XCTest + Swift Testing（推荐），XCTAssert 断言，用协议 Mock 依赖，覆盖率 ≥80%，XCUITest 做 UI 测试 | [07-testing.md](07-testing.md) |
| 日志打印 | os.Logger（推荐 iOS 14+），分级日志，用 OSLogStore 检索，敏感信息脱敏，禁止 print | [08-logging.md](08-logging.md) |
| 基础规范 | 函数≤80行，圈复杂度≤10，命名：PascalCase 类型/协议，camelCase 变量/函数，SwiftFormat + SwiftLint 格式化 | [09-basic-rules.md](09-basic-rules.md) |
| 安全编码 | Keychain 存 Token、HTTPS 强制、证书固定、os.Logger 脱敏、Biometric 保护 | [10-security.md](10-security.md) |

## 按场景选择深入阅读

| 场景 | 必读规范 |
|------|---------|
| 新增页面/功能模块 | 01-project-structure + 05-ui-standards + 03-concurrency |
| 新增网络接口（URLSession/Alamofire） | 01-project-structure + 02-error-handling + 03-concurrency |
| 数据持久化（SwiftData/Core Data） | 06-data-persistence + 03-concurrency + 02-error-handling |
| 后台任务/推送 | 03-concurrency + 02-error-handling |
| 重构现有代码 | 09-basic-rules + 01-project-structure |
| 修复 Bug | 02-error-handling + 08-logging + 07-testing |
| 涉及外部 SDK 集成 | 04-dependency-injection + 02-error-handling + 08-logging |
| 安全敏感功能（登录/支付/隐私） | 10-security + 06-data-persistence |
| 编写测试 | XCTest + Swift Testing、协议 Mock、覆盖要求、XCUITest |
| 通用编码 | 本文件已覆盖 80% 约束，按需深入 |
