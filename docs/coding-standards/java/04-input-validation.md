# 入参校验规范

## 两层校验架构 🔴

```
请求入口 → Controller（JSR303 注解校验）
                ↓
          Service（Assert / 手动校验业务规则）
```

两层校验各司其职，不可互相替代。

## Controller 层：JSR303 注解校验 🔴

校验 HTTP 入参的格式和基本合法性：

```java
@PostMapping("/orders")
public Result<OrderVO> createOrder(@Valid @RequestBody CreateOrderDTO dto) { ... }
```

### 常用注解

| 注解 | 用途 | 示例 |
|------|------|------|
| `@NotNull` | 不为 null | `@NotNull Long userId` |
| `@NotBlank` | 不为空字符串 | `@NotBlank String name` |
| `@Size` | 字符串/集合长度 | `@Size(min = 1, max = 100) String name` |
| `@Min` / `@Max` | 数值范围 | `@Min(1) Integer quantity` |
| `@Pattern` | 正则匹配 | `@Pattern(regexp = "^1[3-9]\\d{9}$") String phone` |
| `@Email` | 邮箱格式 | `@Email String email` |

### 必须使用 `@Valid` 或 `@Validated` 🔴

- 不加 `@Valid` 则 JSR303 注解不生效
- 分组校验用 `@Validated(CreateGroup.class)`

## Service 层：业务规则校验 🔴

JSR303 无法覆盖的业务规则，在 Service 层校验：

```java
public OrderDTO createOrder(CreateOrderDTO dto) {
    // 业务规则校验
    Assert.notNull(userService.getById(dto.getUserId()), "用户不存在");
    if (productService.getStock(dto.getProductId()) < dto.getQuantity()) {
        throw new BizException(ErrorCode.STOCK_NOT_ENOUGH);
    }
    // ...
}
```

### Service 校验 vs Controller 校验

| 维度 | Controller 校验 | Service 校验 |
|------|----------------|-------------|
| 目的 | 格式合法性 | 业务合理性 |
| 典型场景 | 非空、长度、格式、范围 | 用户是否存在、余额是否充足、状态是否允许 |
| 工具 | JSR303 注解 | Assert / if-throw / BizException |
| 调用方 | HTTP 请求 | 可被多个入口复用 |

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| Service 层重复 Controller 的格式校验 | 职责重复，维护成本高 | Service 只校验业务规则 |
| 只在 Controller 校验，Service 不校验 | Service 被其他方法调用时无保护 | 两层都要校验 |
| 用 `if (obj == null) return` | 静默返回 null，调用方无法感知错误 | 抛 BizException |
| 校验逻辑散落在业务代码各处 | 难以维护，容易遗漏 | 方法入口集中校验 |

## 集合参数校验 🟡

```java
// List 中每个元素都需要校验 → 加 @Valid
@PostMapping("/batch")
public Result<?> batchCreate(@Valid @RequestBody List<@Valid CreateOrderDTO> dtoList) { ... }
```

## 自定义校验注解 🔵

当 JSR303 内置注解无法满足时，可自定义：

```java
@Target({FIELD, PARAMETER})
@Retention(RUNTIME)
@Constraint(validatedBy = PhoneValidator.class)
public @interface Phone {
    String message() default "手机号格式不正确";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
```
