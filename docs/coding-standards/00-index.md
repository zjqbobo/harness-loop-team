# 编码规范 — 技术栈路由索引

根据项目技术栈自动路由到对应编码规范。检测规则按优先级排序，命中第一个即停。

## 技术栈检测

| 检测信号 | 技术栈 | 规范目录 |
|---|---|---|
| `pom.xml` / `build.gradle` / `build.gradle.kts`（无 AndroidManifest.xml） | **Java** | [`java/00-index.md`](java/00-index.md) |
| `build.gradle.kts` + `AndroidManifest.xml` | **Android/Kotlin** | [`android/00-index.md`](android/00-index.md) |
| `*.xcodeproj` / `*.xcworkspace` | **iOS/Swift** | [`ios/00-index.md`](ios/00-index.md) |
| `pyproject.toml` / `setup.py` / `requirements.txt` / `Pipfile` | **Python** | [`python/00-index.md`](python/00-index.md) |
| `go.mod` | **Go** | [`go/00-index.md`](go/00-index.md) |
| `package.json` + `tsconfig.json` | **TypeScript** | [`typescript/00-index.md`](typescript/00-index.md) |
| `package.json`（无 tsconfig.json） | **JavaScript** | [`typescript/00-index.md`](typescript/00-index.md)（忽略类型相关条目） |
| `.csproj` / `.sln` / `Directory.Build.props` | **.NET/C#** | [`dotnet/00-index.md`](dotnet/00-index.md) |
| `Cargo.toml` | **Rust** | TODO |
| 以上均未命中 | **通用** | 仅加载本文档的通用纪律 |

## 通用纪律（所有技术栈生效）

1. 命名与领域术语表一致（参考 `docs/business/domain-glossary.md`）
2. 禁止凭印象生成代替读规范
3. 编码完成后必须询问用户是否继续测试（见 `harness-testing`）
4. 错误沉淀按 `00-harness-core/knowledge-index.yaml` 判重后写入对应位置
5. 方法/函数不超过 80 行，圈复杂度不超过 10
6. 魔法值/硬编码字符串必须提取为常量

## 共享跨栈规范（所有后端栈生效）

以下规范核心原则语言无关，各技术栈索引中已有引用。完整内容见各文件：

| 规范 | 核心规则 | 文件 |
|------|---------|------|
| REST API 设计 | URL 名词复数、HTTP method 语义、统一响应格式 `{code,message,data}`、分页必须、版本管理 | [rest-api-design.md](rest-api-design.md) |
| 配置管理 | 配置与代码分离、敏感配置禁止提交 Git、`.env.example` 模式、环境变量命名 `<APP>_<KEY>` | [configuration-management.md](configuration-management.md) |
| 缓存策略 | Cache-Aside 模式、穿透/击穿/雪崩防护、TTL 加随机偏移、禁止缓存实时性数据 | [cache-strategy.md](cache-strategy.md) |
| 幂等性设计 | 支付/订单/消息消费必须幂等、Idempotency-Key 模式、数据库唯一约束兜底、MQ 消息 ID 去重 | [idempotency-design.md](idempotency-design.md) |

## 违规等级

| 等级 | 含义 | 处理 |
|---|---|---|
| 🔴 强制 | 违反则代码不可合并 | 必须修复 |
| 🟡 建议 | 推荐遵守，提升代码质量 | 尽量修复 |
| 🔵 参考 | 特定场景适用 | 酌情采用 |

## 三层覆盖

技术栈规范同样遵循三层覆盖：项目 `.harness/` > `~/.claude/harness.local/` > `~/.claude/harness/`。
