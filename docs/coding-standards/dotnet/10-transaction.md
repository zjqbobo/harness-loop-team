# .NET/C# 事务处理规范

## 基本原则 🔴

- 涉及多个 `SaveChangesAsync()` 调用或多表写入**必须**在事务中执行
- 事务边界在 Application 层 Service 中控制

## EF Core 事务 🔴

```csharp
// ✅ 默认事务（DbContext.SaveChangesAsync 自带事务）
public async Task<OrderDto> CreateOrderAsync(CreateOrderRequest request)
{
    var order = new Order { UserId = request.UserId, TotalAmount = request.TotalAmount };
    _context.Orders.Add(order);
    await _context.SaveChangesAsync();  // 单次 SaveChanges 已是原子操作
    return _mapper.Map<OrderDto>(order);
}

// ✅ 跨多次 SaveChanges 的显式事务
public async Task ProcessPaymentAsync(PaymentRequest request)
{
    using var transaction = await _context.Database.BeginTransactionAsync();
    try
    {
        // 1. 扣库存
        var product = await _context.Products
            .FirstOrDefaultAsync(p => p.Id == request.ProductId);
        if (product.Stock < request.Quantity)
            throw new InsufficientStockException();
        product.Stock -= request.Quantity;
        await _context.SaveChangesAsync();

        // 2. 创建订单
        var order = new Order { UserId = request.UserId, ... };
        _context.Orders.Add(order);
        await _context.SaveChangesAsync();

        // 3. 记录日志
        _context.OrderLogs.Add(new OrderLog { OrderId = order.Id, Action = "paid" });
        await _context.SaveChangesAsync();

        await transaction.CommitAsync();
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;
    }
}

// ✅ Dapper + DbTransaction
public async Task CreateOrderAsync(IDbConnection conn, CreateOrderRequest request)
{
    using var transaction = conn.BeginTransaction();
    try
    {
        await conn.ExecuteAsync("INSERT INTO Orders ...", request, transaction);
        await conn.ExecuteAsync("INSERT INTO OrderLogs ...", log, transaction);
        transaction.Commit();
    }
    catch
    {
        transaction.Rollback();
        throw;
    }
}
```

## 事务边界 🔴

```
✅ 推荐事务边界
┌─ Service 方法 ────────────────────┐
│  1. 参数校验（事务外）              │
│  2. BeginTransactionAsync()       │
│  3. 数据库操作                      │
│  4. CommitAsync()                  │
│  5. 发消息/调外部 API（事务外）       │
└───────────────────────────────────┘

❌ 错误：事务中调外部
┌─ Service 方法 ────────────────────┐
│  BeginTransactionAsync()          │
│  扣库存                            │
│  调用支付 API ← 不可回滚！          │
│  建订单                            │
│  CommitAsync()                    │
└───────────────────────────────────┘
```

- 事务中**禁止**：发 HTTP 请求、文件 I/O、邮件/短信发送
- 长事务（>3 秒）→ 拆分为小事务

## 乐观并发与行级锁 🟡

```csharp
// ✅ 乐观并发：EF Core RowVersion
public class Order
{
    [Timestamp]
    public byte[] RowVersion { get; set; }
}
// 更新冲突时自动抛 DbUpdateConcurrencyException

// ✅ 悲观锁：SELECT ... FOR UPDATE
var product = await _context.Products
    .FromSqlRaw("SELECT * FROM Products WITH (UPDLOCK, ROWLOCK) WHERE Id = {0}", id)
    .FirstOrDefaultAsync();
```

## 事务传播 🟡

| 场景 | 行为 |
|------|------|
| 嵌套 `BeginTransactionAsync` | 不支持，需要手动判断是否已在事务中 |
| 跨 DbContext | 使用 `TransactionScope`（分布式事务，仅在必须时使用） |
| 只读查询 | 不加事务，用 `AsNoTracking()` |

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 关联写入不用事务 | 数据不一致 |
| 事务中调外部 HTTP/gRPC | 外部调用不可回滚 |
| 长事务（>3 秒） | 锁持有过长 |
| Presentation 层管理事务 | 越层 |
| 嵌套 `BeginTransactionAsync` 不检查 | DbContext 不支持嵌套事务 |
