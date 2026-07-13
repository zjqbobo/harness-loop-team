# Go 数据库访问规范

## N+1 查询防护 🔴

- 关联查询用 `JOIN` 一次加载，或收集 ID 后 `WHERE IN` 批量查询
- **禁止**在循环中逐条查询

```go
// ✅ JOIN 一次加载
rows, err := db.Query(`
    SELECT o.id, o.user_id, i.id, i.name
    FROM orders o
    LEFT JOIN items i ON i.order_id = o.id
    WHERE o.user_id = $1
`, userID)

// ✅ 收集 ID 后批量查询（IN）
ids := make([]int64, len(orders))
for i, o := range orders { ids[i] = o.ID }
items, err := repo.FindByOrderIDs(ctx, ids)  // WHERE order_id IN ($1, $2, ...)

// ❌ 循环中逐条查询（N+1）
for _, order := range orders {
    items, _ := repo.FindByOrderID(ctx, order.ID)  // N 次查询！
}
```

## 分页规范 🔴

- 所有列表查询**必须分页**
- 小数据量用 `LIMIT/OFFSET`，大数据量用游标分页（`WHERE id > $lastID LIMIT`）
- 返回统一分页结构

```go
// ✅ 偏移分页
func (r *UserRepo) List(ctx context.Context, page, pageSize int) ([]User, int, error) {
    var total int
    db.QueryRowContext(ctx, "SELECT COUNT(*) FROM users").Scan(&total)

    rows, err := db.QueryContext(ctx,
        "SELECT * FROM users ORDER BY id LIMIT $1 OFFSET $2",
        pageSize, (page-1)*pageSize)
    ...
}

// ✅ 游标分页（大数据量，避免 OFFSET 大值性能问题）
func (r *UserRepo) ListCursor(ctx context.Context, cursor int64, limit int) ([]User, int64, error) {
    rows, err := db.QueryContext(ctx,
        "SELECT * FROM users WHERE id > $1 ORDER BY id LIMIT $2",
        cursor, limit+1)  // 多查一条判断是否有下一页
    ...
}

// ❌ 无分页全量返回
rows, _ := db.Query("SELECT * FROM users")  // 可能百万条
```

## 连接池配置 🔴

```go
db, err := sql.Open("postgres", dsn)
db.SetMaxOpenConns(25)               // 最大连接数
db.SetMaxIdleConns(10)               // 最大空闲连接
db.SetConnMaxLifetime(30 * time.Minute)  // 连接生命周期
db.SetConnMaxIdleTime(5 * time.Minute)   // 空闲超时回收
```

## 数据库迁移 🔴

- 使用 golang-migrate / atlas / goose 管理 schema
- **正向迁移不可回退**（forward-only），回退用新迁移修复
- CI 中自动执行迁移

```bash
# 创建迁移
migrate create -ext sql -dir migrations -seq add_cancel_reason

# 执行迁移（CI/CD）
migrate -path migrations -database "$DATABASE_URL" up
```

## 查询性能 🟡

- 所有 SQL 必须能命中索引（开发阶段跑 `EXPLAIN`）
- 用 `sqlx.In()` 处理 `IN (...)` 的切片参数展开
- 大数据集 INSERT 使用 `COPY` 或批量事务

```go
// ✅ sqlx 批量查询
query, args, _ := sqlx.In("SELECT * FROM users WHERE id IN (?)", ids)
rows, _ := db.QueryContext(ctx, db.Rebind(query), args...)

// ❌ 循环逐条插入
for _, user := range users {
    db.Exec("INSERT INTO users (name) VALUES ($1)", user.Name)  // 慢
}

// ✅ 批量 COPY 或事务批量 INSERT
tx, _ := db.Begin()
stmt, _ := tx.Prepare("INSERT INTO users (name) VALUES ($1)")
for _, user := range users {
    stmt.Exec(user.Name)
}
tx.Commit()
```

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 循环中逐条查询 | N+1 性能灾难 |
| 无分页全量查询 | 内存溢出 |
| `SELECT *`（查不需要的字段） | 浪费带宽 |
| 硬编码 `db, _ := sql.Open(...)` 无连接池配置 | 连接泄漏 |
| 迁移脚本手动执行 | 环境不一致 |
| 线上 `DROP TABLE` / `DROP COLUMN` | 数据丢失 |
