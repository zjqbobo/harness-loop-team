# Python 项目结构规范

## 推荐项目布局

### 应用/服务型项目 🔴

```
project/
├── src/
│   └── <package_name>/        # 主包（snake_case 命名）
│       ├── __init__.py
│       ├── api/               # 接口层（FastAPI routes / Flask views / Django views）
│       │   ├── __init__.py
│       │   ├── router.py      # 路由注册
│       │   └── deps.py        # 依赖注入
│       ├── service/           # 业务层
│       │   ├── __init__.py
│       │   ├── interfaces.py  # Service 接口（Protocol/ABC）
│       │   └── user_service.py
│       ├── repository/        # 数据访问层
│       │   ├── __init__.py
│       │   ├── interfaces.py  # Repository 接口（Protocol/ABC）
│       │   └── user_repo.py
│       ├── consumer/          # MQ 消费者
│       │   ├── __init__.py
│       │   └── order_created_consumer.py
│       ├── scheduler/         # 定时任务
│       │   ├── __init__.py
│       │   └── order_expiry_job.py
│       ├── model/             # 数据模型
│       │   ├── __init__.py
│       │   ├── user.py        # ORM Model / 数据库实体（PO）
│       │   └── schemas.py     # Pydantic 请求/响应 DTO
│       ├── converter/         # Entity ↔ DTO 转换器
│       │   ├── __init__.py
│       │   └── user_converter.py
│       ├── api_client/        # 对外 RPC/API 接口定义
│       │   ├── __init__.py
│       │   └── user_api.py
│       ├── core/              # 核心配置
│       │   ├── __init__.py
│       │   ├── config.py      # 配置管理（pydantic-settings）
│       │   ├── exceptions.py  # 自定义异常
│       │   └── security.py    # 认证/鉴权
│       ├── common/            # 公共工具
│       │   ├── __init__.py
│       │   └── utils.py
│       └── enums/             # 枚举定义
│           └── __init__.py
├── tests/                     # 测试目录（与 src/ 同级）
│   ├── conftest.py            # 共享 fixture
│   ├── unit/
│   │   └── test_user_service.py
│   └── integration/
│       └── test_user_api.py
├── pyproject.toml             # 项目配置（替代 setup.py/setup.cfg）
├── alembic/                   # 数据库迁移（如使用）
│   └── versions/
├── Dockerfile
└── README.md
```

### 库/CLI 型项目 🔴

```
project/
├── <package_name>/            # 扁平结构，src/ 非必须
├── tests/
└── pyproject.toml
```

## 分层规则

```
api/router（接口层）
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
| **api** | 参数校验、调用 service、返回响应 | 包含业务逻辑、直接操作 DB、拼装复杂对象 |
| **service** | 核心业务逻辑、事务控制、数据转换 | 直接操作 HTTP 对象、包含 SQL |
| **repository** | 数据持久化、查询封装 | 包含业务判断（if/else 分支） |
| **model** | 数据结构定义 | 包含业务逻辑 |

### 跨层调用规则 🔴

| 调用方向 | 是否允许 | 说明 |
|---------|---------|------|
| api → service | ✅ | 唯一合法方向 |
| service → repository | ✅ | 唯一合法方向 |
| api → repository | 🔴 禁止 | 必须经由 service |
| service → service | 🟡 允许 | 注意避免循环调用 |
| repository → service | 🔴 禁止 | 数据层不可依赖业务层 |

## 横切关注点 🔴

### MQ 消费者

- 统一放在 `consumer/` 包下
- 职责：消息接收 → 反序列化为 DTO → 调用 Service → Ack/Nack
- **禁止**：在 Consumer 中包含业务逻辑、直接操作 Repository

### 定时任务

- 统一放在 `scheduler/` 包下
- 职责：调度触发 → 调用 Service → 记录执行结果
- 可使用 APScheduler / Celery Beat / Django management commands
- **禁止**：在定时任务中包含业务逻辑、直接操作 Repository

### 对外接口定义（gRPC/Thrift）

- 对外 RPC 接口定义放在 `api_client/` 包或独立 `xxx-api` 包
- 出入参必须是 Pydantic DTO，禁止直接暴露 ORM Model

## 数据隔离与转换 🔴

### Service/Repository 接口化

- Service 和 Repository **必须定义接口**（Protocol 或 ABC），对上层屏蔽实现细节
- 接口定义放在各层 `interfaces.py` 中
- Controller 只依赖接口，不依赖实现类；通过 FastAPI `Depends` 注入

```python
# service/interfaces.py
from typing import Protocol

class UserService(Protocol):
    async def get_user(self, user_id: int) -> UserDTO: ...
    async def create_user(self, req: CreateUserReq) -> UserDTO: ...

# repository/interfaces.py
class UserRepository(Protocol):
    async def find_by_id(self, user_id: int) -> User | None: ...
    async def create(self, user: User) -> User: ...
```

### DTO ↔ Entity 隔离

```
api router  ←→  Pydantic RequestSchema / ResponseSchema
    ↓ 转换（Converter）
Service    ←→  Pydantic DTO（model/schemas.py）
    ↓ 转换（Converter）
Repository ←→  ORM Entity（model/user.py，SQLAlchemy model）
```

| 层 | 使用对象 | 禁止 |
|----|---------|------|
| api router | Pydantic Request/Response Schema | 直接使用 ORM Entity |
| Service | Pydantic DTO | 返回 ORM Entity 给 router |
| Repository | ORM Entity | 接收/返回 Pydantic DTO |

- **Service 入参和出参必须是 Pydantic DTO**，不能用 ORM Entity 跨层传递
- **api router 不得把 ORM Entity 直接返回前端**（字段泄露、循环引用风险）

### Converter 转换层

- ORM Entity ↔ Pydantic DTO 的转换统一放在 `converter/` 包
- 纯函数转换，禁止在 Service/router 中散落转换逻辑
- 命名：`user_converter.py`

```python
# converter/user_converter.py
def user_entity_to_dto(entity: User) -> UserDTO:
    return UserDTO(id=entity.id, name=entity.name, email=entity.email)

def create_user_req_to_entity(req: CreateUserReq) -> User:
    return User(name=req.name, email=req.email)
```

### Service 层复杂度管控 🟡

当 Service 膨胀（单个模块 > 500 行或函数 > 80 行），引入 **UseCase 模式** 拆分：

- 每个 UseCase 只做一件事（单一职责）
- UseCase 由 Service 编排调用，对外仍暴露 Service 接口
- 适用于：跨多个 Repository 的复杂编排、多步骤事务流程

```
service/
├── interfaces.py           # Service 接口（Protocol）
├── user_service.py         # Service 实现（编排 UseCase）
└── usecase/                # UseCase（复杂业务拆分）
    ├── __init__.py
    ├── create_order.py
    └── cancel_order.py
```

## 导入规范 🔴

```python
# ✅ 绝对导入
from myapp.service.user_service import UserService

# ❌ 相对导入（禁止）
from .service import UserService

# ✅ __init__.py 公开 API
# myapp/service/__init__.py
from myapp.service.user_service import UserService
__all__ = ["UserService"]
```

- **禁止相对导入**（`from .xxx import`）
- **禁止循环导入** — 如出现，提取公共模块或使用延迟导入
- `__init__.py` 声明公开 API

## 包命名规范 🟡

| 类型 | 命名规则 | 示例 |
|------|---------|------|
| 包名 | 全小写 + 下划线 | `user_service`、`order_management` |
| 模块名 | 全小写 + 下划线 | `user_service.py`、`email_sender.py` |
| 测试模块 | `test_` 前缀 | `test_user_service.py` |

## pyproject.toml 必要字段 🔴

```toml
[project]
name = "myapp"
version = "0.1.0"
requires-python = ">=3.11"

[project.optional-dependencies]
dev = ["pytest", "pytest-cov", "ruff", "mypy", "black"]

[tool.ruff]
line-length = 120
target-version = "py311"

[tool.mypy]
strict = true

[tool.pytest.ini_options]
testpaths = ["tests"]
```

## 框架差异 🟡

| 框架 | 接口层目录 | 注意 |
|------|----------|------|
| FastAPI | `api/router.py` | 用 `APIRouter`，depends 做 DI |
| Flask | `api/views.py` | 用 Blueprint 组织 |
| Django | `<app>/views.py` | 遵循 Django app 惯例 |
