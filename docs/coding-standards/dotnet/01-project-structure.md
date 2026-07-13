# .NET/C# 项目结构规范

## Solution 组织 🔴

```
solution/
├── <Company>.<Product>.sln            # Solution 文件
├── src/
│   ├── <Company>.<Product>.Domain/    # 领域层（内层）
│   │   ├── Entities/
│   │   ├── ValueObjects/
│   │   ├── Enums/
│   │   └── Interfaces/               # 仓储接口等
│   ├── <Company>.<Product>.Application/  # 应用层
│   │   ├── Services/
│   │   ├── DTOs/
│   │   ├── Interfaces/               # Service 接口 + 外部服务接口
│   │   ├── Mapping/                  # Entity ↔ DTO 转换器（AutoMapper Profile）
│   │   └── Behaviors/                # MediatR Pipeline Behaviors
│   ├── <Company>.<Product>.Infrastructure/  # 基础设施层
│   │   ├── Persistence/
│   │   │   ├── Repositories/
│   │   │   └── EntityConfigurations/  # EF Core Fluent API
│   │   ├── Messaging/                # MQ 消费者/生产者
│   │   ├── BackgroundJobs/           # 定时任务（Hangfire/Quartz）
│   │   └── ExternalServices/         # 外部 API 客户端
│   └── <Company>.<Product>.Presentation/   # 表现层（Web API）
│       ├── Controllers/
│       ├── Middleware/
│       ├── Filters/
│       └── Program.cs
├── tests/
│   ├── <Company>.<Product>.UnitTests/
│   ├── <Company>.<Product>.IntegrationTests/
│   └── <Company>.<Product>.FunctionalTests/
└── README.md
```

## Clean Architecture 依赖规则 🔴

```
Presentation → Application → Domain
                   ↓
            Infrastructure
```

| 层 | 可依赖 | 禁止依赖 |
|---|---|---|
| **Domain** | 无（最内层） | Application / Infrastructure / Presentation |
| **Application** | Domain | Infrastructure / Presentation |
| **Infrastructure** | Domain + Application | Presentation |
| **Presentation** | Domain + Application + Infrastructure | — |

## 项目命名规范 🔴

| 项目 | 命名 | 示例 |
|------|------|------|
| Solution | `<Company>.<Product>` | `Acme.OrderSystem` |
| Domain | `<Company>.<Product>.Domain` | `Acme.OrderSystem.Domain` |
| Application | `<Company>.<Product>.Application` | `Acme.OrderSystem.Application` |
| Infrastructure | `<Company>.<Product>.Infrastructure` | `Acme.OrderSystem.Infrastructure` |
| Presentation | `<Company>.<Product>.Api` 或 `.Web` | `Acme.OrderSystem.Api` |
| 测试 | `<被测试项目>.Tests` | `Acme.OrderSystem.UnitTests` |

## 命名空间约定 🟡

```csharp
// 文件范围命名空间（C# 10+）
namespace Acme.OrderSystem.Application.Services;

// 传统块命名空间
namespace Acme.OrderSystem.Application.Services
{
    public class OrderService { }
}
```

- 默认使用文件范围命名空间（简洁）
- 命名空间与文件夹路径一致

## 横切关注点 🔴

### MQ 消费者

- 放在 `Infrastructure/Messaging/` 项目
- 职责：消息接收 → 反序列化为 DTO → 通过 MediatR 发送 Command/Event → 由 Application 层处理
- **禁止**：在 Consumer 中包含业务逻辑

### 定时任务

- 放在 `Infrastructure/BackgroundJobs/` 项目（使用 Hangfire/Quartz）
- 职责：调度触发 → 通过 MediatR 发送 Command → 由 Application 层 Service 处理
- **禁止**：在 BackgroundJob 中包含业务逻辑、直接操作 DbContext

### 对外接口定义（gRPC）

- RPC 接口的 `.proto` 文件和生成代码放在独立项目 `xxx.Grpc`
- Handler 实现放在 `Presentation/Grpc/`，只做协议转换，调用 Application Service

## 数据隔离与转换 🔴

### Service/Repository 接口化

- Service 接口定义在 `Application/Interfaces/`，实现在 `Application/Services/`
- Repository 接口定义在 `Domain/Interfaces/`，实现在 `Infrastructure/Persistence/Repositories/`
- 上层只依赖接口，通过 DI 注入实现

### DTO ↔ Entity 隔离

```
Presentation  ←→  ViewModel / API Model
    ↓ 转换（AutoMapper）
Application   ←→  DTO
    ↓ 转换（AutoMapper）
Domain        ←→  Entity / ValueObject
    ↓ 转换（Infrastructure）
Infrastructure←→  EF Core Entity Configuration
```

| 项目 | 使用对象 | 禁止 |
|------|---------|------|
| Presentation | API Model / ViewModel | 引用 Domain Entity |
| Application | DTO | 返回 Domain Entity 给 Presentation |
| Domain | Entity / ValueObject | 依赖 EF Core / 外部库 |
| Infrastructure | Entity（持久化） | 修改 Domain Entity 结构 |

- **Application 层 Service 的入参和出参必须是 DTO**，不能将 Domain Entity 直接暴露给 Presentation
- **Presentation 不得直接返回 Domain Entity**

### AutoMapper 转换层

- 所有对象映射统一用 **AutoMapper Profile**，放在 `Application/Mapping/`
- **禁止**在 Service/Controller 中手写对象映射代码
- Profile 命名：`OrderMappingProfile.cs`

```csharp
// Application/Mapping/OrderMappingProfile.cs
public class OrderMappingProfile : Profile
{
    public OrderMappingProfile()
    {
        CreateMap<Order, OrderDto>();
        CreateMap<CreateOrderRequest, Order>();
        CreateMap<OrderDto, OrderViewModel>();
    }
}
```

### Service 层复杂度管控 🟡

当 Service 膨胀（单个类 > 500 行或方法 > 80 行），引入 **UseCase / Command 模式**：

- 使用 MediatR `IRequest<T>` + `IRequestHandler<TRequest, TResponse>` 拆分
- Handler 只做一件事（单一职责），Service 对外仍暴露统一接口
- 适用于：跨多个 Repository/Aggregate 的复杂编排、多步骤事务流程

```
Application/
├── Services/
│   └── OrderService.cs         # 编排 UseCase/CQRS
├── UseCases/                   # 或按 Feature 垂直切分
│   ├── CreateOrder/
│   │   ├── CreateOrderCommand.cs
│   │   └── CreateOrderHandler.cs
│   └── CancelOrder/
│       ├── CancelOrderCommand.cs
│       └── CancelOrderHandler.cs
```

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| Domain 层引用 Infrastructure | 内层依赖外层，架构腐蚀 |
| 循环项目引用 | 编译错误 |
| 跨层直接调用（Presentation → Infrastructure） | 绕过 Application 层 |
| Domain 层有 Entity Framework 引用 | 领域模型不应感知持久化框架 |
