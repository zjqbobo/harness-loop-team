# Python 安全编码规范

## SQL 注入防护 🔴

- 使用 ORM/SQL 参数绑定，**禁止** f-string / `%` / `.format()` 拼接 SQL
- 动态排序/分组字段**必须**白名单校验

```python
# ✅ SQLAlchemy 参数绑定
user = await session.execute(select(User).where(User.name == name)).scalar_one_or_none()

# ✅ 原始 SQL 参数化（psycopg/databases）
row = await conn.execute("SELECT * FROM users WHERE name = $1", name)

# ✅ 动态排序白名单
ALLOWED_SORT = frozenset({"id", "created_at", "name"})
if sort not in ALLOWED_SORT:
    raise ValueError(f"非法排序字段: {sort}")

# ❌ f-string 拼接 SQL
query = f"SELECT * FROM users WHERE name = '{name}'"  # SQL 注入
```

## XSS 防护 🔴

- API 响应设 `Content-Type: application/json`
- Jinja2/Django 模板自动转义（不要用 `|safe` 过滤用户输入）
- 存储富文本使用 Bleach 清洗

```python
# ✅ Bleach 清洗
import bleach
safe_html = bleach.clean(raw_html, tags=["b", "i", "p", "a"], attributes={"a": ["href"]})

# ❌ 模板中标记用户输入为 safe
{{ user_input | safe }}  # XSS
```

## 敏感信息保护 🔴

| 禁止 | 正确做法 |
|------|---------|
| 代码中硬编码密码/密钥/Token | `pydantic-settings` / `os.environ` |
| `.env` 提交到 Git | `.gitignore`，仅提交 `.env.example` |
| 日志中打印密码/Token | 自定义 filter 脱敏 |

```python
# ✅ pydantic-settings
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    secret_key: str
    database_url: str
    model_config = {"env_file": ".env"}

settings = Settings()  # Settings 实例不提交到 Git

# ✅ 日志脱敏 filter
class SensitiveDataFilter(logging.Filter):
    def filter(self, record):
        if hasattr(record, "msg"):
            record.msg = re.sub(r'"password":\s*"[^"]*"', '"password": "***"', str(record.msg))
        return True
```

## 认证与授权 🔴

- 所有接口默认需要认证，通过 FastAPI `Depends` 统一注入
- JWT Token: Access ≤ 15min，Refresh ≤ 7d，Refresh Token 轮换
- 权限校验用 `Depends` 依赖链，不在路由内部散落

```python
# ✅ FastAPI 依赖注入认证
async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=["HS256"])
        return await user_service.get_by_id(payload["sub"])
    except JWTError:
        raise HTTPException(status_code=401, detail="Token 失效")

@router.get("/users/me")
async def me(user: User = Depends(get_current_user)) -> UserDTO:
    ...
```

## 密码存储 🔴

- 使用 `bcrypt` 或 `argon2`，**禁止** MD5/SHA1/SHA256

```python
# ✅ bcrypt
import bcrypt
hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))

# ❌ hashlib 直接哈希
hash = hashlib.md5(password.encode()).hexdigest()  # 不安全
```

## 反序列化安全 🔴

- **禁止** `pickle.loads()` 处理不可信数据（RCE 风险）
- 使用 `json.loads()` 或 `pydantic` model 校验外部输入

## 文件上传安全 🔴

- 限制文件大小
- 校验文件类型（Magic Number，`python-magic`）
- 文件名 UUID 化，禁止保留用户原始文件名

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| f-string 拼接 SQL | SQL 注入 |
| 硬编码密钥/密码 | 安全泄露 |
| `pickle.loads()` 处理不可信数据 | 远程代码执行 |
| `.env` 提交 Git | 密钥泄露 |
| 日志打印明文敏感信息 | 数据泄露 |
| 模板 `{% raw %}{{ user_input \| safe }}{% endraw %}` | XSS |
