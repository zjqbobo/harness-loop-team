# .NET/C# 日志规范

## 日志框架 🔴

```csharp
// ✅ Serilog（推荐）— 结构化日志
using Serilog;

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .WriteTo.Console()
    .WriteTo.Seq("http://localhost:5341")  // 可选：集中日志
    .CreateLogger();

builder.Host.UseSerilog();

// ✅ 或 Microsoft.Extensions.Logging + ILogger<T>
// 内置支持，无需额外依赖
```

## ILogger 使用 🔴

```csharp
// ✅ 构造函数注入 ILogger<T>
public class OrderService : IOrderService
{
    private readonly ILogger<OrderService> _logger;

    public OrderService(ILogger<OrderService> logger)
    {
        _logger = logger;
    }

    public async Task ProcessAsync(Order order)
    {
        _logger.LogInformation("开始处理订单 {OrderId}", order.Id);
        // ...
        _logger.LogInformation("订单处理完成 {OrderId} Status={Status}", order.Id, order.Status);
    }
}

// ❌ Console.WriteLine（禁止）
Console.WriteLine($"订单处理完成: {order.Id}");
```

## 日志级别 🔴

| 级别 | 场景 | 示例 |
|------|------|------|
| `Trace` | 最详细调试信息 | 方法入口退出、循环内部 |
| `Debug` | 开发调试 | SQL 语句、请求详情 |
| `Information` | 业务关键节点 | "用户登录成功"、"订单创建完成" |
| `Warning` | 可恢复异常/降级 | "缓存未命中"、"重试中" |
| `Error` | 需要人工处理 | "支付回调验证失败"、"DB写入失败" |
| `Critical` | 系统级告警 | "消息队列断连"、"磁盘满" |

## 结构化日志 🔴

```csharp
// ✅ 使用泛型重载（结构化，可被日志系统检索）
_logger.LogInformation("用户登录 UserId={UserId} IP={IP}", userId, ip);

// ❌ 字符串插值（结构化丢失）
_logger.LogInformation($"用户登录 UserId={userId} IP={ip}");

// ✅ 异常日志带完整堆栈
try
{
    await CallPaymentApi(order);
}
catch (Exception ex)
{
    _logger.LogError(ex, "支付接口调用失败 OrderId={OrderId}", order.Id);
}

// ❌ 异常日志不带异常对象
catch (Exception ex)
{
    _logger.LogError("支付接口调用失败: {Message}", ex.Message);  // 堆栈丢失！
}
```

## 请求追踪 🟡

```csharp
// Middleware 自动注入 TraceIdentifier
public class TraceMiddleware
{
    private readonly RequestDelegate _next;

    public TraceMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        var traceId = context.Request.Headers["X-Trace-Id"].FirstOrDefault()
                      ?? context.TraceIdentifier;
        context.Response.Headers["X-Trace-Id"] = traceId;

        using (LogContext.PushProperty("TraceId", traceId))
        {
            await _next(context);
        }
    }
}

// 日志自动带上 TraceId：
// { "Timestamp": "...", "Level": "Information", "MessageTemplate": "请求开始",
//   "Properties": { "TraceId": "abc-123", "Method": "GET", "Path": "/users" } }
```

## 敏感信息脱敏 🔴

```csharp
// Serilog 脱敏 Enricher
public class SensitiveDataEnricher : ILogEventEnricher
{
    private static readonly HashSet<string> SensitiveKeys = new()
    {
        "password", "token", "secret", "creditcard", "ssn"
    };

    public void Enrich(LogEvent logEvent, ILogEventPropertyFactory propertyFactory)
    {
        foreach (var key in logEvent.Properties.Keys.ToList())
        {
            if (SensitiveKeys.Contains(key.ToLowerInvariant()))
            {
                logEvent.AddOrUpdateProperty(
                    propertyFactory.CreateProperty(key, "***REDACTED***"));
            }
        }
    }
}
```

## 日志配置模板 🔴

```json
// appsettings.json
{
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "Microsoft.EntityFrameworkCore": "Warning",
        "System": "Warning"
      }
    },
    "WriteTo": [
      { "Name": "Console" }
    ]
  }
}
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `Console.WriteLine` | 无级别、无时间戳、不可控 | `ILogger.LogInformation` |
| 字符串插值拼接日志 | 结构化丢失 | 模板占位符 `{Key}` |
| 日志中输出密码/Token | 安全合规 | 脱敏或跳过 |
| `LogError` 不带异常对象 | 堆栈丢失 | `LogError(ex, "...")` |
| 循环内 `LogInformation` 无节制 | 日志轰炸 | 频率控制 |
