# Python 基础编码规范

## 代码行数限制 🔴

| 元素 | 最大行数 | 超出处理 |
|------|---------|---------|
| 函数 | 80 行 | 提取私有函数 |
| Lambda | 单行表达式 | 提取为命名函数 |

> 类和模块不设行数上限，以职责单一、可快速理解为原则。

## 圈复杂度 🔴

- 单个函数圈复杂度 ≤ 10
- 超过 10 → 用策略模式、卫语句、提取函数降低
- 检测：`ruff check --select=C901 --max-complexity=10`

```python
# ✅ 卫语句：提前 return
def process_order(order: Order | None, user: User | None) -> Result:
    if order is None:
        return Result.fail("订单不存在")
    if order.is_paid:
        return Result.fail("订单已支付")
    if user is None or not user.is_active:
        return Result.fail("用户无效")

    # 主逻辑（无嵌套）
    return _execute_order(order, user)

# ❌ 嵌套 if
def process_order(order: Order | None, user: User | None) -> Result:
    if order is not None:
        if not order.is_paid:
            if user is not None:
                if user.is_active:
                    return _execute_order(order, user)
    ...
```

## 命名规范 🔴

遵循 **PEP 8**：

| 元素 | 规则 | 示例 |
|------|------|------|
| 模块/包 | `snake_case`（全小写+下划线） | `user_service.py`、`order_management/` |
| 函数/方法 | `snake_case` | `create_order()`、`find_by_email()` |
| 类 | `PascalCase` | `UserService`、`OrderRepository` |
| 常量 | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT = 3` |
| 私有成员 | `_` 前缀（单下划线） | `_validate_email()`、`_cache` |
| 内部私有 | `__` 前缀（双下划线，name mangling） | `__secret_key`（极少使用） |
| 布尔变量/函数 | `is_` / `has_` / `can_` 前缀 | `is_paid`、`has_permission`、`can_execute` |

### 方法命名 🟡

| 操作 | 前缀 | 示例 |
|------|------|------|
| 查询 | `get` / `find` / `query` | `get_by_id()`、`find_by_name()`、`query_page()` |
| 判断 | `is` / `has` / `can` | `is_valid()`、`has_stock()` |
| 操作 | `create` / `update` / `delete` | `create_order()`、`update_status()` |
| 转换 | `to` / `from` / `convert` | `to_dict()`、`from_row()` |

## 魔法值 🔴

```python
# ❌ 魔法值
if status == 3:
    ...

# ✅ 枚举
from enum import IntEnum

class OrderStatus(IntEnum):
    PENDING = 0
    PAID = 1
    SHIPPED = 2
    COMPLETED = 3

if status == OrderStatus.COMPLETED:
    ...

# ✅ 模块级常量
MAX_RETRY_COUNT = 3
DEFAULT_TIMEOUT_SECONDS = 30
```

- 简单状态用 `IntEnum` / `StrEnum`（Python 3.11+）
- 配置性数值用模块级常量
- **禁止用注释解释魔法值**（如 `status == 3  # 3=已完成`）

## 空值处理 🔴

```python
# ✅ 返回空列表而非 None
def find_users(role: str) -> list[User]:
    users = _query_by_role(role)
    return users if users else []

# ✅ 返回空字典而非 None
def get_config() -> dict[str, str]:
    return _load_config() or {}

# ❌ 返回 None
def find_users(role: str) -> list[User] | None:
    users = _query_by_role(role)
    return users if users else None  # 调用方被迫做 None 检查
```

## 函数设计 🟡

- 一个函数只做一件事
- 参数不超过 5 个，超过则封装为 dataclass/Pydantic model
- 返回值类型明确，禁止返回 `dict[str, Any]` / `object`
- 避免输出参数（通过参数修改传入对象并返回）

```python
# ✅ 参数封装
@dataclass
class SearchParams:
    keyword: str | None = None
    status: OrderStatus | None = None
    page: int = 1
    page_size: int = 20

def search_orders(params: SearchParams) -> PaginatedResult[Order]:
    ...
```

## 代码格式化 🔴

```toml
# pyproject.toml
[tool.ruff]
line-length = 120

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "B", "C4", "SIM"]
ignore = ["E501"]  # 行长度由 formatter 处理

[tool.ruff.format]
quote-style = "double"
```

- **格式化由工具负责**：`ruff format` + `ruff check --fix`
- **禁止手动调整格式**（缩进、换行、引号等）

## 列表推导式 🟡

```python
# ✅ 简单清晰
active_users = [u for u in users if u.is_active]
names = {u.id: u.name for u in users}

# ❌ 过于复杂（拆成 for 循环 + 函数）
result = [
    (u.name, o.total)
    for u in users
    for o in orders
    if u.id == o.user_id and o.status == "paid" and o.total > 100
]

# ✅ 复杂逻辑拆解
def get_high_value_order_totals(users, orders):
    paid_orders = {o.user_id: o.total for o in orders if o.status == "paid"}
    return [(u.name, paid_orders[u.id]) for u in users if u.id in paid_orders and paid_orders[u.id] > 100]
```

## Docstring 规范 🟡

```python
def transfer(
    from_account: Account,
    to_account: Account,
    amount: float,
) -> Transaction:
    """账户间转账。

    Args:
        from_account: 转出账户。
        to_account: 转入账户。
        amount: 转账金额（正数）。

    Returns:
        创建的交易记录。

    Raises:
        ValueError: 金额 ≤ 0 或账户相同。
        InsufficientFundsError: 转出账户余额不足。
    """
    ...
```

- Google style docstring（与 Sphinx 兼容）
- **公共 API 必须写 docstring**，私有函数可由命名自解释

## 注释规范 🔵

- 代码应自解释，好的命名 > 注释
- 只在以下情况加注释：
  - **WHY**：解释为什么这样做（非显而易见的业务逻辑、算法选择）
  - **WORKAROUND**：临时方案，标注问题编号和预期解决时间
  - **CONCURRENCY**：asyncio/协程/线程安全相关的非显而易见行为
- 禁止：
  - 无价值注释（`# set name`、`# increment counter`）
  - 注释掉的代码（用 git 管理历史）
  - 用注释解释魔法值（用枚举/常量替代）

```python
# ✅ WHY — 解释非显而易见的决策
# 使用 deque 而非 list：频繁左端 pop，deque 的 popleft 是 O(1) 而 list.pop(0) 是 O(n)
from collections import deque
queue: deque[Task] = deque()

# ✅ WORKAROUND — 标注临时方案
# WORKAROUND(issue-421): httpx v0.27 在 http2 下偶发连接泄漏，
# 降级为 http1.1。升级 httpx v0.28 后恢复 http2。
client = httpx.AsyncClient(http2=False)

# ❌ 无价值注释
name = user.name  # get user name

# ❌ 注释掉的代码
# users = await repo.find_all()
```

## 禁止行为清单 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| 函数超 80 行 | 难以理解和测试 | 提取私有函数 |
| 魔法值直接用字面量 | 语义不明、修改困难 | 用枚举或常量 |
| 返回 `None` 代替空集合 | 调用方被迫 None 检查 | 返回 `[]` / `{}` |
| `if x == None` | 不应与 None 用 == 比较 | `if x is None` |
| 可变默认参数 `def f(x=[])` | 多次调用共享同一对象 | `def f(x=None): x = x or []` |
| `except:` 裸写 | 吞掉 KeyboardInterrupt | 指定异常类型 |
