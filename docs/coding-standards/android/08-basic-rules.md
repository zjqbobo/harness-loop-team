# Android/Kotlin 基础编码规范

## 代码行数限制 🔴

| 元素 | 最大行数 | 超出处理 |
|------|---------|---------|
| 函数 | 80 行 | 提取私有函数 |
| Composable | 150 行 | 拆分子组件 |
| Lambda | 15 行 | 提取为命名函数 |

> 类和文件不设行数上限，以职责单一、可快速理解为原则。

## 圈复杂度 🔴

- 单个函数圈复杂度 ≤ 10
- 用 ktlint / detekt 检查

```kotlin
// ✅ 卫语句：提前 return
fun processOrder(order: Order?): Result {
    if (order == null) return Result.fail("订单不存在")
    if (order.isPaid) return Result.fail("订单已支付")
    if (order.amount <= 0) return Result.fail("金额无效")
    return executeOrder(order)
}

// ❌ 深层嵌套
fun processOrder(order: Order?): Result {
    if (order != null) {
        if (!order.isPaid) {
            if (order.amount > 0) { ... }
        }
    }
}
```

## 命名规范 🔴

| 元素 | 规则 | 示例 |
|------|------|------|
| 类/接口/对象 | `PascalCase` | `TaskRepository`、`TaskApi` |
| 函数/变量 | `camelCase` | `createOrder()`、`userId` |
| 常量 | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT = 3` |
| Composable | `PascalCase`（名词/形容词） | `TaskCard`、`TaskList` |
| Composable 回调 | `on` + 动作 | `onTaskClick`、`onDelete` |
| 扩展函数 | `camelCase` | `fun String.isValidEmail(): Boolean` |
| 测试 | 反引号自然语言 | `` fun `getTasks emits cached then remote data`() `` |

## 魔法值 🔴

```kotlin
// ❌ 魔法值
if (status == 3) { ... }

// ✅ 枚举
enum class OrderStatus { Pending, Paid, Shipped, Completed }

// ✅ 常量
private const val MAX_RETRY = 3
private val TIMEOUT = 30.seconds  // kotlin.time
```

## Kotlin 惯用法 🟡

```kotlin
// ✅ ?. 安全调用 / ?: Elvis
val name = user?.name ?: "未知"

// ✅ scope functions 语义清晰
val result = order?.let { process(it) } ?: defaultResult  // let: 非 null 时执行
val user = User().apply { name = "Alice"; email = "a@b.com" }  // apply: 初始化
val dto = user.also { Timber.d("处理用户 %s", it.id) }  // also: 副作用

// ✅ when 表达式（替代 if-else if）
val statusText = when (status) {
    OrderStatus.Pending -> "待处理"
    OrderStatus.Paid -> "已支付"
    OrderStatus.Shipped -> "已发货"
    OrderStatus.Completed -> "已完成"
}

// ✅ data class 替代 POJO
data class User(val id: String, val name: String, val email: String)

// ✅ 扩展函数简化工具方法
fun String.isValidEmail(): Boolean = Patterns.EMAIL_ADDRESS.matcher(this).matches()
```

## 代码格式化 🔴

```kotlin
// ktlint + ktfmt 自动格式化
// .editorconfig
[*.kt]
indent_size = 4
max_line_length = 120
```

- **格式化全自动**：ktlint / ktfmt
- **禁止手动调整格式**

## KDoc 文档注释 🟡

- 公共 API（public 类/函数/属性）必须写 KDoc
- 私有函数可由命名自解释

```kotlin
/**
 * 创建订单并触发支付流程。
 *
 * 该方法在事务中执行：校验库存 → 创建订单 → 支付预授权。
 *
 * @param request 创建订单请求，[amount] 必须为正数
 * @param userId  下单用户 ID
 * @return 创建的订单实体（含支付状态）
 * @throws InsufficientStockException 库存不足时抛出
 * @throws PaymentException           支付预授权失败时抛出
 */
@Transactional
suspend fun createOrder(request: CreateOrderRequest, userId: Long): Order {
    ...
}
```

## 注释规范 🔵

- 代码应自解释，好的命名 > 注释
- 只在以下情况加注释：
  - **WHY**：解释为什么这样做（非显而易见的业务逻辑、算法选择）
  - **WORKAROUND**：临时方案，标注问题编号和预期解决时间
  - **CONCURRENCY**：协程/线程安全/Dispatchers 相关的非显而易见行为
- 禁止：
  - 无价值注释（`// set name`、`// increment counter`）
  - 注释掉的代码（用 git 管理历史）
  - 用注释解释魔法值（用枚举/常量替代）

```kotlin
// ✅ WHY — 解释非显而易见的决策
// 使用 StateFlow 而非 LiveData：需要在 collect 前获取当前值，
// 且不依赖 Android Lifecycle，便于单元测试
private val _uiState = MutableStateFlow(UiState())

// ✅ WORKAROUND — 标注临时方案
// WORKAROUND(issue-421): Compose 1.6 的 LazyColumn 在快速滚动时
// 偶发 index out of bounds，手动加 key 稳定重组。升级 1.7 后移除。
LazyColumn {
    items(items, key = { it.id }) { item -> ItemCard(item) }
}

// ❌ 无价值注释
val name = user.name // get user name

// ❌ 注释掉的代码
// val users = repository.findAll()
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `!!` 非空断言 | 运行时 NPE | `?.` / `?:` / `requireNotNull` |
| `as T` 不安全 cast | ClassCastException | `as? T` |
| `var` 可改变量优先于 `val` | 可变状态增加 bug | 默认 `val` |
| 函数超 80 行 | 难测试 | 提取函数 |
| 魔法值 | 语义不明 | 枚举 / const |
| 在 Composable 中 `!!` | NPE 导致 crash | 可空处理 |
