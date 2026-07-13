# .NET/C# 异常处理规范

## 异常体系 🔴

```csharp
// Domain 层异常基类
public abstract class DomainException : Exception
{
    public string Code { get; }

    protected DomainException(string code, string message)
        : base(message)
    {
        Code = code;
    }
}

public class NotFoundException : DomainException
{
    public NotFoundException(string resource, object id)
        : base("NOT_FOUND", $"{resource} {id} 不存在") { }
}

public class ValidationException : DomainException
{
    public IReadOnlyList<ValidationError> Errors { get; }

    public ValidationException(IReadOnlyList<ValidationError> errors)
        : base("VALIDATION_ERROR", "参数校验失败")
    {
        Errors = errors;
    }
}

public class BusinessRuleViolationException : DomainException
{
    public BusinessRuleViolationException(string message)
        : base("BUSINESS_RULE_VIOLATION", message) { }
}
```

## 全局异常处理 🔴

### ExceptionFilter（推荐）

```csharp
public class GlobalExceptionFilter : IExceptionFilter
{
    private readonly ILogger<GlobalExceptionFilter> _logger;

    public GlobalExceptionFilter(ILogger<GlobalExceptionFilter> logger)
    {
        _logger = logger;
    }

    public void OnException(ExceptionContext context)
    {
        switch (context.Exception)
        {
            case DomainException domainEx:
                _logger.LogWarning("业务异常: {Code} {Message}", domainEx.Code, domainEx.Message);
                context.Result = new ObjectResult(new ErrorResponse(
                    domainEx.Code, domainEx.Message))
                {
                    StatusCode = domainEx switch
                    {
                        NotFoundException => 404,
                        ValidationException => 422,
                        UnauthorizedException => 401,
                        _ => 400
                    }
                };
                break;

            default:
                _logger.LogError(context.Exception, "系统异常");
                context.Result = new ObjectResult(new ErrorResponse(
                    "INTERNAL_ERROR", "服务器内部错误"))
                {
                    StatusCode = 500
                };
                break;
        }

        context.ExceptionHandled = true;
    }
}
```

### Middleware（备选方案）

```csharp
public class ErrorHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ErrorHandlingMiddleware> _logger;

    public ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (DomainException ex)
        {
            _logger.LogWarning("业务异常: {Code} {Message}", ex.Code, ex.Message);
            context.Response.StatusCode = ex is NotFoundException ? 404 : 400;
            await context.Response.WriteAsJsonAsync(new ErrorResponse(ex.Code, ex.Message));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "未处理的异常");
            context.Response.StatusCode = 500;
            await context.Response.WriteAsJsonAsync(new ErrorResponse("INTERNAL_ERROR", "服务器内部错误"));
        }
    }
}
```

## ProblemDetails（RFC 7807）🟡

```csharp
// Program.cs
builder.Services.AddProblemDetails(options =>
{
    options.CustomizeProblemDetails = ctx =>
    {
        ctx.ProblemDetails.Extensions["traceId"] = ctx.HttpContext.TraceIdentifier;
    };
});

// 返回标准 ProblemDetails
public IActionResult GetUser(int id)
{
    throw new NotFoundException("用户", id);
    // 自动返回：
    // { "type": "...", "title": "NOT_FOUND", "status": 404,
    //   "detail": "用户 999 不存在", "traceId": "abc-123" }
}
```

## try/catch 最佳实践 🔴

```csharp
// ✅ 捕获具体异常
try
{
    var user = await _repository.FindByIdAsync(id);
}
catch (SqlException ex)
{
    throw new InfrastructureException("数据库查询失败", ex);
}

// ❌ 吞异常（禁止）
try
{
    RiskyOperation();
}
catch { }  // 静默失败

// ❌ catch(Exception) 不处理（禁止）
try
{
    DoSomething();
}
catch (Exception ex)
{
    // 什么都不做，也不记录日志
}

// ❌ 用异常控制业务流程（禁止）
try
{
    var user = _repository.FindById(id);
    return user.Name;
}
catch (NullReferenceException)
{
    return "未知用户";
}
// ✅ 正确：显式判断
var user = _repository.FindById(id);
return user?.Name ?? "未知用户";
```

## 异常日志规范 🔴

| 异常类型 | 日志级别 | 是否带堆栈 | 示例 |
|---------|---------|-----------|------|
| 业务异常 (4xx) | `LogWarning` | ❌ | `_logger.LogWarning("用户不存在: {UserId}", id)` |
| 系统异常 (5xx) | `LogError` | ✅ | `_logger.LogError(ex, "支付接口超时 OrderId={OrderId}", oid)` |
| 框架异常 | `LogError` | ✅ | `_logger.LogError(ex, "DB连接失败")` |

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `throw new Exception("xxx")` | 无错误码，调用方无法区分 | 抛 `DomainException` 子类 |
| `catch { }` 空块 | 静默失败 | 至少记录日志 |
| `throw ex`（丢失堆栈） | 原始调用栈被重置 | `throw` 不加参数 |
| `e.StackTrace` 拼接字符串 | 日志框架可自动序列化 | `_logger.LogError(ex, "...")` |
