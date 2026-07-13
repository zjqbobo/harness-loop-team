# iOS/Swift 基础编码规范

## 代码行数限制 🔴

| 元素 | 最大行数 | 超出处理 |
|------|---------|---------|
| 函数 | 80 行 | 提取私有函数 |
| View body | 简化为宜 | 拆分子 View |

> 类和文件不设行数上限，以职责单一、可快速理解为原则。

## 圈复杂度 🔴

- 单个函数圈复杂度 ≤ 10
- 检测：SwiftLint `cyclomatic_complexity: 10`

```swift
// ✅ 卫语句：提前 return / throw
func processOrder(_ order: Order?) throws -> OrderResult {
    guard let order else { throw AppError.notFound("订单不存在") }
    guard !order.isPaid else { throw AppError.validation("订单已支付") }
    guard order.amount > 0 else { throw AppError.validation("金额无效") }
    return try executeOrder(order)
}

// ❌ 深层嵌套
func processOrder(_ order: Order?) throws -> OrderResult {
    if let order {
        if !order.isPaid {
            if order.amount > 0 {
                return try executeOrder(order)
            }
        }
    }
}
```

## 命名规范 🔴

| 元素 | 规则 | 示例 |
|------|------|------|
| 类型/协议 | `PascalCase` | `TaskRepository`、`Identifiable` |
| 变量/函数 | `camelCase` | `fetchTasks()`、`userId` |
| 常量 | `camelCase` | `let maxRetryCount = 3` |
| 协议 | 名词 `-able`/`-ible`/`-ing` | `Codable`、`Hashable` |
| 布尔 | `is`/`has`/`should` 前缀 | `isLoading`、`hasChanges` |
| View | `PascalCase` + `View` | `TaskListView` |

## 魔法值 🔴

```swift
// ❌ 魔法值
if status == 3 { ... }

// ✅ 枚举
enum OrderStatus: Int {
    case pending = 0
    case paid = 1
    case shipped = 2
    case completed = 3
}

// ✅ 常量
private enum Constants {
    static let maxRetry = 3
    static let defaultTimeout: TimeInterval = 30
}
```

## Swift 惯用法 🟡

```swift
// ✅ guard let 提前解包
guard let user = currentUser else { return }

// ✅ if let / if case 模式匹配
if case .loaded(let tasks) = state { ... }

// ✅ compactMap 过滤 nil
let validIds = items.compactMap(\.id)

// ✅ defer 清理
func processFile() throws {
    let file = try openFile()
    defer { file.close() }
    // 使用 file
}

// ✅ extension 组织协议实现
extension TaskListView: TaskDelegate { ... }
```

## 代码格式化 🔴

```swift
// SwiftFormat + SwiftLint
// .swiftformat
--indent 4
--maxwidth 120
--wraparguments before-first
```

- **格式化全自动**：SwiftFormat + SwiftLint autocorrect
- **禁止手动调整格式**

## DocC 文档注释 🟡

- 公共 API（public/open 的类型/方法/属性）必须写文档注释
- 使用 `///` 三斜线格式（兼容 Xcode DocC）
- 私有方法可由命名自解释

```swift
/// 创建订单并触发支付流程。
///
/// 该方法在事务中执行：校验库存 → 创建订单 → 支付预授权。
///
/// - Parameters:
///   - request: 创建订单请求，``amount`` 必须为正数
///   - userID:  下单用户 ID
/// - Returns: 创建的订单实体（含支付状态）
/// - Throws: ``InsufficientStockError`` 库存不足时抛出
/// - Throws: ``PaymentError`` 支付预授权失败时抛出
func createOrder(request: CreateOrderRequest, userID: Int64) async throws -> Order {
    ...
}
```

## 注释规范 🔵

- 代码应自解释，好的命名 > 注释
- 只在以下情况加注释：
  - **WHY**：解释为什么这样做（非显而易见的业务逻辑、算法选择）
  - **WORKAROUND**：临时方案，标注问题编号和预期解决时间
  - **CONCURRENCY**：actor/MainActor/Sendable/线程安全相关的非显而易见行为
- 禁止：
  - 无价值注释（`// set name`、`// increment counter`）
  - 注释掉的代码（用 git 管理历史）
  - 用注释解释魔法值（用枚举/常量替代）

```swift
// ✅ WHY — 解释非显而易见的决策
// 使用 actor 而非 class + serial queue：actor 由编译器保证数据隔离，
// 避免手动加锁引入死锁风险
actor ImageCache {
    private var cache: [URL: UIImage] = [:]
}

// ✅ WORKAROUND — 标注临时方案
// WORKAROUND(issue-421): iOS 19.0 的 NavigationStack 在深层 pop 时
// 偶发 path 不一致，手动用 enumerated() 稳定 diff。升级 19.1 后移除。
ForEach(Array(path.enumerated()), id: \.offset) { _, destination in
    ...
}

// ❌ 无价值注释
let name = user.name // get user name

// ❌ 注释掉的代码
// let users = try await repository.findAll()
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `!` 强制解包（`try!`/`as!`） | crash | `guard let` / `do/catch` / `as?` |
| `var` 默认优先于 `let` | 可变状态更多 bug | 默认 `let` |
| 隐式 `self` 在 closure 中（UIKit） | 循环引用 | `[weak self]` |
| 函数超 80 行 | 难测试 | 提取函数 |
| 魔法值 | 语义不明 | 枚举 / 常量 |
