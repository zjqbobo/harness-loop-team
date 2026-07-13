# Java 单元测试规范

## 测试框架 🔴

- JUnit 5（Jupiter）+ Mockito + AssertJ
- Spring Boot Test 做集成测试

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private OrderService orderService;

    // 测试用例...
}
```

## 测试文件位置 🔴

```
src/
├── main/java/com/example/
│   └── service/
│       └── OrderService.java
└── test/java/com/example/
    └── service/
        └── OrderServiceTest.java    ← 与被测类同包同目录
```

## Mock 规范 🔴

| 需要 Mock | 不需要 Mock |
|-----------|------------|
| DAO/Repository（数据库） | 被测类本身 |
| 外部 HTTP/RPC 客户端 | 简单 POJO/DTO |
| 消息队列生产者 | 常量/枚举 |
| 文件系统 | 纯计算逻辑 |

```java
// ✅ Mock Repository
@Mock
private OrderRepository orderRepository;

// ✅ Mock 外部调用
@Mock
private PaymentClient paymentClient;

// ❌ Mock 被测类
@Mock
private OrderService orderService;  // 不是 mock 被测对象，是注入它
```

## 测试结构（Given/When/Then）🔴

```java
@Test
void shouldCreateOrderWhenStockIsSufficient() {
    // Given — 准备数据和 mock
    Long productId = 1L;
    int quantity = 5;
    Product mockProduct = new Product(productId, "测试商品", 10, BigDecimal.valueOf(99.0));
    when(productRepository.findById(productId)).thenReturn(Optional.of(mockProduct));
    when(orderRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    // When — 执行被测方法
    OrderDTO result = orderService.createOrder(new CreateOrderReq(productId, quantity, 1L));

    // Then — 断言结果 + 验证 mock 调用
    assertThat(result).isNotNull();
    assertThat(result.getAmount()).isEqualByComparingTo(BigDecimal.valueOf(495.0));
    verify(orderRepository, times(1)).save(any());
}
```

## 测试覆盖要求 🔴

| 类型 | 最低要求 |
|------|---------|
| **Happy Path** | 所有公开方法的主流程 |
| **边界条件** | null / 空字符串 / 0 / 负数 / 最大最小值 |
| **异常路径** | 依赖失败、数据不存在、业务规则不满足 |
| **状态转换** | 有状态对象的关键状态流转 |

## 覆盖率门禁 🔴

- Statement ≥ 80%
- Branch ≥ 70%
- 使用 JaCoCo 统计，CI 中强制检查

## 禁止行为 🔴

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| Mock 被测类 | 失去测试意义 | `@InjectMocks` 注入被测对象 |
| 测试依赖执行顺序 | 无法单独运行 | 每个测试独立，用 `@BeforeEach` 初始化 |
| 测试中有 `Thread.sleep()` | 不稳定、慢 | `awaitility` 库 |
| 硬编码测试数据无意义 | 可读性差 | 变量命名有业务含义 |
| 只测 Happy Path | 边界/异常漏测 | 每种异常至少一个测试用例 |
