# Android/Kotlin 项目结构规范

## 推荐架构 🔴

采用 MVVM + Clean Architecture 三层分层：

```
app/
├── src/
│   ├── main/
│   │   ├── java/com/<company>/<app>/
│   │   │   ├── App.kt                    # Application 类
│   │   │   ├── MainActivity.kt           # 单 Activity 入口
│   │   │   ├── data/                     # 数据层
│   │   │   │   ├── local/                # Room DAO / DataStore
│   │   │   │   ├── remote/               # Retrofit API / Ktor
│   │   │   │   ├── repository/           # Repository 实现
│   │   │   │   └── mapper/               # DTO ↔ Entity 映射
│   │   │   ├── domain/                   # 领域层
│   │   │   │   ├── model/                # 领域实体
│   │   │   │   ├── repository/           # Repository 接口
│   │   │   │   └── usecase/              # UseCase（可选，复杂业务用）
│   │   │   ├── presentation/             # 表现层
│   │   │   │   ├── navigation/           # Navigation 路由
│   │   │   │   └── feature/<feature>/
│   │   │   │       ├── <Feature>Screen.kt     # Composable 主屏幕
│   │   │   │       ├── <Feature>ViewModel.kt  # ViewModel
│   │   │   │       └── components/            # 页面私有组件
│   │   │   ├── di/                       # Hilt/Koin 模块
│   │   │   └── common/                   # 公共工具/扩展
│   │   ├── res/                          # 资源文件
│   │   └── AndroidManifest.xml
│   ├── test/                             # 单元测试
│   │   └── java/com/<company>/<app>/
│   └── androidTest/                      # 仪表化测试
│       └── java/com/<company>/<app>/
└── build.gradle.kts
```

## 分层规则

```
presentation（UI + ViewModel）
    ↓ 调用
domain（UseCase + Repository 接口）
    ↓ 调用
data（Repository 实现 + 数据源）
    ↓ 操作
local / remote（Room / Retrofit）
```

### 各层职责 🔴

| 层 | 职责 | 禁止 |
|---|---|---|
| **presentation** | Compose UI、ViewModel、状态管理（StateFlow） | 直接操作数据库/网络、包含业务逻辑 |
| **domain** | 领域实体、Repository 接口、UseCase | 依赖 Android SDK（android.*） |
| **data** | Repository 实现、DTO 映射、数据源协调 | 持有 UI 状态 |

## 包命名规范 🔴

```
com.<company>.<app>.<layer>.<feature>
```

| 示例 | 说明 |
|------|------|
| `com.acme.todo.data.local` | 本地数据源 |
| `com.acme.todo.data.remote` | 远程 API |
| `com.acme.todo.domain.model` | 领域实体 |
| `com.acme.todo.presentation.task` | 任务功能 UI |

## 文件命名 🟡

| 类型 | 命名 | 示例 |
|------|------|------|
| Activity | `PascalCase` + `Activity` | `MainActivity.kt` |
| Composable 屏幕 | `PascalCase` + `Screen` | `TaskListScreen.kt` |
| ViewModel | `PascalCase` + `ViewModel` | `TaskListViewModel.kt` |
| Repository | `PascalCase` + `Repository` | `TaskRepository.kt` |
| 数据源 | `PascalCase` + `DataSource` | `TaskLocalDataSource.kt` |
| DTO/Response | `PascalCase` + `Dto`/`Response` | `TaskDto.kt` |
| 测试 | 同名 + `Test` | `TaskRepositoryTest.kt` |

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| Activity/Fragment 中包含业务逻辑 | 职责混乱，ViewModel 负责 |
| domain 层依赖 android.* 包 | 纯 Kotlin，方便单元测试 |
| 跨层直接调用（UI → DataSource） | 必须经过 domain 接口 |
| Composable 函数超过 150 行 | 拆分子组件 |
