# iOS/Swift 项目结构规范

## 推荐架构 🔴

采用 MVVM + Clean Architecture 三层分层：

```
<ProjectName>/
├── App/
│   ├── <ProjectName>App.swift         # @main 入口
│   ├── AppDelegate.swift              # 生命周期（如需要）
│   └── DIContainer.swift              # 依赖注入容器
├── Domain/                            # 领域层（最内层）
│   ├── Entities/                      # 领域实体（struct）
│   ├── ValueObjects/
│   ├── Enums/
│   └── Protocols/                     # Repository 接口
├── Data/                              # 数据层
│   ├── Local/                         # SwiftData/Core Data/UserDefaults
│   │   ├── Models/                    # @Model 类或 NSManagedObject
│   │   └── DataSources/
│   ├── Remote/                        # URLSession/Alamofire API
│   │   ├── DTOs/                      # Codable 响应模型
│   │   └── APIClient.swift
│   └── Repositories/                  # Repository 实现
├── Presentation/                      # 表现层
│   ├── Common/                        # 共享组件/Modifier
│   │   ├── Views/
│   │   └── Modifiers/
│   └── Features/<feature>/
│       ├── <Feature>View.swift        # SwiftUI View
│       ├── <Feature>ViewModel.swift   # @Observable ViewModel
│       └── Components/                # 页面私有视图
├── Core/                              # 核心工具
│   ├── Extensions/
│   ├── Protocols/
│   ├── Errors/                        # AppError 定义
│   └── Utilities/
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.strings
│   └── Fonts/
└── Tests/
    ├── <ProjectName>Tests/            # 单元测试
    └── <ProjectName>UITests/          # UI 测试
```

## 分层规则

```
Presentation（View + ViewModel）
    ↓ 调用
Domain（Entities + Repository 协议）
    ↓ 调用
Data（Repository 实现 + 数据源）
    ↓ 操作
Local / Remote（SwiftData / URLSession）
```

### 各层职责 🔴

| 层 | 职责 | 禁止 |
|---|---|---|
| **Presentation** | SwiftUI View、ViewModel、@Observable 状态管理 | 直接操作数据库/网络、包含业务逻辑 |
| **Domain** | 实体 struct、Repository 协议、UseCase | 依赖任何框架（SwiftData/UIKit） |
| **Data** | Repository 实现、Codable DTO、持久化 | 持有 UI 状态 |

## 文件命名规范 🔴

| 类型 | 命名 | 示例 |
|------|------|------|
| SwiftUI View | `PascalCase` + `View` | `TaskListView.swift` |
| ViewModel | `PascalCase` + `ViewModel` | `TaskListViewModel.swift` |
| Entity | `PascalCase`（名词） | `Task.swift`、`User.swift` |
| Repository 协议 | `PascalCase` + `Repository` | `TaskRepository.swift` |
| Repository 实现 | `PascalCase` + `Repository` + `Impl` | `TaskRepositoryImpl.swift` |
| DTO | `PascalCase` + `DTO`/`Response` | `TaskDTO.swift` |
| API Client | `PascalCase` + `APIClient` | `APIClient.swift` |
| 测试 | 同名 + `Tests` | `TaskListViewModelTests.swift` |

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| Domain 层 import SwiftData/UIKit | 领域不依赖框架 |
| View 中包含业务逻辑/网络调用 | ViewModel 负责 |
| 跨层直接调用（View → Repository） | 经过 ViewModel |
| View struct 超过 200 行 | 拆分子 View |
