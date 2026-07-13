# TypeScript 错误处理规范

## 异步错误处理 🔴

```typescript
// ✅ async/await + try/catch
async function getUser(id: number): Promise<User> {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      throw new ApiError(response.status, "获取用户失败");
    }
    return await response.json();
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(500, "服务器内部错误", { cause: error });
  }
}

// ❌ 未处理的 Promise rejection
async function processData() {
  fetchData();  // 忘记 await，rejection 未被捕获
}

// ❌ 吞异常
try {
  await riskyOperation();
} catch {
  // 什么都不做
}
```

## 自定义错误类 🔴

```typescript
// shared/errors.ts
export class AppError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly statusCode: number = 400,
    public readonly details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "AppError";
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super("NOT_FOUND", `${resource} ${id} 不存在`, 404);
  }
}

export class ValidationError extends AppError {
  constructor(public readonly errors: Array<{ field: string; message: string }>) {
    super("VALIDATION_ERROR", "参数校验失败", 422, { errors });
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = "未登录或 Token 过期") {
    super("UNAUTHORIZED", message, 401);
  }
}
```

## API 统一错误响应 🔴

```typescript
// 统一错误响应格式
interface ErrorResponse {
  error: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
  };
}

// Express 全局错误处理
function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  if (err instanceof AppError) {
    logger.warn("业务异常", { code: err.code, message: err.message });
    res.status(err.statusCode).json({
      error: { code: err.code, message: err.message, details: err.details },
    });
    return;
  }

  logger.error("系统异常", err);
  res.status(500).json({
    error: { code: "INTERNAL_ERROR", message: "服务器内部错误" },
  });
}

// Fastify
app.setErrorHandler((error, _request, reply) => {
  if (error instanceof AppError) {
    reply.status(error.statusCode).send({ error: { code: error.code, message: error.message } });
    return;
  }
  reply.status(500).send({ error: { code: "INTERNAL_ERROR", message: "服务器内部错误" } });
});
```

## React Error Boundary 🔴

```tsx
// components/ErrorBoundary.tsx
class ErrorBoundary extends React.Component<
  { fallback: React.ReactNode; children: React.ReactNode },
  { hasError: boolean }
> {
  state = { hasError: false };

  static getDerivedStateFromError(): { hasError: boolean } {
    return { hasError: true };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo): void {
    logger.error("React 渲染错误", error, { componentStack: info.componentStack });
  }

  render(): React.ReactNode {
    if (this.state.hasError) return this.props.fallback;
    return this.props.children;
  }
}
```

## Result 模式（推荐）🟡

```typescript
// 避免 try/catch 泛滥，用 Result 类型表达可能失败的操作
type Result<T, E = AppError> = { success: true; data: T } | { success: false; error: E };

async function findUser(id: number): Promise<Result<User>> {
  try {
    const user = await userRepo.findById(id);
    if (!user) return { success: false, error: new NotFoundError("用户", String(id)) };
    return { success: true, data: user };
  } catch (error) {
    return { success: false, error: new AppError("DB_ERROR", "数据库查询失败", 500) };
  }
}

// 使用
const result = await findUser(123);
if (!result.success) {
  return res.status(result.error.statusCode).json({ error: result.error });
}
// result.data 类型安全
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| 空 `catch {}` | 静默失败 | 至少记录日志 |
| `throw "error string"` | 丢失堆栈 | `throw new AppError(...)` |
| 用错误码字符串判断 | 脆弱 | `instanceof AppError` |
| 在 useEffect 中不处理异步错误 | React 不会 catch | `try/catch` 或 `.catch()` |
| `JSON.parse` 不 wrap try/catch | 恶意/损坏的 JSON 直接崩溃 | 始终 try/catch |
