# Python 错误处理规范

## 异常体系 🔴

```
Exception
├── AppError（应用基类，继承 Exception）
│   ├── BizError（业务异常：参数不合法、状态不允许、规则不满足）
│   ├── NotFoundError（资源不存在）
│   ├── AuthError（认证失败 401）
│   ├── ForbiddenError（权限不足 403）
│   └── ValidationError（入参校验失败 422）
├── SystemError（系统异常：DB 连接、网络超时）
└── ExternalError（外部服务异常）
```

### 异常定义 🔴

```python
# core/exceptions.py
from typing import Optional

class AppError(Exception):
    """应用异常基类"""
    def __init__(self, code: str, message: str, detail: Optional[dict] = None):
        self.code = code          # 错误码，如 "USER_NOT_FOUND"
        self.message = message    # 用户可读消息
        self.detail = detail or {}
        super().__init__(message)

class BizError(AppError):
    """业务异常 — HTTP 400"""
    pass

class NotFoundError(AppError):
    """资源不存在 — HTTP 404"""
    pass

class AuthError(AppError):
    """认证失败 — HTTP 401"""
    pass

class ValidationError(AppError):
    """参数校验失败 — HTTP 422"""
    def __init__(self, message: str, errors: list[dict]):
        super().__init__("VALIDATION_ERROR", message, {"errors": errors})
```

- 错误码必须使用常量/枚举，禁止硬编码字符串

## 全局异常处理 🔴

### FastAPI

```python
# api/error_handler.py
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import logging

logger = logging.getLogger(__name__)

def register_error_handlers(app: FastAPI):
    @app.exception_handler(AppError)
    async def handle_app_error(request: Request, exc: AppError):
        status_map = {
            "NOT_FOUND": 404,
            "AUTH_ERROR": 401,
            "FORBIDDEN": 403,
            "VALIDATION_ERROR": 422,
        }
        status = status_map.get(exc.code, 400)
        logger.warning("业务异常: code=%s msg=%s path=%s", exc.code, exc.message, request.url.path)
        return JSONResponse(
            status_code=status,
            content={"error": {"code": exc.code, "message": exc.message, "detail": exc.detail}}
        )

    @app.exception_handler(Exception)
    async def handle_unexpected(request: Request, exc: Exception):
        logger.error("系统异常 path=%s", request.url.path, exc_info=exc)
        return JSONResponse(
            status_code=500,
            content={"error": {"code": "INTERNAL_ERROR", "message": "服务器内部错误"}}
        )
```

### Django

```python
# middleware.py
from django.http import JsonResponse

class ErrorMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        try:
            return self.get_response(request)
        except AppError as e:
            return JsonResponse({"error": {"code": e.code, "message": e.message}}, status=400)
        except Exception as e:
            logger.error("系统异常", exc_info=e)
            return JsonResponse({"error": {"code": "INTERNAL_ERROR"}}, status=500)
```

## try/except 最佳实践 🔴

```python
# ✅ 捕获具体异常类型
try:
    user = user_repo.find_by_id(user_id)
except UserNotFoundError:
    raise NotFoundError("USER_NOT_FOUND", f"用户 {user_id} 不存在")

# ✅ 包装上下文后重新抛出
try:
    result = external_api.call(payload)
except ConnectionError as e:
    raise ExternalError("API_TIMEOUT", "外部服务调用超时") from e

# ❌ 裸抛 Exception（禁止）
try:
    do_something()
except Exception:   # 太宽泛
    pass

# ❌ 吞异常（禁止）
try:
    risky_operation()
except Exception:
    pass   # 静默失败，问题被隐藏

# ❌ 用异常控制业务流程（禁止）
def is_admin(user):
    try:
        return user.role == "admin"
    except AttributeError:
        return False
# ✅ 正确：显式判断
def is_admin(user):
    return getattr(user, "role", None) == "admin"
```

## 异常日志规范 🔴

| 异常类型 | 日志级别 | 是否带堆栈 | 示例 |
|---------|---------|-----------|------|
| 业务异常 (4xx) | `logger.warning` | ❌ 不带 | `logger.warning("用户不存在: user_id=%s", user_id)` |
| 系统异常 (5xx) | `logger.error` | ✅ 带 exc_info | `logger.error("DB 连接失败", exc_info=True)` |
| 外部服务异常 | `logger.error` | ✅ 带上下文 | `logger.error("调用支付接口超时 order_id=%s", oid, exc_info=True)` |

## 禁止行为清单 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `try: ... except: ...`（无异常类型） | 吞掉 KeyboardInterrupt/SystemExit | 始终指定异常类型 |
| `except Exception: pass` | 静默失败 | 至少记录日志 |
| `raise Exception("xxx")` | 无错误码，调用方无法区分处理 | 抛自定义异常 |
| 在循环中 try/catch | 性能差 | 校验前置或循环外处理 |
| `print(traceback.format_exc())` | 输出到 stdout，生产不可见 | `logger.error(..., exc_info=True)` |
