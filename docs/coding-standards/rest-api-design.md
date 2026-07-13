# REST API 设计规范

> 适用：所有后端技术栈（Java/TypeScript/Go/Python/.NET）

## URL 设计 🔴

| 规则 | 示例 |
|------|------|
| 名词复数（资源集合） | `GET /api/users`、`POST /api/orders` |
| 嵌套资源 ≤ 2 层 | `GET /api/users/{id}/orders` |
| 小写 + 连字符 | `/api/order-logs`（不用 `/api/orderLogs` 或 `/api/order_logs`） |
| 不用动词（用 HTTP method 表达动作） | `POST /api/orders/{id}/cancel`（非标准动作） |
| 查询/过滤用 query param | `GET /api/users?status=active&page=1&pageSize=20` |
| **禁止** URL 暴露内部实现 | `/api/getUserById`、`/api/user_list.php` |

## HTTP 方法语义 🔴

| 方法 | 语义 | 幂等 | 示例 |
|------|------|------|------|
| `GET` | 读取 | ✅ | `GET /api/users/{id}` |
| `POST` | 创建 | ❌ | `POST /api/users` |
| `PUT` | 全量更新 | ✅ | `PUT /api/users/{id}` |
| `PATCH` | 部分更新 | ❌ | `PATCH /api/users/{id}` |
| `DELETE` | 删除 | ✅ | `DELETE /api/users/{id}` |

- **禁止** `GET` 做修改操作、`POST` 做查询
- `PUT` 和 `PATCH` 必须传资源 ID（含路径参数）

## HTTP 状态码 🔴

| 码 | 场景 | 示例 |
|----|------|------|
| `200` | GET/PUT/PATCH 成功 | 返回资源 |
| `201` | POST 创建成功 | `Location` 头指向新资源 |
| `204` | DELETE 成功 / 无内容返回 | 空 body |
| `400` | 请求参数不合法 | 字段级错误 |
| `401` | 未认证 | Token 失效/缺失 |
| `403` | 已认证但无权限 | 非管理员访问管理接口 |
| `404` | 资源不存在 | 用户/订单不存在 |
| `409` | 资源冲突 | 重复创建/版本冲突 |
| `422` | 业务规则不满足 | 库存不足/状态不允许 |
| `429` | 限流 | `Retry-After` 头 |
| `500` | 服务端未知错误 | 不返回堆栈 |

## 统一响应格式 🔴

```json
// 成功 — 单对象
{
  "code": 0,
  "message": "ok",
  "data": { "id": 1, "name": "Alice" }
}

// 成功 — 列表（分页）
{
  "code": 0,
  "message": "ok",
  "data": {
    "items": [{ "id": 1, "name": "Alice" }],
    "total": 100,
    "page": 1,
    "pageSize": 20
  }
}

// 失败
{
  "code": 40001,
  "message": "库存不足",
  "details": [
    { "field": "quantity", "message": "库存仅剩 3 件" }
  ]
}
```

- `code` = 0 表示成功，非 0 表示业务错误（错误码设计见各语言异常处理规范）
- 分页列表统一用 `{ items, total, page, pageSize }` 结构

## 分页 🔴

- 所有列表接口**必须分页**（默认 `pageSize=20`，最大 `pageSize=100`）
- 实时数据/大数据量用游标分页（`cursor`），历史数据/管理后台用偏移分页（`page`+`pageSize`）

## API 版本管理 🟡

- 版本号放在 URL 前缀：`/api/v1/users`、`/api/v2/users`
- 或通过请求头：`Accept: application/vnd.company.v2+json`
- 推荐 URL 前缀方案（简单直观，网关路由方便）
- 旧版本至少维护 1 个大版本周期，废弃前公告

## 限流 🟡

- 敏感接口（登录/短信/支付）必须有限流
- 响应头返回 `X-RateLimit-Remaining`、`X-RateLimit-Reset`、`Retry-After`

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| URL 中用动词（`/getUser`、`/createOrder`） | RESTful 不规范 |
| `GET` 请求修改数据 | 语义错误，爬虫/缓存可能误触发 |
| 返回 HTML 错误页（应返回 JSON） | API 不是浏览器 |
| 无分页的列表接口 | 内存溢出 |
| 生产环境 5xx 返回堆栈 | 安全泄露 |
| 布尔值字段用 `isSuccess: "1"` | 类型不一致 |
