# Programming — Kotlin

---

## Tech Stack

| Component | Version / Tool |
|-----------|---------------|
| JVM | JDK 21+ (LTS) |
| Framework | Spring Boot 3.x (WebFlux) |
| Language | Kotlin 2.x |
| Build | Gradle Kotlin DSL |
| Async | Coroutines + Flow |

### JDK 21+ Features to Use
- Virtual Threads (`Executors.newVirtualThreadPerTaskExecutor()`) for blocking I/O — **only outside reactive chains**.
- Record patterns, switch pattern matching, sequenced collections.

### Spring Boot 3 WebFlux Rules
- All controllers return `Mono<T>` or `Flux<T>`.
- Service layer uses `suspend` functions and `Flow` for streams.
- Blocking calls (`Thread.sleep()`, `JDBC`) are **forbidden** in the reactive chain. Use `Schedulers.boundedElastic()` only for unavoidable blocking I/O, wrapped with `subscribeOn()`.

---

## Hexagonal Architecture (Ports & Adapters)

### Directory Structure

```
src/main/kotlin/com/example/
├── domain/                  # ═══ PURE KOTLIN — ZERO FRAMEWORK DEPENDENCIES ═══
│   ├── model/               #   Domain entities, value objects, aggregates
│   ├── service/             #   Domain services (stateless, pure logic)
│   ├── port/                #   Inbound / outbound port interfaces
│   │   ├── inbound/         #     e.g. CreateOrderUseCase
│   │   └── outbound/        #     e.g. OrderRepository, PaymentGateway
│   └── event/               #   Domain events (sealed classes)
│
├── application/             # ═══ APPLICATION LAYER (Spring-aware) ═══
│   ├── service/             #   Application services — @Transactional, orchestrates ports
│   └── dto/                 #   Application DTOs (for API / messaging boundaries)
│
├── infrastructure/          # ═══ INFRASTRUCTURE (technical implementations) ═══
│   ├── persistence/         #   JPA / R2DBC / Mongo repositories
│   ├── messaging/           #   Kafka / RabbitMQ producers & consumers
│   └── client/              #   HTTP clients (WebClient, RestClient)
│
├── adapter/                 # ═══ ADAPTERS (external entry points) ═══
│   ├── inbound/             #   Controllers, gRPC handlers, event listeners
│   │   └── rest/
│   │       └── OrderController.kt
│   └── outbound/            #   Outbound adapters implement port interfaces
│
└── support/                 # ═══ CROSS-CUTTING ═══
    └── extensions/          #   Kotlin extension functions only
```

### Hexagonal Architecture Rules

1. **`domain/` has ZERO external dependencies.**
   - No Spring annotations. No `javax.*` / `jakarta.*` imports.
   - No database annotations (`@Entity`, `@Table`, `@Column`).
   - No JSON annotations (`@JsonProperty`, `@Serializable`).
   - Pure Kotlin — only allow `kotlin.*` and `java.util.*` (for `UUID`, `LocalDate`, etc.).

2. **Port interfaces** in `domain/port/` define the contract. Implementations live in `infrastructure/`.
   - Inbound ports: use case interfaces (e.g. `interface CreateOrderUseCase`).
   - Outbound ports: repository interfaces (e.g. `interface OrderRepository`).

3. **Dependency Rule:** Dependencies point **inward**. `infrastructure/` depends on `domain/`. `application/` depends on `domain/`. `adapter/` depends on `application/`. Never the reverse.

---

## Kotlin Language Conventions

### Data Classes — 4-Field Limit

```kotlin
// ✅ Good — under 4 fields
data class Address(
    val street: String,
    val city: String,
    val zipCode: String,
    val country: String,
)

// ❌ Bad — too many fields, split the model
data class Order(
    val id: UUID,
    val customerId: UUID,
    val items: List<OrderLine>,
    val shippingAddress: Address,
    val billingAddress: Address,  // Consider: extract billing info?
    val paymentMethod: String,    // Consider: PaymentDetails value object
    val status: OrderStatus,
)
```

**Rule:** If a data class exceeds 4 fields, extract value objects or nested models. The `copy()` function becomes error-prone with too many fields.

### Extension Functions — in `support/extensions/`

```kotlin
// File: support/extensions/MoneyExtensions.kt
package com.example.support.extensions

fun Money.toDisplayString(): String = "$currency $amount"
```

- Group by domain concept, not by type.
- One file per logical grouping.

### Domain Events — Sealed Classes

```kotlin
sealed class OrderEvent {
    data class Placed(
        val orderId: OrderId,
        val customerId: CustomerId,
        val total: Money,
        val occurredAt: Instant = Instant.now(),
    ) : OrderEvent()

    data class Shipped(
        val orderId: OrderId,
        val trackingNumber: String,
    ) : OrderEvent()

    data class Cancelled(
        val orderId: OrderId,
        val reason: String,
    ) : OrderEvent()
}
```

- `when` exhaustiveness is checked at compile time.
- Never add an `else` branch to a `when` on a sealed class.

### `@Value Class` — Not `typealias`

```kotlin
// ✅ Good — type-safe, no runtime overhead
@JvmInline
value class OrderId(private val value: UUID)

// ❌ Avoid — no type safety beyond compile time warnings
typealias OrderId = UUID
```

**Rule:** Use `@JvmInline value class` for any domain primitive (IDs, emails, phone numbers, currency codes). Never `typealias` for domain concepts.

### Controller Thin, Application Service Responsible

```kotlin
// ✅ Controller — thin, only maps HTTP concerns
@RestController
@RequestMapping("/api/v1/orders")
class OrderController(
    private val createOrderUseCase: CreateOrderUseCase,
) {
    @PostMapping
    suspend fun create(@RequestBody @Valid request: CreateOrderRequest): ResponseEntity<OrderResponse> {
        val result = createOrderUseCase.execute(request.toCommand())
        return result.fold(
            onSuccess = { ResponseEntity.ok(it.toResponse()) },
            onFailure = { ResponseEntity.badRequest().body(ErrorResponse(it.message)) },
        )
    }
}

// ✅ Application Service — owns the transaction boundary
@Service
class OrderApplicationService(
    private val orderRepository: OrderRepository,
    private val paymentGateway: PaymentGateway,
    private val eventPublisher: DomainEventPublisher,
) {
    @Transactional
    suspend fun execute(command: CreateOrderCommand): Result<Order> {
        // 1. Validate
        // 2. Create domain entity
        // 3. Persist
        // 4. Publish event
        // 5. Return
    }
}
```

**Rules:**
- Controllers: no business logic, no `@Transactional`, no repository calls.
- Application Services: `@Transactional`, orchestrates ports, maps between domain and DTOs.
- Domain Services: pure logic, no infrastructure awareness.