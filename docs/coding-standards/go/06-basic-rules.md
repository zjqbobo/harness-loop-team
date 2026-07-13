# Go 基础编码规范

## 代码行数限制 🔴

| 元素 | 最大行数 | 超出处理 |
|------|---------|---------|
| 函数 | 80 行 | 提取私有函数 |
| 嵌套层级 | 4 层 | 卫语句 / 提取函数 |

> 文件不设行数上限，以职责单一、可快速理解为原则。

## 圈复杂度 🔴

- 单个函数圈复杂度 ≤ 10
- 检测：`golangci-lint run --enable=gocyclo --max-complexity=10`

```go
// ✅ 卫语句：提前 return
func ProcessOrder(order *Order) error {
    if order == nil {
        return ErrOrderNotFound
    }
    if order.IsPaid {
        return ErrAlreadyPaid
    }
    if order.Amount <= 0 {
        return ErrInvalidAmount
    }

    // 主逻辑（无嵌套）
    return executeOrder(order)
}

// ❌ 深层嵌套
func ProcessOrder(order *Order) error {
    if order != nil {
        if !order.IsPaid {
            if order.Amount > 0 {
                return executeOrder(order)
            } else {
                return ErrInvalidAmount
            }
        } else {
            return ErrAlreadyPaid
        }
    } else {
        return ErrOrderNotFound
    }
}
```

## 命名规范 🔴

| 元素 | 规则 | 示例 |
|------|------|------|
| 包名 | 全小写，单数，短名 | `user`（不用 `users`） |
| 导出函数/类型 | `PascalCase` | `NewUserService`、`OrderStatus` |
| 私有函数/变量 | `camelCase` | `validateEmail`、`maxRetry` |
| 常量（导出） | `PascalCase` | `MaxRetryCount = 3` |
| 常量（私有） | `camelCase` | `defaultTimeout` |
| 接口 | `-er` 后缀（单方法） | `Reader`、`Writer`、`Closer` |
| 布尔变量 | `is`/`has`/`can` 前缀 | `isPaid`、`hasPermission` |
| 接收器 | 类型首字母小写 | `func (u *User) Name() string` |

### 方法命名 🟡

| 操作 | 前缀 | 示例 |
|------|------|------|
| 查询 | `Get` / `Find` / `List` | `GetByID`、`FindByName`、`ListByStatus` |
| 判断 | `Is` / `Has` / `Can` | `IsValid`、`HasStock` |
| 操作 | `Create` / `Update` / `Delete` | `CreateOrder`、`UpdateStatus` |

## 接口设计 🔴

```go
// ✅ 小接口（1-3 个方法）
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Repository interface {
    FindByID(ctx context.Context, id int) (*User, error)
    Create(ctx context.Context, user *User) error
}

// ✅ 在使用方定义接口（接受接口，返回结构体）
func NewUserHandler(svc UserService) *UserHandler { ... }

// ❌ 大接口（违反接口隔离原则）
type DataAccess interface {
    Create(...)
    Update(...)
    Delete(...)
    FindByID(...)
    FindByName(...)
    List(...)
    Count(...)
    // ... 10+ methods
}
```

## 代码格式化 🔴

```bash
# gofumpt（比 gofmt 更严格）
gofumpt -l -w .

# goimports（自动管理 import）
goimports -w .

# golangci-lint 检查
golangci-lint run
```

- **格式化全自动**：保存时运行 `gofmt` / `gofumpt`
- **禁止手动调整格式**（缩进、空格、换行）

## Go Doc 文档注释 🟡

- 公共 API（导出的函数/类型/常量/变量）必须写文档注释
- 格式：`// 名称 描述`（注释紧贴声明，以名称开头，以句号结尾）
- 私有函数可由命名自解释

```go
// CreateOrder 创建订单并触发支付流程。
//
// 该方法在事务中执行以下步骤：
//  1. 校验库存是否充足
//  2. 创建订单记录
//  3. 调用支付网关预授权
//
// 返回的订单包含支付状态，调用方应检查 order.PayStatus 字段。
func (s *OrderService) CreateOrder(ctx context.Context, req CreateOrderReq) (*Order, error) {
    ...
}
```

## 魔法值 🔴

```go
// ❌ 魔法值
if status == 3 { ... }
if userType == "admin" { ... }

// ✅ 常量
const (
    StatusPending   = 0
    StatusPaid      = 1
    StatusShipped   = 2
    StatusCompleted = 3
)

// ✅ iota 枚举
type OrderStatus int

const (
    OrderPending OrderStatus = iota
    OrderPaid
    OrderShipped
    OrderCompleted
)
```

## 空值处理 🔴

```go
// ✅ nil slice 是有效的（不需要 make 预分配）
var users []*User           // nil slice
users = append(users, u)    // append 对 nil slice 安全
return users                 // 调用方 range nil slice 安全（0 次迭代）

// ✅ 用零值而非 nil 检查
type Config struct {
    Timeout time.Duration  // 默认 0
    Retries int            // 默认 0
}
```

## defer 使用 🟡

```go
// ✅ 资源释放用 defer
f, err := os.Open("file.txt")
if err != nil {
    return err
}
defer f.Close()

// ✅ defer 在 err 检查之后（避免 nil.Close()）
resp, err := http.Get(url)
if err != nil {
    return err
}
defer resp.Body.Close()

// ✅ 循环中用闭包包装 defer（否则 defer 堆积）
for _, file := range files {
    func() {
        f, _ := os.Open(file)
        defer f.Close()
        process(f)
    }()
}
```

## 注释规范 🔵

- 代码应自解释，好的命名 > 注释
- 只在以下情况加注释：
  - **WHY**：解释为什么这样做（非显而易见的业务逻辑、算法选择）
  - **WORKAROUND**：临时方案，标注问题编号和预期解决时间
  - **CONCURRENCY**：goroutine/channel/并发相关的非显而易见行为
- 禁止：
  - 无价值注释（`// set name`、`// increment counter`）
  - 注释掉的代码（用 git 管理历史）
  - 用注释解释魔法值（用 iota 枚举/常量替代）

```go
// ✅ WHY — 解释非显而易见的决策
// 使用 sync.Map 而非普通 map+mutex：读多写少场景，sync.Map 的读几乎无锁竞争
var userCache sync.Map

// ✅ WORKAROUND — 标注临时方案
// WORKAROUND(issue-421): gin v1.9 的 BindJSON 在空 body 时不返回错误，
// 手动检查 content-length 兜底。升级 gin v1.10 后移除。
if r.ContentLength == 0 {
    return ErrEmptyBody
}

// ❌ 无价值注释
name := user.Name // get user name

// ❌ 注释掉的代码
// users, err := repo.FindAll(ctx)
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| 函数超 80 行 | 难测试、难理解 | 提取私有函数 |
| 导出不需要导出的符号 | 膨胀公共 API | 默认私有，确定需要再导出 |
| 魔法值 | 语义不明 | iota 枚举 / const |
| `interface{}`（空接口） | 类型不安全 | `any` 或明确类型 |
| 命名含包名（`user.UserService`） | 重复信息 | `user.Service` |
| `init()` 函数有副作用 | 启动行为不可控 | 显式初始化 |
| 裸 goroutine（`go func(){}()`） | 生命周期无管控 | context + errgroup |
