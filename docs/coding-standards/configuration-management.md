# 配置管理规范

> 适用：所有技术栈

## 核心原则 🔴

**配置与代码分离** — 任何可能在不同环境（开发/测试/生产）变化的值，都不得硬编码在代码中。

## 配置分类

| 类别 | 存储方式 | 示例 |
|------|---------|------|
| **非敏感配置** | 配置文件 + 环境变量覆盖 | 数据库地址、日志级别、超时时间 |
| **敏感配置** | 密钥管理服务 / K8s Secret / CI 变量注入，**禁止**提交 Git | 数据库密码、API Key、JWT Secret、加密密钥 |
| **业务配置** | 数据库 / 配置中心（动态可改） | 费率、开关、阈值 |
| **Feature Flag** | 配置中心 / LaunchDarkly | 灰度发布、A/B 测试 |

## 环境变量命名 🔴

```
<APP>_<COMPONENT>_<KEY>

示例：
  ACM_DATABASE_URL=postgres://...
  ACM_REDIS_HOST=redis.internal
  ACM_JWT_SECRET=xxx
  ACM_LOG_LEVEL=debug
```

- 统一大写 + 下划线
- 应用名前缀避免冲突
- 仅在 CI/CD 或 K8s ConfigMap/Secret 中注入，不提交到仓库

## 代码中读取配置 🔴

| 技术栈 | 工具 |
|--------|------|
| Java | `@Value` / `@ConfigurationProperties` + Spring Boot |
| TypeScript | `process.env.XXX` / `dotenv` / Zod 校验 |
| Go | `os.Getenv()` / `viper` |
| Python | `pydantic-settings` / `os.environ` |
| .NET | `IConfiguration` / `IOptions<T>` / User Secrets |
| Android | `BuildConfig` + CI 注入 |
| iOS | `xcconfig` + `Info.plist` 引用 |

```typescript
// ✅ 启动时校验（缺配置直接 crash，不运行时报错）
const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) throw new Error("DATABASE_URL is required");

export const config = { databaseUrl: DATABASE_URL };
```

## 配置文件层级 🟡

```
环境变量 > 特定环境配置文件 > 默认配置文件

约定：
  config/default.yml     ← 默认值（提交 Git）
  config/production.yml  ← 生产覆盖（提交 Git，不含密钥）
  .env                   ← 本地开发（不提交 Git！）
```

- `.env` / `.env.local` / `.env.production` **必须**在 `.gitignore` 中
- 提交 `.env.example`（只含字段名，值为空或占位符）

## 敏感信息管理 🔴

| 禁止 | 正确做法 |
|------|---------|
| 密钥/密码硬编码在代码注释中 | 环境变量或密钥管理服务 |
| `application.yml` / `appsettings.json` 含生产密钥 | 外部注入 |
| `.env` 提交 Git | `.gitignore` + `.env.example` |
| CI/CD 日志打印环境变量 | 标记为 Secret Variable |

```yaml
# ❌ application.yml（含密钥，不能提交）
jwt:
  secret: "my-super-secret-key"  # 危险！

# ✅ application.yml（只含非敏感默认值）
jwt:
  secret: ${JWT_SECRET}  # 环境变量注入
```

## Feature Flag 🟡

- 新功能 / 灰度发布用 Feature Flag，不靠代码分支（if/else + git branch）切换
- Flag 命名：`feature.<name>` / `temporary.<ticket-id>`
- 临时 Flag 必须在功能全量上线后清理

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 密钥/密码提交 Git | 安全泄露 |
| `.env` 提交 Git | 安全泄露 |
| 硬编码环境相关值（URL/端口/密钥） | 环境不可移植 |
| `config` 对象在运行时可变（应 immutable） | 运行时错误难排查 |
| CI 日志中打印密钥 | 安全泄露 |
