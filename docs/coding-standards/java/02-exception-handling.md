# 异常处理规范

## 异常分类

| 类型 | 基类 | 场景 | 处理方式 |
|------|------|------|---------|
| 业务异常 | `BizException` | 参数不合法、业务规则不满足、状态不允许 | 全局捕获，返回业务错误码+消息 |
| 系统异常 | `RuntimeException` | 空指针、数组越界、类型转换失败 | 全局捕获，返回通用错误，记录日志 |
| 框架异常 | 各框架自带 | 数据库连接失败、网络超时、序列化失败 | 全局捕获，返回通用错误，告警 |

## 全局异常处理 🔴

必须配置 `@RestControllerAdvice` 全局异常处理器，覆盖以下场景：

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    // 1. 业务异常 → 返回业务错误码
    @ExceptionHandler(BizException.class)
    public Result<?> handleBizException(BizException e) {
        log.warn("业务异常: code={}, msg={}", e.getCode(), e.getMessage());
        return Result.fail(e.getCode(), e.getMessage());
    }

    // 2. 参数校验异常 → 返回具体字段错误
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public Result<?> handleValidation(MethodArgumentNotValidException e) {
        // 提取字段级错误信息
    }

    // 3. 兜底异常 → 返回通用错误 + 记录 ERROR 日志
    @ExceptionHandler(Exception.class)
    public Result<?> handleException(Exception e) {
        log.error("系统异常", e);
        return Result.fail("SYSTEM_ERROR", "系统繁忙，请稍后重试");
    }
}
```

## BizException 定义 🔴

```java
public class BizException extends RuntimeException {
    private final String code;    // 业务错误码，如 "ORDER_NOT_FOUND"
    private final String message; // 用户可读消息

    public BizException(ErrorCode errorCode) { ... }
    public BizException(ErrorCode errorCode, Object... args) { ... }
}
```

- 错误码必须使用枚举 `ErrorCode`，禁止硬编码字符串
- 每个模块定义自己的错误码范围

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `catch (Exception e) {}` | 吞掉异常，静默失败 | 至少 log.error + 抛出或返回错误 |
| `e.printStackTrace()` | 输出到 stdout，生产环境不可见 | 使用 `log.error("描述", e)` |
| `catch` 后不处理 | 隐藏问题 | 记录日志 + 重新抛出或返回错误 |
| 在循环中 `try-catch` | 性能差，逻辑混乱 | 循环外处理，或校验前置 |
| 用异常控制业务流程 | 异常不是流程控制工具 | 用 if/else 判断条件 |

## 异常日志规范 🔴

- **业务异常**：`log.warn`，不含堆栈（堆栈无诊断价值）
- **系统异常**：`log.error`，必须带堆栈 `log.error("描述", e)`
- **框架异常**：`log.error`，带堆栈 + 关键上下文（如请求 URL、参数）
