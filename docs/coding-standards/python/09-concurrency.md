# Python 异步与并发规范

## async/await 基本原则 🔴

- I/O 密集操作用 `async/await`（数据库、HTTP、文件），禁止在 async 上下文中调用同步阻塞方法
- CPU 密集操作用 `concurrent.futures.ProcessPoolExecutor`，禁止在 async 事件循环中做 CPU 计算

```python
# ✅ async I/O
async def get_user(user_id: int) -> UserDTO:
    async with session() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

# ❌ 在 async 中同步阻塞
async def bad():
    user = User.objects.get(id=1)  # Django 同步 ORM → 阻塞事件循环
    time.sleep(5)                   # 阻塞事件循环
```

## 并发执行 🔴

```python
# ✅ asyncio.gather 并行（无依赖的异步调用）
async def get_dashboard_data(user_id: int):
    orders, profile, notifications = await asyncio.gather(
        order_service.list_by_user(user_id),
        user_service.get_profile(user_id),
        notification_service.get_unread(user_id),
    )
    return {"orders": orders, "profile": profile, "notifications": notifications}

# ❌ 串行 await 无依赖调用
async def bad():
    orders = await order_service.list_by_user(user_id)       # 等 200ms
    profile = await user_service.get_profile(user_id)         # 再等 200ms
    # 总耗时 400ms（gather 只需 200ms）
```

## 同步 ORM 在异步框架中 🟡

- FastAPI 用 async endpoint 时，数据库操作必须用 async driver（asyncpg / aiosqlite）
- Django 同步 ORM 在 async view 中用 `sync_to_async` 包装，但性能差，推荐用 Django async ORM

```python
# ✅ FastAPI + SQLAlchemy async
@router.get("/users")
async def list_users(session: AsyncSession = Depends(get_session)):
    result = await session.execute(select(User))
    return result.scalars().all()

# ⚠️ Django sync ORM wrapper（过渡方案）
from asgiref.sync import sync_to_async
users = await sync_to_async(list)(User.objects.filter(is_active=True))
```

## GIL 约束与 CPU 任务 🔴

- Python GIL 限制同一时间只有一个线程执行 Python 字节码
- CPU 密集型任务**必须**用 `ProcessPoolExecutor`（多进程），不用 `ThreadPoolExecutor`

```python
# ✅ CPU 密集：多进程
from concurrent.futures import ProcessPoolExecutor

def heavy_cpu(data): ...
with ProcessPoolExecutor(max_workers=4) as executor:
    results = executor.map(heavy_cpu, large_dataset)

# ❌ CPU 密集多线程（GIL 下无效）
with ThreadPoolExecutor() as executor:  # 多线程同样慢
    executor.map(heavy_cpu, large_dataset)
```

## 线程安全 🔴

- FastAPI `Depends` 是请求级隔离，但模块级可变变量不是线程安全的
- **禁止**在模块级使用可变全局状态（dict/list set 缓存等）

```python
# ❌ 模块级可变缓存（非线程安全）
_cache: dict = {}  # 多请求同时读写 → 数据竞态

# ✅ 使用 lru_cache / Redis / 数据库做缓存
from functools import lru_cache

@lru_cache(maxsize=128)
def get_config(key: str) -> str: ...
```

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| async 函数中调用同步阻塞方法 | 阻塞事件循环 |
| 串行 await 无依赖调用 | 性能浪费 |
| CPU 密集任务用 ThreadPoolExecutor | GIL 下无效 |
| 模块级可变全局状态 | 线程不安全 |
| `asyncio.create_task` 不等待不 cancel | 协程泄漏 |
| 生产环境用 `uvicorn` 不加 `--workers` | 单核瓶颈 |
