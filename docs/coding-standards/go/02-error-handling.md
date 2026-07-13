# Go 错误处理规范

## 基本原则 🔴

```go
// ✅ 错误必须处理，禁止忽略
result, err := doSomething()
if err != nil {
    return fmt.Errorf("doSomething: %w", err)
}

// ❌ 用 _ 忽略 error（禁止）
result, _ := doSomething()

// ❌ 先使用 result 再检查 err（禁止——result 可能为 nil）
result, err := doSomething()
process(result)  // 此时 err 未检查！
if err != nil {
    ...
}
```

## 错误包装 🔴

```go
// ✅ fmt.Errorf + %w：保留原始错误链
func GetUser(id int) (*User, error) {
    user, err := repo.FindByID(id)
    if err != nil {
        return nil, fmt.Errorf("GetUser: repo.FindByID(%d): %w", id, err)
    }
    return user, nil
}

// ✅ 判断时用 errors.Is / errors.As
if errors.Is(err, sql.ErrNoRows) {
    // 处理未找到
}

var bizErr *BizError
if errors.As(err, &bizErr) {
    log.Printf("业务错误: code=%s", bizErr.Code)
}

// ❌ 字符串比较（脆弱）
if err.Error() == "user not found" { ... }

// ❌ 裸 fmt.Errorf 不用 %w（错误链断裂）
return fmt.Errorf("failed: %v", err)  // 调用方无法 errors.Is 判断
```

## 自定义错误类型 🔴

```go
// Sentinel Error（哨兵错误）— 用于 Is 判断
var (
    ErrNotFound     = errors.New("resource not found")
    ErrDuplicate    = errors.New("resource already exists")
    ErrUnauthorized = errors.New("unauthorized")
)

// 自定义错误 struct — 用于 As 判断 + 携带上下文
type BizError struct {
    Code    string // 错误码 "ORDER_NOT_FOUND"
    Message string // 用户可读消息 "订单 12345 不存在"
    Cause   error  // 原始错误（可选）
}

func (e *BizError) Error() string {
    return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

func (e *BizError) Unwrap() error {
    return e.Cause
}
```

## panic 使用规则 🔴

```go
// ✅ panic 仅用于不可恢复的程序错误（类似 assert）
func MustCompileRegex(pattern string) *regexp.Regexp {
    re, err := regexp.Compile(pattern)
    if err != nil {
        panic(fmt.Sprintf("invalid regex pattern: %s", pattern))
    }
    return re
}

// ❌ panic 用于业务逻辑（禁止）
func TransferMoney(from, to Account, amount float64) error {
    if from.Balance < amount {
        panic("余额不足")  // 错误！应该 return error
    }
    ...
}

// ✅ defer + recover 仅在边界层使用
func RecoveryMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        defer func() {
            if rec := recover(); rec != nil {
                log.Printf("PANIC: %v\n%s", rec, debug.Stack())
                http.Error(w, "Internal Server Error", 500)
            }
        }()
        next.ServeHTTP(w, r)
    })
}
```

## HTTP 层错误响应 🔴

```go
// ✅ 统一错误响应格式
type ErrorResponse struct {
    Error struct {
        Code    string `json:"code"`
        Message string `json:"message"`
    } `json:"error"`
}

func handleError(w http.ResponseWriter, err error) {
    var bizErr *BizError
    var status int

    switch {
    case errors.As(err, &bizErr):
        status = 400
    case errors.Is(err, ErrNotFound):
        status = 404
    case errors.Is(err, ErrUnauthorized):
        status = 401
    default:
        status = 500
        log.Printf("系统异常: %v", err)
    }

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(ErrorResponse{...})
}
```

## 错误日志规范 🔴

```go
// ✅ 业务错误用 Warn（不打印堆栈）
if errors.Is(err, ErrNotFound) {
    log.Printf("WARN: 用户不存在 userID=%d", userID)
}

// ✅ 系统错误用 Error（打印调用栈）
if err != nil {
    log.Printf("ERROR: DB查询失败: %+v", err)  // %+v 展开错误链
}

// ❌ 吞掉错误
if err != nil {
    // 什么都不做
}
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `_ := doSomething()` 忽略 error | 错误被丢弃 | 始终检查 error |
| `err.Error()` 做字符串匹配 | 脆弱，库升级就断 | `errors.Is` / `errors.As` |
| 用 `panic` 处理业务错误 | 调用方无法恢复 | `return error` |
| `if err != nil { return err }` 不包装上下文 | 错误链无意义 | `fmt.Errorf("...: %w", err)` |
| 循环内忽略 error | 部分失败静默丢失 | 收集错误或快速失败 |
