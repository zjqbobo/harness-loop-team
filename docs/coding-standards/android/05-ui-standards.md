# Android/Kotlin UI 规范 (Jetpack Compose)

## Composable 函数规范 🔴

```kotlin
// ✅ 单一职责 Composable
@Composable
fun TaskCard(task: Task, onComplete: (Task) -> Unit, modifier: Modifier = Modifier) {
    Card(modifier = modifier) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(text = task.title, style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(4.dp))
            Text(text = task.description, style = MaterialTheme.typography.bodyMedium)
            Button(onClick = { onComplete(task) }) { Text("完成") }
        }
    }
}

// ❌ 一个 Composable 做太多事
@Composable
fun TaskScreen(viewModel: TaskViewModel) {
    // 100+ 行的 Composable，包含所有逻辑
}

// ✅ 接收 Modifier 参数（放在第一个可选参数位置）
@Composable
fun TaskList(tasks: List<Task>, modifier: Modifier = Modifier, onTaskClick: (Task) -> Unit) {
    LazyColumn(modifier = modifier) { ... }
}
```

## 状态管理 🔴

```kotlin
// ✅ State Hoisting：状态上提
@Composable
fun TaskScreen(viewModel: TaskViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    TaskContent(
        tasks = uiState.tasks,
        isLoading = uiState.isLoading,
        onTaskClick = { viewModel.onTaskClick(it) }
    )
}

@Composable
fun TaskContent(
    tasks: List<Task>,
    isLoading: Boolean,
    onTaskClick: (Task) -> Unit,
) {
    if (isLoading) {
        CircularProgressIndicator()
    } else {
        LazyColumn { items(tasks) { TaskCard(it, onTaskClick) } }
    }
}

// ✅ @Stable / @Immutable 优化重组
@Immutable
data class TaskUiState(
    val tasks: List<Task> = emptyList(),
    val isLoading: Boolean = false,
)
```

## Preview 规范 🔴

```kotlin
// ✅ 每种状态写 Preview
@Preview(name = "默认", showBackground = true)
@Composable
private fun TaskContentPreview() {
    AppTheme {
        TaskContent(
            tasks = listOf(Task("1", "买菜"), Task("2", "写报告")),
            isLoading = false,
            onTaskClick = {},
        )
    }
}

@Preview(name = "空状态", showBackground = true)
@Composable
private fun TaskContentEmptyPreview() {
    AppTheme {
        TaskContent(tasks = emptyList(), isLoading = false, onTaskClick = {})
    }
}

@Preview(name = "加载中", showBackground = true)
@Composable
private fun TaskContentLoadingPreview() {
    AppTheme {
        TaskContent(tasks = emptyList(), isLoading = true, onTaskClick = {})
    }
}

@Preview(name = "暗黑模式", uiMode = UI_MODE_NIGHT_YES, showBackground = true)
@Composable
private fun TaskContentDarkPreview() {
    AppTheme { TaskContent(tasks = sampleTasks, isLoading = false, onTaskClick = {}) }
}
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| Composable 中直接调用 suspend 函数 | 阻塞重组 | `LaunchedEffect` / `produceState` |
| 在 Composable 内 new ViewModel | 配置变更时重建 | `hiltViewModel()` / `viewModel()` |
| 硬编码颜色/字体值 | 不统一、暗黑模式失效 | `MaterialTheme.colorScheme` / `MaterialTheme.typography` |
| 忘记 `key` 参数 | 列表重组错误 | `items(list, key = { it.id })` |
| 使用 `remember` 记住大量数据 | OOM | `remember` 仅用于小对象 |
| Composable 超过 150 行 | 难理解、难复用 | 拆分子组件 |
