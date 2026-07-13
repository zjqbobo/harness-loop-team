# TypeScript 日志规范

## 日志框架 🔴

```typescript
// 服务端：pino（高性能结构化日志）
import pino from "pino";

const logger = pino({
  level: process.env.LOG_LEVEL || "info",
  transport: process.env.NODE_ENV === "development"
    ? { target: "pino-pretty", options: { colorize: true } }
    : undefined,
});

// 或 winston
import winston from "winston";

const logger = winston.createLogger({
  level: "info",
  format: winston.format.json(),
  transports: [new winston.transports.Console()],
});
```

## 日志级别 🔴

| 级别 | 场景 | 示例 |
|------|------|------|
| `trace` | 最详细调试 | 函数入参、中间变量 |
| `debug` | 开发调试 | SQL 语句、请求体 |
| `info` | 业务关键节点 | "用户登录成功"、"订单创建" |
| `warn` | 可恢复异常 | "缓存未命中"、"重试中" |
| `error` | 需要处理 | "支付接口超时"、"DB 连接失败" |
| `fatal` | 系统级告警 | "无法连接消息队列" |

## 结构化日志 🔴

```typescript
// ✅ 结构化 key=value
logger.info({ userId, action: "login", provider: "google" }, "用户登录成功");

// ❌ 字符串拼接（无法检索）
logger.info(`用户 ${userId} 从 ${ip} 登录成功`);

// ✅ 错误日志带堆栈
try {
  await callPaymentApi(order);
} catch (error) {
  logger.error({ orderId: order.id, err: error }, "支付接口调用失败");
}
```

## 请求追踪 🟡

```typescript
// middleware 注入 traceId
import { randomUUID } from "node:crypto";
import { AsyncLocalStorage } from "node:async_hooks";

const traceStorage = new AsyncLocalStorage<{ traceId: string }>();

function traceMiddleware(req: Request, res: Response, next: NextFunction): void {
  const traceId = (req.headers["x-trace-id"] as string) || randomUUID();
  traceStorage.run({ traceId }, () => next());
}

// 封装带 traceId 的 logger
function getLogger(): pino.Logger {
  const store = traceStorage.getStore();
  if (store) return logger.child({ traceId: store.traceId });
  return logger;
}
```

## 浏览器端 🔵

```typescript
// 生产环境禁止 console.log
// eslintrc: { rules: { "no-console": ["error", { allow: ["warn", "error"] }] } }

// 或桥接到服务端
function clientLog(level: string, message: string, data?: Record<string, unknown>): void {
  if (import.meta.env.PROD) {
    fetch("/api/logs", {
      method: "POST",
      body: JSON.stringify({ level, message, data }),
    });
  } else {
    console[level](message, data);
  }
}
```

## 敏感信息脱敏 🔴

```typescript
const SENSITIVE_KEYS = ["password", "token", "secret", "creditCard", "ssn"];

function sanitize(obj: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(obj)) {
    result[key] = SENSITIVE_KEYS.includes(key) ? "***REDACTED***" : value;
  }
  return result;
}
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `console.log` 留在生产代码 | 无级别、无结构化 | `logger.info()` |
| 日志中输出密码/Token | 安全合规 | 脱敏或跳过 |
| 无 traceId 的日志 | 请求无法追踪 | middleware 注入 |
| 循环内无节制日志 | 日志轰炸 | 频率控制 |
