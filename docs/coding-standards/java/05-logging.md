# 日志打印规范

## 日志级别使用 🔴

| 级别 | 使用场景 | 是否带堆栈 | 示例 |
|------|---------|-----------|------|
| ERROR | 系统异常、影响主流程的失败 | 是 | `log.error("创建订单失败, orderId={}", orderId, e)` |
| WARN | 业务异常、可容忍的异常 | 否 | `log.warn("库存不足, productId={}, need={}, has={}", productId, need, has)` |
| INFO | 关键业务节点、接口调用结果 | 否 | `log.info("订单创建成功, orderId={}, amount={}", orderId, amount)` |
| DEBUG | 入参、出参、中间状态 | 否 | `log.debug("查询用户, userId={}", userId)` |

## 必须打印日志的位置 🔴

| 位置 | 级别 | 内容 |
|------|------|------|
| Service 方法入口 | DEBUG | 方法名 + 关键入参 |
| 关键业务操作前后 | INFO | 操作类型 + 业务标识 + 结果 |
| 异常捕获处 | ERROR/WARN | 异常描述 + 上下文 + 堆栈(ERROR) |
| 外部调用前后 | INFO | 目标 + 耗时 + 结果 |
| 条件分支选择 | DEBUG | 条件值 + 走了哪个分支 |

## 日志格式规范 🔴

```java
// ✅ 正确：使用占位符，键值对格式
log.info("订单创建成功, orderId={}, amount={}", orderId, amount);
log.error("创建订单失败, orderId={}", orderId, e);

// ❌ 错误：字符串拼接
log.info("订单创建成功, orderId=" + orderId);

// ❌ 错误：无业务上下文
log.error("创建失败", e);

// ❌ 错误：ERROR 不带堆栈
log.error("创建订单失败, orderId={}", orderId);  // 缺少异常对象 e
```

### 格式约定

- 使用 `{}` 占位符，禁止字符串拼接
- 键值对格式：`key=value`，逗号分隔
- 每条日志包含足够的业务上下文（订单ID、用户ID等），能定位到具体业务对象

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `System.out.println()` | 生产环境不可控，无级别、无格式 | 使用 `log.info/debug` |
| `e.printStackTrace()` | 输出到 stderr，不可控 | `log.error("描述", e)` |
| 日志中打印敏感信息 | 安全风险（密码、token、身份证） | 脱敏处理：`phone=138****1234` |
| 循环内打 INFO 日志 | 高频场景日志爆炸 | 循环内用 DEBUG，循环外汇总打 INFO |
| ERROR 日志不带异常对象 | 无法定位堆栈 | `log.error("描述", e)` 第二个参数传异常 |
| 日志信息无业务标识 | 无法定位具体问题 | 每条日志带业务 ID |

## 敏感信息脱敏 🟡

| 数据类型 | 脱敏规则 | 示例 |
|---------|---------|------|
| 手机号 | 保留前3后4 | `138****1234` |
| 身份证 | 保留前3后4 | `110***********1234` |
| 银行卡 | 保留后4位 | `************1234` |
| 密码/Token | 完全隐藏 | `******` |
| 邮箱 | 保留首字母和域名 | `t***@example.com` |

## 外部调用日志 🟡

```java
long start = System.currentTimeMillis();
try {
    Result result = externalService.call(request);
    long cost = System.currentTimeMillis() - start;
    log.info("调用外部服务成功, service={}, method={}, cost={}ms, code={}",
             "payment", "pay", cost, result.getCode());
} catch (Exception e) {
    long cost = System.currentTimeMillis() - start;
    log.error("调用外部服务失败, service={}, method={}, cost={}ms",
              "payment", "pay", cost, e);
}
```
