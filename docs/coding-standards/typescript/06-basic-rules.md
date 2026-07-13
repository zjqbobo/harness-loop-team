# TypeScript 基础编码规范

## 代码行数限制 🔴

| 元素 | 最大行数 | 超出处理 |
|------|---------|---------|
| 函数 | 80 行 | 提取辅助函数 |
| 嵌套层级 | 4 层 | 卫语句 / 提取函数 |

> 文件和组件不设行数上限，以职责单一、可快速理解为原则。

## 圈复杂度 🔴

- 单个函数圈复杂度 ≤ 10
- ESLint: `complexity: ["error", 10]`

```typescript
// ✅ 卫语句：提前 return
function processOrder(order: Order | null): Result {
  if (!order) return fail("订单不存在");
  if (order.isPaid) return fail("订单已支付");
  if (order.amount <= 0) return fail("金额无效");

  // 主逻辑（无嵌套）
  return executeOrder(order);
}

// ❌ 深层嵌套
function processOrder(order: Order | null): Result {
  if (order) {
    if (!order.isPaid) {
      if (order.amount > 0) {
        return executeOrder(order);
      }
    }
  }
}
```

## 命名规范 🔴

| 元素 | 规则 | 示例 |
|------|------|------|
| 变量/函数 | `camelCase` | `userName`、`createOrder()` |
| 类/组件/接口 | `PascalCase` | `UserService`、`UserProfile` |
| 常量 | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT = 3` |
| 私有成员 | 无 `_` 前缀（用 `private` 关键字） | `private cache: Map<string, User>` |
| 布尔 | `is`/`has`/`can`/`should` 前缀 | `isActive`、`hasPermission` |
| 事件处理 | `handle` + 事件名 | `handleClick`、`handleSubmit` |
| 类型文件 | `camelCase.ts`（在 types/ 目录） | `user.ts`、`api.ts` |

## 变量声明 🔴

```typescript
// ✅ const 优先，let 仅在需要重新赋值时
const name = "Alice";
const users = await fetchUsers();

// ✅ let 用于循环计数 / 需重新赋值
let count = 0;
for (const item of items) { count++; }

// ❌ var（禁止——变量提升、函数作用域）
var x = 1;
```

## 可选链与空值合并 🔴

```typescript
// ✅ 可选链 ?. — 安全访问嵌套属性
const city = user?.address?.city;

// ✅ 空值合并 ?? — null/undefined 时用默认值
const name = input ?? "未命名";

// ❌ || 短路（0、""、false 也被视为 falsy）
const count = value || 0;      // 若 value=0 则被替换
const count = value ?? 0;      // ✅ 只有 null/undefined 时替换
```

## 解构赋值 🟡

```typescript
// ✅ 对象解构
const { name, email, role = "user" } = user;

// ✅ 参数解构
function Profile({ name, email, onEdit }: ProfileProps): JSX.Element { ... }

// ✅ 数组解构
const [first, second, ...rest] = items;
```

## 代码格式化 🔴

```json
// .eslintrc.json — 规则检查
{
  "extends": ["eslint:recommended", "plugin:@typescript-eslint/strict"],
  "rules": {
    "complexity": ["error", 10],
    "no-console": ["error", { "allow": ["warn", "error"] }],
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/explicit-function-return-type": "error"
  }
}
```

```json
// .prettierrc — 格式化
{
  "semi": true,
  "singleQuote": false,
  "tabWidth": 2,
  "trailingComma": "all",
  "printWidth": 120
}
```

- **格式化全自动**：Prettier 负责格式，ESLint 负责规则
- **禁止手动调整格式**

## TSDoc 文档注释 🟡

- 公共 API（export 的函数/类/接口/类型）必须写 TSDoc
- 私有函数可由命名自解释

```typescript
/**
 * 创建订单并触发支付流程。
 *
 * @param request - 创建订单请求，amount 必须为正数
 * @param userId  - 下单用户 ID
 * @returns 创建的订单实体（含支付状态）
 * @throws {InsufficientStockError} 库存不足时抛出
 * @throws {PaymentError}           支付预授权失败时抛出
 */
async function createOrder(
  request: CreateOrderRequest,
  userId: number,
): Promise<Order> {
  ...
}
```

## 空值处理 🔴

```typescript
// ✅ 返回空数组而非 null
function findUsers(role: string): User[] {
  const users = queryByRole(role);
  return users ?? [];
}

// ✅ 返回 undefined 而非 null（TypeScript 惯例）
function findById(id: number): User | undefined {
  return users.get(id);
}
```

## 注释规范 🔵

- 代码应自解释，好的命名 > 注释
- 只在以下情况加注释：
  - **WHY**：解释为什么这样做（非显而易见的业务逻辑、算法选择）
  - **WORKAROUND**：临时方案，标注问题编号和预期解决时间
  - **CONCURRENCY**：并发/异步/事件循环相关的非显而易见行为
- 禁止：
  - 无价值注释（`// set name`、`// increment counter`）
  - 注释掉的代码（用 git 管理历史）
  - 用注释解释魔法值（用常量/枚举替代）

```typescript
// ✅ WHY — 解释非显而易见的决策
// 使用 Map 而非 Object：键为数字 ID，Map 保证插入顺序且 key 可以是任意类型
const userCache = new Map<number, User>();

// ✅ WORKAROUND — 标注临时方案
// WORKAROUND(issue-421): React 18 严格模式下 useEffect 双重触发，
// 用 ref 标记防止重复请求。预计 React 19 稳定后移除。
const initialized = useRef(false);

// ❌ 无价值注释
const name = user.name; // get user name

// ❌ 注释掉的代码
// fetchUsers().then(users => setUsers(users));
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `var` | 变量提升、作用域混乱 | `const` / `let` |
| `any` | 逃离类型检查 | `unknown` + 类型守卫 |
| `==` | 隐式类型转换陷阱 | `===` |
| `for-in` 遍历数组 | 遍历原型链 | `for-of` 或 `.forEach()` |
| 直接修改参数 | 副作用 | 返回新对象 |
| `eval()` / `new Function()` | 代码注入 | 结构化解析 |
| 魔法字符串/数字 | 语义不明 | 常量 / 枚举 |
