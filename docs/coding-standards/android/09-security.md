# Android/Kotlin 安全编码规范

## 数据存储安全 🔴

| 数据类型 | 存储方式 |
|---------|---------|
| Token/密钥 | **EncryptedSharedPreferences** 或 **Android Keystore**，禁止明文 SharedPreferences |
| 用户凭证 | Android Keystore（非对称加密存储） |
| 数据库敏感字段 | SQLCipher / Room + 字段级加密 |
| 缓存文件 | `context.cacheDir`（系统可清理），禁止存 `context.filesDir` |

```kotlin
// ✅ EncryptedSharedPreferences
val sharedPref = EncryptedSharedPreferences.create(
    "secure_prefs",
    MasterKey.Builder(context).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
    context,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
)

// ❌ 明文存储 Token
val prefs = context.getSharedPreferences("app", Context.MODE_PRIVATE)
prefs.edit().putString("token", accessToken).apply()  // 不安全
```

## 网络安全 🔴

- 使用 HTTPS（强制，Android 9+ 默认阻止 HTTP）
- `res/xml/network_security_config.xml` 配置证书固定（Certificate Pinning），禁止信任所有证书
- 敏感 API 请求中加入防重放机制（Timestamp + Nonce）

```xml
<!-- res/xml/network_security_config.xml -->
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">api.example.com</domain>
        <pin-set>
            <pin digest="SHA-256">sha256/xxxxxxxxxxxxxxxxxxxxx</pin>
        </pin-set>
    </domain-config>
</network-security-config>
```

## 代码混淆与加固 🔴

- Release 构建**必须开启** ProGuard/R8 混淆
- 混淆规则排除反射调用的类（Retrofit/Gson/Hilt）

## 敏感信息保护 🔴

| 禁止 | 正确做法 |
|------|---------|
| 代码中硬编码 API Key/Token | `BuildConfig` + 环境变量注入（CI），或服务端下发 |
| 日志中打印 Token/密码/身份证 | Timber + Release 模式静默 |
| Logcat 打印敏感信息 | `if (BuildConfig.DEBUG) { Timber.d(...) }` |

```kotlin
// ✅ 条件日志
if (BuildConfig.DEBUG) {
    Timber.d("API call: %s", url)
}

// ❌ 日志中包含 Token
Timber.d("Token: %s", accessToken)  // 泄露到 Logcat
```

## WebView 安全 🟡

- 禁止 `setJavaScriptEnabled(true)` + `setAllowFileAccess(true)` 同时开启
- JavaScript 接口方法加 `@JavascriptInterface` 注解
- WebView 不加载 `file://` URL

## 权限最小化 🔴

- 仅请求必要权限
- 运行时权限检查（`checkSelfPermission`），不要在 Manifest 中堆积权限
- 敏感权限（定位/摄像头/通讯录）在使用前向用户解释用途

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| SharedPreferences 存储明文 Token | 数据泄露 |
| 硬编码 API Key / Secret | 安全泄露 |
| `AllowAllHostnameVerifier` / 信任所有证书 | 中间人攻击 |
| Release 包保留 Debug 日志 | 信息泄露 |
| `setAllowFileAccess(true)` + JavaScript 开启 | 跨源攻击 |
| 在 UI 线程做加密操作 | ANR |
