# iOS/Swift 日志规范

## 日志框架 🔴

```swift
// ✅ os.Logger（iOS 14+ 推荐——Apple 官方，高性能）
import OSLog

let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example", category: "Networking")

// 使用
logger.debug("请求开始 url=\(url, privacy: .public)")
logger.info("用户登录成功 userID=\(userID, privacy: .private(mask: .hash))")
logger.error("接口调用失败: \(error.localizedDescription, privacy: .public)")
logger.fault("数据库损坏——需立即处理")
```

## 日志级别 🔴

| 级别 | Logger 函数 | 场景 |
|------|-----------|------|
| Debug | `logger.debug()` | 开发调试、函数入参 |
| Info | `logger.info()` | 业务关键节点 |
| Error | `logger.error()` | 需要关注的错误 |
| Fault | `logger.fault()` | 系统级严重问题 |

## 隐私保护 🔴

```swift
// ✅ 默认隐私（仅在设备本地可见）
logger.info("用户名=\(username, privacy: .private)")  // 默认：本地可见

// ✅ 公开信息（在日志收集工具中可见）
logger.info("请求 URL=\(url, privacy: .public)")

// ✅ 哈希脱敏（可跨日志关联但不能反解）
logger.info("用户ID=\(userID, privacy: .private(mask: .hash))")

// ❌ print（禁止——无级别、无隐私控制、无持久化）
print("用户登录: \(username)")
```

## 日志分类 🟡

```swift
// ✅ 按功能模块分 category
extension Logger {
    static let networking = Logger(subsystem: subsystem, category: "Networking")
    static let database = Logger(subsystem: subsystem, category: "Database")
    static let auth = Logger(subsystem: subsystem, category: "Authentication")
    static let ui = Logger(subsystem: subsystem, category: "UI")
}
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `print()` / `debugPrint()` | 无级别、无持久化、无隐私控制 | `Logger` |
| `NSLog()` | 同步写入、性能差 | `Logger` |
| 日志中输出 Token/密码明文 | 安全合规 | `.private(mask: .hash)` |
| Release 中输出 Debug 日志 | 泄露信息 | Debug/Info 自动过滤 |
