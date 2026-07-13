# .NET/C# 测试规范

## 测试框架 🔴

```xml
<!-- 测试项目 .csproj -->
<ItemGroup>
  <PackageReference Include="xunit" Version="2.9.0" />
  <PackageReference Include="Moq" Version="4.20.0" />
  <PackageReference Include="FluentAssertions" Version="6.12.0" />
  <PackageReference Include="coverlet.collector" Version="6.0.0" />
</ItemGroup>
```

## AAA 模式（Arrange/Act/Assert）🔴

```csharp
public class OrderServiceTests
{
    [Fact]
    public async Task CreateOrder_WithValidInput_ReturnsOrder()
    {
        // Arrange
        var mockRepo = new Mock<IOrderRepository>();
        var mockLogger = new Mock<ILogger<OrderService>>();
        mockRepo.Setup(r => r.CreateAsync(It.IsAny<Order>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync((Order o, CancellationToken _) => o);

        var service = new OrderService(mockRepo.Object, mockLogger.Object);
        var request = new CreateOrderRequest("user-1", 199.99m);

        // Act
        var result = await service.CreateOrderAsync(request, CancellationToken.None);

        // Assert
        result.Should().NotBeNull();
        result.UserId.Should().Be("user-1");
        result.Amount.Should().Be(199.99m);
        mockRepo.Verify(r => r.CreateAsync(It.IsAny<Order>(), It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CreateOrder_WithZeroAmount_ThrowsValidationException()
    {
        // Arrange
        var mockRepo = new Mock<IOrderRepository>();
        var service = new OrderService(mockRepo.Object, Mock.Of<ILogger<OrderService>>());
        var request = new CreateOrderRequest("user-1", 0m);

        // Act
        var act = () => service.CreateOrderAsync(request, CancellationToken.None);

        // Assert
        await act.Should().ThrowAsync<ValidationException>()
            .WithMessage("*金额*");
    }
}
```

## 测试命名 🟡

```csharp
// 命名模式：MethodName_Scenario_ExpectedBehavior
public async Task GetUserAsync_ExistingId_ReturnsUser() { }
public async Task GetUserAsync_NonExistentId_ThrowsNotFoundException() { }
public async Task CreateOrder_InvalidAmount_ThrowsValidationException() { }
```

## Mock 规范 🔴

```csharp
// ✅ Mock 接口（通过接口注入的依赖）
var mockPaymentClient = new Mock<IPaymentClient>();
mockPaymentClient
    .Setup(c => c.ChargeAsync(It.IsAny<string>(), It.IsAny<decimal>(), It.IsAny<CancellationToken>()))
    .ReturnsAsync(new PaymentResult { Success = true, TransactionId = "txn-123" });

// ✅ Mock ILogger
var mockLogger = new Mock<ILogger<OrderService>>();

// ✅ Verify 检查调用
mockPaymentClient.Verify(
    c => c.ChargeAsync("user-1", 199.99m, It.IsAny<CancellationToken>()),
    Times.Once);

// ❌ 禁止：Mock 实体类
var order = new Mock<Order>();  // 用真实的 Order 对象

// ❌ 禁止：Mock 不拥有的类型
```

## Mock 规则 🔴

| 规则 | 说明 |
|------|------|
| **mock 外部边界** | 数据库、HTTP API、文件系统、消息队列 |
| **不 mock 被测代码** | 被测类内部调用的方法走真实实现 |
| **不 mock 值对象** | `Order`、`User` 等 entity/DTO 使用真实构造 |
| **不 mock 框架类型** | `DateTime`、`HttpContext`（用 TestServer） |

## 集成测试 🔴

```csharp
// 用 TestContainers 做数据库集成测试
public class UserRepositoryTests : IAsyncLifetime
{
    private readonly PostgreSqlContainer _dbContainer;
    private AppDbContext _dbContext;

    public UserRepositoryTests()
    {
        _dbContainer = new PostgreSqlBuilder()
            .WithDatabase("testdb")
            .WithUsername("test")
            .WithPassword("test")
            .Build();
    }

    public async Task InitializeAsync()
    {
        await _dbContainer.StartAsync();
        // 创建 DbContext 并执行迁移
    }

    public async Task DisposeAsync()
    {
        await _dbContainer.DisposeAsync();
    }

    [Fact]
    public async Task FindById_ExistingUser_ReturnsUser()
    {
        // 使用真实数据库
        var repo = new UserRepository(_dbContext);
        var user = await repo.FindByIdAsync(1);
        user.Should().NotBeNull();
    }
}
```

## 覆盖率 🔴

```bash
dotnet test --collect:"XPlat Code Coverage"
reportgenerator -reports:coverage.cobertura.xml -targetdir:coveragereport
```

| 指标 | 门禁 |
|------|------|
| 行覆盖率 | ≥ 80% |
| 分支覆盖率 | ≥ 70% |
| 未达标 | CI 阻断 |

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 连真实数据库 | 慢、不稳定、不能并行 |
| 连真实外部 API | 外部不可控 |
| 测试间共享可变状态 | 顺序依赖、flake |
| 只写 happy path | 不测边界 = 生产故障 |
| `Thread.Sleep` 等待 | 用 `Task.Delay` + `await` |
