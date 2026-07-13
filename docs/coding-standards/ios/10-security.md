# iOS/Swift 安全编码规范

## 数据存储安全 🔴

| 数据类型 | 存储方式 |
|---------|---------|
| Token/密码/密钥 | **Keychain**（`kSecClassGenericPassword`），禁止 UserDefaults |
| 用户敏感信息 | Keychain + `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` |
| 数据库敏感字段 | SQLCipher / Core Data 字段级加密 |
| 缓存/临时文件 | `Caches/` 或 `tmp/`（系统可清理） |

```swift
// ✅ Keychain 存储 Token
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "authToken",
    kSecValueData as String: token.data(using: .utf8)!,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
]
SecItemAdd(query as CFDictionary, nil)

// ❌ UserDefaults 存 Token
UserDefaults.standard.set(token, forKey: "authToken")  // 不安全
```

## 网络安全 🔴

- 强制 HTTPS（App Transport Security）
- 证书固定（Certificate Pinning）防中间人
- 敏感请求加防重放（Timestamp + Signature）

```swift
// ✅ URLSession 证书固定（Info.plist）
// NSAppTransportSecurity → NSAllowsArbitraryLoads = false

// ✅ 自定义 URLProtocol 做证书校验
class PinningURLProtocol: URLProtocol {
    override func connection(_ connection: NSURLConnection,
        willSendRequestFor challenge: URLAuthenticationChallenge) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else { return }
        // 比对证书指纹
    }
}
```

## 敏感信息保护 🔴

| 禁止 | 正确做法 |
|------|---------|
| 代码中硬编码 API Key/Secret | `xcconfig` + 环境变量 / CI 注入 |
| `print()` 在生产代码中 | `os.Logger` + `.debug` 级别，Release 自动静默 |
| Info.plist 含敏感配置 | xcconfig 管理，不提交含密钥的 plist |

```swift
// ✅ xcconfig 注入
// Secrets.xcconfig（不提交 Git）:
// API_KEY = sk-abc123
// Info.plist 引用: $(API_KEY)

// ✅ 条件日志
let logger = Logger(subsystem: "com.app", category: "network")
logger.debug("API call: \(url, privacy: .public)")
logger.info("Token: \(token, privacy: .private)")  // Release 自动脱敏

// ❌ print 留在生产代码
print("Token: \(token)")  // Release 也能看到
```

## 认证与授权 🔴

- 使用 ASWebAuthenticationSession（OAuth）/ Sign in with Apple
- Biometric（Face ID / Touch ID）验证后才访问 Keychain 敏感项
- App 进入后台时隐藏敏感界面（`scenePhase` 监听）

```swift
// ✅ Biometric 保护 Keychain 项
let flags: SecAccessControlCreateFlags = [.userPresence, .devicePasscode]
let access = SecAccessControlCreateWithFlags(nil,
    kSecAttrAccessibleWhenUnlockedThisDeviceOnly, flags, nil)
```

## 代码完整性 🔴

- App Store 分发自动加密（FairPlay DRM）
- 调试模式检测（`#if DEBUG`），Release 包关闭调试功能

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| UserDefaults 存储 Token/密码 | 明文可读 |
| 硬编码 API Key/Secret | 安全泄露 |
| `Info.plist` 设置 `NSAllowsArbitraryLoads = true` | 信任所有证书 |
| `print()` 留在 Release 包 | 信息泄露 |
| Scheme 回调处理不做校验 | URL Scheme 劫持 |
| 敏感数据在应用切换到后台时显示 | 应用切换器泄露 |
