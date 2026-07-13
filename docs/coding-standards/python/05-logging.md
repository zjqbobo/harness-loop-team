# Python 日志规范

## 日志框架 🔴

```python
import logging

# ✅ logging 模块（禁止 print）
logger = logging.getLogger(__name__)

# 模块级 logger，`__name__` 自动反映层次
# myapp.service.user_service → logger name: "myapp.service.user_service"
```

## 日志级别 🔴

| 级别 | 场景 | 示例 |
|------|------|------|
| `DEBUG` | 开发调试、入参值、中间变量 | `logger.debug("SQL: %s", sql)` |
| `INFO` | 业务关键节点、状态变更 | `logger.info("订单创建成功 order_id=%s", oid)` |
| `WARNING` | 可恢复异常、降级、重试 | `logger.warning("缓存未命中 key=%s, 降级查DB", key)` |
| `ERROR` | 需要人工处理、外部调用失败 | `logger.error("支付接口超时 order_id=%s", oid, exc_info=True)` |
| `CRITICAL` | 系统级告警、数据损坏 | `logger.critical("DB 主库不可达")` |

## 日志内容规范 🔴

```python
# ✅ 结构化信息：key=value 格式
logger.info("用户登录 user_id=%s ip=%s provider=%s", user_id, ip, provider)

# ❌ 自然语言（难以检索）
logger.info(f"用户 {user_id} 从 {ip} 通过 {provider} 登录了系统")

# ✅ 异常必须带 exc_info
try:
    call_payment_api(order)
except PaymentError:
    logger.error("支付失败 order_id=%s", order.id, exc_info=True)

# ❌ 不带堆栈的异常日志
logger.error(f"支付失败: {e}")  # 堆栈丢了
```

## 占位符 vs f-string 🔴

```python
# ✅ %s 占位符（惰性求值，DEBUG 级别不输出时不计算）
logger.debug("计算结果: result=%s", heavy_computation())

# ❌ f-string（总是求值，DEBUG 禁用时仍计算）
logger.debug(f"计算结果: {heavy_computation()}")  # 浪费！

# ✅ 多条信息
logger.info("订单处理 order_id=%s status=%s amount=%s", oid, status, amount)
```

## 结构化日志 🟡

生产环境推荐结构化日志以便检索：

```python
# python-json-logger
import logging
from pythonjsonlogger import jsonlogger

handler = logging.StreamHandler()
handler.setFormatter(jsonlogger.JsonFormatter(
    "%(asctime)s %(name)s %(levelname)s %(message)s"
))
logger.addHandler(handler)

# 输出 JSON：
# {"asctime": "2025-01-01T00:00:00", "name": "myapp.api", "levelname": "INFO",
#  "message": "请求处理完成 method=GET path=/users status=200 duration_ms=45"}
```

## 请求追踪 🟡

```python
# middleware 中注入 trace_id
import uuid
from contextvars import ContextVar

trace_id_var: ContextVar[str] = ContextVar("trace_id", default="")

class TraceFilter(logging.Filter):
    def filter(self, record):
        record.trace_id = trace_id_var.get()
        return True

# 配置
handler.addFilter(TraceFilter())
formatter = logging.Formatter(
    "%(asctime)s [%(trace_id)s] %(levelname)s %(name)s: %(message)s"
)
```

## 敏感信息脱敏 🔴

```python
import re

def mask_sensitive(msg: str) -> str:
    """脱敏：手机号、身份证、密码"""
    msg = re.sub(r'(?<=\D)\d{11}(?=\D)', '***PHONE***', msg)
    msg = re.sub(r'(?<=\D)\d{18}(?=\D)', '***ID***', msg)
    msg = re.sub(r'password[=:]\s*\S+', 'password=***', msg, flags=re.IGNORECASE)
    return msg

# ✅ 日志中永远不出现：
# - 密码明文
# - Token/API Key
# - 身份证号
# - 银行卡号
# - 手机号/邮箱（视合规要求）
```

## 配置模板 🔴

```python
# core/logging_config.py
import logging
import sys

def setup_logging(level: str = "INFO", json_format: bool = False):
    config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "standard": {
                "format": "%(asctime)s [%(levelname)s] %(name)s: %(message)s",
            },
        },
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "stream": sys.stdout,
                "formatter": "standard",
            },
        },
        "root": {
            "level": level,
            "handlers": ["console"],
        },
        "loggers": {
            "sqlalchemy": {"level": "WARNING"},   # SQL 日志太吵
            "uvicorn": {"level": "INFO"},
        },
    }
    logging.config.dictConfig(config)
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `print()` 输出日志 | 无级别、无时间戳、无法控制 | `logger.info()` |
| f-string 拼接日志消息 | 惰性求值失效 | `%s` 占位符 |
| 日志中输出密码/Token/身份证 | 安全合规 | 脱敏或跳过 |
| `logger.error()` 不带 `exc_info` | 堆栈丢失无法定位 | `exc_info=True` |
| 循环内无节制 `logger.info` | 日志轰炸 | 控制频率或降级到 DEBUG |
