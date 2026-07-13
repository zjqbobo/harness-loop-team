# TypeScript 事务处理规范

## 基本原则 🔴

- 涉及多个表的写操作**必须**在事务中执行
- 事务边界在 Service 层，禁止在 Controller/Consumer 中直接控制事务

## Prisma 事务 🔴

```typescript
// ✅ 交互式事务（推荐，支持依赖注入）
const [order] = await prisma.$transaction(async (tx) => {
  // 1. 扣库存
  const product = await tx.product.update({
    where: { id: productId },
    data: { stock: { decrement: quantity } },
  });
  if (product.stock < 0) throw new InsufficientStockError();

  // 2. 创建订单
  const order = await tx.order.create({
    data: { userId, totalAmount, items: { create: items } },
  });

  // 3. 记录流水
  await tx.orderLog.create({ data: { orderId: order.id, action: "created" } });

  return [order];
});

// ✅ 批量事务
await prisma.$transaction(
  users.map((u) => prisma.user.update({ where: { id: u.id }, data: { status: u.status } }))
);

// ❌ 无事务的关联写入
const order = await prisma.order.create({ data: { ... } });
const log = await prisma.orderLog.create({ data: { ... } });  // order 创建成功，log 可能失败
```

## Drizzle/TypeORM 事务 🟡

```typescript
// ✅ Drizzle 事务
await db.transaction(async (tx) => {
  await tx.update(products).set({ stock: sql`stock - ${quantity}` }).where(eq(products.id, id));
  await tx.insert(orders).values({ ... });
});

// ✅ TypeORM 事务
await dataSource.transaction(async (manager) => {
  await manager.save(order);
  await manager.save(orderLog);
});
```

## 事务边界 🔴

```
✅ 推荐事务边界
┌─ Service 方法 ────────────────────────┐
│  1. 参数校验（事务外）                  │
│  2. 开启事务                            │
│  3. 数据库操作（扣库存 → 建订单 → 记流水）│
│  4. 提交事务                            │
│  5. 发消息/发邮件（事务外）               │
└────────────────────────────────────────┘
```

- 事务中**禁止**：发 HTTP 请求、文件 I/O、邮件/短信发送
- `$transaction` 超时设置（避免长事务锁表）

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 关联写入不用事务 | 数据不一致 |
| 事务中调外部 API | 不可回滚 |
| 长事务（>3 秒） | 锁表 |
| Controller 中控制事务 | 越层 |
