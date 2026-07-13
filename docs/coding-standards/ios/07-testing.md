# iOS/Swift 测试规范

## 测试框架 🔴

```swift
// XCTest（标准框架）
import XCTest

// Swift Testing（iOS 18+ / Xcode 16+ 推荐）
import Testing
```

## XCTest 三段式 🔴

```swift
final class TaskListViewModelTests: XCTestCase {
    private var viewModel: TaskListViewModel!
    private var mockRepository: MockTaskRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockTaskRepository()
        viewModel = TaskListViewModel(repository: mockRepository)
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        super.tearDown()
    }

    func test_loadTasks_updatesTasksOnSuccess() async throws {
        // Arrange
        let expectedTasks = [Task(id: "1", title: "买菜"), Task(id: "2", title: "写报告")]
        mockRepository.fetchTasksResult = .success(expectedTasks)

        // Act
        await viewModel.loadTasks()

        // Assert
        XCTAssertEqual(viewModel.tasks, expectedTasks)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_loadTasks_setsErrorMessageOnFailure() async throws {
        // Arrange
        mockRepository.fetchTasksResult = .failure(.network("连接超时"))

        // Act
        await viewModel.loadTasks()

        // Assert
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.tasks.isEmpty)
    }
}
```

## Swift Testing（推荐新项目）🟡

```swift
import Testing
@testable import MyApp

struct TaskListViewModelTests {
    @Test func loadTasksUpdatesTasksOnSuccess() async throws {
        let mock = MockTaskRepository()
        mock.fetchTasksResult = .success([Task(id: "1", title: "测试")])
        let viewModel = await TaskListViewModel(repository: mock)

        await viewModel.loadTasks()

        let tasks = await viewModel.tasks
        #expect(tasks.count == 1)
        #expect(tasks.first?.title == "测试")
    }
}
```

## Mock 规范 🔴

```swift
// ✅ 协议驱动 Mock
final class MockTaskRepository: TaskRepository {
    var fetchTasksResult: Result<[Task], AppError> = .success([])
    var createTaskCalled = false
    var lastCreatedTitle: String?

    func fetchTasks() async throws -> [Task] {
        switch fetchTasksResult {
        case .success(let tasks): return tasks
        case .failure(let error): throw error
        }
    }

    func createTask(title: String) async throws -> Task {
        createTaskCalled = true
        lastCreatedTitle = title
        return Task(id: UUID().uuidString, title: title)
    }
}
```

## 覆盖率 🔴

| 指标 | 门禁 |
|------|------|
| 行覆盖率 | ≥ 80% |
| 未达标 | CI 阻断 |

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 连真实网络/数据库 | 慢、不稳定 |
| 测试间共享可变状态 | 顺序依赖 |
| 只写 happy path | 边界和异常必须覆盖 |
| 用 `sleep()` 等待异步 | 用 `await` / `expectation` |
