# .NET/C# 基础编码规范

## 代码行数限制 🔴

| 元素 | 最大行数 | 超出处理 |
|------|---------|---------|
| 方法 | 80 行 | 提取私有方法 |

> 类和文件不设行数上限，以职责单一、可快速理解为原则。

## 圈复杂度 🔴

- 单个方法圈复杂度 ≤ 10
- 超过 10 → 用策略模式、卫语句、提取方法降低

```csharp
// ✅ 卫语句：提前 return
public Result ProcessOrder(Order? order)
{
    if (order is null) return Result.Fail("订单不存在");
    if (order.IsPaid) return Result.Fail("订单已支付");
    if (order.Amount <= 0) return Result.Fail("金额无效");

    // 主逻辑（无嵌套）
    return ExecuteOrder(order);
}

// ❌ 深层嵌套
public Result ProcessOrder(Order? order)
{
    if (order is not null)
    {
        if (!order.IsPaid)
        {
            if (order.Amount > 0)
            {
                return ExecuteOrder(order);
            }
        }
    }
}
```

## 命名规范 🔴

| 元素 | 规则 | 示例 |
|------|------|------|
| 公共类型/方法/属性 | `PascalCase` | `OrderService`、`GetByIdAsync` |
| 接口 | `I` 前缀 + `PascalCase` | `IOrderService`、`IRepository<T>` |
| 私有字段 | `_camelCase` | `_repository`、`_logger` |
| 局部变量/参数 | `camelCase` | `orderId`、`cancellationToken` |
| 常量 | `PascalCase` | `MaxRetryCount = 3` |
| 异步方法 | `Async` 后缀 | `GetByIdAsync`、`CreateOrderAsync` |
| 布尔变量/属性 | `Is`/`Has`/`Can` 前缀 | `IsPaid`、`HasPermission` |

### 方法命名 🟡

| 操作 | 前缀 | 示例 |
|------|------|------|
| 查询 | `Get` / `Find` / `Query` | `GetById`、`FindByName`、`QueryPage` |
| 判断 | `Is` / `Has` / `Can` | `IsValid`、`HasStock` |
| 操作 | `Create` / `Update` / `Delete` | `CreateOrder`、`UpdateStatus` |
| 转换 | `To` / `Map` / `Convert` | `ToDto`、`MapToEntity` |
| 异步 | `Async` 后缀 | `CreateOrderAsync` |

## 魔法值 🔴

```csharp
// ❌ 魔法值
if (status == 3) { ... }

// ✅ 枚举
public enum OrderStatus
{
    Pending = 0,
    Paid = 1,
    Shipped = 2,
    Completed = 3
}

if (status == OrderStatus.Completed) { ... }

// ✅ 常量
public static class Constants
{
    public const int MaxRetryCount = 3;
    public static readonly TimeSpan DefaultTimeout = TimeSpan.FromSeconds(30);
}
```

## Null 检查 🔴

```csharp
// ✅ C# 可空引用类型（NRT）
public class OrderService
{
    private readonly IOrderRepository _repository;

    public OrderService(IOrderRepository repository)
    {
        _repository = repository ?? throw new ArgumentNullException(nameof(repository));
    }

    public async Task<User?> FindUserAsync(int id)  // 返回值可空
    {
        ArgumentNullException.ThrowIfNull(id);
        return await _repository.FindByIdAsync(id);
    }
}

// ✅ 模式匹配处理 null
if (user is not null)
{
    Console.WriteLine(user.Name);
}

// ❌ 返回 null 代替空集合
public List<Order> GetOrders()
{
    var orders = _repository.FindAll();
    return orders.Any() ? orders : null;  // 调用方被迫 null 检查
}

// ✅ 返回空集合
public List<Order> GetOrders()
{
    var orders = _repository.FindAll();
    return orders;
}
```

## 代码格式化 🔴

```xml
<!-- .editorconfig -->
[*.cs]
indent_style = space
indent_size = 4
charset = utf-8-bom
trim_trailing_whitespace = true
insert_final_newline = true

dotnet_style_prefer_is_null_check_over_reference_equality_method = true
csharp_style_pattern_matching_over_as_with_null_check = true
dotnet_style_coalesce_expression = true
csharp_prefer_simple_using_statement = true
```

- **格式化全自动**：`.editorconfig` + `dotnet format`
- **禁止手动调整格式**

## 模式匹配 🟡

```csharp
// ✅ is 模式匹配
if (obj is string { Length: > 0 } s)
{
    Console.WriteLine(s);
}

// ✅ switch 表达式（C# 8+）
string GetStatusText(OrderStatus status) => status switch
{
    OrderStatus.Pending => "待处理",
    OrderStatus.Paid => "已支付",
    OrderStatus.Shipped => "已发货",
    OrderStatus.Completed => "已完成",
    _ => throw new ArgumentOutOfRangeException(nameof(status))
};

// ✅ 属性模式
if (order is { IsPaid: true, Amount: > 1000 }) { ... }
```

## XML 文档注释 🟡

```csharp
/// <summary>
/// 创建订单并触发支付流程。
/// </summary>
/// <param name="request">创建订单请求。</param>
/// <param name="ct">取消令牌。</param>
/// <returns>创建的订单实体。</returns>
/// <exception cref="ValidationException">金额无效时抛出。</exception>
/// <exception cref="NotFoundException">用户不存在时抛出。</exception>
public async Task<Order> CreateOrderAsync(CreateOrderRequest request, CancellationToken ct)
{
    ...
}
```

- 公共 API 必须写 XML 文档注释
- 私有方法可由命名自解释

## 注释规范 🔵

- 代码应自解释，好的命名 > 注释
- 只在以下情况加注释：
  - **WHY**：解释为什么这样做（非显而易见的业务逻辑、算法选择）
  - **WORKAROUND**：临时方案，标注问题编号和预期解决时间
  - **CONCURRENCY**：async/await/线程安全相关的非显而易见行为
- 禁止：
  - 无价值注释（`// set name`、`// increment counter`）
  - 注释掉的代码（用 git 管理历史）
  - 用注释解释魔法值（用枚举/常量替代）

```csharp
// ✅ WHY — 解释非显而易见的决策
// 使用 ConcurrentDictionary 而非 Dictionary + lock：
// 热点路径高并发读写，无锁 CAS 比粗粒度锁性能高 3-5x
private readonly ConcurrentDictionary<int, User> _cache = new();

// ✅ WORKAROUND — 标注临时方案
// WORKAROUND(issue-421): EF Core 9.0 的 SplitQuery 在 SQL Server 2019 下偶发
// 查询计划 cache 错乱。升级至 EF Core 9.1 后移除 AsSplitQuery 回退。
var orders = await context.Orders
    .AsSplitQuery()
    .ToListAsync(ct);

// ❌ 无价值注释
var name = user.Name; // get user name

// ❌ 注释掉的代码
// var users = await repo.FindAllAsync();
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| 方法超 80 行 | 难测试、难理解 | 提取私有方法 |
| 魔法值 | 语义不明 | 枚举 / const |
| 返回 `null` 代替空集合 | 调用方被迫 null 检查 | 返回 `Enumerable.Empty<T>()` |
| `if (x == null)` | 不是惯用法 | `if (x is null)` |
| 未启用 nullable reference types | null 安全缺失 | `<Nullable>enable</Nullable>` |
| `public` 字段 | 破坏封装 | 属性 `{ get; set; }` |
| 复杂三元表达式嵌套 | 可读性差 | if/else 或 switch 表达式 |
