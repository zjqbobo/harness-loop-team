# 工程分层规范

## 分层架构

```
Controller（接口层）
    ↓ 调用
Service（业务层）
    ↓ 调用
DAO/Mapper（数据访问层）
```

## 各层职责

### Controller 层 🔴

- 只做参数接收、校验（JSR303）、调用 Service、返回响应
- **禁止**：包含业务逻辑、直接操作 DAO、拼装复杂对象
- **禁止**：在 Controller 中做数据转换（DTO↔VO 转换应由 Service 或 Converter 处理）
- 返回统一响应体 `Result<T>`

### Service 层 🔴

- 核心业务逻辑所在地
- 负责事务控制（@Transactional）
- 负责 DTO ↔ Entity 转换
- **禁止**：直接操作 HttpServletRequest/Response
- **禁止**：包含 SQL 拼接逻辑

### DAO/Mapper 层 🔴

- 只做数据持久化，不包含业务判断
- 方法命名语义化：`findByUserId`，禁止 `getData1`/`getData2`
- **禁止**：包含业务逻辑（如 if/else 分支判断）

## 跨层调用规则

| 调用方向 | 是否允许 | 说明 |
|---------|---------|------|
| Controller → Service | ✅ | 唯一合法调用方向 |
| Service → DAO | ✅ | 唯一合法调用方向 |
| Controller → DAO | 🔴 禁止 | 必须经由 Service |
| Service → Service | 🟡 允许 | 同层调用，注意事务传播 |
| DAO → Service | 🔴 禁止 | 数据层不可依赖业务层 |
| Controller → Controller | 🔴 禁止 | 接口层不可互调 |

## 横切关注点 🔴

### MQ 消费者

- 统一放在 `consumer/` 包下
- Consumer 职责：消息接收 → 反序列化为 DTO → 调用 Service → 确认/拒绝
- **禁止**：在 Consumer 中包含业务逻辑、直接操作 DAO

```
com.<company>.<project>
├── consumer/
│   ├── OrderCreatedConsumer.java
│   └── PaymentResultConsumer.java
```

### 定时任务

- 统一放在 `scheduler/` 或 `job/` 包下
- 定时任务职责：调度触发 → 调用 Service → 记录执行结果
- **禁止**：在定时任务中包含业务逻辑、直接操作 DAO

```
com.<company>.<project>
├── scheduler/
│   └── OrderExpiryJob.java
```

### 对外接口定义（Feign/Dubbo/gRPC）

- 对外暴露的 RPC/Feign 接口定义放在 `api/` 或 `client/` 包，推荐拆为独立 `xxx-api` 模块
- 接口定义与实现分离：接口在 api 模块，实现在 Controller/Service
- **对外接口的出入参必须是 DTO**，禁止直接暴露 Entity/VO

```
com.<company>.<project>
├── api/                       # 对外 RPC 接口定义（可拆为独立模块 xxx-api）
│   ├── dto/                   # 接口专用 DTO（外部调用方可引用）
│   └── OrderApi.java          # Feign/Dubbo 接口
```

## 数据隔离与转换 🔴

### Service/DAO 接口化

- Service 层和 DAO 层**必须定义接口**，对上层屏蔽实现细节
- Service 接口放在 `service/`，实现放在 `service/impl/`
- DAO 接口放在 `dao/`，实现类由 MyBatis/Spring Data JPA 自动生成
- Controller 只依赖 Service 接口，不依赖实现类

### DTO/Entity/VO 隔离

**数据对象分层**，每层只使用自己层的数据对象，**禁止跨层混用**：

```
Controller  ←→  VO（视图对象，面向前端）
    ↓ 转换（Converter）
Service    ←→  DTO（数据传输对象，面向业务）
    ↓ 转换（Converter）
DAO        ←→  Entity/PO（持久化对象，面向数据库）
```

| 层 | 使用对象 | 禁止 |
|----|---------|------|
| Controller | VO / Request / Response | 直接使用 Entity/PO、直接使用 DTO |
| Service | DTO | 返回 Entity/PO 给 Controller |
| DAO | Entity/PO | 接收/返回 DTO |

- **Controller 不得把 Entity/PO 直接返回前端**（字段泄露、序列化风险、循环引用）
- **Service 的入参和出参必须是 DTO**，不能用 Entity/PO 跨层传递
- **Service 内部调用 DAO 时必须做 DTO → Entity 转换，返回结果时做 Entity → DTO 转换**

### Converter 转换层

- Entity ↔ DTO ↔ VO 之间的转换**统一放在 `converter/` 包**
- 使用 **MapStruct**（编译期代码生成，零反射），**禁止**手写逐字段 setter
- 转换逻辑不得分散在 Service/Controller 中
- Converter 类命名：`XxxConverter`

```java
@Mapper(componentModel = "spring")
public interface OrderConverter {
    OrderDTO toDTO(OrderEntity entity);
    List<OrderDTO> toDTOList(List<OrderEntity> entities);
    OrderEntity toEntity(OrderDTO dto);
    OrderVO toVO(OrderDTO dto);
}
```

### Service 层复杂度管控 🟡

当 Service 膨胀（单个类 > 500 行或方法 > 80 行），引入 **UseCase 模式** 拆分：

- 每个 UseCase 只做一件事（单一职责）
- UseCase 由 Service 编排调用，对外仍暴露 Service 接口
- 适用于：跨多个 DAO 的复杂编排、多步骤事务流程

```
service/
├── XxxService.java              # Service 接口
├── impl/XxxServiceImpl.java     # Service 实现（编排 UseCase）
└── usecase/                     # UseCase（复杂业务拆分）
    ├── CreateOrderUseCase.java
    └── CancelOrderUseCase.java
```

## 包结构约定 🔴

```
com.<company>.<project>
├── controller/     ← 接口层
├── service/        ← 业务层接口
│   └── impl/       ← 业务层实现
├── dao/            ← 数据访问层（接口，实现在 mapper xml）
├── entity/         ← 数据库实体（PO）
├── dto/            ← 数据传输对象
├── vo/             ← 视图对象
├── converter/      ← Entity ↔ DTO ↔ VO 转换器
├── consumer/       ← MQ 消费者
├── scheduler/      ← 定时任务
├── api/            ← 对外 RPC 接口定义（推荐拆为独立模块）
├── config/         ← 配置类
├── common/         ← 公共工具
│   ├── exception/  ← 异常定义
│   ├── constant/   ← 常量定义
│   └── util/       ← 工具类
└── enums/          ← 枚举定义
```

## 命名规范 🟡

| 层 | 类名后缀 | 方法名前缀 |
|----|---------|-----------|
| Controller | `XxxController` | 无限制 |
| Service 接口 | `XxxService` | 无限制 |
| Service 实现 | `XxxServiceImpl` | 无限制 |
| DAO | `XxxMapper` / `XxxDao` | `find`/`insert`/`update`/`delete` |
| Entity | `XxxEntity` / `XxxPO` | — |
| DTO | `XxxDTO` / `XxxRequest` | — |
| VO | `XxxVO` / `XxxResponse` | — |
