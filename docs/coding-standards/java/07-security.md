# Java/Spring 安全编码规范

## SQL 注入防护 🔴

- 使用 MyBatis `#{}` / JPA 参数绑定，**禁止** SQL 字符串拼接
- 动态排序/分组字段**必须**白名单校验后使用，禁止直接拼接入参

```java
// ✅ MyBatis #{} 预编译
@Select("SELECT * FROM users WHERE name = #{name}")
User findByName(@Param("name") String name);

// ✅ 动态排序白名单
private static final Set<String> ALLOWED_SORT_FIELDS = Set.of("id", "createdAt", "name");

public List<User> listByOrder(String orderBy) {
    if (orderBy == null || !ALLOWED_SORT_FIELDS.contains(orderBy)) {
        throw new BizException("非法排序字段");
    }
    return mapper.listByOrder(orderBy);
}

// ❌ 字符串拼接 SQL
String sql = "SELECT * FROM users WHERE name = '" + name + "'";   // SQL 注入
```

## XSS 防护 🔴

- 前端渲染时对用户输入做 HTML 实体编码
- 后端存储富文本时使用 HTML 白名单清洗库（Jsoup）

```java
// ✅ Jsoup 清洗富文本
String safeHtml = Jsoup.clean(rawHtml,
    Safelist.basic().addTags("img").addAttributes("img", "src", "alt"));
```

## 敏感信息保护 🔴

| 禁止 | 正确做法 |
|------|---------|
| 代码/配置文件中硬编码密码、密钥、Token | 使用环境变量 / Vault / K8s Secret |
| 日志中打印密码、Token、身份证、银行卡号 | 脱敏处理 |
| 接口返回 Entity 时连带敏感字段（passwordHash/salt） | DTO 过滤 |
| URL 参数传递 Token/sessionId | Header（Authorization）|

```java
// ❌ 硬编码密钥
private static final String SECRET_KEY = "sk-abc123";

// ✅ 环境变量注入
@Value("${app.secret-key}")
private String secretKey;

// ✅ 日志脱敏
log.info("用户登录: phone={}", maskPhone(phone));  // 138****1234

// ✅ Jackson 敏感字段过滤
public class UserVO {
    @JsonIgnore  // 永远不序列化到前端
    private String passwordHash;
}
```

## 认证与授权 🔴

- 所有接口默认需要认证（白名单例外），通过 Spring Security Filter 统一控制
- 权限校验用 `@PreAuthorize` 注解，不做硬编码角色判断
- JWT Token 设置合理过期时间（Access Token ≤ 15min，Refresh Token ≤ 7d）

```java
// ✅ 注解声明权限
@PreAuthorize("hasRole('ADMIN')")
public Result<?> deleteUser(Long id) { ... }

// ❌ 硬编码角色判断
if (!user.getRole().equals("admin")) { ... }
```

## CSRF 防护 🔴

- 非纯 API 项目（含页面的传统 Web）必须启用 Spring Security CSRF
- 纯 REST API 项目（无 Session、JWT Bearer 认证）可不启用

## 文件上传安全 🔴

- 校验文件类型（Magic Number 检查）
- 限制文件大小
- 存储路径不在 Web 可访问目录

```java
// ✅ 类型校验
String contentType = Files.probeContentType(tempFile.toPath());
if (!ALLOWED_TYPES.contains(contentType)) {
    throw new BizException("不支持的文件类型");
}
```

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| SQL 字符串拼接 | SQL 注入 |
| 硬编码密钥/密码 | 安全泄露 |
| 日志打印明文敏感信息 | 数据泄露 |
| API 返回 passwordHash/salt | 撞库风险 |
| 文件上传不做类型/大小检查 | 任意文件上传漏洞 |
| 用户输入未经清洗直接回显 | XSS |
