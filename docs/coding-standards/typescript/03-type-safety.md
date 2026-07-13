# TypeScript 类型安全规范

## strict 模式 🔴

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,               // 开启所有严格检查
    "noUncheckedIndexedAccess": true,  // 索引访问包含 undefined
    "noImplicitReturns": true,    // 函数所有分支必须返回值
    "noFallthroughCasesInSwitch": true,
    "exactOptionalPropertyTypes": true  // 可选属性不允许显式赋 undefined
  }
}
```

## 禁止 any 🔴

```typescript
// ❌ any 逃离类型检查（禁止）
function parseJson(text: string): any { ... }
const data: any = fetchData();

// ✅ unknown + 类型守卫
function parseJson(text: string): unknown {
  return JSON.parse(text);
}
const raw = parseJson('{"id":1}');
if (isUser(raw)) {
  console.log(raw.email); // raw 被收窄为 User
}

// ✅ 泛型
function first<T>(items: T[]): T | undefined {
  return items[0];
}

// ✅ Record / unknown 代替 any
type Config = Record<string, unknown>;
```

## interface vs type 🟡

```typescript
// ✅ interface：公共 API、对象形状、可扩展声明
export interface User {
  id: number;
  name: string;
  email: string;
}

// ✅ interface 声明合并（扩展第三方类型）
interface Window {
  __CUSTOM_CONFIG__: Config;
}

// ✅ type：联合类型、交叉类型、映射类型
type Status = "pending" | "active" | "suspended";
type UserWithRole = User & { role: Role };
type Readonly<T> = { readonly [K in keyof T]: T[K] };

// ❌ type 用于对象形状（无扩展需求除外）
type UserShape = { id: number; name: string };  // 用 interface 更好
```

## 类型守卫 🔴

```typescript
// ✅ typeof 守卫
function process(value: string | number): string {
  if (typeof value === "number") return value.toFixed(2);
  return value.trim();
}

// ✅ instanceof 守卫
function handleError(err: Error | AppError): void {
  if (err instanceof AppError) {
    console.log(err.code);  // access AppError-specific field
  }
}

// ✅ 自定义类型守卫（is 关键字）
interface Cat { meow(): void }
interface Dog { bark(): void }
type Pet = Cat | Dog;

function isCat(pet: Pet): pet is Cat {
  return "meow" in pet;
}

if (isCat(pet)) {
  pet.meow();  // pet 被收窄为 Cat
}
```

## Discriminated Unions 🔴

```typescript
// ✅ 用 kind/type 字段区分联合类型
type Shape =
  | { kind: "circle"; radius: number }
  | { kind: "rectangle"; width: number; height: number }
  | { kind: "triangle"; sides: [number, number, number] };

function area(shape: Shape): number {
  switch (shape.kind) {
    case "circle":
      return Math.PI * shape.radius ** 2;
    case "rectangle":
      return shape.width * shape.height;
    case "triangle": {
      const [a, b, c] = shape.sides;
      const s = (a + b + c) / 2;
      return Math.sqrt(s * (s - a) * (s - b) * (s - c));
    }
  }
}

// ✅ API 响应模式
type ApiResponse<T> =
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; error: AppError };
```

## 泛型约束 🟡

```typescript
// ✅ extends 约束
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

// ✅ 条件类型
type IsString<T> = T extends string ? true : false;

// ✅ 模板字面量类型（TypeScript 4.1+）
type EventName = `user:${"created" | "updated" | "deleted"}`;
// "user:created" | "user:updated" | "user:deleted"
```

## 运行时校验 🔴

类型标注只在编译期存在，运行时需要显式校验：

```typescript
import { z } from "zod";

// ✅ Zod schema — 编译期类型 + 运行时校验
const CreateUserSchema = z.object({
  name: z.string().min(1).max(50),
  email: z.string().email(),
  age: z.number().int().min(0).max(150),
});
type CreateUserRequest = z.infer<typeof CreateUserSchema>;

function handleCreateUser(body: unknown): CreateUserRequest {
  return CreateUserSchema.parse(body);  // 运行时校验
}
```

## as 断言规范 🔴

```typescript
// ✅ 有充分把握时使用 as
const el = document.getElementById("app") as HTMLDivElement;

// ❌ 滥用 as 绕过类型检查
const user = data as any as User;

// ✅ as const 字面量收窄
const routes = ["home", "dashboard", "settings"] as const;
type Route = (typeof routes)[number];  // "home" | "dashboard" | "settings"
```

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| `any` | 关闭所有类型检查 | `unknown` + 类型守卫 |
| `as any as T` 双重断言 | 绕过检查 | 重构类型，不要断言 |
| `@ts-ignore` | 隐藏问题 | `@ts-expect-error` + 注释原因 |
| `!` 非空断言滥用 | 运行时可能为 null | 显式 null check |
| `object` 类型 | 无法访问任何属性 | `Record<string, unknown>` |
