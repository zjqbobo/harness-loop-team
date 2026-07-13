# iOS/Swift UI 规范 (SwiftUI)

## View 组合原则 🔴

```swift
// ✅ 小而专注的 View
struct TaskRow: View {
    let task: Task
    let onComplete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title).font(.headline)
                Text(task.description).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            Button(action: onComplete) {
                Image(systemName: "checkmark.circle")
            }
        }
        .padding(.vertical, 8)
    }
}

// ✅ 使用 ViewBuilder 组合
struct TaskListView: View {
    @State private var viewModel = TaskListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.tasks.isEmpty {
                    ContentUnavailableView("暂无任务", systemImage: "tray")
                } else {
                    taskList
                }
            }
            .navigationTitle("任务")
            .task { await viewModel.loadTasks() }
        }
    }

    private var taskList: some View {
        List(viewModel.tasks) { task in
            TaskRow(task: task, onComplete: { viewModel.completeTask(task) })
        }
    }
}
```

## @State / @Binding / @Bindable 🔴

| 属性包装器 | 用途 | 示例 |
|---|---|---|
| `@State` | View 局部状态（简单类型） | `@State private var text = ""` |
| `@Binding` | 从父 View 传递的双向绑定 | `@Binding var isPresented: Bool` |
| `@Bindable` | @Observable ViewModel 的双向绑定 | `@Bindable var viewModel: TaskListViewModel` |
| `@Environment` | 跨层级共享值 | `@Environment(\.dismiss) private var dismiss` |

```swift
// ✅ @Bindable 双向绑定（iOS 17+）
struct TaskFormView: View {
    @Bindable var viewModel: TaskFormViewModel

    var body: some View {
        TextField("标题", text: $viewModel.title)
    }
}

// ❌ 在子 View 中 @State 重复父 View 状态
```

## Preview 规范 🔴

```swift
// ✅ 覆盖正常/空/加载/错误/暗黑模式
#Preview("默认") {
    TaskListView()
}

#Preview("空状态") {
    let viewModel = TaskListViewModel()
    TaskListView(viewModel: viewModel)
}

#Preview("暗黑模式") {
    TaskListView()
        .preferredColorScheme(.dark)
}

#Preview("大字体") {
    TaskListView()
        .environment(\.sizeCategory, .accessibilityLarge)
}

#Preview("iPhone SE") {
    TaskListView()
}
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| View struct 超过 200 行 | 难以理解、复用 | 拆分子 View |
| 在 View 中调用 async 函数（无 .task） | 阻塞渲染 | `.task { }` |
| 在 body 中创建 ViewModel | 重绘时重复创建 | `@State` 或外部注入 |
| 硬编码字体/颜色 | 不统一、可访问性差 | `.font(.headline)`、`Color.accentColor` |
