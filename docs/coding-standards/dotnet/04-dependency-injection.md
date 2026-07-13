# .NET/C# 依赖注入规范

## 构造函数注入 🔴

```csharp
// ✅ 构造函数注入（唯一方式）
public class OrderService : IOrderService
{
    private readonly IOrderRepository _repository;
    private readonly ILogger<OrderService> _logger;
    private readonly IMapper _mapper;

    public OrderService(
        IOrderRepository repository,
        ILogger<OrderService> logger,
        IMapper mapper)
    {
        _repository = repository ?? throw new ArgumentNullException(nameof(repository));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _mapper = mapper ?? throw new ArgumentNullException(nameof(mapper));
    }

    // 使用私有只读字段，不用属性
}

// ❌ 属性注入（禁止）
public class OrderService
{
    public IOrderRepository Repository { get; set; }  // 禁止
}

// ❌ Service Locator（禁止）
public class OrderService
{
    public void Process(IServiceProvider sp)
    {
        var repo = sp.GetRequiredService<IOrderRepository>();  // 禁止
    }
}
```

## 注册生命周期 🔴

| 生命周期 | 使用场景 | 示例 |
|---------|---------|------|
| **Transient** | 轻量级、无状态服务 | 工具类、策略 |
| **Scoped** | 与请求一一对应 | DbContext、Repository、Service |
| **Singleton** | 全局共享、线程安全 | 配置、缓存、连接池 |

```csharp
// Program.cs — 按接口注册（推荐）
builder.Services.AddScoped<IOrderRepository, OrderRepository>();
builder.Services.AddScoped<IOrderService, OrderService>();

// HttpClient 用 AddHttpClient
builder.Services.AddHttpClient<IPaymentClient, PaymentClient>(client =>
{
    client.BaseAddress = new Uri(builder.Configuration["PaymentApi:BaseUrl"]!);
    client.Timeout = TimeSpan.FromSeconds(10);
});

// DbContext 用 AddDbContext
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("Default")));

// 选项模式
builder.Services.Configure<PaymentOptions>(
    builder.Configuration.GetSection("Payment"));
```

## 禁止在 Singleton 注入 Scoped 🔴

```csharp
// ❌ Singleton 依赖 Scoped（生命周期陷阱）
builder.Services.AddSingleton<IMyService, MyService>();  // Singleton
public class MyService
{
    public MyService(AppDbContext dbContext) { ... }  // AppDbContext 是 Scoped！
    // Singleton 持有 Scoped 实例，DbContext 被复用导致异常
}

// ✅ 通过 IServiceScopeFactory 手动创建 scope
public class MyBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;

    public MyBackgroundService(IServiceScopeFactory scopeFactory)
    {
        _scopeFactory = scopeFactory;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        // 每次循环创建新 scope
    }
}
```

## 选项模式（IOptions）🟡

```csharp
// 配置类
public class PaymentOptions
{
    public const string Section = "Payment";

    [Required]
    public string BaseUrl { get; init; } = string.Empty;

    [Range(1, 60)]
    public int TimeoutSeconds { get; init; } = 30;
}

// 注册
builder.Services.AddOptions<PaymentOptions>()
    .Bind(builder.Configuration.GetSection(PaymentOptions.Section))
    .ValidateDataAnnotations()
    .ValidateOnStart();

// 使用
public class PaymentService
{
    public PaymentService(IOptions<PaymentOptions> options)
    {
        var config = options.Value;
        // config.BaseUrl, config.TimeoutSeconds
    }
}
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| 属性注入 | 依赖不透明，难以测试 | 构造函数注入 |
| `GetService<T>()` (Service Locator) | 依赖隐蔽，运行时才报错 | 构造函数注入 |
| Singleton 注入 Scoped | 生命周期陷阱 | `IServiceScopeFactory` |
| `new` 具体类（在可注入场景） | 硬编码依赖 | 通过接口注入 |
| 构造函数中有重逻辑 | 影响 DI 容器性能 | 构造函数只做赋值 |
