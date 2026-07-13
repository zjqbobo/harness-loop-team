# 缓存策略规范

> 适用：所有后端技术栈（Java/TypeScript/Go/Python/.NET）

## 缓存分层

```
本地缓存（Caffeine/LRU/ConcurrentHashMap）
  → 分布式缓存（Redis/Memcached）
    → 数据库
```

**原则**：能本地缓存就不要远程，能远程就不要查库。

## 什么时候用缓存 🔴

| 场景 | 适合 | 不适合 |
|------|------|--------|
| 读多写少 | ✅ | — |
| 热点数据（频繁查询） | ✅ | — |
| 实时性要求高（库存/余额） | ❌ | 直接读库 |
| 数据一致性要求严格（支付结果） | ❌ | 直接读库 + 幂等 |
| 计算开销大 | ✅ | — |

## Cache-Aside 模式（推荐）🔴

```
读：
  1. 查缓存 → 命中返回
  2. 未命中 → 查 DB → 写入缓存 → 返回

写：
  1. 更新 DB
  2. 删除缓存（让下次读重新加载）
  （少用 更新缓存，避免并发写下缓存脏数据）
```

```java
// ✅ Cache-Aside 模式
public UserDTO getUser(Long id) {
    String key = "user:" + id;
    UserDTO cached = cache.get(key);
    if (cached != null) return cached;

    User user = userRepo.findById(id);
    UserDTO dto = userConverter.toDTO(user);
    cache.set(key, dto, Duration.ofMinutes(5));
    return dto;
}

// ❌ 先删缓存再写 DB（删除后、写 DB 前，其他请求可能读到旧数据写回缓存）
cache.delete(key);
repo.save(user);
```

## 缓存失效策略 🔴

| 策略 | 场景 | 注意 |
|------|------|------|
| **TTL（过期时间）** | 大多数场景 | 根据数据新鲜度要求设置（5min / 30min / 1h） |
| **主动失效** | 数据更新时 | 写操作后删除对应缓存 key |
| **LRU/LFU** | 内存缓存 | 内存不足时淘汰最少使用 |
| **Cascade 失效** | 关联数据 | 更新 A 时级联删除 A 相关的所有缓存 key |

## 缓存穿透/击穿/雪崩 🔴

| 问题 | 原因 | 方案 |
|------|------|------|
| **穿透** | 查不存在的数据，缓存没命中，每次穿透到 DB | 布隆过滤器 / 空值缓存（TTL 短） |
| **击穿** | 热点 key 过期瞬间大量请求打到 DB | 互斥锁（`SETNX`）/ 逻辑过期（永不过期+异步刷新） |
| **雪崩** | 大量 key 同时过期 | TTL 加随机偏移（TTL ± 20%）/ 多级缓存 |

```java
// ✅ 防止缓存穿透：空值缓存
public UserDTO getUser(Long id) {
    UserDTO cached = cache.get("user:" + id);
    if (cached != null) return cached == NULL_MARKER ? null : cached;

    User user = userRepo.findById(id);
    if (user == null) {
        cache.set("user:" + id, NULL_MARKER, Duration.ofMinutes(1));  // 缓存空值 1 分钟
        return null;
    }
    UserDTO dto = userConverter.toDTO(user);
    cache.set("user:" + id, dto, Duration.ofMinutes(5) + randomOffset());  // TTL 随机偏移
    return dto;
}

// ✅ 防止缓存击穿：分布式锁
public UserDTO getUser(Long id) {
    UserDTO cached = cache.get("user:" + id);
    if (cached != null) return cached;

    Lock lock = redis.getLock("lock:user:" + id);
    if (lock.tryLock(3, TimeUnit.SECONDS)) {
        try {
            // 双重检查（拿锁后可能其他线程已加载）
            cached = cache.get("user:" + id);
            if (cached != null) return cached;

            User user = userRepo.findById(id);
            UserDTO dto = userConverter.toDTO(user);
            cache.set("user:" + id, dto, Duration.ofMinutes(5));
            return dto;
        } finally {
            lock.unlock();
        }
    }
    // 没拿到锁，等一会再试
    Thread.sleep(100);
    return getUser(id);
}
```

## TTL 选择指南 🟡

| 数据类型 | 建议 TTL | 理由 |
|---------|---------|------|
| 配置/字典 | 10-30 min | 低频变更 |
| 用户信息 | 5-15 min | 可容忍短暂延迟 |
| 热点列表 | 1-5 min | 新鲜度要求高 |
| Session/Token | 跟业务过期时间一致 | 一致性要求 |
| 防穿透空值 | 1-3 min | 避免长期缓存不存在的数据 |

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 无 TTL 的缓存（永不过期） | 内存泄漏、脏数据 |
| 先删缓存再写 DB | 缓存脏数据 |
| 缓存大对象（>1MB） | 网络延迟 + 内存浪费 |
| 缓存实时性数据（库存/余额） | 超卖 |
| 无击穿保护的缓存 | 热点失效打崩 DB |
