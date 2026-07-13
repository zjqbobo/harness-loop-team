# .NET/C# 安全编码规范

## SQL 注入防护 🔴

- 使用 EF Core / Dapper 参数化查询，**禁止**字符串拼接 SQL
- 动态排序字段**必须**白名单校验

```csharp
// ✅ EF Core 参数化
var user = await context.Users.FirstOrDefaultAsync(u => u.Name == name);

// ✅ Dapper 参数化
var user = await conn.QueryFirstOrDefaultAsync<User>(
    "SELECT * FROM Users WHERE Name = @Name", new { Name = name });

// ✅ 动态排序白名单
private static readonly HashSet<string> AllowedSort = new() { "Id", "CreatedAt", "Name" };
if (!AllowedSort.Contains(orderBy))
    throw new ValidationException("非法排序字段");

// ❌ 字符串拼接
var sql = $"SELECT * FROM Users WHERE Name = '{name}'";  // SQL 注入
```

## XSS 防护 🔴

- Razor View 自动 HTML 编码（`@Model.Name` 安全，`@Html.Raw()` 危险）
- Web API 返回 JSON 不会被浏览器当 HTML 解析，但仍需注意富文本清洗

```csharp
// ✅ HtmlSanitizer 清洗
var sanitizer = new HtmlSanitizer();
var safeHtml = sanitizer.Sanitize(rawHtml);

// ❌ Razor 中直接渲染用户输入为 HTML
@Html.Raw(Model.UserInput)  // XSS
```

## 敏感信息保护 🔴

| 禁止 | 正确做法 |
|------|---------|
| 代码/配置文件中硬编码密码/密钥 | User Secrets（开发）/ Azure Key Vault / AWS Secrets Manager / 环境变量 |
| `appsettings.json` 提交生产密钥 | 仅提交非敏感默认值，生产密钥外部注入 |
| 日志中打印密码/Token/身份证 | 脱敏处理 |

```csharp
// ✅ User Secrets（开发环境）
// dotnet user-secrets set "SecretKey" "xxx"
var secret = builder.Configuration["SecretKey"];

// ✅ 日志脱敏 — 重写 ToString 或用结构化日志字段过滤
logger.LogInformation("用户登录: Phone={Phone}", MaskPhone(phone));
```

## 认证与授权 🔴

- 使用 ASP.NET Core Identity / JWT Bearer，所有 API 默认需认证
- 权限用 `[Authorize(Roles = "...")]` 或 Policy-based 授权
- JWT: Access Token ≤ 15min，Refresh Token ≤ 7d，Refresh Token 旋转

```csharp
// ✅ Policy-based 授权
[Authorize(Policy = "RequireAdminRole")]
public async Task<ActionResult> DeleteUser(int id) { ... }

// ❌ 代码中硬编码角色判断
if (user.Role != "admin") return Forbid();
```

## CSRF 防护 🔴

- ASP.NET Core MVC（含 Razor Pages）自动启用 Anti-Forgery Token
- 纯 Web API（JWT 认证，无 Cookie Session）不需要
- SPA + Cookie 认证时，Cookie 设 `SameSite=Strict` + 使用 Anti-Forgery Header

## 密码存储 🔴

- 使用 ASP.NET Core Identity 内置 `PasswordHasher`（PBKDF2）
- 或 `BCrypt.Net-Next`（bcrypt）
- **禁止** MD5/SHA1/SHA256 直接哈希

## 文件上传安全 🔴

- 限制大小（`RequestSizeLimit`）
- 校验文件类型（Magic Number）
- 文件名 UUID 化，路径在 Web Root 外

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 字符串拼接 SQL | SQL 注入 |
| 硬编码密钥/密码 | 安全泄露 |
| `appsettings.json` 含生产密钥 | Git 泄露 |
| 日志打印明文敏感信息 | 数据泄露 |
| MD5/SHA1 存密码 | 彩虹表破解 |
| `Html.Raw()` 渲染用户输入 | XSS |
