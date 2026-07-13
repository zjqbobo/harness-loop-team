# Android/Kotlin 测试规范

## 测试框架 🔴

```kotlin
// build.gradle.kts
dependencies {
    testImplementation("junit:junit:4.13.2")
    testImplementation("io.mockk:mockk:1.13.12")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.9.0")
    testImplementation("app.cash.turbine:turbine:1.1.0")  // Flow 测试
    testImplementation("com.google.truth:truth:1.4.0")    // 断言
}
```

## 三段式结构 🔴

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class TaskRepositoryTest {
    private val api: TaskApi = mockk()
    private val dao: TaskDao = mockk()
    private lateinit var repository: TaskRepository

    @Before
    fun setUp() {
        repository = TaskRepository(api, dao)
        Dispatchers.setMain(UnconfinedTestDispatcher())
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `getTasks emits cached then remote data`() = runTest {
        // Arrange
        val localTasks = listOf(Task("1", "本地任务"))
        val remoteTasks = listOf(Task("1", "远程任务"))
        coEvery { api.fetchTasks() } returns remoteTasks
        every { dao.getAll() } returns flowOf(localTasks)

        // Act & Assert — Turbine 测试 Flow
        repository.getTasks().test {
            assertThat(awaitItem()).isEqualTo(DataResult.Loading)
            assertThat(awaitItem()).isEqualTo(DataResult.Success(localTasks))
            assertThat(awaitItem()).isEqualTo(DataResult.Success(remoteTasks))
            awaitComplete()
        }
    }

    @Test
    fun `getTasks emits error on network failure`() = runTest {
        // Arrange
        coEvery { api.fetchTasks() } throws IOException("网络错误")
        every { dao.getAll() } returns flowOf(emptyList())

        // Act & Assert
        repository.getTasks().test {
            assertThat(awaitItem()).isEqualTo(DataResult.Loading)
            val error = awaitItem() as DataResult.Error
            assertThat(error.code).isEqualTo("NETWORK_ERROR")
            awaitComplete()
        }
    }
}
```

## ViewModel 测试 🔴

```kotlin
class TaskViewModelTest {
    @get:Rule
    val dispatcherRule = MainDispatcherRule()

    private val repository: TaskRepository = mockk()
    private lateinit var viewModel: TaskViewModel

    @Before
    fun setUp() {
        viewModel = TaskViewModel(repository)
    }

    @Test
    fun `loadTasks updates uiState with tasks`() = runTest {
        val tasks = listOf(Task("1", "测试"))
        every { repository.getTasks() } returns flowOf(DataResult.Success(tasks))

        viewModel.loadTasks()

        assertThat(viewModel.uiState.value.tasks).isEqualTo(tasks)
        assertThat(viewModel.uiState.value.isLoading).isFalse()
    }
}
```

## Compose UI 测试 🟡

```kotlin
class TaskScreenTest {
    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun `TaskScreen shows tasks from ViewModel`() {
        val viewModel: TaskViewModel = mockk()
        every { viewModel.uiState } returns MutableStateFlow(
            TaskUiState(tasks = listOf(Task("1", "买菜"), Task("2", "写报告")))
        )

        composeTestRule.setContent { TaskScreen(viewModel = viewModel) }

        composeTestRule.onNodeWithText("买菜").assertIsDisplayed()
        composeTestRule.onNodeWithText("写报告").assertIsDisplayed()
    }
}
```

## Mock 规则 🔴

| 规则 | 说明 |
|------|------|
| **mock 外部边界** | API、数据库、文件系统 |
| **不 mock 被测代码** | ViewModel/Repository 内部逻辑走真实实现 |
| **不 mock 框架类** | `Application`、`Context`（用 AndroidX Test） |

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 连真实网络/数据库 | 慢、不稳定 |
| `Thread.sleep` | 阻塞测试线程 |
| 测试间共享可变状态 | 顺序依赖 |
| 只写 happy path | 边界和异常必须覆盖 |
