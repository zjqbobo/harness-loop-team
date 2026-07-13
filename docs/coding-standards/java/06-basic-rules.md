# 基础编码规范

## 代码行数限制 🔴

| 元素 | 最大行数 | 超出处理 |
|------|---------|---------|
| 方法 | 80 行 | 拆分为多个私有方法 |
| 匿名 Lambda | 20 行 | 提取为命名方法 |

> 类和文件不设行数上限，以职责单一、可快速理解为原则。

## 圈复杂度 🔴

- 单个方法圈复杂度 ≤ 10
- 超过 10 → 用策略模式、卫语句、提取方法降低
- 卫语句优先：提前 return 减少嵌套

```java
// ✅ 卫语句：提前返回
public Result<?> process(Order order) {
    if (order == null) {
        return Result.fail("订单不存在");
    }
    if (order.isPaid()) {
        return Result.fail("订单已支付");
    }
    // 主逻辑（无嵌套）
    doProcess(order);
    return Result.ok();
}

// ❌ 嵌套 if
public Result<?> process(Order order) {
    if (order != null) {
        if (!order.isPaid()) {
            doProcess(order);
            return Result.ok();
        } else {
            return Result.fail("订单已支付");
        }
    } else {
        return Result.fail("订单不存在");
    }
}
```

## 魔法值 🔴

禁止代码中出现未解释的字面量：

```java
// ❌ 魔法值
if (status == 3) { ... }
if (type.equals("VIP")) { ... }

// ✅ 常量或枚举
if (status == OrderStatus.COMPLETED) { ... }
if (type == UserType.VIP) { ... }
```

- 简单状态用枚举
- 配置性数值用常量类：`public static final int MAX_RETRY = 3;`
- 禁止用注释解释魔法值（`if (status == 3) // 3=已完成`），必须用枚举

## 命名规范 🟡

### 通用规则

- 类名：UpperCamelCase（`OrderService`）
- 方法名/变量名：lowerCamelCase（`createOrder`、`userId`）
- 常量：UPPER_SNAKE_CASE（`MAX_RETRY_COUNT`）
- 包名：全小写（`com.company.project.service`）
- 布尔变量/方法：`is`/`has`/`can` 前缀（`isPaid`、`hasPermission`）

### 方法命名

| 操作 | 前缀 | 示例 |
|------|------|------|
| 查询 | `get`/`find`/`query` | `getById`、`findByStatus`、`queryPage` |
| 判断 | `is`/`has`/`can`/`should` | `isValid`、`hasStock` |
| 操作 | `create`/`update`/`delete` | `createOrder`、`updateStatus` |
| 转换 | `to`/`convert`/`transform` | `toDTO`、`convertToVO` |
| 计算 | `calculate`/`compute` | `calculateTotal` |

## 方法设计 🟡

- 一个方法只做一件事
- 参数不超过 5 个，超过则封装为对象
- 返回值类型明确，禁止返回 `Object` / `Map<String, Object>`
- 避免输出参数（通过参数返回结果）

## 集合处理 🟡

```java
// ✅ 空集合代替 null
public List<OrderDTO> getOrders(Long userId) {
    List<Order> orders = orderMapper.findByUserId(userId);
    return orders.isEmpty() ? Collections.emptyList() : convert(orders);
}

// ❌ 返回 null
public List<OrderDTO> getOrders(Long userId) {
    List<Order> orders = orderMapper.findByUserId(userId);
    return orders.isEmpty() ? null : convert(orders);
}
```

- 方法返回集合时，空返回 `Collections.emptyList()`，不返回 null
- 遍历前不需要 null 检查（因为不会返回 null）

## Javadoc 文档注释 🟡

- 公共 API（public 类/接口/方法）必须写 Javadoc
- 私有方法可由命名自解释

```java
/**
 * 创建订单并触发支付流程。
 *
 * <p>该方法在事务中执行以下步骤：
 * <ol>
 *   <li>校验库存是否充足</li>
 *   <li>创建订单记录</li>
 *   <li>调用支付网关预授权</li>
 * </ol>
 *
 * @param request 创建订单请求，amount 必须为正数
 * @param userId  下单用户 ID
 * @return 创建的订单实体（含支付状态）
 * @throws InsufficientStockException 库存不足时抛出
 * @throws PaymentException          支付预授权失败时抛出
 */
@Transactional
public Order createOrder(CreateOrderRequest request, Long userId) {
    ...
}
```

## 注释规范 🔵

- 代码应自解释，好的命名 > 注释
- 只在以下情况加注释：
  - **WHY**：解释为什么这样做（非显而易见的业务逻辑、算法选择）
  - **WORKAROUND**：临时方案，标注问题编号和预期解决时间
  - **CONCURRENCY**：并发/线程安全相关说明
- 禁止：无价值注释（`// set name`）、注释掉的代码（用 git 管理）、用注释解释魔法值

```java
// ✅ WHY — 解释非显而易见的决策
// 使用 ConcurrentHashMap 而非 HashMap + synchronized：
// 热点路径读多写少，分段锁比全局锁吞吐高 3-5x
private final ConcurrentHashMap<Long, User> cache = new ConcurrentHashMap<>();

// ✅ WORKAROUND — 标注临时方案
// WORKAROUND(issue-421): Spring Boot 3.2 的 @Async 在线程池满时
// 静默丢弃任务，手动捕获 RejectedExecutionException 告警。
// 升级 Spring Boot 3.3 后移除。
try {
    asyncService.send(event);
} catch (RejectedExecutionException e) {
    alertService.alert("async queue full", e);
}

// ❌ 无价值注释
String name = user.getName(); // get user name

// ❌ 注释掉的代码
// List<User> users = repository.findAll();
```
