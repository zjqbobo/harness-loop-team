# TypeScript/Node.js 并发与异步规范

## 事件循环原则 🔴

- 禁止阻塞事件循环：CPU 密集型任务用 Worker Threads，**禁止**同步循环处理大数据
- `Promise` 链不要有未捕获的 reject（`unhandledRejection` 会导致进程崩溃）

```typescript
// ✅ 异步 I/O（非阻塞）
const users = await prisma.user.findMany();

// ❌ 同步阻塞（JSON.parse 大文件、crypto 同步方法、fs.readFileSync 大文件）
const data = fs.readFileSync("/path/to/huge/file.json");  // 阻塞事件循环
const hash = crypto.createHash("sha256").update(data).digest("hex");  // 阻塞

// ✅ 大文件异步流处理
const stream = fs.createReadStream("/path/to/huge/file.json");
```

## Promise 使用规范 🔴

```typescript
// ✅ async/await（可读性强）
async function processOrder(id: number): Promise<Order> {
  const order = await orderService.getById(id);
  const user = await userService.getById(order.userId);
  return { ...order, user };
}

// ✅ 并行 Promise（无依赖）
const [order, user] = await Promise.all([
  orderService.getById(id),
  userService.getById(userId),
]);

// ✅ Promise 兜底 + 超时
const result = await Promise.race([
  fetchWithTimeout(url, 5000),
  timeout(5000, "请求超时"),
]);

// ❌ 串行 await 无依赖的调用
const order = await orderService.getById(id);    // 等 200ms
const user = await userService.getById(userId);  // 再等 200ms
// 总耗时 400ms（改为 Promise.all 只需 200ms）

// ❌ 未捕获的 reject
async function bad() {
  doAsync();  // 没有 await，reject 无人处理 → unhandledRejection
}

// ✅ 全局兜底
process.on("unhandledRejection", (reason) => {
  logger.error("Unhandled Rejection:", reason);
});
```

## Worker Threads 🟡

CPU 密集型（加密、图像处理、大数据序列化）移到 Worker Thread：

```typescript
import { Worker } from "worker_threads";

const worker = new Worker("./heavy-task.js", { workerData: { input } });
worker.on("message", (result) => resolve(result));
worker.on("error", reject);
```

## 并发限制 🟡

同时对同一资源的并发请求数需控制：

```typescript
import pLimit from "p-limit";

// ✅ 限制并发数为 5
const limit = pLimit(5);
const results = await Promise.all(
  urls.map((url) => limit(() => fetch(url)))
);

// ❌ 无限制并发
const results = await Promise.all(urls.map((url) => fetch(url)));  // 1000 并发打崩 API
```

## 竞态条件防护 🔴

```typescript
// ✅ AbortController 取消过期请求
const controller = new AbortController();
const timeoutId = setTimeout(() => controller.abort(), 5000);
try {
  const res = await fetch(url, { signal: controller.signal });
} finally {
  clearTimeout(timeoutId);
}

// ✅ 防重复提交
let isSubmitting = false;
async function submit() {
  if (isSubmitting) return;
  isSubmitting = true;
  try {
    await doSubmit();
  } finally {
    isSubmitting = false;
  }
}
```

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| `fs.readFileSync` / `crypto.*Sync` 在请求路径中 | 阻塞事件循环 |
| 串行 await 无依赖的异步调用 | 性能浪费 |
| `Promise` 链无全局 `unhandledRejection` 处理 | 进程崩溃 |
| 无限制并发（`Promise.all` 对 1000+ 项） | 资源耗尽 |
| 不设置请求超时/AbortController | 资源泄漏 |
