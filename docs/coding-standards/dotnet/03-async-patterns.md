# .NET/C# 异步编程规范

## async/await 规则 🔴

```csharp
// ✅ async/await 一路到底
public async Task<Order> GetOrderAsync(int id)
{
    var order = await _repository.FindByIdAsync(id);
    return order ?? throw new NotFoundException("订单", id);
}

// ❌ async void（除事件处理器外禁止）
public async void ProcessData() { ... }  // 异常无法被捕获！

// ❌ 同步调用异步（可能死锁）
public Order GetOrder(int id)
{
    return _repository.FindByIdAsync(id).Result;  // 死锁风险！
}
```

## ConfigureAwait 🔴

```csharp
// ✅ 库代码（class library）：加 ConfigureAwait(false)
public async Task<T> GetAsync<T>(string key)
{
    var data = await _cache.GetStringAsync(key).ConfigureAwait(false);
    return JsonSerializer.Deserialize<T>(data);
}

// ✅ 应用代码（Controller/Service）：可以不加（需要 HttpContext）
public async Task<IActionResult> Get(int id)
{
    var user = await _userService.GetAsync(id);  // 不需要 ConfigureAwait
    return Ok(user);
}
```

## 并行等待 🔴

```csharp
// ✅ Task.WhenAll：并行执行独立任务
var userTask = _userService.GetAsync(userId);
var ordersTask = _orderService.GetByUserAsync(userId);
var couponTask = _couponService.GetAvailableAsync(userId);

await Task.WhenAll(userTask, ordersTask, couponTask);

var user = userTask.Result;
var orders = ordersTask.Result;
var coupons = couponTask.Result;

// ❌ 串行等待独立任务
var user = await _userService.GetAsync(userId);
var orders = await _orderService.GetByUserAsync(userId);  // 可以并行！
var coupons = await _couponService.GetAvailableAsync(userId);

// ✅ Task.WhenAny：超时控制
var timeout = Task.Delay(TimeSpan.FromSeconds(5));
var completed = await Task.WhenAny(actualTask, timeout);
if (completed == timeout) throw new TimeoutException("操作超时");
```

## CancellationToken 🔴

```csharp
// ✅ Controller 层传入 CancellationToken
[HttpGet("{id}")]
public async Task<ActionResult<UserDto>> Get(int id, CancellationToken ct)
{
    var user = await _userService.GetAsync(id, ct);
    return Ok(user);
}

// ✅ 逐层传递 CancellationToken
public async Task<User> GetAsync(int id, CancellationToken ct = default)
{
    return await _repository.FindByIdAsync(id, ct);
}

// ✅ EF Core 使用 CancellationToken
public async Task<User?> FindByIdAsync(int id, CancellationToken ct = default)
{
    return await _dbContext.Users
        .AsNoTracking()
        .FirstOrDefaultAsync(u => u.Id == id, ct);
}
```

## IAsyncEnumerable 🟡

```csharp
// ✅ 流式返回大数据集
public async IAsyncEnumerable<UserDto> GetAllUsersAsync(
    [EnumeratorCancellation] CancellationToken ct = default)
{
    await foreach (var user in _dbContext.Users.AsNoTracking().AsAsyncEnumerable()
        .WithCancellation(ct))
    {
        yield return _mapper.Map<UserDto>(user);
    }
}

// Controller 中使用
[HttpGet]
public IAsyncEnumerable<UserDto> GetAll(CancellationToken ct)
{
    return _userService.GetAllUsersAsync(ct);
}
```

## ValueTask 使用 🟡

```csharp
// ✅ 高频调用且多数情况同步完成时用 ValueTask
public ValueTask<User?> GetCachedAsync(int id)
{
    if (_cache.TryGetValue(id, out var user))
        return new ValueTask<User?>(user);  // 同步完成，不分配 Task

    return new ValueTask<User?>(FetchFromDbAsync(id));
}
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `async void`（事件外） | 异常无法捕获，进程崩溃 | `async Task` |
| `.Result` / `.Wait()` | 死锁 | `await` |
| `Task.Run()` 在 ASP.NET 中 | 抢线程池线程 | 直接 `await` 原生异步方法 |
| 忘记 CancellationToken | 请求取消后仍在执行 | 逐层传递 `ct` |
| `Task.Run(async () => ...)` | 无需双重包装 | `Task.Run` 就够了 |
| `Thread.Sleep()` 在异步代码 | 阻塞线程 | `await Task.Delay()` |
