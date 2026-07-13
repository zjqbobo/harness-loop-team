# Go 日志规范

## 日志框架 🔴

Go 1.21+ 使用标准库 `log/slog`（结构化日志）：

```go
import "log/slog"

// 生产环境：JSON 格式
logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelInfo,
}))

// 开发环境：文本格式
logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelDebug,
}))
```

## 日志级别 🔴

| 级别 | 函数 | 场景 |
|------|------|------|
| `Debug` | `slog.Debug()` | 开发调试、入参值、SQL |
| `Info` | `slog.Info()` | 业务关键节点、状态变更 |
| `Warn` | `slog.Warn()` | 可恢复异常、降级、重试 |
| `Error` | `slog.Error()` | 需要人工处理的错误 |

## 结构化日志 🔴

```go
// ✅ 结构化 key=value（可用于检索）
slog.Info("用户登录成功",
    "userID", userID,
    "ip", ip,
    "method", "password",
)

// ✅ 分组日志
slog.Info("订单创建",
    slog.Group("order",
        "id", orderID,
        "amount", amount,
        "userID", userID,
    ),
)

// ❌ 字符串拼接（无法检索）
log.Printf("用户 %d 从 %s 登录成功\n", userID, ip)
```

## Context 传递 TraceID 🔴

```go
// middleware 注入 traceID
type contextKey string
const traceIDKey contextKey = "traceID"

func TraceMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        traceID := r.Header.Get("X-Trace-ID")
        if traceID == "" {
            traceID = uuid.New().String()
        }
        ctx := context.WithValue(r.Context(), traceIDKey, traceID)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}

// 日志中自动带 traceID
func LogWithTrace(ctx context.Context, level slog.Level, msg string, args ...any) {
    traceID, _ := ctx.Value(traceIDKey).(string)
    allArgs := append([]any{"traceID", traceID}, args...)
    slog.Log(ctx, level, msg, allArgs...)
}
```

## 错误日志 🔴

```go
// ✅ 带堆栈的错误日志
if err != nil {
    slog.Error("支付接口调用失败",
        "orderID", orderID,
        "error", err,
        "duration_ms", elapsed.Milliseconds(),
    )
}

// ✅ 业务错误用 Warn
if errors.Is(err, ErrNotFound) {
    slog.Warn("资源未找到",
        "resource", "user",
        "id", userID,
    )
}
```

## 敏感信息脱敏 🔴

```go
// ✅ 日志过滤器
type SensitiveFilter struct{}

func (f *SensitiveFilter) Replace(attrs []slog.Attr) []slog.Attr {
    result := make([]slog.Attr, 0, len(attrs))
    for _, attr := range attrs {
        if isSensitiveKey(attr.Key) {
            result = append(result, slog.String(attr.Key, "***REDACTED***"))
        } else {
            result = append(result, attr)
        }
    }
    return result
}

var sensitiveKeys = map[string]bool{
    "password": true, "token": true, "secret": true,
    "credit_card": true, "ssn": true, "id_card": true,
}
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `fmt.Println` / `log.Println` | 无级别、无结构化 | `slog.Info()` |
| 日志中输出密码/Token | 安全合规 | 脱敏或跳过 |
| `slog.Error` 不传 error | 无堆栈信息 | `"error", err` |
| 循环内 `slog.Info` 无节制 | 日志轰炸 | 控制频率或降 Debug |
