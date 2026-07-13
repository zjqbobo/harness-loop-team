# .NET/C# 数据库访问规范

## N+1 查询防护 🔴

- 使用 EF Core `Include()` / `ThenInclude()` 或 Dapper 的 `JOIN` + `QueryMultiple`
- **禁止**在循环中触发懒加载

```csharp
// ✅ EF Core eager loading
var orders = await context.Orders
    .Include(o => o.Items)
    .Where(o => o.UserId == userId)
    .ToListAsync();

// ✅ Dapper 批量查询
var users = await conn.QueryAsync<User>(
    "SELECT * FROM Users WHERE Id IN @Ids", new { Ids = ids });

// ❌ 循环中逐条查询（N+1）
foreach (var order in orders) {
    var items = await context.Items.Where(i => i.OrderId == order.Id).ToListAsync();  // N 次！
}

// ❌ 懒加载 N+1（访问 navigation property 触发）
foreach (var order in orders) {
    Console.WriteLine(order.Items.Count);  // 每次触发一次 SQL
}
```

## 分页规范 🔴

- 所有列表查询**必须分页**
- 小数据量用 `Skip/Take`，大数据量用游标分页（Keyset Pagination）
- 统一分页响应结构

```csharp
// ✅ EF Core 偏移分页
public async Task<PagedResult<UserDto>> ListUsers(int page, int pageSize) {
    var query = context.Users.AsNoTracking();
    var total = await query.CountAsync();
    var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
    return new PagedResult<UserDto>(items.Select(mapper.ToDto), total, page, pageSize);
}

// ✅ 游标分页（大数据量，避免 OFFSET 大值性能差）
var items = await context.Users
    .Where(u => u.Id > cursor)
    .OrderBy(u => u.Id)
    .Take(pageSize + 1)  // 多查一条判断是否有下一页
    .AsNoTracking()
    .ToListAsync();

// ❌ 无分页全量返回
var users = await context.Users.ToListAsync();  // 内存溢出
```

## 连接池与 DbContext 生命周期 🔴

- DbContext 必须是 Scoped 生命周期（每个请求一个实例）
- **禁止** Singleton DbContext（线程不安全 + 内存泄漏）
- **禁止**手动 `new DbContext()`，必须通过 DI 注入

```csharp
// ✅ DI 注入（Scoped，每个请求自动创建和释放）
public class UserService
{
    private readonly AppDbContext _context;
    public UserService(AppDbContext context) => _context = context;
}

// ✅ 连接池配置
builder.Services.AddDbContextPool<AppDbContext>(options =>
    options.UseSqlServer(connectionString, sqlOptions => {
        sqlOptions.EnableRetryOnFailure(maxRetryCount: 3);
    }),
    poolSize: 128  // DbContext pool 大小
);
```

## 数据库迁移 🔴

- 使用 EF Core Migrations
- **正向迁移不可回退**（forward-only）
- CI/CD 执行 `dotnet ef database update`

```bash
# 生成迁移
dotnet ef migrations add AddCancelReason

# 生成幂等 SQL 脚本（生产安全）
dotnet ef migrations script --idempotent -o migrations/script.sql

# CI 中执行
dotnet ef database update
```

## 查询性能 🟡

- 只读查询用 `AsNoTracking()`（禁用变更追踪，性能提升 2-3x）
- 明确指定需要的列（`Select`），**禁止** `ToListAsync()` 拉全字段
- 复杂报表用 Dapper 或 raw SQL（`FromSqlRaw`），不使用 EF Core 动态拼接

```csharp
// ✅ 只读查询 + Select 指定字段
var users = await context.Users
    .AsNoTracking()
    .Select(u => new { u.Id, u.Name, u.Email })
    .ToListAsync();

// ❌ 跟踪所有字段
var users = await context.Users.ToListAsync();  // Change Tracker 跟踪所有字段
```

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 循环中逐条查询 | N+1 性能灾难 |
| 无分页全量查询 | 内存溢出 |
| 读查询不加 `AsNoTracking()` | 性能浪费 |
| Singleton DbContext | 线程不安全 |
| `new DbContext()` 不用 DI | 生命周期失控 |
| EnableRetryOnFailure 不配置 | 瞬时错误导致请求失败 |
| `SELECT *` 映射全字段 | 浪费带宽 |
