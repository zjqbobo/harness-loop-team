# 幂等性设计规范

> 适用：所有后端技术栈（Java/TypeScript/Go/Python/.NET）

## 什么是幂等 🔴

同一操作执行一次和执行多次，**结果相同、副作用相同**。

- `GET /api/users/1` — 天然幂等（读操作）
- `DELETE /api/users/1` — 天然幂等（第二次调用返回 404，但状态一致）
- `POST /api/orders` — **不幂等**（重复调用创建多条订单）
- `PUT /api/users/1` — 天然幂等（全量更新）

## 哪些接口必须做幂等 🔴

| 接口类型 | 风险 | 要求 |
|---------|------|------|
| 支付/退款 | 重复扣款 | 必须幂等 |
| 订单创建 | 重复下单 | 必须幂等 |
| 发短信/邮件 | 重复发送 | 必须幂等 |
| 账户操作（充值/提现） | 金额错误 | 必须幂等 |
| 外部回调/Webhook | 第三方重试 | 必须幂等 |
| 消息队列消费 | MQ 重投 | 必须幂等 |

## 幂等实现方案 🔴

### 方案一：幂等键（推荐，通用性最强）

客户端生成唯一 `Idempotency-Key`，服务端缓存处理结果：

```
流程：
  1. 客户端请求带 Idempotency-Key 头
  2. 服务端查 Redis/DB 是否已处理过该 key
  3. 已处理 → 直接返回缓存的结果
  4. 未处理 → 执行业务 → 缓存结果 → 返回
```

```java
// ✅ 幂等键模式
@PostMapping("/api/orders")
public Result<OrderVO> createOrder(
    @RequestHeader("Idempotency-Key") String idempotencyKey,
    @RequestBody CreateOrderDTO dto) {

    // 1. 检查是否已处理
    String cacheKey = "idempotent:" + idempotencyKey;
    String cachedResult = redis.get(cacheKey);
    if (cachedResult != null) {
        return Result.ok(JSON.parse(cachedResult, OrderVO.class));  // 返回缓存结果
    }

    // 2. 执行业务
    OrderVO result = orderService.createOrder(dto);

    // 3. 缓存结果（TTL 24h，确保客户端重试窗口内可用）
    redis.set(cacheKey, JSON.toJSONString(result), Duration.ofHours(24));

    return Result.ok(result);
}
```

```typescript
// ✅ Node.js 幂等键中间件
export function idempotencyMiddleware() {
  return async (req: Request, res: Response, next: NextFunction) => {
    const key = req.headers["idempotency-key"] as string;
    if (!key) return next();  // GET 不需要

    const cached = await redis.get(`idempotent:${key}`);
    if (cached) return res.json(JSON.parse(cached));

    // 拦截 res.json，缓存响应
    const originalJson = res.json.bind(res);
    res.json = (body: any) => {
      redis.set(`idempotent:${key}`, JSON.stringify(body), "EX", 86400);
      return originalJson(body);
    };
    next();
  };
}
```

### 方案二：数据库唯一约束

适用于创建类操作（如订单、用户），用业务唯一键防重：

```sql
ALTER TABLE orders ADD UNIQUE INDEX uk_order_no (order_no);
```

```java
// 插入重复时捕获异常，返回已有记录
try {
    orderRepo.insert(order);
} catch (DuplicateKeyException e) {
    return orderRepo.findByOrderNo(order.getOrderNo());
}
```

### 方案三：状态机

适用于有明确状态流转的操作：

```
待支付 → 已支付 → 已发货 → 已完成

重复"支付"请求：
  if (order.status == "已支付") return order;  // 已处理，直接返回
```

## 幂等键规范 🔴

| 规则 | 说明 |
|------|------|
| 客户端生成 | UUID v4，每次重试用**相同** key |
| 请求头传递 | `Idempotency-Key: <uuid>` |
| 服务端校验 | 幂等键唯一性（同一用户 + 同一操作类型） |
| 缓存 TTL | ≥ 24h（覆盖客户端重试窗口） |
| 幂等键粒度 | `{userId}:{operation}:{idempotencyKey}` 防跨用户冲突 |

## MQ 消费幂等 🔴

消息队列天生不保证 exactly-once，消费者必须自己处理：

```java
// ✅ 消息 ID 去重
@RabbitListener(queues = "order.paid")
public void handleOrderPaid(Message msg) {
    String msgId = msg.getMessageProperties().getMessageId();
    if (!redis.setNX("msg:" + msgId, "1", Duration.ofHours(24))) {
        return;  // 已处理过，跳过
    }
    orderService.confirmPayment(parseBody(msg));
}
```

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 支付/退款接口不实现幂等 | 重复扣款 |
| 幂等键仅靠客户端约束 | 恶意/故障客户端可绕过 |
| 幂等缓存 TTL 过短（<1h） | 客户端正常重试窗口内失效 |
| 用订单号直接防重（不用唯一索引） | SELECT + INSERT 竞态仍可能重复 |
