# TypeScript 数据库访问规范

## N+1 查询防护 🔴

- 使用 Prisma `include` / Drizzle `relations` 一次加载关联
- **禁止**在循环中逐条查询关联数据
- 批量查询用 `WHERE IN`，**禁止** for 循环逐条查

```typescript
// ✅ Prisma include 一次加载关联
const orders = await prisma.order.findMany({
  where: { userId },
  include: { items: true },
});

// ✅ Drizzle 批量查询
const users = await db.select().from(usersTable).where(inArray(usersTable.id, ids));

// ❌ 循环中逐条查询（N+1）
for (const order of orders) {
  const items = await prisma.item.findMany({ where: { orderId: order.id } });  // N 次查询！
}
```

## 分页规范 🔴

- 所有列表查询**必须分页**
- 小数据量用 `page`+`pageSize`（偏移分页），大数据量/实时数据用 `cursor`（游标分页）
- 统一分页响应结构：`{ items, total, page, pageSize }` 或 `{ items, nextCursor }`

```typescript
// ✅ 偏移分页
const [items, total] = await Promise.all([
  prisma.user.findMany({ skip: (page - 1) * pageSize, take: pageSize }),
  prisma.user.count(),
]);

// ✅ 游标分页（大数据量）
const items = await prisma.order.findMany({
  take: pageSize,
  cursor: cursor ? { id: cursor } : undefined,
  skip: cursor ? 1 : 0,  // 跳过游标本身
  orderBy: { id: "desc" },
});
const nextCursor = items.length === pageSize ? items[items.length - 1].id : null;

// ❌ 无分页全量返回
const users = await prisma.user.findMany();  // 内存溢出
```

## 连接池配置 🔴

- Prisma 默认连接数 = `physical_cores * 2 + 1`，Serverless 环境需调整为 1-3

```env
# Prisma connection limit
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=20&pool_timeout=10"
```

- 使用 `pgbouncer` 做 Serverless/Lambda 场景的连接管理（`pgbouncer=true`）

## 数据库迁移 🔴

- 使用 Prisma Migrate / Drizzle Kit / Knex 管理 schema
- **正向迁移不可回退**（forward-only），回退用新迁移修复
- 迁移文件提交到 Git，CI 中执行 `prisma migrate deploy`

```bash
# 开发环境：生成迁移
npx prisma migrate dev --name add_cancel_reason

# 生产环境：只应用不生成（CI/CD）
npx prisma migrate deploy
```

## 查询性能 🟡

- 开发阶段用 `prisma.$queryRaw` 跑 `EXPLAIN ANALYZE`
- ORM 自动生成的复杂关联查询怀疑性能时，用 raw SQL 替代并写注释说明原因
- **禁止** `SELECT *`，明确指定需要的字段（`select`）

```typescript
// ✅ 只查需要的字段
const users = await prisma.user.findMany({
  select: { id: true, name: true, email: true },
});

// ❌ 查全表所有字段
const users = await prisma.user.findMany();  // 包含 passwordHash 等大字段
```

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 循环中逐条查询 | N+1 性能灾难 |
| 无分页全量查询 | 内存溢出 |
| `SELECT *`（查不需要的字段） | 浪费带宽 |
| Prisma `findMany` 不加 `take` | 可能返回百万条 |
| Serverless 中用默认连接池 | 连接耗尽 |
| 迁移脚本手动执行（非 CI） | 环境不一致 |
