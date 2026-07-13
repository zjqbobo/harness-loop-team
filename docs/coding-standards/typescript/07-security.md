# TypeScript 安全编码规范

## SQL/NoSQL 注入防护 🔴

- 使用 Prisma/Drizzle/TypeORM 的参数化查询，**禁止**原始拼接
- 动态排序/分组字段**必须**白名单校验

```typescript
// ✅ Prisma 参数化
const user = await prisma.user.findFirst({ where: { name: input.name } });

// ✅ 动态排序白名单
const ALLOWED_SORT = ["id", "createdAt", "name"] as const;
if (!ALLOWED_SORT.includes(req.sort)) throw new BadRequestError("非法排序字段");

// ❌ 字符串拼接
const query = `SELECT * FROM users WHERE name = '${name}'`;   // SQL 注入
```

## XSS 防护 🔴

- 前端：React 默认转义 JSX（`{userInput}` 安全，`dangerouslySetInnerHTML` 危险）
- 后端：存储用户输入前做清洗，API 响应设置 `Content-Type: application/json`（非 HTML）
- 禁止未经清洗的用户输入在 `dangerouslySetInnerHTML` / `v-html` / `innerHTML` 中使用

```typescript
// ✅ DOMPurify 清洗富文本（前端）
import DOMPurify from "dompurify";
const clean = DOMPurify.sanitize(dirty, { ALLOWED_TAGS: ["b", "i", "p", "a"] });

// ❌ 直接插入用户输入
element.innerHTML = userInput;  // XSS
<div dangerouslySetInnerHTML={{ __html: userInput }} />  // 未清洗 → XSS
```

## 敏感信息保护 🔴

| 禁止 | 正确做法 |
|------|---------|
| `.env` 文件提交到 Git | `.gitignore` 排除 `.env*`，仅提交 `.env.example` |
| 日志中打印密码/Token/身份证 | 脱敏处理 |
| 前端存储 JWT/密码到 localStorage | httpOnly Secure SameSite Cookie |
| 代码中硬编码 API Key/Secret | 环境变量 `process.env.XXX` |

```typescript
// ✅ 从环境变量读取
const apiKey = process.env.API_KEY;
if (!apiKey) throw new Error("API_KEY not configured");

// ❌ 硬编码
const apiKey = "sk-abc123def456";

// ✅ 日志脱敏
logger.info({ phone: maskPhone(phone) }, "用户登录");  // 138****1234

// ✅ Cookie 安全存储 Token（后端设置）
res.cookie("token", jwt, {
  httpOnly: true,    // JS 不可读
  secure: true,      // 仅 HTTPS
  sameSite: "strict",
  maxAge: 15 * 60 * 1000,  // 15min
});
```

## 认证与授权 🔴

- 所有 API 默认需要认证，通过中间件统一校验
- 前端路由：敏感页面做权限守卫，不依赖"隐藏 UI"做权限控制
- JWT 设置合理过期（Access ≤ 15min，Refresh ≤ 7d），Refresh Token 实现轮换机制

```typescript
// ✅ 中间件统一认证
export function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const token = req.cookies.token || req.headers.authorization?.split(" ")[1];
  if (!token) return res.status(401).json({ error: "未认证" });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET!);
    next();
  } catch {
    return res.status(401).json({ error: "Token 失效" });
  }
}
```

## CSRF 防护 🟡

- SPA + JWT（不基于 Cookie Session）可不启用 CSRF
- 基于 Cookie Session 的项目必须启用 CSRF Token（csurf/lusca）
- 使用 `sameSite: "strict"` Cookie 作为额外防线

## 前端安全 🟡

| 风险 | 防护 |
|------|------|
| npm 依赖漏洞 | `npm audit` / `yarn audit` 定期检查，CI 执行 |
| 第三方脚本注入 | 使用 Subresource Integrity (SRI) / CSP Header |
| open redirect | 跳转 URL 白名单校验，禁止 `window.location = userInput` |
| 敏感路由无权限守卫 | `<ProtectedRoute>` 组件包裹 |

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| SQL/NoSQL 拼接查询 | 注入攻击 |
| 硬编码密钥/密码 | 安全泄露 |
| `innerHTML` / `dangerouslySetInnerHTML` 直接插入用户输入 | XSS |
| localStorage 存储 Token/密码 | XSS 可读取 |
| `.env` 提交 Git | 密钥泄露 |
| 日志打印明文敏感信息 | 数据泄露 |
