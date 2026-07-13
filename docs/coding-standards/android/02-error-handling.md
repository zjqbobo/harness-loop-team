# Android/Kotlin 错误处理规范

## 核心原则 🔴

避免异常作为控制流，用 sealed class + Result 类型建模可预见的错误。

## sealed class 错误建模 🔴

```kotlin
// ✅ sealed class 表示有限错误状态
sealed class DataResult<out T> {
    data class Success<T>(val data: T) : DataResult<T>()
    data class Error(val code: String, val message: String) : DataResult<Nothing>()
    data object Loading : DataResult<Nothing>()
}

// Repository 中使用
class TaskRepository(private val api: TaskApi, private val dao: TaskDao) {
    fun getTasks(): Flow<DataResult<List<Task>>> = flow {
        emit(DataResult.Loading)
        try {
            val local = dao.getAll().first()
            if (local.isNotEmpty()) emit(DataResult.Success(local))
            val remote = api.fetchTasks()
            dao.insertAll(remote)
            emit(DataResult.Success(remote))
        } catch (e: IOException) {
            emit(DataResult.Error("NETWORK_ERROR", "网络连接失败"))
        } catch (e: Exception) {
            emit(DataResult.Error("UNKNOWN", e.message ?: "未知错误"))
        }
    }
}

// ❌ 用异常控制流程（禁止）
fun validateEmail(email: String): Boolean {
    return try {
        Patterns.EMAIL_ADDRESS.matcher(email).matches()
    } catch (e: Exception) {
        false  // 异常控制流
    }
}
```

## ViewModel One-Shot 事件 🔴

```kotlin
// ✅ Channel 发送一次性事件（SnackBar/导航）
class TaskViewModel(
    private val repository: TaskRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(TaskUiState())
    val uiState: StateFlow<TaskUiState> = _uiState.asStateFlow()

    private val _events = Channel<TaskEvent>(Channel.BUFFERED)
    val events: Flow<TaskEvent> = _events.receiveAsFlow()

    fun deleteTask(id: String) {
        viewModelScope.launch {
            repository.getTasks()
                .catch { e -> _events.send(TaskEvent.ShowError("删除失败: ${e.message}")) }
                .collect { result ->
                    when (result) {
                        is DataResult.Success -> _uiState.update { it.copy(tasks = result.data) }
                        is DataResult.Error -> _events.send(TaskEvent.ShowError(result.message))
                        is DataResult.Loading -> _uiState.update { it.copy(isLoading = true) }
                    }
                }
        }
    }
}

sealed class TaskEvent {
    data class ShowError(val message: String) : TaskEvent()
    data class NavigateTo(val route: String) : TaskEvent()
}
```

## 网络/IO 异常处理 🔴

```kotlin
// ✅ 分类处理网络异常
suspend fun <T> safeApiCall(call: suspend () -> T): DataResult<T> {
    return try {
        DataResult.Success(call())
    } catch (e: HttpException) {
        DataResult.Error("HTTP_${e.code()}", "服务器错误 (${e.code()})")
    } catch (e: IOException) {
        DataResult.Error("NETWORK_ERROR", "网络连接失败，请检查网络")
    } catch (e: Exception) {
        DataResult.Error("UNKNOWN", e.message ?: "未知错误")
    }
}
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `try/catch` 控制业务流程 | 性能差、语义混乱 | sealed class / Result |
| `throw RuntimeException` 到 UI 层 | crash | sealed class 包装 |
| 空 catch 块 | 静默失败 | 至少记录日志 |
| 在 Composable 中 try/catch | Composable 不应处理异常 | ViewModel 处理 |
