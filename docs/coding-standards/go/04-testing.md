# Go 测试规范

## 测试框架 🔴

```go
import (
    "testing"
    "github.com/stretchr/testify/assert"   // 断言
    "github.com/stretchr/testify/require"  // 致命断言（失败即停止）
    "github.com/stretchr/testify/mock"     // Mock
)
```

## 表驱动测试 🔴

```go
// ✅ 表驱动测试（Go 惯用法）
func TestCalculateFee(t *testing.T) {
    tests := []struct {
        name        string
        amount      float64
        expectedFee float64
        expectErr   bool
    }{
        {"正常金额", 100, 1.0, false},
        {"大额", 1000, 10.0, false},
        {"零金额", 0, 0, true},
        {"负数", -100, 0, true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            fee, err := CalculateFee(tt.amount)
            if tt.expectErr {
                require.Error(t, err)
                return
            }
            require.NoError(t, err)
            assert.InDelta(t, tt.expectedFee, fee, 0.01)
        })
    }
}

// ❌ 多个独立测试函数重复代码
func TestCalculateFee_Normal(t *testing.T) { ... }
func TestCalculateFee_Large(t *testing.T) { ... }
func TestCalculateFee_Zero(t *testing.T) { ... }
```

## Mock 规范 🔴

```go
// ✅ 接口驱动 mock
type UserRepository interface {
    FindByID(ctx context.Context, id int) (*User, error)
    Create(ctx context.Context, user *User) error
}

// testify/mock
type MockUserRepo struct {
    mock.Mock
}

func (m *MockUserRepo) FindByID(ctx context.Context, id int) (*User, error) {
    args := m.Called(ctx, id)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*User), args.Error(1)
}

// 使用
func TestGetUser(t *testing.T) {
    mockRepo := new(MockUserRepo)
    mockRepo.On("FindByID", mock.Anything, 1).Return(&User{ID: 1, Name: "Alice"}, nil)

    svc := NewUserService(mockRepo)
    user, err := svc.GetUser(context.Background(), 1)

    require.NoError(t, err)
    assert.Equal(t, "Alice", user.Name)
    mockRepo.AssertExpectations(t)  // 确保所有 mock 调用都发生了
}
```

## Mock 规则 🔴

| 规则 | 说明 |
|------|------|
| **mock 外部边界** | 数据库、HTTP API、文件系统、消息队列 |
| **不 mock 被测代码** | 被测函数内部调用的方法走真实实现 |
| **不 mock 标准库** | `time`、`json`、`os` 等使用真实调用 |
| **不 mock 值对象** | `User`、`Order` 等 struct 使用真实构造 |

## 三段式结构 🟡

```go
func TestCreateOrder_Success(t *testing.T) {
    // Arrange — 准备数据和 mock
    mockRepo := new(MockOrderRepo)
    mockRepo.On("Create", mock.Anything, mock.AnythingOfType("*Order")).Return(nil)
    svc := NewOrderService(mockRepo)

    // Act — 执行被测方法
    order, err := svc.CreateOrder(context.Background(), CreateOrderRequest{
        UserID: 1,
        Amount: 99.99,
    })

    // Assert — 验证结果
    require.NoError(t, err)
    assert.Equal(t, 1, order.UserID)
    assert.Equal(t, 99.99, order.Amount)
    mockRepo.AssertExpectations(t)
}
```

## 并行测试 🟡

```go
func TestHeavyOperation(t *testing.T) {
    t.Parallel()  // 与其他并行测试并发执行

    tests := []struct{ ... }{ ... }
    for _, tt := range tests {
        tt := tt  // Go 1.22 之前需要此行
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()  // 子测试也可并行
            ...
        })
    }
}
```

## 测试辅助函数 🟡

```go
// ✅ t.Helper() 标记辅助函数（错误报告指向调用方）
func createTestUser(t *testing.T, name string) *User {
    t.Helper()
    return &User{
        ID:   1,
        Name: name,
    }
}
```

## 覆盖率 🔴

```bash
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
go tool cover -html=coverage.out -o coverage.html
```

| 指标 | 门禁 |
|------|------|
| 语句覆盖率 | ≥ 80% |
| 未达标 | CI 阻断 |

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 连真实数据库 | 慢、不可控、不可并行 |
| 连真实外部 API | 外部依赖、网络问题 |
| 测试间共享可变状态 | 顺序依赖、不可独立运行 |
| 只写 happy path | 边界和异常 = 线上事故高发区 |
| `time.Sleep` 等待异步 | 用 channel 或 context 同步 |
| 不使用 `t.Parallel()` | 测试过慢 |
