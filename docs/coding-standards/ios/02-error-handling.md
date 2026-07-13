# iOS/Swift 错误处理规范

## 错误建模 🔴

```swift
// ✅ Error enum 定义可预见的错误
enum AppError: LocalizedError {
    case network(String)
    case notFound(String)
    case validation(String)
    case unauthorized
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .network(let msg): return "网络错误: \(msg)"
        case .notFound(let msg): return "未找到: \(msg)"
        case .validation(let msg): return "校验失败: \(msg)"
        case .unauthorized: return "请先登录"
        case .unknown(let msg): return "未知错误: \(msg)"
        }
    }

    var code: String {
        switch self {
        case .network: return "NETWORK_ERROR"
        case .notFound: return "NOT_FOUND"
        case .validation: return "VALIDATION_ERROR"
        case .unauthorized: return "UNAUTHORIZED"
        case .unknown: return "UNKNOWN"
        }
    }
}

// ✅ throws 函数 + do/catch
func fetchTasks() async throws -> [Task] {
    do {
        let data = try await apiClient.get(path: "/tasks")
        return try JSONDecoder().decode([TaskDTO].self, from: data).map { $0.toDomain() }
    } catch let error as DecodingError {
        throw AppError.unknown("数据解析失败: \(error)")
    } catch let error as URLError {
        throw AppError.network(error.localizedDescription)
    }
}
```

## try? / try! 规则 🔴

```swift
// ❌ try? 吞错（除非明确忽略错误）
let data = try? JSONEncoder().encode(model)  // 可能静默失败

// ✅ try? 仅在已知不会失败或错误无意义时
let defaults = UserDefaults.standard
let count = (try? defaults.getInt(forKey: "count")) ?? 0

// ❌ try! 禁止——crash
let data = try! JSONEncoder().encode(model)

// ✅ 使用 do/catch 代替
do {
    let data = try JSONEncoder().encode(model)
} catch {
    logger.error("编码失败: \(error)")
}
```

## Result 类型 🟡

```swift
// ✅ 简洁异步操作用 Result
func loadUser(id: String) async -> Result<User, AppError> {
    do {
        let user = try await repository.fetchUser(id: id)
        return .success(user)
    } catch {
        return .failure(error as? AppError ?? .unknown(error.localizedDescription))
    }
}

// 使用点
switch await loadUser(id: "1") {
case .success(let user):
    // handle user
case .failure(let error):
    // handle error
}
```

## ViewModel 错误处理 🔴

```swift
@Observable
final class TaskListViewModel {
    var tasks: [Task] = []
    var errorMessage: String?
    var isLoading = false

    func loadTasks() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            tasks = try await repository.fetchTasks()
        } catch let error as AppError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "加载失败"
        }
    }
}
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `try!` | 强制解包 crash | `do/catch` |
| `try?` 忽视所有错误 | 静默失败 | `do/catch` + 明确处理 |
| 用 error 控制业务流程 | 语义混乱 | Result / enum |
| catch 块为空 | 静默失败 | 至少记录日志 |
