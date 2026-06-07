# Testing & TDD

---

## RED — GREEN — REFACTOR

Every feature starts with a failing test.

```
┌─────────────────────────────────────────────────────────┐
│  1. RED     Write a test that fails                      │
│  2. GREEN   Write the minimum code to make it pass       │
│  3. REFACTOR Clean up both test and production code      │
│  4. Repeat (cycles of 2–10 minutes)                     │
└─────────────────────────────────────────────────────────┘
```

### TDD Rules
- **No production code without a failing test** (exception: exploratory spikes).
- **Test one behavior per test method** — not one method per test.
- **Commit only when all tests pass** (GREEN).
- **Refactor under GREEN** — production and test code both get cleaned up.

---

## Test Layers

| Layer | Scope | Tooling | Coverage Target |
|-------|-------|---------|----------------|
| **Unit** | Single class / function, isolated | JUnit 5 + MockK (Kotlin) / pytest + Mock (Python) | ≥ 90% |
| **Integration** | Component + real infrastructure | Testcontainers | ≥ 80% |
| **Contract** | API / message schema compatibility | Spring Cloud Contract / Pact | Per service pair |
| **E2E** | Full system through real entry points | RestAssured / Playwright | Critical paths |

---

## Test Naming Convention

```
should_{expected}_when_{condition}
```

### Examples

| Test Name | Layer |
|-----------|-------|
| `should_return_order_when_find_by_valid_id` | Unit |
| `should_throw_not_found_when_order_does_not_exist` | Unit |
| `should_persist_order_when_create_is_called` | Integration |
| `should_return_201_when_valid_order_is_submitted` | E2E |

---

## Kotlin Example (Unit — MockK)

```kotlin
class CreateOrderUseCaseTest {

    private val orderRepository = mockk<OrderRepository>()
    private val paymentGateway = mockk<PaymentGateway>()
    private val useCase = CreateOrderUseCase(orderRepository, paymentGateway)

    @Test
    fun `should_create_order_when_inventory_is_sufficient`() = runTest {
        // GIVEN
        val command = CreateOrderCommand(
            customerId = UUID.randomUUID(),
            items = listOf(OrderLineItem(productId = UUID.randomUUID(), quantity = 2)),
        )
        every { orderRepository.save(any()) } returns ArgumentCaptor<Order>().also {
            it.captured // capture the saved order for assertion
        }
        every { paymentGateway.charge(any(), any()) } returns PaymentResult.Success

        // WHEN
        val result = useCase.execute(command)

        // THEN
        assertThat(result.isSuccess).isTrue
        verify { orderRepository.save(any()) }
        verify { paymentGateway.charge(any(), any()) }
    }

    @Test
    fun `should_return_error_when_payment_declined`() = runTest {
        // GIVEN
        val command = CreateOrderCommand(/* ... */)
        every { orderRepository.save(any()) } returns mockk()
        every { paymentGateway.charge(any(), any()) } returns PaymentResult.Declined("Insufficient funds")

        // WHEN
        val result = useCase.execute(command)

        // THEN
        assertThat(result.isFailure).isTrue
        verify(exactly = 1) { paymentGateway.charge(any(), any()) }
    }
}
```

### MockK Rules
- Use `mockk<T>()` for interfaces, `spyk(obj)` for partial mocks (rare).
- Prefer `every { ... } returns` over `every { ... } answers`.
- Verify interactions with `verify { ... }` and `verify(exactly = 0) { ... }`.

---

## Python Example (Unit — unittest.mock)

```python
import pytest
from unittest.mock import AsyncMock, MagicMock, patch

async def test_create_order_when_inventory_is_sufficient():
    # GIVEN
    command = CreateOrderCommand(
        customer_id=uuid4(),
        items=[OrderLineItem(product_id=uuid4(), quantity=2)],
    )
    mock_repo = AsyncMock(spec=OrderRepository)
    mock_gateway = AsyncMock(spec=PaymentGateway)
    mock_gateway.charge.return_value = PaymentResult.success()

    service = OrderService(repository=mock_repo, gateway=mock_gateway)

    # WHEN
    result = await service.create_order(command)

    # THEN
    assert result.is_success
    mock_repo.save.assert_awaited_once()
    mock_gateway.charge.assert_awaited_once()

async def test_create_order_when_payment_declined():
    # GIVEN
    mock_repo = AsyncMock(spec=OrderRepository)
    mock_gateway = AsyncMock(spec=PaymentGateway)
    mock_gateway.charge.return_value = PaymentResult.declined("Insufficient funds")

    service = OrderService(repository=mock_repo, gateway=mock_gateway)

    # WHEN
    result = await service.create_order(command)

    # THEN
    assert result.is_failure
    mock_gateway.charge.assert_awaited_once()
    mock_repo.save.assert_not_awaited()  # rollback — order not saved
```

---

## Integration Example (Testcontainers — Kotlin)

```kotlin
@Testcontainers
class OrderRepositoryIntegrationTest {

    companion object {
        @Container
        val postgres = PostgreSQLContainer<Nothing>("postgres:16-alpine").apply {
            withDatabaseName("testdb")
            withUsername("test")
            withPassword("test")
        }
    }

    private lateinit var repository: OrderRepository
    private lateinit var r2dbc: R2dbcEntityTemplate

    @BeforeEach
    fun setUp() {
        val connectionFactory = PostgresqlConnectionFactory(
            PostgresqlConnectionConfiguration.builder()
                .host(postgres.host)
                .port(postgres.firstMappedPort)
                .database(postgres.databaseName)
                .username(postgres.username)
                .password(postgres.password)
                .build()
        )
        r2dbc = R2dbcEntityTemplate(DatabaseClient.create(connectionFactory))
        repository = PostgresOrderRepository(r2dbc)
    }

    @Test
    fun `should_persist_and_retrieve_order_when_valid_order_is_saved`() = runTest {
        // GIVEN
        val order = Order(
            id = OrderId(UUID.randomUUID()),
            customerId = UUID.randomUUID(),
            total = Money(BigDecimal("99.99"), Currency.USD),
        )

        // WHEN
        repository.save(order)
        val loaded = repository.findById(order.id)

        // THEN
        assertThat(loaded).isNotNull
        assertThat(loaded!!.total.amount).isEqualByComparingTo(BigDecimal("99.99"))
    }
}
```

### Testcontainers Rules
- Use a **single container per group of related tests** (companion object / `@pytest.fixture(scope="session")`).
- **Always pin the image tag** (e.g. `postgres:16-alpine`).
- Clean data before each test (truncate tables, not drop).
- **Never run integration tests without Testcontainers** — no in-memory substitutes.

---

## Coverage Enforcement

```
# Gradle (Kotlin DSL) — Kotlin
tasks.jacocoTestCoverageVerification {
    violationRules {
        rule { limit { minimum = BigDecimal("0.9") } }   // Unit ≥ 90%
        rule { limit { minimum = BigDecimal("0.8") } }   // Integration ≥ 80%
    }
}

# pyproject.toml — Python
[tool.pytest.ini_options]
addopts = "--cov=src --cov-fail-under=90 --cov-report=term-missing"
```