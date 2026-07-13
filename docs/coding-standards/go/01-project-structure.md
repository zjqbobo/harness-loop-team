# Go 项目结构规范

## 标准布局 🔴

```
project/
├── cmd/                        # 可执行程序入口（每个子目录一个 main）
│   └── server/
│       └── main.go             # 启动入口
├── internal/                   # 私有包（不可被外部 import）
│   ├── api/                    # 接口层（handler / controller）
│   │   ├── router.go           # 路由注册
│   │   ├── user_handler.go     # HTTP handler
│   │   └── middleware/         # 中间件（auth/logging/cors）
│   ├── service/                # 业务层
│   │   ├── interface.go        # Service 接口定义
│   │   └── user_service.go     # Service 实现
│   ├── repository/             # 数据访问层
│   │   ├── interface.go        # Repository 接口定义
│   │   └── user_repo.go        # Repository 实现
│   ├── consumer/               # MQ 消费者
│   │   └── order_created_consumer.go
│   ├── scheduler/              # 定时任务
│   │   └── order_expiry_job.go
│   ├── model/                  # 数据模型（struct）
│   │   ├── user.go             # 数据库实体（PO）
│   │   └── dto.go              # 请求/响应 DTO
│   ├── converter/              # Entity ↔ DTO 转换器
│   │   └── user_converter.go
│   ├── domain/                 # 领域实体（DDD 风格）
│   │   └── user.go
│   └── config/                 # 配置加载
│       └── config.go
├── pkg/                        # 可复用公共库（可被外部 import）
│   └── validator/
│       └── validator.go
├── migrations/                 # 数据库迁移
├── scripts/                    # 构建/部署脚本
├── go.mod
├── go.sum
├── Makefile
├── Dockerfile
└── README.md
```

## 分层规则

```
api（接口层）
    ↓ 调用
service（业务层）
    ↓ 调用
repository（数据访问层）
    ↓ 操作
model（数据模型）
```

### 各层职责 🔴

| 层 | 职责 | 禁止 |
|---|---|---|
| **api** | HTTP 参数绑定、校验、调用 service、写响应 | 包含业务逻辑、直接操作 DB |
| **service** | 核心业务逻辑、事务控制、DTO 转换 | 直接操作 `*http.Request` |
| **repository** | 数据持久化、SQL 执行 | 包含 if/else 业务判断 |
| **model** | struct 定义 | 包含方法逻辑（除简单 getter） |

### 跨层调用规则 🔴

| 调用方向 | 是否允许 | 说明 |
|---------|---------|------|
| api → service | ✅ | 唯一合法调用方向 |
| service → repository | ✅ | 唯一合法调用方向 |
| api → repository | 🔴 禁止 | 必须经由 service |
| service → service | 🟡 允许 | 注意避免循环调用 |
| repository → service | 🔴 禁止 | 数据层不可依赖业务层 |
| consumer → service | ✅ | MQ 消费者调用业务层 |
| scheduler → service | ✅ | 定时任务调用业务层 |

## 交叉关注点 🔴

### MQ 消费者

- 统一放在 `internal/consumer/` 目录
- 职责：消息接收 → 反序列化为 DTO → 调用 Service → Ack/Nack
- **禁止**：在 Consumer 中包含业务逻辑、直接操作 Repository

### 定时任务

- 统一放在 `internal/scheduler/` 目录
- 职责：调度触发 → 调用 Service → 记录执行结果
- **禁止**：在定时任务中包含业务逻辑、直接操作 Repository

### 对外接口定义（gRPC/tRPC）

- 对外 RPC 接口定义统一放在 `internal/api/` 目录
- 出入参必须是 DTO，禁止直接暴露 DB struct
- 推荐将 proto 文件和生成代码放在 `api/` 子目录

```go
// internal/api/user_api.go — gRPC handler，只做协议转换
func (s *UserAPIServer) GetUser(ctx context.Context, req *pb.GetUserReq) (*pb.GetUserResp, error) {
    dto := converter.ToGetUserDTO(req)
    result, err := s.userService.GetUser(ctx, dto)
    if err != nil {
        return nil, err
    }
    return converter.ToGetUserResp(result), nil
}
```

## 数据隔离与转换 🔴

### Service/Repository 接口化

- Service 和 Repository **必须定义接口**，对上层屏蔽实现细节
- 接口定义放在 `interface.go` 文件中，与实现文件同目录
- Handler 依赖 Service 接口，Service 依赖 Repository 接口，均通过构造函数注入

```go
// internal/service/interface.go
type UserService interface {
    GetUser(ctx context.Context, id int64) (*dto.UserDTO, error)
    CreateUser(ctx context.Context, req *dto.CreateUserReq) (*dto.UserDTO, error)
}

// internal/repository/interface.go
type UserRepository interface {
    FindByID(ctx context.Context, id int64) (*model.User, error)
    Create(ctx context.Context, user *model.User) error
}
```

### DTO/Entity 隔离

Go 中 struct 的使用分层：

```
Handler  ←→  pb/gRPC 生成类型 或 HTTP 请求/响应
    ↓ 转换（Converter）
Service ←→  DTO（model/dto.go）
    ↓ 转换（Converter）
Repo    ←→  Entity（model/user.go → DB struct）
```

| 层 | 使用 struct | 禁止 |
|----|-----------|------|
| Handler | HTTP 请求/响应 或 gRPC pb | 直接使用 DB struct |
| Service | DTO（`model/dto.go`） | 返回 DB struct 给 Handler |
| Repository | Entity（`model/user.go`，含 db tag） | 接收/返回 DTO |

- **Service 入参和出参必须是 DTO**，不能将 DB struct 暴露到 Handler 层
- 数据库字段变更时只影响 Entity 和 Converter，不影响 Service 和 Handler

### Converter 转换层

- Entity ↔ DTO ↔ pb 之间转换统一放在 `converter/` 目录
- 纯函数转换，禁止在 Service/Handler 中散落转换逻辑
- 命名：`user_converter.go`

```go
// internal/converter/user_converter.go
func UserEntityToDTO(entity *model.User) *dto.UserDTO {
    return &dto.UserDTO{
        ID:    entity.ID,
        Name:  entity.Name,
        Email: entity.Email,
    }
}

func CreateUserDTOToEntity(dto *dto.CreateUserReq) *model.User {
    return &model.User{
        Name:  dto.Name,
        Email: dto.Email,
    }
}
```

### Service 层复杂度管控 🟡

当 Service 膨胀（单个文件 > 500 行或函数 > 80 行），引入 **UseCase 模式** 拆分：

- 每个 UseCase 只做一件事（单一职责）
- UseCase 由 Service 编排调用，对外仍暴露 Service 接口
- 适用于：跨多个 Repository 的复杂编排、多步骤事务流程

```
internal/service/
├── interface.go            # Service 接口
├── user_service.go         # Service 实现（编排 UseCase）
└── usecase/                # UseCase（复杂业务拆分）
    ├── create_order.go
    └── cancel_order.go
```

## internal 包规则 🔴

```
✅ 正确：
  internal/service/   → 可被 internal/api/ import
  internal/repository/ → 可被 internal/service/ import

❌ 禁止：
  pkg/xxx → internal/xxx  → 外不可引内
  internal/a → internal/b → internal/a  → 循环导入
```

## 包命名规范 🔴

| 规则 | 示例 |
|------|------|
| 全小写，不用下划线 | `userservice` 不用 `user_service` |
| 短名优先 | `user` 不用 `usermanagement` |
| 单数形式 | `user` 不用 `users` |
| 与目录名一致 | `service/` 目录中包名 `service` |

## 文件命名 🟡

| 类型 | 命名 | 示例 |
|------|------|------|
| 实现文件 | `{entity}_{layer}.go` | `user_service.go`、`user_repo.go` |
| 测试文件 | `{entity}_{layer}_test.go` | `user_service_test.go` |
| 接口定义 | 就近放在实现文件中，或 `interface.go` | |

## go.mod 规范 🔴

```
module github.com/<org>/<project>

go 1.23

require (
    github.com/gin-gonic/gin v1.10.0
    ...
)
```

- module path：`github.com/<org>/<repo>`
- Go 版本：当前 stable 版本（大版本 N）
- 依赖版本锁定在 go.sum（提交到 git）

## 依赖注入 🟡

```go
// ✅ 构造函数注入（推荐）
type UserService struct {
    repo UserRepository
    cache CacheClient
}

func NewUserService(repo UserRepository, cache CacheClient) *UserService {
    return &UserService{repo: repo, cache: cache}
}

// ✅ Wire 自动生成（大型项目）
//go:build wireinject
func InitializeUserHandler() *UserHandler {
    wire.Build(
        NewUserRepository,
        NewUserService,
        NewUserHandler,
    )
    return nil
}
```

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 循环 import | Go 编译器拒绝 |
| pkg/ 包依赖 internal/ | internal 不可外露 |
| init() 函数做重操作 | 影响启动速度，行为不可控 |
| main.go 有业务逻辑 | 入口只做启动组装 |
