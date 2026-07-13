# Python 测试规范

## 测试框架 🔴

```ini
# pyproject.toml
[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-cov>=5.0",
    "pytest-mock>=3.14",
    "pytest-asyncio>=0.23",  # 异步测试
]
```

## 三段式结构 🔴

每个测试用例遵循 **Arrange → Act → Assert**：

```python
# tests/unit/test_user_service.py
import pytest
from myapp.service.user_service import UserService
from myapp.core.exceptions import NotFoundError

class TestUserService:
    def test_find_by_id_returns_user_when_exists(self, user_service, sample_user):
        # Arrange — 准备数据和 mock
        user_service.repo.find_by_id.return_value = sample_user

        # Act — 执行被测方法
        result = user_service.find_by_id(1)

        # Assert — 验证结果
        assert result.id == sample_user.id
        assert result.name == sample_user.name
        user_service.repo.find_by_id.assert_called_once_with(1)

    def test_find_by_id_raises_when_not_found(self, user_service):
        # Arrange
        user_service.repo.find_by_id.return_value = None

        # Act & Assert
        with pytest.raises(NotFoundError, match="用户.*不存在"):
            user_service.find_by_id(999)

    def test_create_user_with_empty_name_raises(self, user_service):
        # Arrange, Act & Assert
        with pytest.raises(ValueError, match="用户名不能为空"):
            user_service.create_user(name="", email="test@example.com")
```

## Fixture 管理 🟡

```python
# tests/conftest.py — 共享 fixture
import pytest
from unittest.mock import MagicMock

@pytest.fixture
def mock_user_repo():
    """mock UserRepository"""
    repo = MagicMock()
    repo.find_by_id.return_value = None
    return repo

@pytest.fixture
def user_service(mock_user_repo):
    """注入 mock 依赖的 UserService"""
    return UserService(repo=mock_user_repo)

@pytest.fixture
def sample_user():
    """标准测试用户"""
    return User(id=1, name="Alice", email="alice@example.com")
```

## Mock 规范 🔴

```python
# ✅ 只 mock 外部依赖（数据库、API、文件系统）
from unittest.mock import MagicMock, patch

def test_send_email(mock_email_client):
    mock_email_client.send.return_value = {"status": "sent"}
    service = NotificationService(email_client=mock_email_client)
    result = service.notify_user(user_id=1, message="Hello")
    assert result.success is True

# ✅ patch 上下文管理器
def test_fetch_remote_data():
    with patch("myapp.service.external.requests.get") as mock_get:
        mock_get.return_value.json.return_value = {"data": [1, 2, 3]}
        result = fetch_remote_data("http://api.example.com")
        assert len(result) == 3

# ❌ 禁止：mock 被测代码本身
def test_calculate_total():
    # 不要 mock calculate_total 内部调用的私有方法
    ...
```

## Mock 规则 🔴

| 规则 | 说明 |
|------|------|
| **mock 外部边界** | 数据库、HTTP API、文件系统、消息队列 |
| **不 mock 被测代码** | 被测类的方法调用真实实现 |
| **不 mock 标准库** | `datetime`、`json`、`os.path` 等使用真实调用 |
| **不 mock 值对象** | `User`、`Order` 等数据类使用真实构造 |

## 参数化测试 🟡

```python
import pytest

@pytest.mark.parametrize("amount,expected_fee", [
    (100, 1.0),      # 正常金额
    (1000, 10.0),    # 大额
    (0.01, 0.0),     # 极小金额（按规则免手续费）
    (0, 0.0),        # 零金额
    (-100, None),    # 负数（预期抛异常）
])
def test_calculate_fee(amount, expected_fee):
    if expected_fee is None:
        with pytest.raises(ValueError):
            calculate_fee(amount)
    else:
        assert calculate_fee(amount) == pytest.approx(expected_fee, rel=1e-2)
```

## 异步测试 🔵

```python
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_create_user_api(async_client: AsyncClient):
    response = await async_client.post("/api/users", json={
        "name": "Bob",
        "email": "bob@example.com"
    })
    assert response.status_code == 201
    assert response.json()["name"] == "Bob"
```

## 覆盖率 🔴

```bash
pytest --cov=myapp --cov-report=term --cov-report=html --cov-fail-under=80
```

| 指标 | 门禁 |
|------|------|
| 行覆盖率 (statement) | ≥ 80% |
| 分支覆盖率 (branch) | ≥ 70% |
| 未达标 | CI 阻断，不可合并 |

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 连真实数据库 | 慢、不稳定、无法并行 |
| 连真实外部 API | 外部不可控、网络依赖 |
| 测试间共享状态 | 测试应独立，无执行顺序依赖 |
| 只写 happy path | 边界和异常同样重要 |
| `time.sleep()` 等待 | 用 `pytest-asyncio` 或轮询 |
