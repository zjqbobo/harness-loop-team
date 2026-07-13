# Python 类型标注规范

## 基本原则 🔴

- 所有函数签名必须有**完整类型标注**（参数 + 返回值）
- CI 中运行 `mypy --strict`，不通过不可合并
- 类型标注优先于文档注释：类型即文档

```python
# ✅ 完整标注
def get_user(user_id: int, include_orders: bool = False) -> User | None:
    ...

# ❌ 无标注
def get_user(user_id, include_orders=False):
    ...

# ❌ 部分标注
def get_user(user_id: int, include_orders=False):  # 缺返回值
    ...
```

## mypy 配置 🔴

```toml
# pyproject.toml
[tool.mypy]
strict = true                    # 开启所有严格检查
disallow_untyped_defs = true     # 禁止无类型函数
disallow_any_generics = true     # 禁止空泛型 List 应为 List[str]
warn_return_any = true           # 返回 Any 时警告
warn_unused_ignores = true       # 无用的 type: ignore 警告
```

## 常用标注场景

### Optional 与 Union 🟡

```python
# Python 3.10+ 推荐
def find_user(user_id: int) -> User | None:
    ...

# Python 3.9 兼容写法
from typing import Optional
def find_user(user_id: int) -> Optional[User]:
    ...

# Union
def process(data: str | bytes) -> str:
    ...
```

### 泛型集合 🟡

```python
# ✅ 明确元素类型
users: list[User] = []
config: dict[str, int] = {}
result: tuple[int, str] = (1, "ok")

# ❌ 空泛型
users: list = []       # mypy 报错
data: dict = {}        # mypy 报错
```

### 回调与高阶函数 🟡

```python
from collections.abc import Callable

# ✅ 明确签名
def retry(
    fn: Callable[[int, str], bool],
    max_attempts: int = 3,
) -> bool:
    ...

# 复杂回调用 Protocol
from typing import Protocol

class Handler(Protocol):
    def handle(self, event: dict[str, object]) -> None: ...
```

### Pydantic Schema 🔴

```python
from pydantic import BaseModel, Field

class CreateUserRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    email: str = Field(..., pattern=r"^[^@]+@[^@]+\.[^@]+$")
    age: int = Field(ge=0, le=150)
    tags: list[str] = Field(default_factory=list)

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    created_at: str
```

### TypedDict 与 dataclass 🔵

```python
# TypedDict：已知键名的字典（JSON 解析、配置）
from typing import TypedDict

class APIConfig(TypedDict):
    base_url: str
    timeout: int
    retries: int

# dataclass：数据容器（无需 Pydantic 验证的场景）
from dataclasses import dataclass, field

@dataclass
class OrderItem:
    product_id: int
    quantity: int
    price: float = field(default=0.0)
```

## 禁止 Any 🔴

```python
# ❌ Any 逃离类型检查
def parse(data: str) -> Any:          # 返回什么？
    ...

# ✅ 用 object 替代（至少需要类型守卫）
def parse(data: str) -> object:
    ...

# ✅ 用 Generic 替代
from typing import TypeVar
T = TypeVar("T")

def first(items: list[T]) -> T | None:
    return items[0] if items else None

# ✅ 用 Protocol 替代
class JSONSerializable(Protocol):
    def to_json(self) -> str: ...

def encode(obj: JSONSerializable) -> str:
    return obj.to_json()
```

## 类型守卫 🔵

```python
# ✅ isinstance 收窄类型
def process(value: int | str) -> str:
    if isinstance(value, int):
        return str(value)          # 此时 value 被收窄为 int
    return value.upper()           # 此时 value 被收窄为 str

# ✅ 自定义类型守卫（Python 3.10+ TypeGuard）
from typing import TypeGuard

def is_user(obj: object) -> TypeGuard[User]:
    return isinstance(obj, User) and hasattr(obj, "email")

# ✅ assert 收窄
def get_name(user: User | None) -> str:
    assert user is not None, "user 不应为 None"
    return user.name
```

## 运行时校验 🔵

类型标注是静态检查，**不可替代运行时校验**：

```python
# API 入参用 Pydantic（FastAPI 自动校验）
class CreateOrderRequest(BaseModel):
    user_id: int
    amount: float = Field(gt=0)

# 非 API 入口用 assert / 显式判断
def transfer(from_account: Account, to_account: Account, amount: float) -> None:
    assert amount > 0, f"金额必须为正: {amount}"
    assert from_account.id != to_account.id, "不能给自己转账"
    ...
```
