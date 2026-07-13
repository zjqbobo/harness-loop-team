# iOS/Swift 数据持久化规范

## SwiftData（iOS 17+ 推荐）🔴

```swift
// ✅ @Model 实体
import SwiftData

@Model
final class Task {
    @Attribute(.unique) var id: String = UUID().uuidString
    var title: String
    var isCompleted: Bool = false
    var createdAt: Date = Date()

    @Relationship(inverse: \Project.tasks) var project: Project?

    init(title: String) {
        self.title = title
    }
}

// ✅ @ModelActor 线程隔离的数据操作
@ModelActor
actor TaskRepository {
    func fetchAll() throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    func create(title: String) throws -> Task {
        let task = Task(title: title)
        modelContext.insert(task)
        try modelContext.save()
        return task
    }

    func delete(_ task: Task) throws {
        modelContext.delete(task)
        try modelContext.save()
    }
}
```

## Core Data（兼容旧版）🟡

```swift
// ✅ NSPersistentContainer 封装
final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "AppModel")
        container.loadPersistentStores { _, error in
            if let error { fatalError("CoreData 加载失败: \(error)") }
        }
    }

    var viewContext: NSManagedObjectContext { container.viewContext }

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
```

## 数据迁移 🔴

```swift
// SwiftData — 自动轻量迁移（VersionedSchema）
enum TaskSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [Task.self]

    @Model final class Task {
        var title: String
        var isCompleted: Bool = false
    }
}

// Core Data — 轻量迁移
container.persistentStoreDescriptions.first?.shouldMigrateStoreAutomatically = true
container.persistentStoreDescriptions.first?.shouldInferMappingModelAutomatically = true
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| 在主线程执行 Core Data 重操作 | 卡 UI | `@ModelActor` / `performBackgroundTask` |
| 跨线程传递 NSManagedObject | 线程不安全 | 传递 objectID 或转换 DTO |
| 不使用版本迁移 | 数据丢失 | VersionedSchema / Mapping Model |
| 在 SwiftUI View 中直接写 modelContext.save() | 职责混乱 | Repository 封装 |
