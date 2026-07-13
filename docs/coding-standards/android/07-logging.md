# Android/Kotlin 日志规范

## 日志框架 🔴

```kotlin
// ✅ Timber（推荐——自动处理 TAG、Release 静默）
// build.gradle.kts
dependencies {
    implementation("com.jakewharton.timber:timber:5.0.1")
}

// Application.onCreate()
class App : Application() {
    override fun onCreate() {
        super.onCreate()
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        }
        // Release 不 plant，自动静默
    }
}

// 使用
Timber.d("用户登录 userID=%s", userId)
Timber.i("订单创建 orderID=%s", orderId)
Timber.w("缓存未命中 key=%s", cacheKey)
Timber.e(exception, "支付接口调用失败 orderID=%s", orderId)
```

## 日志级别 🔴

| 级别 | Timber | 场景 |
|------|--------|------|
| Verbose | `Timber.v()` | 极详细调试 |
| Debug | `Timber.d()` | 开发调试、函数入参 |
| Info | `Timber.i()` | 业务关键节点 |
| Warn | `Timber.w()` | 可恢复异常、降级 |
| Error | `Timber.e(ex, msg)` | 需要处理的错误 |
| WTF | `Timber.wtf()` | 永不应发生的错误 |

## 日志规范 🔴

```kotlin
// ✅ TAG 自动推断（类名），无需手动设置
class OrderRepository {
    fun createOrder(order: Order) {
        Timber.i("创建订单 orderID=%s amount=%.2f", order.id, order.amount)
    }
    // 输出：D/OrderRepository: 创建订单 orderID=123 amount=199.99
}

// ❌ 字符串拼接（性能浪费）
Timber.d("用户 " + userId + " 从 " + ip + " 登录")

// ✅ 占位符（惰性求值）
Timber.d("用户 %s 从 %s 登录", userId, ip)

// ❌ android.util.Log 直接使用（禁止——无自动 TAG、无 Release 控制）
Log.d("MyTag", "message")

// ❌ println / printStackTrace（禁止——输出到 stdout，无级别）
e.printStackTrace()
```

## 敏感信息脱敏 🔴

```kotlin
// ✅ 自定义 Timber Tree 脱敏
class ReleaseTree : Timber.Tree() {
    override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
        val sanitized = message
            .replace(Regex("password=[^&\\s]+"), "password=***")
            .replace(Regex("token=[^&\\s]+"), "token=***")
        // 发送到 Crashlytics / 日志服务
    }
}
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `Log.d/e/wtf` 直接使用 | 无自动 TAG、Release 不受控 | `Timber.d/e` |
| `println` / `printStackTrace` | 输出到 stdout | `Timber.e(exception, msg)` |
| 日志中输出 Token/密码 | 安全合规 | 脱敏或跳过 |
| Release 中输出 Debug 日志 | 泄露信息 | `BuildConfig.DEBUG` 判断 |
