# Java 并发编程规范

## 基本原则 🔴

- 优先使用不可变对象（`final` 字段 + 构造注入），避免共享可变状态
- 需要共享状态时，使用 `java.util.concurrent` 包下的工具类
- **禁止**在 Controller/Service 中持有可变的实例变量（Spring Bean 默认单例，存在线程安全问题）

## @Async 异步执行 🔴

```java
// ✅ 配置线程池
@Configuration
@EnableAsync
public class AsyncConfig {
    @Bean("taskExecutor")
    public Executor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(5);
        executor.setMaxPoolSize(10);
        executor.setQueueCapacity(100);
        executor.setRejectedExecutionHandler(new CallerRunsPolicy());  // 不丢任务
        executor.setThreadNamePrefix("async-");
        executor.initialize();
        return executor;
    }
}

// ✅ 指定线程池
@Async("taskExecutor")
public CompletableFuture<Result> processAsync(OrderDTO dto) {
    return CompletableFuture.completedFuture(doProcess(dto));
}

// ❌ 默认 SimpleAsyncTaskExecutor（每次新建线程，无上限）
@Async  // 不指定线程池，生产不可用
public void process() { ... }
```

## CompletableFuture 使用 🔴

```java
// ✅ 组合异步操作
CompletableFuture<UserDTO> userFuture = CompletableFuture.supplyAsync(() -> userService.getUser(id));
CompletableFuture<List<OrderDTO>> ordersFuture = CompletableFuture.supplyAsync(() -> orderService.listByUser(id));
CompletableFuture.allOf(userFuture, ordersFuture).join();
UserDTO user = userFuture.get();
List<OrderDTO> orders = ordersFuture.get();

// ✅ 异常处理
future.exceptionally(ex -> {
    log.error("异步任务失败", ex);
    return fallbackValue;
});

// ❌ future.get() 阻塞主线程无超时
future.get();  // 永远等待

// ✅ 带超时
future.get(5, TimeUnit.SECONDS);
```

## 并发集合选择 🟡

| 场景 | 使用 |
|------|------|
| 读多写少 | `ConcurrentHashMap` |
| 高并发写 | `ConcurrentHashMap` + 乐观锁 |
| 写多读少 | 考虑 `Collections.synchronizedMap()` + 同步块 |
| 阻塞队列 | `LinkedBlockingQueue` / `ArrayBlockingQueue` |
| 计数器 | `AtomicLong` / `LongAdder`（高并发用 Adder） |

## ThreadLocal 管理 🔴

- ThreadLocal 使用后**必须**在 `finally` 中 `remove()`
- 线程池场景下 ThreadLocal 不清理会导致内存泄漏和脏数据

```java
// ✅ 必须 finally remove
ThreadLocal<String> traceId = new ThreadLocal<>();
try {
    traceId.set(generateTraceId());
    doBusiness();
} finally {
    traceId.remove();  // 必须清理
}
```

## 分布式锁 🟡

- 优先数据库乐观锁（`version` 字段）解决并发更新
- 需要跨进程互斥时，用 Redis（Redisson）/ ZooKeeper 分布式锁
- **禁止**用 `synchronized` 做分布式场景的并发控制（只在单 JVM 内生效）

```java
// ✅ 乐观锁（version 字段）
@Update("UPDATE orders SET status = #{status}, version = version + 1 WHERE id = #{id} AND version = #{version}")
int updateWithOptimisticLock(Order order);  // 影响行数 = 0 表示版本冲突

// ✅ Redis 分布式锁
boolean locked = lock.tryLock(5, 30, TimeUnit.SECONDS);
try {
    if (locked) { doBusiness(); }
} finally {
    if (locked) lock.unlock();
}
```

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| Spring Bean 中持有可变实例变量 | 线程不安全 |
| `@Async` 不指定线程池 | 无限创建线程 |
| `synchronized` 做分布式并发控制 | 只在单 JVM 生效 |
| `future.get()` 无超时 | 线程永远阻塞 |
| ThreadLocal 不 `remove()` | 内存泄漏 |
| `HashMap` 在多线程下使用 | 死循环 CPU 100% |
