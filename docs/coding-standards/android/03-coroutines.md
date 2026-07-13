# Android/Kotlin 协程与并发规范

## 协程作用域 🔴

```kotlin
// ✅ ViewModel 用 viewModelScope
class TaskViewModel : ViewModel() {
    fun loadTasks() {
        viewModelScope.launch {
            repository.getTasks().collect { ... }
        }
    }
}

// ✅ Composable 用 LaunchedEffect / rememberCoroutineScope
@Composable
fun TaskScreen(viewModel: TaskViewModel) {
    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        viewModel.loadTasks()
    }

    Button(onClick = { scope.launch { viewModel.refresh() } }) {
        Text("刷新")
    }
}

// ❌ GlobalScope（禁止——无生命周期绑定，泄漏）
GlobalScope.launch { ... }

// ❌ 在 Activity/Fragment 中手动 new CoroutineScope 不 cancel
```

## Dispatchers 规则 🔴

| Dispatcher | 使用场景 |
|---|---|
| `Dispatchers.Main` | UI 操作、StateFlow 更新（默认） |
| `Dispatchers.IO` | 网络请求、文件读写、数据库操作 |
| `Dispatchers.Default` | CPU 密集型计算、数据转换 |
| `Dispatchers.Unconfined` | 仅在测试中使用，**生产代码禁止** |

```kotlin
// ✅ withContext 切换调度器
suspend fun fetchAndSave() {
    return withContext(Dispatchers.IO) {
        val data = api.fetch()
        dao.insertAll(data)
        data
    }
}

// ❌ 在 IO 线程更新 UI
launch(Dispatchers.IO) {
    _state.value = newState  // 非主线程更新 StateFlow 可能 crash
}
```

## Flow 规范 🔴

```kotlin
// ✅ StateFlow — 持有一个状态值的热流（UI State）
private val _uiState = MutableStateFlow(TaskUiState())
val uiState: StateFlow<TaskUiState> = _uiState.asStateFlow()

// ✅ SharedFlow — 不持有值的广播流（事件）
private val _events = MutableSharedFlow<TaskEvent>()
val events: SharedFlow<TaskEvent> = _events.asSharedFlow()

// ✅ Flow — 冷流（数据库观察、分页数据）
fun observeTasks(): Flow<List<Task>> = dao.observeAll()

// ❌ LiveData 用于新建功能（迁移到 Flow）
// ❌ StateFlow 用于 one-shot 事件（用 Channel/SharedFlow）
```

## 并发安全 🔴

```kotlin
// ✅ Mutex：保护协程中的共享可变状态
private val mutex = Mutex()
private var counter = 0

suspend fun increment() {
    mutex.withLock { counter++ }
}

// ✅ @Volatile：简单变量的可见性保证
@Volatile
private var isConnected = false
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `GlobalScope.launch` | 无生命周期，内存泄漏 | `viewModelScope` / `lifecycleScope` |
| `runBlocking` 在主线程 | 阻塞 UI，ANR | `coroutineScope` / `supervisorScope` |
| Dispatchers.Unconfined 生产使用 | 行为不确定 | 明确的 Dispatcher |
| suspend 函数不指定 Dispatcher | IO 操作可能阻塞 Main | `withContext(Dispatchers.IO)` |
