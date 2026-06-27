# Architecture & Design — Python

## Visibility & API surface

| Prefix   | Meaning   | Usage                                                        |
| :------- | :-------- | :----------------------------------------------------------- |
| `name`   | Public    | External symbols; list in `__all__`                          |
| `_name`  | Protected | Internal; stable within the module, not an external contract |
| `__name` | Private   | Name-mangling for subclass collision avoidance only          |

Always define `__all__` in modules that export a public API:

```python
__all__ = ["Processor", "Status"]
```

## Design patterns

```python
from enum import Enum
from typing import Protocol, TypedDict

# Prefer Enum over bare string constants
class Status(Enum):
    PENDING = "pending"
    ACTIVE = "active"

# Protocol for structural contracts (duck typing) — not abc.ABC
class OrderRepository(Protocol):
    def save(self, order: Order) -> None: ...
    def find_by_id(self, order_id: int) -> Order | None: ...

# Factory via classmethod — avoid @staticmethod
class Processor:
    def __init__(self, name: str) -> None:
        self._name = name

    @classmethod
    def from_config(cls, config: dict[str, str]) -> Processor:
        return cls(config["name"])
```

## Value Objects — `@dataclass(frozen=True)`

A Value Object encapsulates a primitive with strong semantics. Immutable, compared by value, with no identity of its own.

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class Money:
    amount: int  # cents — never a float for monetary amounts
    currency: str

    def __post_init__(self) -> None:
        if self.amount < 0:
            raise ValueError("Amount cannot be negative")

@dataclass(frozen=True)
class EmailAddress:
    value: str

    def __post_init__(self) -> None:
        if "@" not in self.value:
            raise ValueError(f"Invalid email: {self.value}")

# Usage: Money(1000, "EUR") != Money(1000, "USD")
# Domain entities use Value Objects, not bare primitives
```

## `dataclass` vs `TypedDict` — choosing

| Criterion                               | `@dataclass`      | `TypedDict` |
| :-------------------------------------- | :---------------- | :---------- |
| Behavior (methods, validation)          | ✅                 | ❌           |
| Immutability (`frozen=True`)            | ✅                 | ❌           |
| External data without logic (JSON, API) | ❌                 | ✅           |
| Zero runtime overhead                   | ❌                 | ✅           |
| Domain Value Objects                    | ✅                 | ❌           |
| Structured data schema                  | Context-dependent | ✅           |

```python
# TypedDict — structured external data without logic
class UserData(TypedDict):
    id: int
    email: str

# dataclass — entity with behavior or immutability
@dataclass
class User:
    id: int
    email: EmailAddress

    def change_email(self, new_email: EmailAddress) -> "User":
        return User(id=self.id, email=new_email)
```

## Type system

```python
from __future__ import annotations
from typing import Protocol, TypedDict, Literal, Annotated, Mapping

# Native generics (not typing.List / typing.Dict)
items: list[str]
counts: dict[str, int]

# Literal — fixed set of values
Status = Literal["pending", "active", "closed"]

# Immutable config — Mapping, or frozendict in 3.14+
Config = Mapping[str, str]
```

Zero `Any`. Use `object` or `Unknown` (ty) when the type is genuinely unknown.

## Hexagonal structure

```text
src/
├── domain/          ← Entities, Value Objects (zero external imports)
├── application/     ← Use Cases + Ports (Protocol interfaces)
└── infrastructure/  ← Adapters (DB, APIs) + Composition Root
```

Dependency rule: **always inward** — Infrastructure → Application → Domain.

```python
# application/ports.py — Port as a Protocol (Application layer)
class OrderRepository(Protocol):
    def save(self, order: Order) -> None: ...

# infrastructure/adapters/sql_orders.py — Adapter (Infrastructure layer)
class SQLOrderRepository:
    def save(self, order: Order) -> None:
        ...  # SQLAlchemy here — the Domain never sees this
```

Domain entities hold the business logic — not plain data bags (avoid the Anemic Domain Model).

### Enforcing the dependency rule

The inward rule must be machine-checked, not just documented:

- **import-linter** — declare import contracts (`layers`, `forbidden`, `independence`) in `pyproject.toml` and gate them in CI (e.g. `domain/` may never import `infrastructure/`). Introduce early — hard to retrofit on a layered legacy.
- **deptry** — catches missing, unused, or transitively-imported dependencies declared in `pyproject.toml`. Complements import-linter (declared vs. actually-used packages).

## Fakes for Port tests

Prefer fakes (lightweight in-memory implementations) over complex mocks for testing Ports.

```python
# tests/fakes.py — Fake of the OrderRepository Port
class InMemoryOrderRepository:
    def __init__(self) -> None:
        self._store: dict[int, Order] = {}

    def save(self, order: Order) -> None:
        self._store[order.id] = order

    def find_by_id(self, order_id: int) -> Order | None:
        return self._store.get(order_id)

# In the test — no mock.patch, no MagicMock
def test_process_order() -> None:
    repo = InMemoryOrderRepository()
    service = OrderService(repo)
    service.process(order_id=1)
    assert repo.find_by_id(1) is not None
```

## Success criteria

- `__all__` defines the explicit public surface.
- `Protocol` used for all structural contracts, not `abc.ABC`.
- No infrastructure imports in Domain or Application — enforced by `import-linter` contracts in CI.
- Fakes (not complex mocks) used to test Ports.
- `@dataclass(frozen=True)` for immutable Value Objects.
- `TypedDict` for external data without logic.
- `from __future__ import annotations` at the top of every file.
- Zero `Any`, zero `typing.List`/`typing.Dict`.
