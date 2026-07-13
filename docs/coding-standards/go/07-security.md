# Go 安全编码规范

## SQL 注入防护 🔴

- 使用参数化查询（`$1`/`?` 占位符），**禁止** fmt.Sprintf 拼接 SQL
- 动态排序/分组/表名字段**必须**白名单校验

```go
// ✅ database/sql 参数化
row := db.QueryRow(
    "SELECT * FROM users WHERE name = $1",
    name,
)

// ✅ 动态排序白名单
var allowedSort = map[string]bool{"id": true, "created_at": true, "name": true}
func ListUsers(sort string) ([]User, error) {
    if !allowedSort[sort] {
        return nil, ErrInvalidSortField
    }
    return repo.ListByOrder(sort)
}

// ❌ 字符串拼接
query := fmt.Sprintf("SELECT * FROM users WHERE name = '%s'", name)  // SQL 注入
```

## XSS 防护 🔴

- API 响应设置 `Content-Type: application/json`（非 `text/html`）
- 模板引擎（html/template）自动转义 HTML，但用 `template.HTML` 类型时需先清洗

```go
// ✅ html/template 自动转义
tmpl.Execute(w, data)  // 自动对 {{.}} 做 HTML 编码

// ⚠️ 使用 template.HTML 前必须清洗
import "github.com/microcosm-cc/bluemonday"
safeHTML := bluemonday.UGCPolicy().Sanitize(userInput)
```

## 敏感信息保护 🔴

| 禁止 | 正确做法 |
|------|---------|
| 代码中硬编码密码/密钥 | 环境变量 / Vault / K8s Secret |
| 日志中打印密码/Token/身份证 | 脱敏处理 |
| 密钥提交到 Git | `.gitignore` 排除 `.env`，使用 `os.Getenv()` |

```go
// ✅ 环境变量
secretKey := os.Getenv("APP_SECRET_KEY")
if secretKey == "" {
    log.Fatal("APP_SECRET_KEY not set")
}

// ✅ 日志脱敏
slog.Info("用户登录", "phone", maskPhone(phone))  // 138****1234

// ❌ 硬编码
const secretKey = "sk-abc123def456"
```

## 认证与授权 🔴

- 所有接口默认需要认证，通过中间件统一校验
- JWT Token: Access Token ≤ 15min，Refresh Token ≤ 7d
- 权限校验在中间件层做，不在 Handler 里散落

```go
// ✅ 中间件统一认证
func AuthMiddleware(jwtSecret string) gin.HandlerFunc {
    return func(c *gin.Context) {
        token := c.GetHeader("Authorization")
        if token == "" {
            c.JSON(401, gin.H{"error": "未认证"})
            c.Abort()
            return
        }
        claims, err := jwt.Parse(token[7:], jwtSecret)  // Bearer xxx
        if err != nil {
            c.JSON(401, gin.H{"error": "Token 失效"})
            c.Abort()
            return
        }
        c.Set("user", claims)
        c.Next()
    }
}
```

## 密码存储 🔴

- 使用 `bcrypt`（cost ≥ 12），**禁止** MD5/SHA1/SHA256 直接哈希

```go
import "golang.org/x/crypto/bcrypt"

// ✅ bcrypt
hash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)  // cost=10
err := bcrypt.CompareHashAndPassword(hash, []byte(inputPassword))

// ❌ MD5/SHA256 直接哈希
hash := md5.Sum([]byte(password))   // 彩虹表秒破
```

## 文件上传安全 🔴

- 限制文件大小（`http.MaxBytesReader`）
- 校验文件类型（Magic Number，非扩展名）
- 上传路径不在 Web 可访问目录，文件名 UUID 化

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| fmt.Sprintf 拼接 SQL | SQL 注入 |
| 硬编码密钥/密码 | 安全泄露 |
| MD5/SHA1 存密码 | 彩虹表破解 |
| 日志打印明文敏感信息 | 数据泄露 |
| 文件上传不做类型检查 | 任意文件上传 |
| 模板中使用 `template.HTML` 直接放用户输入 | XSS |
