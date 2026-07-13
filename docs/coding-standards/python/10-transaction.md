# Python 事务处理规范

## 基本原则 🔴

- 涉及多个表的写操作**必须**在事务中执行
- 事务边界在 Service 层

## SQLAlchemy 事务 🔴

```python
# ✅ SQLAlchemy async 事务
async def create_order(session: AsyncSession, req: CreateOrderReq) -> OrderDTO:
    async with session.begin():  # 上下文管理器自动 commit/rollback
        # 1. 扣库存
        product = await session.get(Product, req.product_id, with_for_update=True)  # 行锁
        if product.stock < req.quantity:
            raise InsufficientStockError()
        product.stock -= req.quantity

        # 2. 创建订单
        order = Order(user_id=req.user_id, total_amount=req.total_amount, ...)
        session.add(order)
        await session.flush()  # 获取 order.id

        # 3. 记流水
        session.add(OrderLog(order_id=order.id, action="created"))

    # session.begin() 退出时自动 commit（或异常时 rollback）
    await session.refresh(order)
    return order_converter.to_dto(order)

# ✅ 手动管理事务
async def create_order_manual(session: AsyncSession, req: CreateOrderReq) -> OrderDTO:
    async with session.begin_nested():  # savepoint（嵌套事务）
        ...
```

## Django 事务 🔴

```python
from django.db import transaction

# ✅ 装饰器
@transaction.atomic
def create_order(req: CreateOrderReq) -> Order:
    product = Product.objects.select_for_update().get(id=req.product_id)
    if product.stock < req.quantity:
        raise InsufficientStockError()
    product.stock -= req.quantity
    product.save()
    order = Order.objects.create(user_id=req.user_id, ...)
    OrderLog.objects.create(order=order, action="created")
    return order

# ✅ 上下文管理器
with transaction.atomic():
    ...
```

## 事务边界 🔴

```
✅ 推荐事务边界
┌─ Service 方法 ────────────────────┐
│  1. 参数校验（事务外）              │
│  2. session.begin() / atomic()    │
│  3. 数据库操作                      │
│  4. commit / 退出上下文             │
│  5. 发消息/发邮件（事务外）           │
└───────────────────────────────────┘
```

## 行级锁与并发控制 🟡

```python
# ✅ SELECT ... FOR UPDATE（扣库存等关键操作）
product = await session.get(Product, product_id, with_for_update=True)

# ✅ SQLAlchemy 2.0 版本号乐观锁
class Order(Base):
    version: Mapped[int] = mapped_column(default=1)
    __mapper_args__ = {"version_id_col": version}

# 更新时自动检查 version，冲突抛 StaleDataError
```

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 关联写入不用事务 | 数据不一致 |
| 事务中调外部 HTTP/gRPC | 不可回滚 |
| 长事务（>3 秒） | 锁持有过长 |
| async session 中调用同步 ORM | 阻塞事件循环 |
| 在 api 层管理事务 | 越层 |
| `autocommit=True` 模式 | 事务行为不可控 |
