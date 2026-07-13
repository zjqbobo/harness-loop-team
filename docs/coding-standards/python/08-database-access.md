# Python 数据库访问规范

## N+1 查询防护 🔴

- 使用 SQLAlchemy `selectinload` / `joinedload` 或 Django `select_related` / `prefetch_related`
- **禁止**在循环中触发懒加载查询

```python
# ✅ SQLAlchemy: selectinload 一次加载关联
from sqlalchemy.orm import selectinload

stmt = select(Order).options(selectinload(Order.items)).where(Order.user_id == user_id)
orders = (await session.execute(stmt)).scalars().all()

# ✅ Django: select_related + prefetch_related
orders = Order.objects.filter(user_id=user_id).select_related("user").prefetch_related("items")

# ✅ 收集 ID 后批量 IN 查询
ids = [o.id for o in orders]
items = await session.execute(select(Item).where(Item.order_id.in_(ids)))

# ❌ 循环中逐条查询（N+1）
for order in orders:
    items = await session.execute(select(Item).where(Item.order_id == order.id))  # N 次查询！
```

## 分页规范 🔴

- 所有列表查询**必须分页**
- 小数据量用 `page`+`page_size`（OFFSET），大数据量用游标分页
- 返回统一分页结构

```python
# ✅ SQLAlchemy 偏移分页
def paginate(stmt, page: int, page_size: int) -> dict:
    total = await session.scalar(select(func.count()).select_from(stmt.subquery()))
    items = (await session.execute(stmt.offset((page - 1) * page_size).limit(page_size))).scalars().all()
    return {"items": items, "total": total, "page": page, "page_size": page_size}

# ✅ 游标分页（大数据量）
stmt = select(User).where(User.id > cursor).order_by(User.id).limit(page_size + 1)
results = (await session.execute(stmt)).scalars().all()
has_next = len(results) > page_size

# ❌ 无分页全量返回
users = await session.execute(select(User))  # 百万条全拉！
```

## 连接池配置 🔴

```python
# SQLAlchemy async (asyncpg)
engine = create_async_engine(
    settings.database_url,
    pool_size=20,                  # 连接池大小
    max_overflow=10,               # 溢出连接（pool_size 满时额外创建）
    pool_recycle=3600,             # 连接回收（1 小时）
    pool_pre_ping=True,            # 使用前检查连接有效性
    echo=False,                    # 生产必须关闭
)

# Django
DATABASES = {
    "default": {
        "CONN_MAX_AGE": 600,    # 持久连接 10 分钟
        "CONN_HEALTH_CHECKS": True,
    }
}
```

## 数据库迁移 🔴

- 使用 Alembic / Django Migrations
- **正向迁移不可回退**（forward-only）
- 迁移文件提交 Git，CI 执行 `alembic upgrade head`

```bash
# 生成迁移
alembic revision --autogenerate -m "add_cancel_reason"

# 执行迁移（CI/CD）
alembic upgrade head
```

## 查询性能 🟡

- 开发阶段在 SQLAlchemy 设置 `echo=True` 观察生成的 SQL
- `select()` 明确指定列（`select(User.id, User.name)`），**禁止** `select(User)` 查全字段
- SQLAlchemy 2.0+ 使用 `select()` 风格（非 `Query` 风格）

```python
# ✅ 只查需要的字段
stmt = select(User.id, User.name, User.email).where(User.is_active == True)

# ❌ 查全所有字段
users = await session.execute(select(User))  # 包含 password_hash 等大字段
```

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 循环中触发懒加载查询 | N+1 性能灾难 |
| 无分页全量查询 | 内存溢出 |
| `select(User)` 不指定字段 | 浪费带宽 |
| 同步 ORM 在 async 路由中 | 阻塞事件循环 |
| 迁移脚本手动执行 | 环境不一致 |
| `echo=True` 留在生产配置 | 日志轰炸 |
