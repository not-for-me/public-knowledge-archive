# Programming — Python

---

## Tech Stack

| Component | Version / Tool |
|-----------|---------------|
| Python | 3.12+ |
| Framework | FastAPI |
| Validation | Pydantic v2 |
| Package & env | UV |
| Async | `asyncio` (FastAPI-native) |

---

## UV Commands

UV replaces `pip`, `pip-tools`, `venv`, and `poetry`.

```bash
# Create and activate a virtual environment
uv venv
source .venv/bin/activate          # macOS/Linux
# .venv\Scripts\activate           # Windows

# Sync dependencies from pyproject.toml / uv.lock
uv sync

# Add a dependency
uv add fastapi uvicorn[standard]
uv add --dev pytest pytest-cov pytest-mock

# Run a script / module
uv run python -m api.routes

# Lock dependencies
uv lock
```

**Rules:**
- Always commit `uv.lock`. It pins transitive dependencies deterministically.
- Never use `pip install` directly. All dependencies go through `uv add`.
- `pyproject.toml` is the single source of truth for dependencies and metadata.

---

## Project Structure

```
project-root/
├── pyproject.toml
├── uv.lock
├── .gitignore
├── src/
│   ├── __init__.py
│   ├── domain/
│   │   ├── __init__.py
│   │   ├── models.py          # Domain entities, value objects
│   │   └── exceptions.py      # Domain-specific exceptions
│   │
│   ├── application/
│   │   ├── __init__.py
│   │   ├── services.py        # Application services (orchestration)
│   │   ├── dto.py             # Request/response schemas (Pydantic v2)
│   │   └── ports.py           # Repository / gateway interfaces (Protocols)
│   │
│   ├── infrastructure/
│   │   ├── __init__.py
│   │   ├── database/          # SQLAlchemy async, migrations
│   │   ├── messaging/         # Kafka / RabbitMQ producers
│   │   └── external/          # HTTP clients, third-party APIs
│   │
│   └── api/
│       ├── __init__.py
│       └── routes.py          # FastAPI route definitions
│
└── tests/
    ├── unit/
    ├── integration/
    └── conftest.py
```

---

## FastAPI + Pydantic v2 Conventions

### Routes — Thin, No Business Logic

```python
# src/api/routes.py
from fastapi import APIRouter, Depends, status
from src.application.dto import CreateOrderRequest, OrderResponse
from src.application.services import OrderService
from src.domain.models import OrderId

router = APIRouter(prefix="/api/v1/orders", tags=["orders"])

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_order(
    request: CreateOrderRequest,
    service: OrderService = Depends(get_order_service),
) -> OrderResponse:
    result = await service.create_order(request.to_command())
    return OrderResponse.from_domain(result)
```

- Routes call into application services. No direct database or domain logic.
- Dependency injection via FastAPI `Depends()`.

### Pydantic v2 Schemas

```python
# src/application/dto.py
from pydantic import BaseModel, Field
from uuid import UUID, uuid4
from decimal import Decimal
from datetime import datetime

class CreateOrderRequest(BaseModel):
    customer_id: UUID
    items: list[OrderLineItem]
    shipping_address: Address

    model_config = {"frozen": True}  # immutability by default

class OrderLineItem(BaseModel):
    product_id: UUID
    quantity: int = Field(ge=1)
    unit_price: Decimal = Field(gt=Decimal("0"))

class OrderResponse(BaseModel):
    order_id: UUID
    status: str
    total: Decimal
    created_at: datetime
```

- Use `BaseModel` (not `dataclass`) for API boundaries.
- `model_config = {"frozen": True}` for request/response schemas.
- Use `Field(ge=...)`, `Field(pattern=r"...")` for validation.

---

## Type Hints & Idioms

### `X | None` — Not `Optional[X]`

```python
# ✅ Good — Python 3.10+ union syntax
def find_user(user_id: UUID) -> User | None:
    ...

# ❌ Avoid — legacy style
from typing import Optional
def find_user(user_id: UUID) -> Optional[User]:  # noqa
    ...
```

**Rule:** Use `X | None` everywhere. `Optional[X]` is only acceptable when supporting Python < 3.10.

### All public functions and methods must have type hints.

```python
# ✅ Good
def calculate_discount(price: Decimal, rate: float) -> Decimal:
    return price * Decimal(str(rate))

# ❌ Bad — no type hints
def calculate_discount(price, rate):
    return price * rate
```

### Google-Style Docstrings

```python
def create_order(command: CreateOrderCommand) -> Result[Order, DomainError]:
    """Create a new order from the given command.

    Validates inventory availability, calculates total, and persists
    the order. Returns a DomainError if stock is insufficient.

    Args:
        command: The validated creation command with customer and items.

    Returns:
        A Result containing either the created Order or a DomainError.
    """
    ...
```

**Structure:** Summary line (verb + object), blank line, description, `Args:`, `Returns:`, optional `Raises:`.

---

## Domain Layer Rules (Same as Kotlin Hexagonal)

- `src/domain/` has zero dependencies on FastAPI, SQLAlchemy, or Pydantic.
- Domain models use plain `@dataclass` or `NamedTuple`.
- Domain exceptions live in `src/domain/exceptions.py` and extend `Exception`.

```python
# src/domain/models.py
from dataclasses import dataclass
from uuid import UUID, uuid4
from decimal import Decimal
from enum import Enum

class OrderStatus(Enum):
    PENDING = "PENDING"
    CONFIRMED = "CONFIRMED"
    SHIPPED = "SHIPPED"
    CANCELLED = "CANCELLED"

@dataclass(frozen=True)
class OrderId:
    value: UUID

@dataclass
class Order:
    id: OrderId
    customer_id: UUID
    status: OrderStatus
    total: Decimal
```

```python
# src/domain/exceptions.py
class DomainError(Exception):
    """Base exception for all domain errors."""
    ...

class InsufficientStockError(DomainError):
    def __init__(self, product_id: UUID, requested: int, available: int):
        self.product_id = product_id
        self.requested = requested
        self.available = available
        super().__init__(
            f"Insufficient stock for product {product_id}: "
            f"requested {requested}, available {available}"
        )
```