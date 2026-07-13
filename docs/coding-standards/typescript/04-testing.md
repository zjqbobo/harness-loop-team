# TypeScript 测试规范

## 测试框架 🔴

```typescript
// Vitest（推荐，与 Vite 生态集成）或 Jest
import { describe, it, expect, vi, beforeEach } from "vitest";
```

## 三段式结构 🔴

```typescript
describe("UserService", () => {
  let service: UserService;
  let mockRepo: Mocked<UserRepository>;

  beforeEach(() => {
    mockRepo = { findById: vi.fn(), create: vi.fn() };
    service = new UserService(mockRepo);
  });

  it("should return user when found", async () => {
    // Arrange
    const mockUser = { id: 1, name: "Alice", email: "alice@example.com" };
    mockRepo.findById.mockResolvedValue(mockUser);

    // Act
    const result = await service.getUser(1);

    // Assert
    expect(result).toEqual(mockUser);
    expect(mockRepo.findById).toHaveBeenCalledWith(1);
    expect(mockRepo.findById).toHaveBeenCalledTimes(1);
  });

  it("should throw NotFoundError when user not found", async () => {
    // Arrange
    mockRepo.findById.mockResolvedValue(null);

    // Act & Assert
    await expect(service.getUser(999)).rejects.toThrow(NotFoundError);
  });
});
```

## Mock 规范 🔴

```typescript
// ✅ 只 mock 外部依赖（API、DB、文件系统）
import { vi } from "vitest";

vi.mock("@/services/api", () => ({
  fetchUser: vi.fn().mockResolvedValue({ id: 1, name: "Alice" }),
}));

// ✅ 手动 mock 类
const mockRepo: Mocked<UserRepository> = {
  findById: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
};

// ❌ 禁止：mock 被测代码的内部实现
vi.mock("@/services/userService/helpers");  // 不要 mock 私有函数

// ❌ 禁止：mock 标准库
vi.mock("fs");  // 不要 mock Node 标准库
```

## React 组件测试 🔴

```tsx
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

describe("LoginForm", () => {
  it("should submit credentials and call onSuccess", async () => {
    const onSuccess = vi.fn();
    render(<LoginForm onSuccess={onSuccess} />);

    // Act — 模拟用户操作
    await userEvent.type(screen.getByLabelText("邮箱"), "alice@example.com");
    await userEvent.type(screen.getByLabelText("密码"), "password123");
    await userEvent.click(screen.getByRole("button", { name: "登录" }));

    // Assert
    await waitFor(() => {
      expect(onSuccess).toHaveBeenCalledWith({ email: "alice@example.com" });
    });
  });

  it("should show error message on failed login", async () => {
    vi.mocked(authService.login).mockRejectedValue(new Error("Invalid credentials"));
    render(<LoginForm onSuccess={vi.fn()} />);

    await userEvent.type(screen.getByLabelText("邮箱"), "bad@example.com");
    await userEvent.type(screen.getByLabelText("密码"), "wrong");
    await userEvent.click(screen.getByRole("button", { name: "登录" }));

    expect(await screen.findByText("登录失败")).toBeVisible();
  });
});
```

## API Handler 测试 🟡

```typescript
import request from "supertest";
import { createApp } from "@/app";

describe("GET /api/users/:id", () => {
  it("should return 200 with user data", async () => {
    const app = createApp({ userService: mockUserService });
    mockUserService.getUser.mockResolvedValue({ id: 1, name: "Alice" });

    const response = await request(app).get("/api/users/1");

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ id: 1, name: "Alice" });
  });

  it("should return 404 when user not found", async () => {
    const app = createApp({ userService: mockUserService });
    mockUserService.getUser.mockRejectedValue(new NotFoundError("用户", "999"));

    const response = await request(app).get("/api/users/999");

    expect(response.status).toBe(404);
    expect(response.body.error.code).toBe("NOT_FOUND");
  });
});
```

## 覆盖率 🔴

```bash
# Vitest
npx vitest run --coverage

# Jest
npx jest --coverage
```

| 指标 | 门禁 |
|------|------|
| 行覆盖率 | ≥ 80% |
| 分支覆盖率 | ≥ 70% |
| 函数覆盖率 | ≥ 80% |

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 连真实 API/DB | 慢、脆弱、不可并行 |
| 测试间共享可变状态 | 顺序依赖、flake |
| 只写 happy path | 边界和异常 = bug 高发区 |
| 用 `setTimeout` 等待 | 用 `waitFor` / `findBy*` |
| 测试实现细节（内部 state） | 重构会破坏测试 |
