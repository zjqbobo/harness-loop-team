# Go 事务处理规范

## 基本原则 🔴

- 涉及多个表的写操作**必须**在事务中执行
- 事务边界在 Service 层，通过 Repository 的 `BeginTx`/`WithTx` 方法控制

## database/sql 事务 🔴

```go
// ✅ 事务模板（标准模式）
func (s *OrderService) CreateOrder(ctx context.Context, req CreateOrderReq) (*Order, error) {
    tx, err := s.db.BeginTx(ctx, nil)
    if err != nil {
        return nil, fmt.Errorf("begin tx: %w", err)
    }
    defer tx.Rollback()  // 确保失败时回滚

    // 1. 扣库存
    if err := s.productRepo.WithTx(tx).DecrementStock(ctx, req.ProductID, req.Quantity); err != nil {
        return nil, fmt.Errorf("decrement stock: %w", err)
    }

    // 2. 创建订单
    order, err := s.orderRepo.WithTx(tx).Create(ctx, req)
    if err != nil {
        return nil, fmt.Errorf("create order: %w", err)
    }

    // 3. 记流水
    if err := s.logRepo.WithTx(tx).Create(ctx, order.ID, "created"); err != nil {
        return nil, fmt.Errorf("create log: %w", err)
    }

    // 提交（成功）
    if err := tx.Commit(); err != nil {
        return nil, fmt.Errorf("commit tx: %w", err)
    }
    return order, nil
}
```

## Repository 事务接口设计 🔴

```go
type OrderRepository interface {
    WithTx(tx *sql.Tx) OrderRepository  // 返回事务版本的 Repository
    Create(ctx context.Context, req CreateOrderReq) (*Order, error)
}

type orderRepo struct {
    db *sql.DB
    tx *sql.Tx  // nil 表示非事务模式
}

func (r *orderRepo) WithTx(tx *sql.Tx) OrderRepository {
    return &orderRepo{db: r.db, tx: tx}
}

func (r *orderRepo) db() DBTX {
    if r.tx != nil {
        return r.tx  // 事务中
    }
    return r.db  // 非事务
}
```

## 事务边界 🔴

```
✅ 推荐事务边界
┌─ Service 方法 ────────────────────────┐
│  1. 参数校验（事务外）                  │
│  2. BeginTx → 事务开始                 │
│  3. 数据库操作                          │
│  4. Commit                             │
│  5. 发消息/写缓存（事务外）               │
└────────────────────────────────────────┘

❌ 错误：事务中调外部
┌─ Service 方法 ────────────────────────┐
│  BeginTx                              │
│  扣库存                                │
│  调用支付 API ← 不可回滚！              │
│  建订单                                │
│  Commit                               │
└────────────────────────────────────────┘
```

## sqlx 事务 🟡

```go
// ✅ sqlx 事务
func (r *userRepo) CreateWithTx(ctx context.Context, tx *sqlx.Tx, user *User) error {
    query := `INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id`
    return tx.QueryRowxContext(ctx, query, user.Name, user.Email).Scan(&user.ID)
}
```

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 关联写入不用事务 | 数据不一致 |
| 事务中调 HTTP/gRPC | 外部调用不可回滚 |
| `defer tx.Rollback()` 不放在 Commit 前 | Commit 后 Rollback 是 no-op，但意图不清 |
| 长事务（>3 秒） | 锁持有过长 |
| 在 Handler 层管理事务 | 越层 |
