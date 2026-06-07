# Clean Code

---

## Functions

### One Thing

A function does **one thing** — one level of abstraction, one reason to change.

```kotlin
// ✅ Good — each function has a single responsibility
fun calculateDiscount(order: Order): Money
fun applyPromotion(promotion: Promotion, total: Money): Money
fun sendConfirmationEmail(email: Email, order: Order)

// ❌ Bad — calculates, applies AND sends email
fun processOrder(order: Order, promotion: Promotion?) {
    var total = calculateTotal(order)
    if (promotion != null) {
        total = total * promotion.discountRate
    }
    emailService.send(order.customer.email, "Order Confirmed", total.toString())
    // ...
}
```

### 20 Lines Max

- **Soft limit:** 15 lines. **Hard limit:** 20 lines (excluding braces and blank lines).
- If a function exceeds 20 lines → extract helper functions.
- Nesting depth: maximum 2 levels.

### Early Return

```kotlin
// ✅ Good
fun getUserDisplayName(user: User?): String {
    if (user == null) return "Anonymous"
    if (user.name.isNullOrBlank()) return "User ${user.id}"
    return user.name
}

// ❌ Bad — deeply nested if-else
fun getUserDisplayName(user: User?): String {
    return if (user != null) {
        if (user.name.isNullOrBlank()) "User ${user.id}" else user.name
    } else {
        "Anonymous"
    }
}
```

### Command-Query Separation (CQS)

- **Commands** (mutate state) → return `void` / `Unit` or a Result type.
- **Queries** (return data) → have zero side effects.

```kotlin
// ✅ Good — command
fun save(order: Order): Unit

// ✅ Good — query
fun findById(id: OrderId): Order?

// ❌ Bad — query that mutates state
fun findByIdAndIncrementCounter(id: OrderId): Order?
```

---

## Naming

### Boolean Prefixes

| Prefix | Convention |
|--------|-----------|
| `is` | `isActive`, `isValid`, `isDeleted` |
| `has` | `hasItems`, `hasPermission`, `hasErrors` |
| `can` | `canCancel`, `canApprove`, `canDelete` |

```kotlin
// ✅ Good
fun isActive(): Boolean
fun hasPermission(user: User, action: String): Boolean
fun canCancel(order: Order): Boolean
```

### Collections — Plural

```kotlin
// ✅ Good
val orders: List<Order>
val customerMap: Map<UUID, Customer>
val productNames: Set<String>

// ❌ Bad
val orderList: List<Order>
val customerMapData: Map<UUID, Customer>
```

### Verbs for Methods

| Operation | Verb | Example |
|-----------|------|---------|
| Read | `get` | `getOrderById(id)` |
| Create | `create` | `createOrder(command)` |
| Update | `update` | `updateAddress(id, address)` |
| Delete | `delete` | `deleteOrder(id)` |
| Find/Search | `find` / `search` | `findOrdersByCustomer(cid)` |

---

## Exceptions

### Business Exceptions — in `domain/exception/`

```kotlin
// src/main/kotlin/com/example/domain/exception/OrderExceptions.kt
package com.example.domain.exception

class InsufficientStockException(
    productId: UUID,
    requested: Int,
    available: Int,
) : RuntimeException(
    "Insufficient stock for product $productId: requested $requested, available $available"
) {
    val context: Map<String, Any> = mapOf(
        "productId" to productId,
        "requested" to requested,
        "available" to available,
    )
}

class OrderAlreadyCancelledException(
    orderId: UUID,
) : RuntimeException("Order $orderId is already cancelled")
```

### Rules
- **Always extend `RuntimeException`** (unchecked). Never checked exceptions.
- **Include context in the message** — enough to debug without stack trace diving.
- **One file per aggregate** — `OrderExceptions.kt`, `PaymentExceptions.kt`, etc.
- **Catch at the boundary** (controller / adapter), never in domain or application service.

---

## Comments

### Why, Not What

```kotlin
// ✅ Good — explains WHY (rationale, trade-off)
// Using exponential backoff because the upstream rate-limits at 10 req/s
fun retryPayment(payment: Payment): Result {
    // ...
}

// ❌ Bad — explains WHAT (code is self-documenting)
// Wait 2 seconds
Thread.sleep(2000)
```

### TODO with Issue Number

```kotlin
// ✅ Good
// TODO (#347): Replace with batch insert when volume exceeds 10k rows/day
fun saveAll(orders: List<Order>)

// ❌ Bad — no tracking
// TODO: optimize this later
```

- Every `TODO` in committed code **must** reference a JIRA/GitHub issue.
- `FIXME` is reserved for known bugs that are not yet fixed. Same rule: must have issue #.

---

## Dependency Injection

### Constructor Injection Only

```kotlin
// ✅ Good
@Service
class OrderService(
    private val orderRepository: OrderRepository,
    private val paymentGateway: PaymentGateway,
)

// ❌ Avoid — field injection
@Service
class OrderService {
    @Autowired
    private lateinit var orderRepository: OrderRepository  // noqa
}

// ❌ Avoid — setter injection
@Service
class OrderService {
    @Autowired          // noqa
    fun setRepository(repo: OrderRepository) { ... }
}
```

**Rules:**
- No `@Autowired` on fields. No `lateinit` with `@Autowired`.
- No manual `new` for dependencies in service classes (except value objects).
- Spring / Dagger / Guice wiring is handled by the framework — classes don't know about DI.

---

## Circular Dependencies

> **A circular dependency is a design problem, not a framework configuration problem.**

### Detection
- Gradle: `./gradlew build` will fail on circular project dependencies.
- IntelliJ: Structural Search → "circular dependency pattern".
- Runtime: `BeanCurrentlyInCreationException` = circular dependency.

### Fixes

| Pattern | Problem | Fix |
|---------|---------|-----|
| **A → B → A** | Bidirectional relationship | Extract shared interface to a third module/class |
| **A → B → C → A** | Layer violation | Move one dependency to an event/observer pattern |
| **Service → Repository → Service** | Cross-domain query | Extract a query service or use CQRS |

**Iron rule:** If you find yourself adding `@Lazy` to break a circular dependency, **stop**. Refactor the design instead.