# Java/Spring 数据库访问规范

## N+1 查询防护 🔴

- 关联查询使用 `JOIN FETCH` / `@EntityGraph` 或 MyBatis 的 `LEFT JOIN` 一次加载
- **禁止**在循环中访问懒加载关联属性触发多次查询
- 集合查询必须带 `IN` 条件，**禁止** for 循环逐条查

```java
// ✅ JPA JOIN FETCH 一次加载关联
@Query("SELECT o FROM Order o JOIN FETCH o.items WHERE o.userId = :userId")
List<Order> findByUserIdWithItems(@Param("userId") Long userId);

// ✅ MyBatis 批量查询
@Select("SELECT * FROM users WHERE id IN <foreach collection='ids' item='id' open='(' close=')' separator=','>#{id}</foreach>")
List<User> findByIds(@Param("ids") List<Long> ids);

// ❌ 循环中逐条查询（N+1）
for (Order order : orders) {
    List<Item> items = itemMapper.findByOrderId(order.getId());  // N 次查询！
}

// ❌ JPA 懒加载触发 N+1
orders.forEach(order -> order.getItems().size());  // 每次触发一次 SQL
```

## 分页规范 🔴

- 所有列表查询**必须分页**，不允许无限制返回全量数据
- 分页参数命名统一：`page`（从 1 开始，用 `Pageable` 或 PageHelper）
- 返回统一分页结构：`{ items, total, page, pageSize }`

```java
// ✅ MyBatis PageHelper 分页
public PageInfo<UserDTO> listUsers(int page, int pageSize) {
    PageHelper.startPage(page, pageSize);
    List<User> users = userMapper.findAll();
    return PageInfo.of(userConverter.toDTOList(users));
}

// ✅ JPA Pageable
public Page<UserDTO> listUsers(Pageable pageable) {
    return userRepository.findAll(pageable).map(userConverter::toDTO);
}

// ❌ 无分页全量返回
List<User> users = userMapper.findAll();  // 10 万条全返回！
```

## 连接池配置 🔴

- 生产环境必须显式配置连接池参数

```yaml
# HikariCP (Spring Boot 默认)
spring.datasource.hikari:
  maximum-pool-size: 20          # 根据数据库 max_connections / 实例数计算
  minimum-idle: 5
  connection-timeout: 3000       # 3 秒超时（不挂起）
  idle-timeout: 600000           # 10 分钟空闲回收
  max-lifetime: 1800000          # 30 分钟生命周期
```

## 数据库迁移 🔴

- 使用 Flyway 或 Liquibase 管理 schema 变更
- **正向迁移不可回退**（禁止写 down/undo 脚本，用 forward-only fix）
- 迁移脚本命名：`V{YYYYMMDDHHmmss}__{description}.sql`

```sql
-- ✅ 增量迁移，只加字段不删字段
ALTER TABLE orders ADD COLUMN cancel_reason VARCHAR(255);

-- ❌ 删除字段的迁移（先标记 deprecated，下一版本再删）
ALTER TABLE orders DROP COLUMN old_field;
```

## 索引策略 🟡

- 所有 WHERE/JOIN/ORDER BY 字段必须有对应索引
- 复合索引遵循最左前缀
- 对线上大表（> 100 万行）加索引前评估：online DDL（pt-online-schema-change）
- 每个查询必须命中索引，全表扫描**禁止**出现在生产 SQL 中

## 大批量写入 🟡

- 批量 INSERT 使用 `batch_size` 分批（每批 500-1000 条），禁止单条循环插入
- MyBatis: `INSERT INTO ... VALUES <foreach collection="list" separator=",">`
- JPA: `saveAll()` + `spring.jpa.properties.hibernate.jdbc.batch_size=500`

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 循环中逐条查询 | N+1 性能灾难 |
| 无分页全量查询 | 内存溢出 |
| SELECT *（查询不需要的字段） | 浪费带宽和内存 |
| 查询后 N+1 关联加载 | 数据库过载 |
| 生产环境用 `spring.jpa.hibernate.ddl-auto=create-drop` | 数据全部丢失 |
| SQL 全表扫描（EXPLAIN type=ALL） | 生产不可接受 |
| 单条循环 INSERT | 写入性能差 100x |
| 在事务中做 HTTP/RPC 调用（见 03-transaction.md） | 长事务 |
