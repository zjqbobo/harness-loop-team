# 事务处理规范

## 基本原则 🔴

1. **@Transactional 只加在 Service 层**，Controller 和 DAO 层禁止加
2. **只读方法必须加 `readOnly = true`**，提升性能并防止误写
3. **默认回滚所有异常**：`rollbackFor = Exception.class`

```java
// 写操作
@Transactional(rollbackFor = Exception.class)
public void createOrder(CreateOrderDTO dto) { ... }

// 只读操作
@Transactional(readOnly = true)
public OrderDTO getOrder(Long orderId) { ... }
```

## 事务传播行为 🟡

| 传播行为 | 使用场景 | 说明 |
|---------|---------|------|
| `REQUIRED`（默认） | 大部分场景 | 有事务加入，无事务新建 |
| `REQUIRES_NEW` | 需要独立事务（如审计日志） | 始终新建事务，外层事务挂起 |
| `NOT_SUPPORTED` | 非事务操作（如查询+缓存） | 以非事务方式执行 |
| `NEVER` | 明确禁止事务的场景 | 存在事务则抛异常 |

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| 嵌套 @Transactional 调用同类方法 | Spring 代理失效，内层事务不生效 | 提取到另一个 Service |
| @Transactional 加在 private 方法 | 代理无法拦截，事务不生效 | 只加在 public 方法 |
| @Transactional 加在 Controller | 破坏分层，事务范围过大 | 只在 Service 层 |
| 事务方法中调用 RPC/HTTP | 外部调用不可回滚，导致数据不一致 | 先完成本地事务，再发消息或调用 |
| 长事务（>3秒） | 锁持有时间长，影响并发 | 拆分事务，非核心操作移出 |
| 事务中做文件 IO | IO 不可回滚 | 先完成事务，再写文件 |

## 事务边界设计 🟡

```
✅ 推荐的事务边界
┌─ Service 方法 ──────────────────────┐
│  1. 参数校验（事务外）               │
│  2. 开启事务                         │
│  3. 业务逻辑 + 数据库操作             │
│  4. 提交事务                         │
│  5. 发消息/调RPC/写文件（事务外）      │
└─────────────────────────────────────┘

❌ 错误的事务边界
┌─ Service 方法 ──────────────────────┐
│  1. 开启事务                         │
│  2. 调用外部 RPC ← 不可回滚！        │
│  3. 数据库操作                       │
│  4. 提交事务                         │
└─────────────────────────────────────┘
```

## 多数据源事务 🔵

- 跨数据源事务使用分布式事务框架（Seata 等）
- 优先考虑：本地消息表 > TCC > XA
- 单体应用避免多数据源，优先同库设计
