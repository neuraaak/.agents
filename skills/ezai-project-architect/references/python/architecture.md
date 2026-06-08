# Architecture & Design — Python

## Visibility & API surface

| Prefix   | Meaning   | Use for                                               |
| :------- | :-------- | :---------------------------------------------------- |
| `name`   | Public    | External symbols; list in `__all__`                   |
| `_name`  | Protected | Internal; stable within module, not external contract |
| `__name` | Private   | Subclass name-collision avoidance only                |

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

## Type system

```python
from __future__ import annotations
from typing import Protocol, TypedDict, Literal, Annotated, Mapping

# Native generics (no typing.List / typing.Dict)
items: list[str]
counts: dict[str, int]

# TypedDict — structured external data, no runtime overhead
class UserData(TypedDict):
    id: int
    email: str

# Literal — fixed value set
Status = Literal["pending", "active", "closed"]

# Immutable config — Mapping, or frozendict in 3.14+
Config = Mapping[str, str]
```

Zero `Any`. Use `object` or `Unknown` (ty) when type is truly unknown.

## Hexagonal structure

```txt
src/
├── domain/          ← Entities, Value Objects (zero external imports)
├── application/     ← Use Cases + Ports (Protocol interfaces)
└── infrastructure/  ← Adapters (DB, APIs) + Composition Root
```

Dependency rule: **always inward** — Infrastructure → Application → Domain.

```python
# application/ports.py — Port as Protocol (Application layer)
class OrderRepository(Protocol):
    def save(self, order: Order) -> None: ...

# infrastructure/adapters/sql_orders.py — Adapter (Infrastructure layer)
class SQLOrderRepository:
    def save(self, order: Order) -> None:
        ...  # SQLAlchemy here — Domain never sees this
```

Domain entities contain business logic — not just data bags (avoid anemic domain).

## Success criteria

- `__all__` defines the explicit public surface.
- `Protocol` used for all structural contracts, not `abc.ABC`.
- No infrastructure imports in Domain or Application layers.
- Fakes (not complex mocks) used to test Ports.
- `from __future__ import annotations` at every file top.
- Zero `Any`, zero `typing.List`/`typing.Dict`.
