# iOS/Swift 依赖注入规范

## 构造函数注入 🔴

```swift
// ✅ 构造函数注入（推荐）
final class TaskListViewModel {
    private let repository: TaskRepository
    private let analytics: AnalyticsTracker

    init(repository: TaskRepository, analytics: AnalyticsTracker) {
        self.repository = repository
        self.analytics = analytics
    }
}

// ✅ 协议驱动
protocol TaskRepository {
    func fetchTasks() async throws -> [Task]
    func createTask(_ task: Task) async throws
}

final class TaskRepositoryImpl: TaskRepository {
    private let apiClient: APIClient
    private let database: LocalDatabase

    init(apiClient: APIClient, database: LocalDatabase) {
        self.apiClient = apiClient
        self.database = database
    }
}
```

## SwiftUI 注入方式 🟡

```swift
// ✅ @Environment — 跨多层传递
struct TaskListView: View {
    @Environment(\.taskRepository) private var repository

    var body: some View { ... }
}

// 注册
struct TaskRepositoryKey: EnvironmentKey {
    static let defaultValue: TaskRepository = TaskRepositoryImpl(apiClient: liveAPIClient, database: liveDatabase)
}

extension EnvironmentValues {
    var taskRepository: TaskRepository {
        get { self[TaskRepositoryKey.self] }
        set { self[TaskRepositoryKey.self] = newValue }
    }
}

// ✅ @EnvironmentObject — ViewModel 传递（已逐步被 @Observable + @Environment 替代）
```

## DI 容器 🟡

```swift
// ✅ 简单容器（无需 Swinject 等第三方）
final class DIContainer {
    static let shared = DIContainer()

    private init() {}

    func makeAPIClient() -> APIClient { APIClient(baseURL: "https://api.example.com") }
    func makeDatabase() -> LocalDatabase { LocalDatabase() }
    func makeTaskRepository() -> TaskRepository {
        TaskRepositoryImpl(apiClient: makeAPIClient(), database: makeDatabase())
    }
    func makeTaskListViewModel() -> TaskListViewModel {
        TaskListViewModel(repository: makeTaskRepository(), analytics: AnalyticsTracker.shared)
    }
}
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| 全局单例容器（Service Locator） | 依赖隐蔽 | 构造函数注入 |
| 在 View 中 `DIContainer.shared.resolve()` | 规避注入 | 通过 `@Environment` / 构造函数 |
| ViewModel 持有 View 引用 | 循环引用/泄漏 | View 持有 ViewModel |
| 使用第三方重型 DI（Swinject） | 不必要的复杂度 | 手写容器 + 构造函数注入 |
