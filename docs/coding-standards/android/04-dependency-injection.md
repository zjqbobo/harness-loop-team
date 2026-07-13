# Android/Kotlin 依赖注入规范

## DI 框架 🔴

- **推荐**：Hilt（Android 官方，基于 Dagger）
- **备选**：Koin（轻量级，Kotlin 原生 DSL）

## Hilt 构造函数注入 🔴

```kotlin
// ✅ 构造函数注入（推荐）
@HiltViewModel
class TaskViewModel @Inject constructor(
    private val taskRepository: TaskRepository,
    private val analytics: AnalyticsTracker,
) : ViewModel() {
    ...
}

// ✅ Repository 注入
@Singleton
class TaskRepository @Inject constructor(
    private val api: TaskApi,
    private val dao: TaskDao,
) {
    ...
}

// ✅ 模块提供外部依赖（Retrofit/Room 等）
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    @Provides @Singleton
    fun provideRetrofit(): Retrofit = Retrofit.Builder()
        .baseUrl("https://api.example.com/")
        .addConverterFactory(MoshiConverterFactory.create())
        .build()
}

// ❌ 属性注入（禁止）
@Inject lateinit var repository: TaskRepository  // 不透明，难以测试

// ❌ Service Locator（禁止）
val repo = ServiceLocator.get<TaskRepository>()
```

## 生命周期作用域 🔴

| 注解 | 生命周期 | 使用场景 |
|------|---------|---------|
| `@Singleton` | Application | Repository、Analytics、Database |
| `@ViewModelScoped` | ViewModel | ViewModel 及所需依赖 |
| `@ActivityScoped` | Activity | 与 Activity 同生命周期 |
| `@FragmentScoped` | Fragment | 与 Fragment 同生命周期 |

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `@Inject lateinit var` 属性注入 | 依赖不透明 | 构造函数注入 |
| Singleton 持有 ViewModel/View 引用 | 内存泄漏 | 注入 Application 级别的上下文 |
| 手动创建被注入对象 `new TaskRepository()` | 绕过 DI | 通过 DI 容器获取 |
| ViewModel 中注入 Activity Context | 内存泄漏 | `@ApplicationContext` |
