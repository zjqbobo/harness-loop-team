# Go 并发编程规范

## goroutine 生命周期 🔴

```go
// ✅ 用 context 控制 goroutine 生命周期
func worker(ctx context.Context, jobs <-chan Job) {
    for {
        select {
        case <-ctx.Done():
            log.Println("worker: 收到取消信号，退出")
            return
        case job, ok := <-jobs:
            if !ok {
                return
            }
            process(job)
        }
    }
}

// ❌ goroutine 无退出机制（泄漏）
func worker(jobs <-chan Job) {
    for job := range jobs {  // jobs 关闭前永不退出
        process(job)
    }
}
```

## context 传递规则 🔴

```go
// ✅ context 作为第一个参数，命名为 ctx
func GetUser(ctx context.Context, userID int) (*User, error) {
    ...
}

// ✅ 派生 context：超时控制
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()

// ✅ 派生 context：携带值（仅用于请求范围的元数据）
ctx = context.WithValue(ctx, "traceID", traceID)

// ❌ context 存储在 struct 中
type Service struct {
    ctx context.Context  // 禁止
}

// ❌ context 作为最后一个参数
func GetUser(userID int, ctx context.Context) { ... }
```

## channel 使用规范 🔴

```go
// ✅ 明确 channel 方向
func producer(out chan<- int) {  // 只写
    for i := 0; i < 10; i++ {
        out <- i
    }
    close(out)
}

func consumer(in <-chan int) {  // 只读
    for v := range in {
        fmt.Println(v)
    }
}

// ✅ 谁创建谁关闭
ch := make(chan int)
go func() {
    defer close(ch)
    ch <- 42
}()

// ❌ 接收方关闭 channel（panic）
ch := make(chan int)
go func() {
    close(ch)  // 发送方可能还在写
}()

// ✅ buffered channel：已知容量的场景
sem := make(chan struct{}, 10)  // 最多 10 个并发

// ✅ unbuffered channel：同步通信
done := make(chan struct{})
go func() {
    heavyWork()
    close(done)
}()
<-done  // 等待完成
```

## select 规范 🔴

```go
// ✅ 带超时的 select
select {
case result := <-resultCh:
    handleResult(result)
case <-time.After(5 * time.Second):
    return fmt.Errorf("操作超时")
case <-ctx.Done():
    return ctx.Err()
}

// ❌ 无超时的 select（可能永久阻塞）
select {
case result := <-resultCh:
    handleResult(result)
}
```

## sync 包使用 🟡

```go
// ✅ sync.Mutex：保护共享状态
type Counter struct {
    mu    sync.Mutex
    value int
}

func (c *Counter) Inc() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.value++
}

// ✅ sync.RWMutex：读多写少
type Cache struct {
    mu   sync.RWMutex
    data map[string]string
}

func (c *Cache) Get(key string) string {
    c.mu.RLock()
    defer c.mu.RUnlock()
    return c.data[key]
}

func (c *Cache) Set(key, value string) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.data[key] = value
}

// ✅ sync.Once：单例初始化
var (
    instance *Service
    once     sync.Once
)

func GetService() *Service {
    once.Do(func() {
        instance = &Service{...}
    })
    return instance
}

// ✅ sync.WaitGroup：等待一组 goroutine
var wg sync.WaitGroup
for i := 0; i < 10; i++ {
    wg.Add(1)
    go func(id int) {
        defer wg.Done()
        process(id)
    }(i)
}
wg.Wait()
```

## errgroup 🟡

```go
import "golang.org/x/sync/errgroup"

// ✅ errgroup：并发 + 错误传播
g, ctx := errgroup.WithContext(ctx)

g.Go(func() error {
    return fetchUserData(ctx, userID)
})
g.Go(func() error {
    return fetchOrderData(ctx, userID)
})

if err := g.Wait(); err != nil {
    log.Printf("并发任务失败: %v", err)
}
```

## 并发测试 🔴

```bash
# 必加 -race 标志
go test -race ./...
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| goroutine 无退出机制 | 泄漏，内存增长 | 传入 ctx 或 done channel |
| 接收方关闭 channel | panic | 发送方关闭 |
| select 无超时 | 永久阻塞 | 加 `time.After` 或 ctx.Done() |
| 在 goroutine 中直接使用循环变量 | 闭包捕获问题 | 传参 `go func(id int){}` 或 Go 1.22+ |
| `sync.Mutex` 值拷贝 | 锁失效 | 用指针或声明为 struct 字段 |
| 不跑 `go test -race` | 竞态条件漏检 | CI 必跑 |
