# Android/Kotlin 编码规范速查索引

> AI 编码前必须先读本文件。以下为摘要，完整规则见各子文件。

## 规范速查表

| 规范 | 核心规则（一句话） | 详情文件 |
|------|-------------------|---------|
| 工程分层 | 按 feature 分包，MVVM/MVI 分层，data/domain/presentation 三层架构 | [01-project-structure.md](01-project-structure.md) |
| 异常处理 | 用 sealed class 建模错误，Result 类型替代 try/catch，ViewModel 用 Channel 发送 one-shot 事件 | [02-error-handling.md](02-error-handling.md) |
| 并发编程 | viewModelScope/lifecycleScope 管理生命周期，Dispatchers 按场景选择，Flow 替代 LiveData（数据流场景） | [03-coroutines.md](03-coroutines.md) |
| 依赖注入 | Hilt（推荐）构造函数注入，Singleton/ViewModelScoped/ActivityScoped 生命周期绑定，禁止 Service Locator | [04-dependency-injection.md](04-dependency-injection.md) |
| UI 规范 | Jetpack Compose（推荐），可组合函数单一职责，State hoisting，Preview 覆盖多状态 | [05-ui-standards.md](05-ui-standards.md) |
| 测试规范 | JUnit5 + MockK + Turbine（Flow 测试），单测覆盖率 ≥80%，Compose UI 用 Compose Testing | [06-testing.md](06-testing.md) |
| 日志打印 | Timber（Debug 输出/Release 静默），分级 TAG，敏感信息脱敏，禁止 Log.x 直接使用 | [07-logging.md](07-logging.md) |
| 基础规范 | 函数≤80行，圈复杂度≤10，命名：PascalCase 类/Composable，camelCase 变量/函数，ktlint 格式化 | [08-basic-rules.md](08-basic-rules.md) |
| 安全编码 | EncryptedSharedPreferences 存 Token、HTTPS 强制、ProGuard 混淆、权限最小化 | [09-security.md](09-security.md) |

## 按场景选择深入阅读

| 场景 | 必读规范 |
|------|---------|
| 新增页面/功能模块 | 01-project-structure + 05-ui-standards + 03-coroutines |
| 新增网络接口（Retrofit/Ktor） | 01-project-structure + 02-error-handling + 03-coroutines |
| 数据库读写（Room） | 01-project-structure + 03-coroutines + 02-error-handling |
| 后台任务/WorkManager | 03-coroutines + 04-dependency-injection |
| 重构现有代码 | 08-basic-rules + 01-project-structure |
| 修复 Bug | 02-error-handling + 07-logging + 06-testing |
| 涉及外部 SDK 集成 | 04-dependency-injection + 02-error-handling + 07-logging |
| 安全敏感功能（登录/支付/隐私） | 09-security |
| 编写测试 | JUnit5 + MockK + Turbine、mock 策略、覆盖要求、Compose Testing |
| 通用编码 | 本文件已覆盖 80% 约束，按需深入 |
