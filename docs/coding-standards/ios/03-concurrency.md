# iOS/Swift 并发规范

## async/await 🔴

```swift
// ✅ 用 Task 从同步上下文进入异步
struct TaskListView: View {
    @State var viewModel = TaskListViewModel()

    var body: some View {
        List(viewModel.tasks) { task in
            TaskRow(task: task)
        }
        .task {                              // SwiftUI 内置 async context
            await viewModel.loadTasks()
        }
        .refreshable {                       // 下拉刷新
            await viewModel.loadTasks()
        }
    }
}

// ❌ Task { } 忘记取消
struct ContentView: View {
    var body: some View {
        List { ... }
            .task { await loadData() }  // View 消失时自动取消 ✅
    }
}
```

## @MainActor 🔴

```swift
// ✅ @MainActor 标注 UI 相关代码
@MainActor
@Observable
final class TaskListViewModel {
    var tasks: [Task] = []
    var isLoading = false

    func loadTasks() async {
        isLoading = true
        defer { isLoading = false }
        tasks = await repository.fetchTasks()  // 自动回到 MainActor
    }
}

// ✅ 非 UI 代码不加 @MainActor
actor DataCache {
    private var storage: [String: Any] = [:]

    func set<T>(_ value: T, forKey key: String) {
        storage[key] = value
    }
}
```

## Actor 🔴

```swift
// ✅ Actor 保护共享可变状态
actor TaskCache {
    private var tasks: [String: Task] = [:]

    func get(_ id: String) -> Task? {
        tasks[id]
    }

    func set(_ task: Task) {
        tasks[task.id] = task
    }

    func clear() {
        tasks.removeAll()
    }
}
```

## Sendable 🔴

```swift
// ✅ struct/enum 自动 Sendable
struct Task: Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
}

// ✅ @unchecked Sendable（需自行保证线程安全）
final class ThreadSafeCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0

    var value: Int {
        lock.lock(); defer { lock.unlock() }
        return _value
    }
}
```

## Task 优先级 🟡

```swift
// ✅ 明确指定优先级
Task(priority: .userInitiated) {
    await viewModel.loadTasks()
}

Task(priority: .background) {
    await cache.cleanup()
}

// ❌ Task.detached（解绑 context，很少需要）
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `Task { }` 忘记取消（SwiftUI） | 内存泄漏 | 用 `.task { }` |
| 越界传非 Sendable 到 actor | 数据竞争 | 确认 Sendable |
| `@MainActor` 标注非 UI 代码 | 阻塞主线程 | 仅 UI 层用 |
| `Task.detached` 默认使用 | 丢失 context | `Task { }` |
| 在 `DispatchQueue` 中混用 async/await | 线程混乱 | 统一 async/await |
